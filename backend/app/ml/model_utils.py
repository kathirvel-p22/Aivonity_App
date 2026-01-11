"""
AIVONITY ML Model Utilities
Helper functions for ML model operations and predictions
"""

import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
import logging
from sklearn.preprocessing import StandardScaler, MinMaxScaler
import joblib

class ModelUtils:
    """Utility functions for ML model operations"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    @staticmethod
    def create_dummy_features(component: str, n_features: int = 20) -> Optional[List[float]]:
        """Create dummy features for model warmup"""
        try:
            # Component-specific feature ranges for realistic dummy data
            feature_ranges = {
                "engine": {
                    "engine_temp": (80, 105),
                    "oil_pressure": (20, 80),
                    "rpm": (600, 6000),
                    "engine_load": (0, 100),
                    "fuel_consumption": (5, 15)
                },
                "transmission": {
                    "transmission_temp": (70, 95),
                    "gear_position": (1, 6),
                    "rpm": (600, 6000),
                    "speed": (0, 120),
                    "transmission_pressure": (50, 200)
                },
                "battery": {
                    "battery_voltage": (12.0, 14.4),
                    "charging_current": (-50, 100),
                    "battery_temp": (20, 60),
                    "alternator_output": (13.5, 14.8)
                },
                "brakes": {
                    "brake_pressure": (0, 2000),
                    "brake_temp": (20, 300),
                    "speed": (0, 120),
                    "brake_fluid_level": (0, 100),
                    "abs_activity": (0, 1)
                },
                "cooling_system": {
                    "engine_temp": (80, 105),
                    "coolant_temp": (75, 100),
                    "fan_speed": (0, 3000),
                    "coolant_level": (0, 100),
                    "thermostat_position": (0, 100)
                },
                "fuel_system": {
                    "fuel_pressure": (30, 80),
                    "fuel_level": (0, 100),
                    "engine_load": (0, 100),
                    "fuel_consumption": (5, 15),
                    "injector_pulse": (1, 10)
                }
            }
            
            ranges = feature_ranges.get(component, {})
            features = []
            
            # Generate features based on component ranges
            for i, (sensor, (min_val, max_val)) in enumerate(ranges.items()):
                if i < n_features:
                    features.append(np.random.uniform(min_val, max_val))
            
            # Fill remaining features with generic values
            while len(features) < n_features:
                features.append(np.random.uniform(0, 100))
            
            return features[:n_features]
            
        except Exception as e:
            logging.error(f"❌ Error creating dummy features for {component}: {e}")
            return None

    @staticmethod
    def create_dummy_sequence(component: str, sequence_length: int = 15, n_features: int = 5) -> Optional[np.ndarray]:
        """Create dummy sequence for LSTM warmup"""
        try:
            # Create a sequence of dummy features
            sequence = []
            for _ in range(sequence_length):
                features = ModelUtils.create_dummy_features(component, n_features)
                if features:
                    sequence.append(features)
                else:
                    sequence.append([0.0] * n_features)
            
            return np.array(sequence).reshape(1, sequence_length, n_features)
            
        except Exception as e:
            logging.error(f"❌ Error creating dummy sequence for {component}: {e}")
            return None

    @staticmethod
    def calculate_xgboost_confidence(features: List[float], historical_data: pd.DataFrame) -> float:
        """Calculate confidence score for XGBoost prediction"""
        try:
            if len(features) == 0 or historical_data.empty:
                return 0.3
            
            # Calculate confidence based on feature stability and data quality
            confidence_factors = []
            
            # Feature completeness (no NaN or extreme values)
            feature_array = np.array(features)
            if not np.isnan(feature_array).any() and not np.isinf(feature_array).any():
                confidence_factors.append(0.3)
            else:
                confidence_factors.append(0.1)
            
            # Historical data quality
            if len(historical_data) > 50:
                confidence_factors.append(0.3)
            elif len(historical_data) > 20:
                confidence_factors.append(0.2)
            else:
                confidence_factors.append(0.1)
            
            # Feature variance (stable features = higher confidence)
            if len(historical_data) > 1:
                try:
                    variance = historical_data.select_dtypes(include=[np.number]).var().mean()
                    if variance < 100:  # Low variance = stable
                        confidence_factors.append(0.2)
                    else:
                        confidence_factors.append(0.1)
                except:
                    confidence_factors.append(0.1)
            else:
                confidence_factors.append(0.1)
            
            # Data recency
            if 'timestamp' in historical_data.columns:
                try:
                    latest_data = historical_data['timestamp'].max()
                    if isinstance(latest_data, str):
                        latest_data = pd.to_datetime(latest_data)
                    
                    hours_old = (datetime.now() - latest_data).total_seconds() / 3600
                    if hours_old < 24:
                        confidence_factors.append(0.2)
                    elif hours_old < 168:  # 1 week
                        confidence_factors.append(0.15)
                    else:
                        confidence_factors.append(0.05)
                except:
                    confidence_factors.append(0.1)
            else:
                confidence_factors.append(0.1)
            
            return min(sum(confidence_factors), 1.0)
            
        except Exception as e:
            logging.error(f"❌ Error calculating XGBoost confidence: {e}")
            return 0.5

    @staticmethod
    def calculate_lstm_confidence(sequence_data: List[List[float]]) -> float:
        """Calculate confidence score for LSTM prediction"""
        try:
            if not sequence_data or len(sequence_data) < 5:
                return 0.2
            
            confidence_factors = []
            
            # Sequence completeness
            sequence_array = np.array(sequence_data)
            if not np.isnan(sequence_array).any() and not np.isinf(sequence_array).any():
                confidence_factors.append(0.3)
            else:
                confidence_factors.append(0.1)
            
            # Sequence length adequacy
            if len(sequence_data) >= 15:
                confidence_factors.append(0.3)
            elif len(sequence_data) >= 10:
                confidence_factors.append(0.2)
            else:
                confidence_factors.append(0.1)
            
            # Sequence stability (low variance = higher confidence)
            try:
                if len(sequence_data) > 1:
                    variances = np.var(sequence_array, axis=0)
                    avg_variance = np.mean(variances)
                    
                    if avg_variance < 0.1:  # Very stable
                        confidence_factors.append(0.2)
                    elif avg_variance < 0.5:  # Moderately stable
                        confidence_factors.append(0.15)
                    else:
                        confidence_factors.append(0.05)
                else:
                    confidence_factors.append(0.1)
            except:
                confidence_factors.append(0.1)
            
            # Trend consistency
            try:
                if len(sequence_data) > 3:
                    # Calculate trend consistency across features
                    trends = []
                    for feature_idx in range(len(sequence_data[0])):
                        feature_values = [seq[feature_idx] for seq in sequence_data]
                        if len(feature_values) > 1:
                            trend = np.polyfit(range(len(feature_values)), feature_values, 1)[0]
                            trends.append(abs(trend))
                    
                    avg_trend = np.mean(trends) if trends else 0
                    if avg_trend < 0.1:  # Consistent trend
                        confidence_factors.append(0.2)
                    else:
                        confidence_factors.append(0.1)
                else:
                    confidence_factors.append(0.1)
            except:
                confidence_factors.append(0.1)
            
            return min(sum(confidence_factors), 1.0)
            
        except Exception as e:
            logging.error(f"❌ Error calculating LSTM confidence: {e}")
            return 0.5

    @staticmethod
    def calculate_degradation_trend(sequence_data: List[List[float]]) -> float:
        """Calculate degradation trend from sequence data"""
        try:
            if not sequence_data or len(sequence_data) < 3:
                return 0.0
            
            sequence_array = np.array(sequence_data)
            
            # Calculate trend for each feature
            trends = []
            
            for feature_idx in range(sequence_array.shape[1]):
                feature_values = sequence_array[:, feature_idx]
                
                # Remove NaN values
                valid_indices = ~np.isnan(feature_values)
                if np.sum(valid_indices) < 3:
                    continue
                
                valid_values = feature_values[valid_indices]
                valid_positions = np.arange(len(feature_values))[valid_indices]
                
                # Calculate linear trend
                if len(valid_values) > 1:
                    trend_coeff = np.polyfit(valid_positions, valid_values, 1)[0]
                    
                    # Normalize trend by feature range
                    feature_range = np.max(valid_values) - np.min(valid_values)
                    if feature_range > 0:
                        normalized_trend = trend_coeff / feature_range
                        trends.append(normalized_trend)
            
            if not trends:
                return 0.0
            
            # Calculate overall degradation trend
            # Positive trend indicates degradation, negative indicates improvement
            overall_trend = np.mean(trends)
            
            # Clip to reasonable range
            return np.clip(overall_trend, -1.0, 1.0)
            
        except Exception as e:
            logging.error(f"❌ Error calculating degradation trend: {e}")
            return 0.0

    @staticmethod
    def get_feature_importance(component: str, model=None) -> Dict[str, float]:
        """Get feature importance for component prediction"""
        try:
            if model and hasattr(model, 'feature_importances_'):
                # Get actual feature importance from trained model
                importances = model.feature_importances_
                
                # Create feature names based on component
                feature_names = ModelUtils._get_feature_names_for_component(component)
                
                # Create importance dictionary
                importance_dict = {}
                for i, importance in enumerate(importances):
                    if i < len(feature_names):
                        importance_dict[feature_names[i]] = float(importance)
                    else:
                        importance_dict[f"feature_{i}"] = float(importance)
                
                return importance_dict
            else:
                # Return default importance for component
                return ModelUtils._get_default_feature_importance(component)
                
        except Exception as e:
            logging.error(f"❌ Error getting feature importance for {component}: {e}")
            return ModelUtils._get_default_feature_importance(component)

    @staticmethod
    def _get_feature_names_for_component(component: str) -> List[str]:
        """Get feature names for a specific component"""
        component_features = {
            "engine": [
                "engine_temp_mean", "engine_temp_std", "engine_temp_current",
                "oil_pressure_mean", "oil_pressure_std", "oil_pressure_current",
                "rpm_mean", "rpm_std", "rpm_current",
                "engine_load_mean", "engine_load_std", "engine_load_current",
                "fuel_consumption_mean", "fuel_consumption_std", "fuel_consumption_current",
                "temporal_position", "data_quality", "trend_indicator"
            ],
            "transmission": [
                "transmission_temp_mean", "transmission_temp_std", "transmission_temp_current",
                "gear_position_mean", "gear_position_std", "gear_position_current",
                "rpm_mean", "rpm_std", "rpm_current",
                "speed_mean", "speed_std", "speed_current",
                "transmission_pressure_mean", "transmission_pressure_std", "transmission_pressure_current",
                "temporal_position", "data_quality", "trend_indicator"
            ],
            "battery": [
                "battery_voltage_mean", "battery_voltage_std", "battery_voltage_current",
                "charging_current_mean", "charging_current_std", "charging_current_current",
                "battery_temp_mean", "battery_temp_std", "battery_temp_current",
                "alternator_output_mean", "alternator_output_std", "alternator_output_current",
                "temporal_position", "data_quality", "trend_indicator"
            ],
            "brakes": [
                "brake_pressure_mean", "brake_pressure_std", "brake_pressure_current",
                "brake_temp_mean", "brake_temp_std", "brake_temp_current",
                "speed_mean", "speed_std", "speed_current",
                "brake_fluid_level_mean", "brake_fluid_level_std", "brake_fluid_level_current",
                "abs_activity_mean", "abs_activity_std", "abs_activity_current",
                "temporal_position", "data_quality", "trend_indicator"
            ],
            "cooling_system": [
                "engine_temp_mean", "engine_temp_std", "engine_temp_current",
                "coolant_temp_mean", "coolant_temp_std", "coolant_temp_current",
                "fan_speed_mean", "fan_speed_std", "fan_speed_current",
                "coolant_level_mean", "coolant_level_std", "coolant_level_current",
                "thermostat_position_mean", "thermostat_position_std", "thermostat_position_current",
                "temporal_position", "data_quality", "trend_indicator"
            ],
            "fuel_system": [
                "fuel_pressure_mean", "fuel_pressure_std", "fuel_pressure_current",
                "fuel_level_mean", "fuel_level_std", "fuel_level_current",
                "engine_load_mean", "engine_load_std", "engine_load_current",
                "fuel_consumption_mean", "fuel_consumption_std", "fuel_consumption_current",
                "injector_pulse_mean", "injector_pulse_std", "injector_pulse_current",
                "temporal_position", "data_quality", "trend_indicator"
            ]
        }
        
        return component_features.get(component, [f"feature_{i}" for i in range(20)])

    @staticmethod
    def _get_default_feature_importance(component: str) -> Dict[str, float]:
        """Get default feature importance when model is not available"""
        default_importance = {
            "engine": {
                "engine_temp_current": 0.25,
                "oil_pressure_current": 0.20,
                "rpm_current": 0.15,
                "engine_load_current": 0.12,
                "fuel_consumption_current": 0.10,
                "engine_temp_std": 0.08,
                "oil_pressure_std": 0.06,
                "trend_indicator": 0.04
            },
            "transmission": {
                "transmission_temp_current": 0.22,
                "transmission_pressure_current": 0.20,
                "gear_position_current": 0.18,
                "rpm_current": 0.15,
                "speed_current": 0.10,
                "transmission_temp_std": 0.08,
                "transmission_pressure_std": 0.07
            },
            "battery": {
                "battery_voltage_current": 0.30,
                "charging_current_current": 0.25,
                "battery_temp_current": 0.20,
                "alternator_output_current": 0.15,
                "battery_voltage_std": 0.10
            },
            "brakes": {
                "brake_pressure_current": 0.25,
                "brake_temp_current": 0.20,
                "brake_fluid_level_current": 0.18,
                "speed_current": 0.15,
                "abs_activity_current": 0.12,
                "brake_pressure_std": 0.10
            },
            "cooling_system": {
                "coolant_temp_current": 0.25,
                "engine_temp_current": 0.22,
                "fan_speed_current": 0.18,
                "coolant_level_current": 0.15,
                "thermostat_position_current": 0.12,
                "coolant_temp_std": 0.08
            },
            "fuel_system": {
                "fuel_pressure_current": 0.25,
                "fuel_consumption_current": 0.20,
                "fuel_level_current": 0.18,
                "engine_load_current": 0.15,
                "injector_pulse_current": 0.12,
                "fuel_pressure_std": 0.10
            }
        }
        
        return default_importance.get(component, {"default_feature": 1.0})

    @staticmethod
    def validate_model_input(data: Dict[str, Any], component: str) -> bool:
        """Validate input data for model prediction"""
        try:
            if not data or not isinstance(data, dict):
                return False
            
            # Check for required sensors based on component
            component_patterns = {
                "engine": ["engine_temp", "oil_pressure", "rpm"],
                "transmission": ["transmission_temp", "rpm", "speed"],
                "battery": ["battery_voltage", "charging_current"],
                "brakes": ["brake_pressure", "brake_temp"],
                "cooling_system": ["coolant_temp", "fan_speed"],
                "fuel_system": ["fuel_pressure", "fuel_level"]
            }
            
            required_sensors = component_patterns.get(component, [])
            
            # Check if at least 50% of required sensors are present
            present_sensors = [sensor for sensor in required_sensors if sensor in data]
            
            return len(present_sensors) >= len(required_sensors) * 0.5
            
        except Exception as e:
            logging.error(f"❌ Error validating model input: {e}")
            return False

    @staticmethod
    def normalize_prediction_output(prediction: Dict[str, Any]) -> Dict[str, Any]:
        """Normalize and validate prediction output"""
        try:
            normalized = {
                "probability": max(0.0, min(1.0, prediction.get("probability", 0.5))),
                "confidence": max(0.0, min(1.0, prediction.get("confidence", 0.5))),
                "method": prediction.get("method", "unknown"),
                "timestamp": datetime.utcnow().isoformat()
            }
            
            # Add optional fields if present
            if "trend" in prediction:
                normalized["trend"] = max(-1.0, min(1.0, prediction["trend"]))
            
            if "feature_importance" in prediction:
                normalized["feature_importance"] = prediction["feature_importance"]
            
            return normalized
            
        except Exception as e:
            logging.error(f"❌ Error normalizing prediction output: {e}")
            return {
                "probability": 0.5,
                "confidence": 0.3,
                "method": "error_fallback",
                "timestamp": datetime.utcnow().isoformat()
            }