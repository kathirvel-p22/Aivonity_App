"""
AIVONITY Diagnosis Agent
Advanced predictive maintenance and failure prediction with ML models
"""

import asyncio
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
from sklearn.ensemble import RandomForestClassifier, IsolationForest
from sklearn.preprocessing import StandardScaler, LabelEncoder, MinMaxScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
import xgboost as xgb
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import LSTM, Dense, Dropout, BatchNormalization
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
import joblib
import json
import os
from pathlib import Path
import pickle
import hashlib

from app.agents.base_agent import BaseAgent, AgentMessage
from app.db.models import TelemetryData, Vehicle, MaintenancePrediction
from app.db.database import AsyncSessionLocal
from app.config import settings
from app.ml.model_trainer import MLModelTrainer
from app.ml.model_utils import ModelUtils
from sqlalchemy import select, and_, desc
from sqlalchemy.orm import selectinload

class DiagnosisAgent(BaseAgent):
    """
    Advanced Diagnosis Agent for predictive maintenance
    Handles ML-based failure prediction and health assessment with XGBoost and LSTM models
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("diagnosis_agent", config)
        
        # ML Models - Component-specific models
        self.xgboost_models = {}  # One model per component
        self.lstm_models = {}     # One LSTM model per component
        self.scalers = {}         # One scaler per component
        self.feature_encoders = {}
        
        # Model configuration
        self.prediction_threshold = config.get("prediction_threshold", 0.7)
        self.lookback_days = config.get("lookback_days", 30)
        self.lstm_sequence_length = config.get("lstm_sequence_length", 15)
        self.min_data_points = config.get("min_data_points", 50)
        
        # Component failure patterns with enhanced sensor mappings
        self.component_patterns = {
            "engine": {
                "sensors": ["engine_temp", "oil_pressure", "rpm", "engine_load", "fuel_consumption"],
                "failure_indicators": ["overheating", "low_oil_pressure", "irregular_rpm"],
                "normal_ranges": {
                    "engine_temp": (80, 105),  # Celsius
                    "oil_pressure": (20, 80),  # PSI
                    "rpm": (600, 6000)
                }
            },
            "transmission": {
                "sensors": ["transmission_temp", "gear_position", "rpm", "speed", "transmission_pressure"],
                "failure_indicators": ["overheating", "gear_slipping", "pressure_drop"],
                "normal_ranges": {
                    "transmission_temp": (70, 95),
                    "transmission_pressure": (50, 200)
                }
            },
            "battery": {
                "sensors": ["battery_voltage", "charging_current", "battery_temp", "alternator_output"],
                "failure_indicators": ["voltage_drop", "charging_issues", "overheating"],
                "normal_ranges": {
                    "battery_voltage": (12.0, 14.4),
                    "charging_current": (-50, 100)
                }
            },
            "brakes": {
                "sensors": ["brake_pressure", "brake_temp", "speed", "brake_fluid_level", "abs_activity"],
                "failure_indicators": ["pressure_loss", "overheating", "fluid_leak"],
                "normal_ranges": {
                    "brake_pressure": (0, 2000),  # PSI
                    "brake_temp": (20, 300)       # Celsius
                }
            },
            "cooling_system": {
                "sensors": ["engine_temp", "coolant_temp", "fan_speed", "coolant_level", "thermostat_position"],
                "failure_indicators": ["overheating", "coolant_leak", "fan_failure"],
                "normal_ranges": {
                    "coolant_temp": (75, 100),
                    "fan_speed": (0, 3000)
                }
            },
            "fuel_system": {
                "sensors": ["fuel_pressure", "fuel_level", "engine_load", "fuel_consumption", "injector_pulse"],
                "failure_indicators": ["pressure_drop", "consumption_spike", "injector_failure"],
                "normal_ranges": {
                    "fuel_pressure": (30, 80),  # PSI
                    "fuel_level": (0, 100)      # Percentage
                }
            }
        }
        
        # Model serving infrastructure
        self.prediction_cache = {}
        self.cache_ttl = config.get("cache_ttl", 3600)  # 1 hour
        self.model_cache = {}
        self.feature_cache = {}
        
        # Performance tracking
        self.predictions_made = 0
        self.high_risk_predictions = 0
        self.model_accuracy = {}
        self.model_performance_history = {}
        
        # Model paths
        self.model_base_path = Path(settings.ML_MODEL_PATH) / "diagnosis"
        self.model_base_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize ML trainer and utilities
        self.ml_trainer = MLModelTrainer({
            "model_path": str(self.model_base_path),
            "xgb_params": {
                "n_estimators": 200,
                "max_depth": 8,
                "learning_rate": 0.1,
                "subsample": 0.8,
                "colsample_bytree": 0.8,
                "random_state": 42,
                "eval_metric": "logloss"
            },
            "lstm_params": {
                "epochs": 100,
                "batch_size": 32,
                "validation_split": 0.2,
                "patience": 15,
                "min_delta": 0.001
            }
        })
        self.model_utils = ModelUtils()

    def _define_capabilities(self) -> List[str]:
        """Define Diagnosis Agent capabilities"""
        return [
            "failure_prediction",
            "component_health_assessment", 
            "trend_analysis",
            "risk_scoring",
            "maintenance_recommendations",
            "model_training",
            "pattern_recognition",
            "predictive_analytics",
            "xgboost_prediction",
            "lstm_forecasting",
            "model_serving",
            "cache_management"
        ]

    async def _initialize_resources(self):
        """Initialize ML models and resources"""
        try:
            # Load or train ML models for each component
            await self._load_all_ml_models()
            
            # Initialize model serving infrastructure
            await self._initialize_model_serving()
            
            # Start prediction scheduling task
            asyncio.create_task(self._prediction_scheduling_loop())
            
            # Start model retraining task
            asyncio.create_task(self._model_retraining_loop())
            
            # Start cache cleanup task
            asyncio.create_task(self._cache_cleanup_loop())
            
            self.logger.info("✅ Diagnosis Agent resources initialized with ML models")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize Diagnosis Agent resources: {e}")
            raise

    async def _initialize_model_serving(self):
        """Initialize model serving infrastructure with caching"""
        try:
            # Initialize prediction cache
            self.prediction_cache = {}
            self.feature_cache = {}
            
            # Warm up models by running test predictions
            for component in self.component_patterns.keys():
                if component in self.xgboost_models and component in self.lstm_models:
                    # Create dummy data for warmup
                    dummy_features = ModelUtils.create_dummy_features(component)
                    dummy_sequence = ModelUtils.create_dummy_sequence(component)
                    
                    # Warm up XGBoost model
                    if dummy_features is not None:
                        _ = self.xgboost_models[component].predict_proba([dummy_features])
                    
                    # Warm up LSTM model
                    if dummy_sequence is not None:
                        _ = self.lstm_models[component].predict(dummy_sequence, verbose=0)
            
            self.logger.info("✅ Model serving infrastructure initialized")
            
        except Exception as e:
            self.logger.error(f"❌ Error initializing model serving: {e}")
            raise

    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process incoming messages for diagnosis and prediction"""
        try:
            message_type = message.message_type
            payload = message.payload
            
            if message_type == "anomaly_detected":
                return await self._process_anomaly_alert(payload, message.correlation_id)
            
            elif message_type == "prediction_request":
                return await self._process_prediction_request(payload, message.correlation_id)
            
            elif message_type == "health_assessment":
                return await self._process_health_assessment(payload, message.correlation_id)
            
            elif message_type == "model_retrain":
                return await self._process_model_retrain(payload, message.correlation_id)
            
            elif message_type == "trend_analysis":
                return await self._process_trend_analysis(payload, message.correlation_id)
            
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

    async def _process_anomaly_alert(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process anomaly alert and generate predictions"""
        try:
            vehicle_id = payload.get("vehicle_id")
            processed_data = payload.get("processed_data", {})
            
            self.logger.info(f"🔍 Processing anomaly alert for vehicle {vehicle_id}")
            
            # Generate failure predictions for all components
            predictions = await self._generate_failure_predictions(vehicle_id, processed_data)
            
            # Assess overall vehicle health
            health_assessment = await self._assess_vehicle_health(vehicle_id, predictions)
            
            # Save predictions to database
            await self._save_predictions(vehicle_id, predictions)
            
            # Update vehicle health score
            await self._update_vehicle_health_score(vehicle_id, health_assessment["health_score"])
            
            # Determine response based on risk level
            max_risk = max([p["failure_probability"] for p in predictions], default=0.0)
            
            response_payload = {
                "vehicle_id": vehicle_id,
                "predictions": predictions,
                "health_assessment": health_assessment,
                "requires_immediate_attention": max_risk > 0.8,
                "recommended_actions": self._generate_recommendations(predictions)
            }
            
            # Send to scheduling agent if high risk
            recipient = "scheduling_agent" if max_risk > self.prediction_threshold else "customer_agent"
            message_type = "urgent_maintenance_needed" if max_risk > 0.8 else "maintenance_recommendations"
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=recipient,
                message_type=message_type,
                payload=response_payload,
                priority=4 if max_risk > 0.8 else 2,
                correlation_id=correlation_id
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error processing anomaly alert: {e}")
            raise

    async def _generate_failure_predictions(self, vehicle_id: str, current_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate failure predictions for all vehicle components"""
        try:
            predictions = []
            
            # Get historical telemetry data
            historical_data = await self._get_historical_telemetry(vehicle_id)
            
            if len(historical_data) < 10:  # Need minimum data for predictions
                self.logger.warning(f"⚠️ Insufficient historical data for vehicle {vehicle_id}")
                return self._generate_baseline_predictions(vehicle_id, current_data)
            
            # Generate predictions for each component
            for component, pattern in self.component_patterns.items():
                try:
                    # Extract relevant sensor data
                    component_data = self._extract_component_data(historical_data, pattern["sensors"])
                    current_component_data = {k: v for k, v in current_data.get("sensor_data", {}).items() if k in pattern["sensors"]}
                    
                    if component_data.empty or not current_component_data:
                        continue
                    
                    # XGBoost prediction
                    xgb_prediction = await self._predict_with_xgboost(component, component_data, current_component_data)
                    
                    # LSTM prediction for trend analysis
                    lstm_prediction = await self._predict_with_lstm(component, component_data, current_component_data)
                    
                    # Combine predictions with weighted average
                    combined_probability = (xgb_prediction["probability"] * 0.6 + lstm_prediction["probability"] * 0.4)
                    combined_confidence = min(xgb_prediction["confidence"], lstm_prediction["confidence"])
                    
                    # Calculate timeframe based on degradation rate
                    timeframe_days = self._calculate_failure_timeframe(combined_probability, lstm_prediction.get("trend", 0))
                    
                    prediction = {
                        "component": component,
                        "failure_probability": combined_probability,
                        "confidence_score": combined_confidence,
                        "timeframe_days": timeframe_days,
                        "recommended_action": self._get_component_recommendation(component, combined_probability),
                        "urgency_level": self._get_urgency_level(combined_probability, timeframe_days),
                        "model_details": {
                            "xgboost": xgb_prediction,
                            "lstm": lstm_prediction,
                            "combined_method": "weighted_average"
                        }
                    }
                    
                    predictions.append(prediction)
                    
                except Exception as e:
                    self.logger.error(f"❌ Error predicting for component {component}: {e}")
                    continue
            
            self.predictions_made += len(predictions)
            self.high_risk_predictions += len([p for p in predictions if p["failure_probability"] > 0.7])
            
            return predictions
            
        except Exception as e:
            self.logger.error(f"❌ Error generating failure predictions: {e}")
            return []

    async def _predict_with_xgboost(self, component: str, historical_data: pd.DataFrame, current_data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate prediction using XGBoost model"""
        try:
            if component not in self.xgboost_models:
                return {"probability": 0.5, "confidence": 0.3, "method": "fallback"}
            
            # Prepare features
            features = self._prepare_xgboost_features(historical_data, current_data)
            
            # Make prediction
            model = self.xgboost_models[component]
            probability = float(model.predict_proba([features])[0][1])
            
            # Calculate confidence based on feature importance and data quality
            confidence = ModelUtils.calculate_xgboost_confidence(features, historical_data)
            
            return {
                "probability": probability,
                "confidence": confidence,
                "method": "xgboost",
                "feature_importance": ModelUtils.get_feature_importance(component, model)
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error in XGBoost prediction: {e}")
            return {"probability": 0.5, "confidence": 0.2, "method": "error_fallback"}

    async def _predict_with_lstm(self, component: str, historical_data: pd.DataFrame, current_data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate prediction using LSTM model for trend analysis"""
        try:
            if component not in self.lstm_models:
                return {"probability": 0.5, "confidence": 0.3, "trend": 0, "method": "fallback"}
            
            # Prepare sequence data for LSTM
            sequence_data = self._prepare_lstm_sequence(historical_data, current_data)
            
            if len(sequence_data) < self.lstm_sequence_length:
                return {"probability": 0.5, "confidence": 0.2, "trend": 0, "method": "insufficient_data"}
            
            # Normalize sequence data using component scaler
            if component in self.scalers:
                scaler = self.scalers[component]
                sequence_array = np.array(sequence_data[-self.lstm_sequence_length:])
                normalized_sequence = scaler.transform(sequence_array.reshape(-1, sequence_array.shape[-1])).reshape(sequence_array.shape)
                X = normalized_sequence.reshape(1, self.lstm_sequence_length, -1)
            else:
                X = np.array(sequence_data[-self.lstm_sequence_length:]).reshape(1, self.lstm_sequence_length, -1)
            
            # Make prediction
            model = self.lstm_models[component]
            prediction = model.predict(X, verbose=0)
            probability = float(prediction[0][0])
            
            # Calculate trend (degradation rate)
            trend = ModelUtils.calculate_degradation_trend(sequence_data)
            
            # Calculate confidence based on sequence stability
            confidence = ModelUtils.calculate_lstm_confidence(sequence_data)
            
            return {
                "probability": probability,
                "confidence": confidence,
                "trend": trend,
                "method": "lstm",
                "sequence_length": len(sequence_data)
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error in LSTM prediction: {e}")
            return {"probability": 0.5, "confidence": 0.2, "trend": 0, "method": "error_fallback"}

    def _prepare_xgboost_features(self, historical_data: pd.DataFrame, current_data: Dict[str, Any]) -> List[float]:
        """Prepare features for XGBoost model"""
        try:
            features = []
            
            # Statistical features from historical data
            for column in historical_data.columns:
                if column in current_data:
                    # Current value
                    features.append(current_data[column])
                    
                    # Statistical features
                    features.extend([
                        historical_data[column].mean(),
                        historical_data[column].std(),
                        historical_data[column].min(),
                        historical_data[column].max(),
                        historical_data[column].quantile(0.25),
                        historical_data[column].quantile(0.75)
                    ])
                    
                    # Trend features
                    if len(historical_data) > 1:
                        recent_mean = historical_data[column].tail(5).mean()
                        overall_mean = historical_data[column].mean()
                        features.append(recent_mean - overall_mean)  # Recent trend
            
            # Time-based features
            features.extend([
                len(historical_data),  # Data points available
                (datetime.now().hour / 24.0),  # Time of day normalized
                (datetime.now().weekday() / 7.0)  # Day of week normalized
            ])
            
            return features
            
        except Exception as e:
            self.logger.error(f"❌ Error preparing XGBoost features: {e}")
            return [0.0] * 20  # Return default features

    def _prepare_lstm_sequence(self, historical_data: pd.DataFrame, current_data: Dict[str, Any]) -> List[List[float]]:
        """Prepare sequence data for LSTM model"""
        try:
            sequence = []
            
            # Convert historical data to sequences
            for _, row in historical_data.iterrows():
                sequence_point = []
                for column in historical_data.columns:
                    sequence_point.append(float(row[column]))
                sequence.append(sequence_point)
            
            # Add current data point
            current_point = []
            for column in historical_data.columns:
                if column in current_data:
                    current_point.append(float(current_data[column]))
                else:
                    current_point.append(0.0)
            
            if current_point:
                sequence.append(current_point)
            
            return sequence
            
        except Exception as e:
            self.logger.error(f"❌ Error preparing LSTM sequence: {e}")
            return []

    async def _load_all_ml_models(self):
        """Load or train ML models for all components"""
        try:
            loaded_components = []
            
            for component in self.component_patterns.keys():
                try:
                    # Try to load existing models for this component
                    if await self._load_component_models(component):
                        loaded_components.append(component)
                        self.logger.info(f"✅ Loaded existing models for {component}")
                    else:
                        # Train new models for this component
                        await self._train_component_models(component)
                        loaded_components.append(component)
                        self.logger.info(f"✅ Trained new models for {component}")
                        
                except Exception as e:
                    self.logger.error(f"❌ Error with {component} models: {e}")
                    # Create fallback model for this component
                    self._create_fallback_models_for_component(component)
            
            self.logger.info(f"✅ ML models ready for components: {loaded_components}")
            
        except Exception as e:
            self.logger.error(f"❌ Error loading ML models: {e}")
            raise

    async def _load_component_models(self, component: str) -> bool:
        """Load ML models for a specific component"""
        try:
            xgb_path = self.model_base_path / f"{component}_xgboost.joblib"
            lstm_path = self.model_base_path / f"{component}_lstm.h5"
            scaler_path = self.model_base_path / f"{component}_scaler.joblib"
            
            # Check if all model files exist
            if not (xgb_path.exists() and lstm_path.exists() and scaler_path.exists()):
                return False
            
            # Load XGBoost model
            self.xgboost_models[component] = joblib.load(xgb_path)
            
            # Load LSTM model
            self.lstm_models[component] = load_model(lstm_path)
            
            # Load scaler
            self.scalers[component] = joblib.load(scaler_path)
            
            self.logger.info(f"✅ Loaded models for component: {component}")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error loading models for {component}: {e}")
            return False

    async def _train_component_models(self, component: str):
        """Train ML models for a specific component"""
        try:
            self.logger.info(f"🔄 Training models for component: {component}")
            
            # Get training data
            training_data = await self._get_training_data(component)
            
            if len(training_data) < self.min_data_points:
                self.logger.warning(f"⚠️ Insufficient training data for {component}: {len(training_data)} points")
                # Generate synthetic data for initial training
                synthetic_data = self.ml_trainer.generate_synthetic_training_data(component, 1000)
                training_data = pd.concat([training_data, synthetic_data], ignore_index=True)
                self.logger.info(f"📊 Using synthetic data for {component} training: {len(training_data)} total samples")
            
            # Train XGBoost model
            try:
                xgb_model, xgb_metrics = await self.ml_trainer.train_xgboost_model(
                    component, training_data, optimize_hyperparams=True
                )
                self.xgboost_models[component] = xgb_model
                self.model_accuracy[f"{component}_xgboost"] = xgb_metrics.__dict__
            except Exception as e:
                self.logger.error(f"❌ XGBoost training failed for {component}: {e}")
                self._create_fallback_xgboost_model(component)
            
            # Train LSTM model
            try:
                lstm_model, lstm_metrics, scaler = await self.ml_trainer.train_lstm_model(
                    component, training_data, self.lstm_sequence_length
                )
                self.lstm_models[component] = lstm_model
                self.scalers[component] = scaler
                self.model_accuracy[f"{component}_lstm"] = lstm_metrics.__dict__
            except Exception as e:
                self.logger.error(f"❌ LSTM training failed for {component}: {e}")
                self._create_fallback_lstm_model(component)
            
            # Save models
            if component in self.xgboost_models and component in self.lstm_models:
                await self.ml_trainer.save_models(
                    component, 
                    self.xgboost_models[component],
                    self.lstm_models[component],
                    self.scalers[component],
                    type('obj', (object,), self.model_accuracy.get(f"{component}_xgboost", {}))(),
                    type('obj', (object,), self.model_accuracy.get(f"{component}_lstm", {}))()
                )
            
            self.logger.info(f"✅ Successfully trained models for component: {component}")
            
        except Exception as e:
            self.logger.error(f"❌ Error training models for {component}: {e}")
            self._create_fallback_models_for_component(component)

    def _create_fallback_models_for_component(self, component: str):
        """Create simple fallback models when training fails"""
        try:
            self._create_fallback_xgboost_model(component)
            self._create_fallback_lstm_model(component)
            
            # Simple scaler
            dummy_X = np.random.random((100, 5))
            self.scalers[component] = StandardScaler()
            self.scalers[component].fit(dummy_X)
            
            self.logger.warning(f"⚠️ Created fallback models for {component}")
            
        except Exception as e:
            self.logger.error(f"❌ Error creating fallback models for {component}: {e}")

    def _create_fallback_xgboost_model(self, component: str):
        """Create simple fallback XGBoost model"""
        try:
            # Simple XGBoost fallback
            fallback_xgb = xgb.XGBClassifier(n_estimators=10, max_depth=3, random_state=42)
            
            # Create dummy training data
            dummy_X = np.random.random((100, 20))
            dummy_y = np.random.randint(0, 2, 100)
            
            fallback_xgb.fit(dummy_X, dummy_y)
            self.xgboost_models[component] = fallback_xgb
            
            self.logger.warning(f"⚠️ Created fallback XGBoost model for {component}")
            
        except Exception as e:
            self.logger.error(f"❌ Error creating fallback XGBoost model for {component}: {e}")

    def _create_fallback_lstm_model(self, component: str):
        """Create a simple fallback LSTM model"""
        try:
            model = Sequential([
                LSTM(32, input_shape=(self.lstm_sequence_length, 5)),
                Dense(1, activation='sigmoid')
            ])
            
            model.compile(
                optimizer='adam',
                loss='binary_crossentropy',
                metrics=['accuracy']
            )
            
            # Train on dummy data
            dummy_X = np.random.random((50, self.lstm_sequence_length, 5))
            dummy_y = np.random.randint(0, 2, 50)
            
            model.fit(dummy_X, dummy_y, epochs=5, verbose=0)
            self.lstm_models[component] = model
            
            self.logger.warning(f"⚠️ Created fallback LSTM model for {component}")
            
        except Exception as e:
            self.logger.error(f"❌ Error creating fallback LSTM for {component}: {e}")

    # Helper methods for data processing and utilities
    async def _get_historical_telemetry(self, vehicle_id: str) -> pd.DataFrame:
        """Get historical telemetry data for analysis"""
        try:
            async with AsyncSessionLocal() as session:
                # Get telemetry data from the last lookback period
                cutoff_date = datetime.utcnow() - timedelta(days=self.lookback_days)
                
                stmt = select(TelemetryData).where(
                    and_(
                        TelemetryData.vehicle_id == vehicle_id,
                        TelemetryData.timestamp >= cutoff_date,
                        TelemetryData.processed == True
                    )
                ).order_by(TelemetryData.timestamp)
                
                result = await session.execute(stmt)
                telemetry_records = result.scalars().all()
                
                if not telemetry_records:
                    return pd.DataFrame()
                
                # Convert to DataFrame
                data_rows = []
                for record in telemetry_records:
                    row = record.sensor_data.copy()
                    row['timestamp'] = record.timestamp
                    row['anomaly_score'] = record.anomaly_score or 0.0
                    data_rows.append(row)
                
                df = pd.DataFrame(data_rows)
                
                # Clean and prepare data
                df = df.select_dtypes(include=[np.number])  # Only numeric columns
                df = df.fillna(df.mean())  # Fill NaN with mean
                
                return df
                
        except Exception as e:
            self.logger.error(f"❌ Error getting historical telemetry: {e}")
            return pd.DataFrame()

    def _extract_component_data(self, historical_data: pd.DataFrame, sensors: List[str]) -> pd.DataFrame:
        """Extract data for specific component sensors"""
        try:
            available_sensors = [sensor for sensor in sensors if sensor in historical_data.columns]
            if not available_sensors:
                return pd.DataFrame()
            
            return historical_data[available_sensors].copy()
            
        except Exception as e:
            self.logger.error(f"❌ Error extracting component data: {e}")
            return pd.DataFrame()

    async def _get_training_data(self, component: str) -> pd.DataFrame:
        """Get historical training data for a component"""
        try:
            async with AsyncSessionLocal() as session:
                # Get telemetry data from multiple vehicles for training
                cutoff_date = datetime.utcnow() - timedelta(days=90)  # Last 90 days
                
                stmt = select(TelemetryData).where(
                    and_(
                        TelemetryData.timestamp >= cutoff_date,
                        TelemetryData.processed == True
                    )
                ).order_by(TelemetryData.timestamp).limit(10000)  # Limit for performance
                
                result = await session.execute(stmt)
                telemetry_records = result.scalars().all()
                
                if not telemetry_records:
                    return pd.DataFrame()
                
                # Convert to DataFrame
                data_rows = []
                for record in telemetry_records:
                    row = record.sensor_data.copy()
                    row['timestamp'] = record.timestamp
                    row['vehicle_id'] = str(record.vehicle_id)
                    row['anomaly_score'] = record.anomaly_score or 0.0
                    data_rows.append(row)
                
                df = pd.DataFrame(data_rows)
                
                # Filter for component-relevant sensors
                sensors = self.component_patterns[component]["sensors"]
                available_sensors = [s for s in sensors if s in df.columns]
                
                if available_sensors:
                    df = df[available_sensors + ['timestamp', 'vehicle_id', 'anomaly_score']]
                    df = df.select_dtypes(include=[np.number, 'datetime64'])
                    df = df.fillna(df.mean(numeric_only=True))
                
                return df
                
        except Exception as e:
            self.logger.error(f"❌ Error getting training data: {e}")
            return pd.DataFrame()

    def _calculate_failure_timeframe(self, probability: float, trend: float) -> int:
        """Calculate estimated timeframe until failure"""
        try:
            # Base timeframe based on probability
            if probability > 0.9:
                base_days = 7
            elif probability > 0.8:
                base_days = 14
            elif probability > 0.7:
                base_days = 30
            elif probability > 0.5:
                base_days = 60
            else:
                base_days = 90
            
            # Adjust based on trend (degradation rate)
            if trend > 0.1:  # Fast degradation
                base_days = int(base_days * 0.7)
            elif trend < -0.1:  # Improving trend
                base_days = int(base_days * 1.5)
            
            return max(base_days, 1)  # At least 1 day
            
        except Exception as e:
            self.logger.error(f"❌ Error calculating failure timeframe: {e}")
            return 30  # Default to 30 days

    def _get_component_recommendation(self, component: str, probability: float) -> str:
        """Get maintenance recommendation for component"""
        recommendations = {
            "engine": {
                0.9: "Immediate engine inspection required - potential critical failure",
                0.8: "Schedule engine diagnostic and oil change within 7 days",
                0.7: "Monitor engine parameters closely, schedule maintenance check",
                0.5: "Regular engine maintenance recommended within 30 days",
                0.0: "Engine operating normally, continue regular maintenance schedule"
            },
            "transmission": {
                0.9: "Urgent transmission service required - avoid heavy driving",
                0.8: "Schedule transmission fluid change and inspection",
                0.7: "Monitor transmission performance, check fluid levels",
                0.5: "Regular transmission maintenance recommended",
                0.0: "Transmission operating normally"
            },
            "battery": {
                0.9: "Replace battery immediately - risk of vehicle not starting",
                0.8: "Battery replacement recommended within 1-2 weeks",
                0.7: "Monitor battery performance, consider replacement soon",
                0.5: "Battery health declining, plan for replacement",
                0.0: "Battery operating normally"
            },
            "brakes": {
                0.9: "CRITICAL: Immediate brake inspection required for safety",
                0.8: "Schedule brake service within 3-5 days",
                0.7: "Brake system needs attention, schedule inspection",
                0.5: "Monitor brake performance, schedule routine service",
                0.0: "Brake system operating normally"
            },
            "cooling_system": {
                0.9: "Immediate cooling system repair required - risk of overheating",
                0.8: "Schedule cooling system service to prevent overheating",
                0.7: "Monitor engine temperature, check coolant levels",
                0.5: "Cooling system maintenance recommended",
                0.0: "Cooling system operating normally"
            },
            "fuel_system": {
                0.9: "Fuel system requires immediate attention",
                0.8: "Schedule fuel system cleaning and inspection",
                0.7: "Monitor fuel efficiency and performance",
                0.5: "Regular fuel system maintenance recommended",
                0.0: "Fuel system operating normally"
            }
        }
        
        component_recs = recommendations.get(component, {})
        
        # Find the appropriate recommendation based on probability
        for threshold in sorted(component_recs.keys(), reverse=True):
            if probability >= threshold:
                return component_recs[threshold]
        
        return f"Monitor {component} performance and follow regular maintenance schedule"

    def _get_urgency_level(self, probability: float, timeframe_days: int) -> str:
        """Determine urgency level based on probability and timeframe"""
        if probability > 0.9 or timeframe_days <= 7:
            return "critical"
        elif probability > 0.8 or timeframe_days <= 14:
            return "high"
        elif probability > 0.7 or timeframe_days <= 30:
            return "medium"
        else:
            return "low"

    def _generate_baseline_predictions(self, vehicle_id: str, current_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate baseline predictions when insufficient historical data"""
        predictions = []
        
        for component in self.component_patterns.keys():
            prediction = {
                "component": component,
                "failure_probability": 0.3,  # Low baseline probability
                "confidence_score": 0.2,     # Low confidence due to insufficient data
                "timeframe_days": 90,        # Conservative timeframe
                "recommended_action": f"Collect more data for {component} analysis",
                "urgency_level": "low",
                "model_details": {
                    "method": "baseline_insufficient_data"
                }
            }
            predictions.append(prediction)
        
        return predictions

    def _generate_recommendations(self, predictions: List[Dict[str, Any]]) -> List[str]:
        """Generate actionable recommendations based on predictions"""
        recommendations = []
        
        # Sort predictions by urgency
        sorted_predictions = sorted(predictions, key=lambda x: x["failure_probability"], reverse=True)
        
        for prediction in sorted_predictions:
            if prediction["failure_probability"] > 0.7:
                recommendations.append(prediction["recommended_action"])
        
        # Add general recommendations if no high-risk components
        if not recommendations:
            recommendations.append("Continue regular maintenance schedule")
            recommendations.append("Monitor vehicle performance for any changes")
        
        return recommendations

    async def _assess_vehicle_health(self, vehicle_id: str, predictions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Assess overall vehicle health based on component predictions"""
        try:
            if not predictions:
                return {"health_score": 0.8, "status": "unknown", "critical_components": []}
            
            # Calculate weighted health score
            total_weight = 0
            weighted_score = 0
            
            component_weights = {
                "engine": 0.25,
                "brakes": 0.20,
                "transmission": 0.15,
                "battery": 0.15,
                "cooling_system": 0.15,
                "fuel_system": 0.10
            }
            
            critical_components = []
            
            for prediction in predictions:
                component = prediction["component"]
                probability = prediction["failure_probability"]
                weight = component_weights.get(component, 0.1)
                
                # Convert failure probability to health score (inverse)
                component_health = 1.0 - probability
                weighted_score += component_health * weight
                total_weight += weight
                
                # Track critical components
                if probability > 0.8:
                    critical_components.append(component)
            
            # Calculate overall health score
            health_score = weighted_score / total_weight if total_weight > 0 else 0.8
            
            # Determine status
            if health_score > 0.8:
                status = "excellent"
            elif health_score > 0.6:
                status = "good"
            elif health_score > 0.4:
                status = "fair"
            elif health_score > 0.2:
                status = "poor"
            else:
                status = "critical"
            
            return {
                "health_score": health_score,
                "status": status,
                "critical_components": critical_components,
                "assessment_timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error assessing vehicle health: {e}")
            return {"health_score": 0.5, "status": "unknown", "critical_components": []}

    async def _save_predictions(self, vehicle_id: str, predictions: List[Dict[str, Any]]):
        """Save predictions to database"""
        try:
            async with AsyncSessionLocal() as session:
                for prediction in predictions:
                    db_prediction = MaintenancePrediction(
                        vehicle_id=vehicle_id,
                        component=prediction["component"],
                        failure_probability=prediction["failure_probability"],
                        confidence_score=prediction["confidence_score"],
                        recommended_action=prediction["recommended_action"],
                        timeframe_days=prediction["timeframe_days"],
                        status="pending",
                        created_at=datetime.utcnow()
                    )
                    session.add(db_prediction)
                
                await session.commit()
                self.logger.info(f"✅ Saved {len(predictions)} predictions for vehicle {vehicle_id}")
                
        except Exception as e:
            self.logger.error(f"❌ Error saving predictions: {e}")

    async def _update_vehicle_health_score(self, vehicle_id: str, health_score: float):
        """Update vehicle health score in database"""
        try:
            async with AsyncSessionLocal() as session:
                stmt = select(Vehicle).where(Vehicle.id == vehicle_id)
                result = await session.execute(stmt)
                vehicle = result.scalar_one_or_none()
                
                if vehicle:
                    vehicle.health_score = health_score
                    vehicle.updated_at = datetime.utcnow()
                    await session.commit()
                    self.logger.info(f"✅ Updated health score for vehicle {vehicle_id}: {health_score:.2f}")
                
        except Exception as e:
            self.logger.error(f"❌ Error updating vehicle health score: {e}")

    # Background task methods
    async def _prediction_scheduling_loop(self):
        """Background task for scheduled predictions"""
        while True:
            try:
                await asyncio.sleep(3600)  # Run every hour
                # Implementation for scheduled predictions would go here
            except Exception as e:
                self.logger.error(f"❌ Error in prediction scheduling loop: {e}")

    async def _model_retraining_loop(self):
        """Background task for model retraining"""
        while True:
            try:
                await asyncio.sleep(86400)  # Run daily
                # Implementation for model retraining would go here
            except Exception as e:
                self.logger.error(f"❌ Error in model retraining loop: {e}")

    async def _cache_cleanup_loop(self):
        """Background task for cache cleanup"""
        while True:
            try:
                await asyncio.sleep(1800)  # Run every 30 minutes
                # Implementation for cache cleanup would go here
            except Exception as e:
                self.logger.error(f"❌ Error in cache cleanup loop: {e}")

    # Placeholder methods for other message types
    async def _process_prediction_request(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process prediction request"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="prediction_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )

    async def _process_health_assessment(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process health assessment request"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="health_assessment_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )

    async def _process_model_retrain(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process model retraining request"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="system",
            message_type="retrain_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )

    async def _process_trend_analysis(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process trend analysis request"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="trend_analysis_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )