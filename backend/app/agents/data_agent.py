"""
AIVONITY Data Agent
Advanced telemetry processing and anomaly detection
"""

import asyncio
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import joblib
import json

from app.agents.base_agent import BaseAgent, AgentMessage
from app.db.models import TelemetryData, Vehicle
from app.db.database import AsyncSessionLocal
from app.utils.ml_utils import FeatureExtractor, DataValidator
from app.config import settings

class DataAgent(BaseAgent):
    """
    Advanced Data Agent for telemetry processing and anomaly detection
    Handles real-time data ingestion, preprocessing, and anomaly detection
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("data_agent", config)
        
        # ML Models
        self.anomaly_detector = None
        self.scaler = StandardScaler()
        self.feature_extractor = FeatureExtractor()
        self.data_validator = DataValidator()
        
        # Processing configuration
        self.batch_size = config.get("batch_size", settings.MAX_TELEMETRY_BATCH_SIZE)
        self.processing_interval = config.get("processing_interval", settings.TELEMETRY_PROCESSING_INTERVAL)
        self.anomaly_threshold = config.get("anomaly_threshold", settings.ANOMALY_THRESHOLD)
        
        # Data buffers
        self.telemetry_buffer = []
        self.processing_queue = asyncio.Queue()
        
        # Statistics tracking
        self.processed_count = 0
        self.anomaly_count = 0
        self.data_quality_scores = []

    def _define_capabilities(self) -> List[str]:
        """Define Data Agent capabilities"""
        return [
            "telemetry_ingestion",
            "data_preprocessing", 
            "anomaly_detection",
            "data_quality_assessment",
            "real_time_processing",
            "batch_processing",
            "feature_extraction",
            "statistical_analysis"
        ]

    async def _initialize_resources(self):
        """Initialize ML models and resources"""
        try:
            # Load or train anomaly detection model
            await self._load_anomaly_model()
            
            # Start batch processing task
            asyncio.create_task(self._batch_processing_loop())
            
            self.logger.info("✅ Data Agent resources initialized")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize Data Agent resources: {e}")
            raise

    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process incoming telemetry data messages"""
        try:
            message_type = message.message_type
            payload = message.payload
            
            if message_type == "telemetry_data":
                return await self._process_telemetry_data(payload, message.correlation_id)
            
            elif message_type == "batch_process":
                return await self._process_batch_request(payload, message.correlation_id)
            
            elif message_type == "model_update":
                return await self._update_anomaly_model(payload, message.correlation_id)
            
            elif message_type == "data_quality_check":
                return await self._perform_data_quality_check(payload, message.correlation_id)
            
            else:
                self.logger.warning(f"⚠️ Unknown message type: {message_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"❌ Error processing message: {e}")
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="error",
                payload={"error": str(e), "original_message_id": message.id},
                correlation_id=message.correlation_id
            )

    async def _process_telemetry_data(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process individual telemetry data point"""
        try:
            vehicle_id = payload.get("vehicle_id")
            sensor_data = payload.get("sensor_data", {})
            timestamp = payload.get("timestamp", datetime.utcnow().isoformat())
            
            # Validate incoming data
            validation_result = self.data_validator.validate_telemetry(sensor_data)
            if not validation_result["valid"]:
                self.logger.warning(f"⚠️ Invalid telemetry data for vehicle {vehicle_id}: {validation_result['errors']}")
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="diagnosis_agent",
                    message_type="validation_error",
                    payload={
                        "vehicle_id": vehicle_id,
                        "errors": validation_result["errors"],
                        "timestamp": timestamp
                    },
                    correlation_id=correlation_id
                )
            
            # Extract features for anomaly detection
            features = self.feature_extractor.extract_features(sensor_data)
            
            # Detect anomalies
            anomaly_score = await self._detect_anomaly(features)
            is_anomaly = anomaly_score > self.anomaly_threshold
            
            # Calculate data quality score
            quality_score = self._calculate_data_quality(sensor_data, validation_result)
            
            # Store processed data
            processed_data = {
                "vehicle_id": vehicle_id,
                "timestamp": timestamp,
                "sensor_data": sensor_data,
                "features": features,
                "anomaly_score": anomaly_score,
                "is_anomaly": is_anomaly,
                "quality_score": quality_score,
                "processing_metadata": {
                    "processed_at": datetime.utcnow().isoformat(),
                    "agent_version": self.version,
                    "feature_count": len(features),
                    "validation_passed": validation_result["valid"]
                }
            }
            
            # Save to database
            await self._save_telemetry_data(processed_data)
            
            # Update statistics
            self.processed_count += 1
            if is_anomaly:
                self.anomaly_count += 1
            self.data_quality_scores.append(quality_score)
            
            # Send to Diagnosis Agent if anomaly detected
            response_payload = {
                "vehicle_id": vehicle_id,
                "processed_data": processed_data,
                "requires_analysis": is_anomaly or quality_score < 0.7
            }
            
            # Determine recipient based on anomaly status
            recipient = "diagnosis_agent" if is_anomaly else "master_agent"
            message_type = "anomaly_detected" if is_anomaly else "data_processed"
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=recipient,
                message_type=message_type,
                payload=response_payload,
                priority=3 if is_anomaly else 1,
                correlation_id=correlation_id
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error processing telemetry data: {e}")
            raise

    async def _detect_anomaly(self, features: Dict[str, float]) -> float:
        """Detect anomalies using Isolation Forest"""
        try:
            if self.anomaly_detector is None:
                # Return neutral score if model not loaded
                return 0.5
            
            # Convert features to array
            feature_array = np.array(list(features.values())).reshape(1, -1)
            
            # Scale features
            scaled_features = self.scaler.transform(feature_array)
            
            # Get anomaly score
            anomaly_score = self.anomaly_detector.decision_function(scaled_features)[0]
            
            # Convert to probability (0-1 range)
            anomaly_probability = 1 / (1 + np.exp(anomaly_score))
            
            return float(anomaly_probability)
            
        except Exception as e:
            self.logger.error(f"❌ Error in anomaly detection: {e}")
            return 0.5  # Return neutral score on error

    def _calculate_data_quality(self, sensor_data: Dict[str, Any], validation_result: Dict[str, Any]) -> float:
        """Calculate data quality score"""
        try:
            quality_factors = []
            
            # Completeness score
            expected_sensors = ["engine_temp", "oil_pressure", "battery_voltage", "rpm", "speed"]
            present_sensors = [sensor for sensor in expected_sensors if sensor in sensor_data]
            completeness = len(present_sensors) / len(expected_sensors)
            quality_factors.append(completeness)
            
            # Validity score from validation
            validity = 1.0 if validation_result["valid"] else 0.5
            quality_factors.append(validity)
            
            # Range check score
            range_score = self._check_sensor_ranges(sensor_data)
            quality_factors.append(range_score)
            
            # Consistency score
            consistency_score = self._check_data_consistency(sensor_data)
            quality_factors.append(consistency_score)
            
            # Calculate weighted average
            weights = [0.3, 0.3, 0.2, 0.2]  # Completeness, Validity, Range, Consistency
            quality_score = sum(score * weight for score, weight in zip(quality_factors, weights))
            
            return min(max(quality_score, 0.0), 1.0)  # Clamp to [0, 1]
            
        except Exception as e:
            self.logger.error(f"❌ Error calculating data quality: {e}")
            return 0.5

    def _check_sensor_ranges(self, sensor_data: Dict[str, Any]) -> float:
        """Check if sensor values are within expected ranges"""
        try:
            # Define expected ranges for common sensors
            sensor_ranges = {
                "engine_temp": (60, 120),    # Celsius
                "oil_pressure": (10, 80),    # PSI
                "battery_voltage": (11, 15), # Volts
                "rpm": (0, 8000),           # RPM
                "speed": (0, 200),          # km/h
                "fuel_level": (0, 100)      # Percentage
            }
            
            in_range_count = 0
            total_count = 0
            
            for sensor, value in sensor_data.items():
                if sensor in sensor_ranges and isinstance(value, (int, float)):
                    min_val, max_val = sensor_ranges[sensor]
                    if min_val <= value <= max_val:
                        in_range_count += 1
                    total_count += 1
            
            return in_range_count / total_count if total_count > 0 else 1.0
            
        except Exception as e:
            self.logger.error(f"❌ Error checking sensor ranges: {e}")
            return 0.5

    def _check_data_consistency(self, sensor_data: Dict[str, Any]) -> float:
        """Check data consistency and logical relationships"""
        try:
            consistency_score = 1.0
            
            # Check logical relationships
            if "speed" in sensor_data and "rpm" in sensor_data:
                speed = sensor_data["speed"]
                rpm = sensor_data["rpm"]
                
                # Basic consistency check: if speed is 0, RPM should be low
                if speed == 0 and rpm > 1000:
                    consistency_score -= 0.2
                
                # If speed is high, RPM should also be reasonably high
                if speed > 50 and rpm < 1500:
                    consistency_score -= 0.2
            
            # Check engine temp vs other parameters
            if "engine_temp" in sensor_data and "speed" in sensor_data:
                temp = sensor_data["engine_temp"]
                speed = sensor_data["speed"]
                
                # Engine should warm up with driving
                if speed > 30 and temp < 70:
                    consistency_score -= 0.1
            
            return max(consistency_score, 0.0)
            
        except Exception as e:
            self.logger.error(f"❌ Error checking data consistency: {e}")
            return 0.5

    async def _save_telemetry_data(self, processed_data: Dict[str, Any]):
        """Save processed telemetry data to database"""
        try:
            async with AsyncSessionLocal() as session:
                telemetry = TelemetryData(
                    vehicle_id=processed_data["vehicle_id"],
                    timestamp=datetime.fromisoformat(processed_data["timestamp"].replace('Z', '+00:00')),
                    sensor_data=processed_data["sensor_data"],
                    anomaly_score=processed_data["anomaly_score"],
                    quality_score=processed_data["quality_score"],
                    processed=True,
                    processing_metadata=processed_data["processing_metadata"]
                )
                
                session.add(telemetry)
                await session.commit()
                
        except Exception as e:
            self.logger.error(f"❌ Error saving telemetry data: {e}")
            raise

    async def _load_anomaly_model(self):
        """Load or train anomaly detection model"""
        try:
            model_path = f"{settings.ML_MODEL_PATH}/anomaly_detector.joblib"
            scaler_path = f"{settings.ML_MODEL_PATH}/anomaly_scaler.joblib"
            
            try:
                # Try to load existing model
                self.anomaly_detector = joblib.load(model_path)
                self.scaler = joblib.load(scaler_path)
                self.logger.info("✅ Loaded existing anomaly detection model")
            except FileNotFoundError:
                # Train new model with synthetic data
                await self._train_anomaly_model()
                self.logger.info("✅ Trained new anomaly detection model")
                
        except Exception as e:
            self.logger.error(f"❌ Error loading anomaly model: {e}")
            # Create a simple fallback model
            self.anomaly_detector = IsolationForest(contamination=0.1, random_state=42)
            # Train with dummy data
            dummy_data = np.random.normal(0, 1, (100, 5))
            self.anomaly_detector.fit(dummy_data)

    async def _train_anomaly_model(self):
        """Train anomaly detection model with historical data"""
        try:
            # Generate synthetic training data for now
            # In production, this would use historical telemetry data
            training_data = self._generate_synthetic_training_data()
            
            # Train scaler
            self.scaler.fit(training_data)
            scaled_data = self.scaler.transform(training_data)
            
            # Train anomaly detector
            self.anomaly_detector = IsolationForest(
                contamination=0.1,
                random_state=42,
                n_estimators=100
            )
            self.anomaly_detector.fit(scaled_data)
            
            # Save models
            model_path = f"{settings.ML_MODEL_PATH}/anomaly_detector.joblib"
            scaler_path = f"{settings.ML_MODEL_PATH}/anomaly_scaler.joblib"
            
            joblib.dump(self.anomaly_detector, model_path)
            joblib.dump(self.scaler, scaler_path)
            
            self.logger.info("✅ Anomaly detection model trained and saved")
            
        except Exception as e:
            self.logger.error(f"❌ Error training anomaly model: {e}")
            raise

    def _generate_synthetic_training_data(self) -> np.ndarray:
        """Generate synthetic training data for anomaly detection"""
        # Generate normal operating conditions
        n_samples = 1000
        
        # Engine temperature: normal distribution around 90°C
        engine_temp = np.random.normal(90, 10, n_samples)
        
        # Oil pressure: normal distribution around 40 PSI
        oil_pressure = np.random.normal(40, 8, n_samples)
        
        # Battery voltage: normal distribution around 12.6V
        battery_voltage = np.random.normal(12.6, 0.5, n_samples)
        
        # RPM: varies with driving conditions
        rpm = np.random.normal(2000, 800, n_samples)
        
        # Speed: varies with driving conditions
        speed = np.random.normal(60, 30, n_samples)
        
        # Combine features
        training_data = np.column_stack([
            engine_temp, oil_pressure, battery_voltage, rpm, speed
        ])
        
        return training_data

    async def _batch_processing_loop(self):
        """Process telemetry data in batches for efficiency"""
        while self.is_running:
            try:
                if len(self.telemetry_buffer) >= self.batch_size:
                    # Process batch
                    batch = self.telemetry_buffer[:self.batch_size]
                    self.telemetry_buffer = self.telemetry_buffer[self.batch_size:]
                    
                    await self._process_telemetry_batch(batch)
                
                await asyncio.sleep(self.processing_interval)
                
            except Exception as e:
                self.logger.error(f"❌ Error in batch processing loop: {e}")
                await asyncio.sleep(5)

    async def _process_telemetry_batch(self, batch: List[Dict[str, Any]]):
        """Process a batch of telemetry data"""
        try:
            self.logger.info(f"📊 Processing batch of {len(batch)} telemetry records")
            
            # Process each record in the batch
            for record in batch:
                # Extract features and detect anomalies
                features = self.feature_extractor.extract_features(record["sensor_data"])
                anomaly_score = await self._detect_anomaly(features)
                
                # Update record with processing results
                record["anomaly_score"] = anomaly_score
                record["processed_at"] = datetime.utcnow().isoformat()
            
            # Batch save to database
            await self._batch_save_telemetry(batch)
            
            self.logger.info(f"✅ Batch processing complete")
            
        except Exception as e:
            self.logger.error(f"❌ Error processing telemetry batch: {e}")

    async def _batch_save_telemetry(self, batch: List[Dict[str, Any]]):
        """Save batch of telemetry data to database"""
        try:
            async with AsyncSessionLocal() as session:
                telemetry_records = []
                
                for record in batch:
                    telemetry = TelemetryData(
                        vehicle_id=record["vehicle_id"],
                        timestamp=datetime.fromisoformat(record["timestamp"]),
                        sensor_data=record["sensor_data"],
                        anomaly_score=record.get("anomaly_score"),
                        processed=True
                    )
                    telemetry_records.append(telemetry)
                
                session.add_all(telemetry_records)
                await session.commit()
                
        except Exception as e:
            self.logger.error(f"❌ Error batch saving telemetry data: {e}")
            raise

    async def health_check(self) -> Dict[str, Any]:
        """Perform comprehensive health check"""
        try:
            health_status = {
                "healthy": True,
                "timestamp": datetime.utcnow().isoformat(),
                "metrics": {
                    "processed_count": self.processed_count,
                    "anomaly_count": self.anomaly_count,
                    "anomaly_rate": self.anomaly_count / max(self.processed_count, 1),
                    "buffer_size": len(self.telemetry_buffer),
                    "average_quality": np.mean(self.data_quality_scores) if self.data_quality_scores else 0.0
                },
                "model_status": {
                    "anomaly_detector_loaded": self.anomaly_detector is not None,
                    "scaler_loaded": self.scaler is not None
                }
            }
            
            # Check if anomaly rate is too high
            anomaly_rate = health_status["metrics"]["anomaly_rate"]
            if anomaly_rate > 0.5:  # More than 50% anomalies might indicate a problem
                health_status["healthy"] = False
                health_status["issues"] = ["High anomaly rate detected"]
            
            return health_status
            
        except Exception as e:
            self.logger.error(f"❌ Error in health check: {e}")
            return {
                "healthy": False,
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e)
            }