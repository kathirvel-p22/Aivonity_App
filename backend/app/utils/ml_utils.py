"""
AIVONITY Machine Learning Utilities
Advanced ML utilities for feature engineering and data processing
"""

import numpy as np
import pandas as pd
from typing import Dict, Any, List, Tuple, Optional
from datetime import datetime, timedelta
import json
import logging
from dataclasses import dataclass
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from scipy import stats
import warnings

warnings.filterwarnings('ignore')

logger = logging.getLogger(__name__)

@dataclass
class FeatureMetadata:
    """Metadata for extracted features"""
    feature_name: str
    feature_type: str  # statistical, temporal, domain_specific
    importance_score: float = 0.0
    description: str = ""

class FeatureExtractor:
    """
    Advanced feature extraction for vehicle telemetry data
    Extracts statistical, temporal, and domain-specific features
    """
    
    def __init__(self):
        self.feature_metadata = {}
        self._initialize_feature_definitions()
    
    def _initialize_feature_definitions(self):
        """Initialize feature definitions and metadata"""
        self.feature_metadata = {
            # Statistical features
            "engine_temp_mean": FeatureMetadata("engine_temp_mean", "statistical", 0.8, "Average engine temperature"),
            "engine_temp_std": FeatureMetadata("engine_temp_std", "statistical", 0.7, "Engine temperature variability"),
            "oil_pressure_mean": FeatureMetadata("oil_pressure_mean", "statistical", 0.9, "Average oil pressure"),
            "rpm_variance": FeatureMetadata("rpm_variance", "statistical", 0.6, "RPM variability"),
            
            # Domain-specific features
            "thermal_efficiency": FeatureMetadata("thermal_efficiency", "domain_specific", 0.9, "Engine thermal efficiency"),
            "power_efficiency": FeatureMetadata("power_efficiency", "domain_specific", 0.8, "Power efficiency ratio"),
            "fuel_consumption_rate": FeatureMetadata("fuel_consumption_rate", "domain_specific", 0.9, "Fuel consumption rate"),
            
            # Temporal features
            "trend_slope": FeatureMetadata("trend_slope", "temporal", 0.7, "Parameter trend slope"),
            "change_rate": FeatureMetadata("change_rate", "temporal", 0.6, "Rate of change"),
        }
    
    def extract_features(self, sensor_data: Dict[str, Any], 
                        historical_data: Optional[List[Dict[str, Any]]] = None) -> Dict[str, float]:
        """
        Extract comprehensive features from sensor data
        
        Args:
            sensor_data: Current sensor readings
            historical_data: Historical sensor data for temporal features
            
        Returns:
            Dictionary of extracted features
        """
        try:
            features = {}
            
            # Extract statistical features
            statistical_features = self._extract_statistical_features(sensor_data)
            features.update(statistical_features)
            
            # Extract domain-specific features
            domain_features = self._extract_domain_features(sensor_data)
            features.update(domain_features)
            
            # Extract temporal features if historical data available
            if historical_data:
                temporal_features = self._extract_temporal_features(sensor_data, historical_data)
                features.update(temporal_features)
            
            # Extract derived features
            derived_features = self._extract_derived_features(sensor_data)
            features.update(derived_features)
            
            return features
            
        except Exception as e:
            logger.error(f"Error extracting features: {e}")
            return {}
    
    def _extract_statistical_features(self, sensor_data: Dict[str, Any]) -> Dict[str, float]:
        """Extract basic statistical features"""
        features = {}
        
        try:
            # Engine temperature features
            if "engine_temp" in sensor_data:
                temp = float(sensor_data["engine_temp"])
                features["engine_temp_normalized"] = self._normalize_temperature(temp)
                features["engine_temp_deviation"] = abs(temp - 90) / 90  # Deviation from optimal
            
            # Oil pressure features
            if "oil_pressure" in sensor_data:
                pressure = float(sensor_data["oil_pressure"])
                features["oil_pressure_normalized"] = self._normalize_pressure(pressure)
                features["oil_pressure_health"] = self._calculate_pressure_health(pressure)
            
            # Battery voltage features
            if "battery_voltage" in sensor_data:
                voltage = float(sensor_data["battery_voltage"])
                features["battery_health"] = self._calculate_battery_health(voltage)
            
            # RPM features
            if "rpm" in sensor_data:
                rpm = float(sensor_data["rpm"])
                features["rpm_normalized"] = rpm / 8000  # Normalize to max RPM
                features["rpm_efficiency_zone"] = self._calculate_rpm_efficiency(rpm)
            
            # Speed features
            if "speed" in sensor_data:
                speed = float(sensor_data["speed"])
                features["speed_normalized"] = speed / 200  # Normalize to max speed
            
        except Exception as e:
            logger.error(f"Error extracting statistical features: {e}")
        
        return features
    
    def _extract_domain_features(self, sensor_data: Dict[str, Any]) -> Dict[str, float]:
        """Extract automotive domain-specific features"""
        features = {}
        
        try:
            # Thermal efficiency
            if "engine_temp" in sensor_data and "rpm" in sensor_data:
                temp = float(sensor_data["engine_temp"])
                rpm = float(sensor_data["rpm"])
                features["thermal_efficiency"] = self._calculate_thermal_efficiency(temp, rpm)
            
            # Power efficiency
            if "rpm" in sensor_data and "speed" in sensor_data:
                rpm = float(sensor_data["rpm"])
                speed = float(sensor_data["speed"])
                features["power_efficiency"] = self._calculate_power_efficiency(rpm, speed)
            
            # Engine load estimation
            if "rpm" in sensor_data and "engine_temp" in sensor_data:
                rpm = float(sensor_data["rpm"])
                temp = float(sensor_data["engine_temp"])
                features["engine_load"] = self._estimate_engine_load(rpm, temp)
            
            # Fuel efficiency estimation
            if all(key in sensor_data for key in ["rpm", "speed", "engine_temp"]):
                features["fuel_efficiency"] = self._estimate_fuel_efficiency(sensor_data)
            
            # Vehicle health score
            features["overall_health"] = self._calculate_overall_health(sensor_data)
            
        except Exception as e:
            logger.error(f"Error extracting domain features: {e}")
        
        return features
    
    def _extract_temporal_features(self, current_data: Dict[str, Any], 
                                 historical_data: List[Dict[str, Any]]) -> Dict[str, float]:
        """Extract temporal and trend features"""
        features = {}
        
        try:
            if len(historical_data) < 2:
                return features
            
            # Extract trends for key parameters
            for param in ["engine_temp", "oil_pressure", "rpm", "speed"]:
                if param in current_data:
                    values = [float(d.get(param, 0)) for d in historical_data if param in d]
                    if len(values) >= 2:
                        # Calculate trend slope
                        x = np.arange(len(values))
                        slope, _, r_value, _, _ = stats.linregress(x, values)
                        
                        features[f"{param}_trend_slope"] = slope
                        features[f"{param}_trend_strength"] = abs(r_value)
                        
                        # Calculate rate of change
                        if len(values) >= 2:
                            change_rate = (values[-1] - values[0]) / len(values)
                            features[f"{param}_change_rate"] = change_rate
            
            # Calculate volatility
            for param in ["engine_temp", "oil_pressure"]:
                if param in current_data:
                    values = [float(d.get(param, 0)) for d in historical_data if param in d]
                    if len(values) >= 3:
                        volatility = np.std(values) / np.mean(values) if np.mean(values) != 0 else 0
                        features[f"{param}_volatility"] = volatility
            
        except Exception as e:
            logger.error(f"Error extracting temporal features: {e}")
        
        return features
    
    def _extract_derived_features(self, sensor_data: Dict[str, Any]) -> Dict[str, float]:
        """Extract derived and composite features"""
        features = {}
        
        try:
            # Temperature-pressure correlation
            if "engine_temp" in sensor_data and "oil_pressure" in sensor_data:
                temp = float(sensor_data["engine_temp"])
                pressure = float(sensor_data["oil_pressure"])
                features["temp_pressure_ratio"] = temp / pressure if pressure != 0 else 0
            
            # Performance index
            if all(key in sensor_data for key in ["rpm", "speed", "engine_temp"]):
                rpm = float(sensor_data["rpm"])
                speed = float(sensor_data["speed"])
                temp = float(sensor_data["engine_temp"])
                
                # Simple performance index
                performance_index = (speed * rpm) / (temp * 1000) if temp != 0 else 0
                features["performance_index"] = performance_index
            
            # Stress indicator
            stress_factors = []
            if "engine_temp" in sensor_data:
                temp_stress = max(0, (float(sensor_data["engine_temp"]) - 90) / 30)
                stress_factors.append(temp_stress)
            
            if "rpm" in sensor_data:
                rpm_stress = float(sensor_data["rpm"]) / 6000  # High RPM stress
                stress_factors.append(rpm_stress)
            
            if stress_factors:
                features["stress_indicator"] = np.mean(stress_factors)
            
        except Exception as e:
            logger.error(f"Error extracting derived features: {e}")
        
        return features
    
    def _normalize_temperature(self, temp: float) -> float:
        """Normalize engine temperature to 0-1 scale"""
        # Normal operating range: 70-110°C
        return max(0, min(1, (temp - 70) / 40))
    
    def _normalize_pressure(self, pressure: float) -> float:
        """Normalize oil pressure to 0-1 scale"""
        # Normal operating range: 20-60 PSI
        return max(0, min(1, (pressure - 20) / 40))
    
    def _calculate_pressure_health(self, pressure: float) -> float:
        """Calculate oil pressure health score"""
        if 30 <= pressure <= 50:
            return 1.0  # Optimal range
        elif 20 <= pressure < 30 or 50 < pressure <= 60:
            return 0.7  # Acceptable range
        elif 10 <= pressure < 20 or 60 < pressure <= 70:
            return 0.4  # Warning range
        else:
            return 0.1  # Critical range
    
    def _calculate_battery_health(self, voltage: float) -> float:
        """Calculate battery health score"""
        if 12.4 <= voltage <= 12.8:
            return 1.0  # Optimal
        elif 12.0 <= voltage < 12.4 or 12.8 < voltage <= 13.2:
            return 0.7  # Good
        elif 11.5 <= voltage < 12.0 or 13.2 < voltage <= 14.0:
            return 0.4  # Fair
        else:
            return 0.1  # Poor
    
    def _calculate_rpm_efficiency(self, rpm: float) -> float:
        """Calculate RPM efficiency zone score"""
        # Most efficient RPM range: 1500-3000
        if 1500 <= rpm <= 3000:
            return 1.0
        elif 1000 <= rpm < 1500 or 3000 < rpm <= 4000:
            return 0.7
        elif 500 <= rpm < 1000 or 4000 < rpm <= 5000:
            return 0.4
        else:
            return 0.2
    
    def _calculate_thermal_efficiency(self, temp: float, rpm: float) -> float:
        """Calculate thermal efficiency based on temperature and RPM"""
        optimal_temp = 90  # Optimal operating temperature
        temp_factor = 1 - abs(temp - optimal_temp) / optimal_temp
        
        # RPM efficiency factor
        rpm_factor = self._calculate_rpm_efficiency(rpm)
        
        return (temp_factor + rpm_factor) / 2
    
    def _calculate_power_efficiency(self, rpm: float, speed: float) -> float:
        """Calculate power efficiency ratio"""
        if rpm == 0:
            return 0
        
        # Ideal ratio varies by gear, but roughly speed/rpm should be in certain range
        ratio = speed / (rpm / 1000)  # Speed per 1000 RPM
        
        # Optimal ratio range: 15-25 km/h per 1000 RPM
        if 15 <= ratio <= 25:
            return 1.0
        elif 10 <= ratio < 15 or 25 < ratio <= 30:
            return 0.7
        elif 5 <= ratio < 10 or 30 < ratio <= 35:
            return 0.4
        else:
            return 0.2
    
    def _estimate_engine_load(self, rpm: float, temp: float) -> float:
        """Estimate engine load based on RPM and temperature"""
        # Higher RPM and temperature indicate higher load
        rpm_load = rpm / 6000  # Normalize to max RPM
        temp_load = max(0, (temp - 70) / 50)  # Temperature above normal
        
        return (rpm_load + temp_load) / 2
    
    def _estimate_fuel_efficiency(self, sensor_data: Dict[str, Any]) -> float:
        """Estimate fuel efficiency based on multiple parameters"""
        try:
            rpm = float(sensor_data["rpm"])
            speed = float(sensor_data["speed"])
            temp = float(sensor_data["engine_temp"])
            
            # Simple fuel efficiency model
            # Lower RPM, moderate speed, optimal temperature = better efficiency
            rpm_efficiency = self._calculate_rpm_efficiency(rpm)
            
            # Speed efficiency (moderate speeds are most efficient)
            if 50 <= speed <= 80:
                speed_efficiency = 1.0
            elif 30 <= speed < 50 or 80 < speed <= 100:
                speed_efficiency = 0.7
            else:
                speed_efficiency = 0.4
            
            # Temperature efficiency
            temp_efficiency = 1 - abs(temp - 90) / 90
            
            return (rpm_efficiency + speed_efficiency + temp_efficiency) / 3
            
        except Exception as e:
            logger.error(f"Error estimating fuel efficiency: {e}")
            return 0.5
    
    def _calculate_overall_health(self, sensor_data: Dict[str, Any]) -> float:
        """Calculate overall vehicle health score"""
        health_scores = []
        
        try:
            # Engine temperature health
            if "engine_temp" in sensor_data:
                temp = float(sensor_data["engine_temp"])
                temp_health = 1 - abs(temp - 90) / 90
                health_scores.append(temp_health)
            
            # Oil pressure health
            if "oil_pressure" in sensor_data:
                pressure = float(sensor_data["oil_pressure"])
                pressure_health = self._calculate_pressure_health(pressure)
                health_scores.append(pressure_health)
            
            # Battery health
            if "battery_voltage" in sensor_data:
                voltage = float(sensor_data["battery_voltage"])
                battery_health = self._calculate_battery_health(voltage)
                health_scores.append(battery_health)
            
            # Return average health score
            return np.mean(health_scores) if health_scores else 0.5
            
        except Exception as e:
            logger.error(f"Error calculating overall health: {e}")
            return 0.5

class DataValidator:
    """
    Advanced data validation for telemetry data
    Validates data quality, completeness, and consistency
    """
    
    def __init__(self):
        self.validation_rules = self._initialize_validation_rules()
    
    def _initialize_validation_rules(self) -> Dict[str, Dict[str, Any]]:
        """Initialize validation rules for different sensors"""
        return {
            "engine_temp": {
                "type": "float",
                "min_value": -40,
                "max_value": 150,
                "required": True,
                "unit": "celsius"
            },
            "oil_pressure": {
                "type": "float", 
                "min_value": 0,
                "max_value": 100,
                "required": True,
                "unit": "psi"
            },
            "battery_voltage": {
                "type": "float",
                "min_value": 8,
                "max_value": 16,
                "required": True,
                "unit": "volts"
            },
            "rpm": {
                "type": "float",
                "min_value": 0,
                "max_value": 10000,
                "required": True,
                "unit": "rpm"
            },
            "speed": {
                "type": "float",
                "min_value": 0,
                "max_value": 300,
                "required": False,
                "unit": "kmh"
            },
            "fuel_level": {
                "type": "float",
                "min_value": 0,
                "max_value": 100,
                "required": False,
                "unit": "percentage"
            }
        }
    
    def validate_telemetry(self, sensor_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate telemetry data against rules
        
        Returns:
            Dictionary with validation results
        """
        validation_result = {
            "valid": True,
            "errors": [],
            "warnings": [],
            "completeness_score": 0.0,
            "quality_score": 0.0
        }
        
        try:
            # Check required fields
            required_fields = [field for field, rules in self.validation_rules.items() 
                             if rules.get("required", False)]
            
            missing_fields = [field for field in required_fields if field not in sensor_data]
            if missing_fields:
                validation_result["errors"].extend([f"Missing required field: {field}" for field in missing_fields])
                validation_result["valid"] = False
            
            # Validate each field
            valid_fields = 0
            total_fields = len(self.validation_rules)
            
            for field, rules in self.validation_rules.items():
                if field in sensor_data:
                    field_valid = self._validate_field(field, sensor_data[field], rules)
                    if field_valid["valid"]:
                        valid_fields += 1
                    else:
                        validation_result["errors"].extend(field_valid["errors"])
                        validation_result["warnings"].extend(field_valid["warnings"])
                        if rules.get("required", False):
                            validation_result["valid"] = False
            
            # Calculate completeness score
            validation_result["completeness_score"] = len(sensor_data) / total_fields
            
            # Calculate quality score
            validation_result["quality_score"] = valid_fields / total_fields if total_fields > 0 else 0
            
            # Check data consistency
            consistency_check = self._check_data_consistency(sensor_data)
            if not consistency_check["consistent"]:
                validation_result["warnings"].extend(consistency_check["warnings"])
            
        except Exception as e:
            logger.error(f"Error validating telemetry data: {e}")
            validation_result["valid"] = False
            validation_result["errors"].append(f"Validation error: {str(e)}")
        
        return validation_result
    
    def _validate_field(self, field_name: str, value: Any, rules: Dict[str, Any]) -> Dict[str, Any]:
        """Validate individual field against rules"""
        result = {
            "valid": True,
            "errors": [],
            "warnings": []
        }
        
        try:
            # Type validation
            expected_type = rules.get("type", "float")
            if expected_type == "float":
                try:
                    float_value = float(value)
                except (ValueError, TypeError):
                    result["valid"] = False
                    result["errors"].append(f"{field_name}: Invalid numeric value")
                    return result
                
                # Range validation
                min_val = rules.get("min_value")
                max_val = rules.get("max_value")
                
                if min_val is not None and float_value < min_val:
                    result["valid"] = False
                    result["errors"].append(f"{field_name}: Value {float_value} below minimum {min_val}")
                
                if max_val is not None and float_value > max_val:
                    result["valid"] = False
                    result["errors"].append(f"{field_name}: Value {float_value} above maximum {max_val}")
                
                # Warning ranges (slightly outside normal but not invalid)
                if field_name == "engine_temp":
                    if float_value > 110:
                        result["warnings"].append(f"{field_name}: High temperature warning")
                    elif float_value < 60:
                        result["warnings"].append(f"{field_name}: Low temperature warning")
                
                elif field_name == "oil_pressure":
                    if float_value < 15:
                        result["warnings"].append(f"{field_name}: Low pressure warning")
                    elif float_value > 70:
                        result["warnings"].append(f"{field_name}: High pressure warning")
            
        except Exception as e:
            result["valid"] = False
            result["errors"].append(f"{field_name}: Validation error - {str(e)}")
        
        return result
    
    def _check_data_consistency(self, sensor_data: Dict[str, Any]) -> Dict[str, Any]:
        """Check logical consistency between sensor values"""
        result = {
            "consistent": True,
            "warnings": []
        }
        
        try:
            # Check RPM vs Speed consistency
            if "rpm" in sensor_data and "speed" in sensor_data:
                rpm = float(sensor_data["rpm"])
                speed = float(sensor_data["speed"])
                
                # If vehicle is stationary, RPM should be idle or off
                if speed == 0 and rpm > 1200:
                    result["warnings"].append("Inconsistent: High RPM with zero speed")
                
                # If speed is high, RPM should be reasonable
                if speed > 60 and rpm < 1500:
                    result["warnings"].append("Inconsistent: High speed with low RPM")
            
            # Check engine temperature consistency
            if "engine_temp" in sensor_data and "speed" in sensor_data:
                temp = float(sensor_data["engine_temp"])
                speed = float(sensor_data["speed"])
                
                # Engine should warm up during driving
                if speed > 40 and temp < 70:
                    result["warnings"].append("Inconsistent: High speed with cold engine")
            
            # Check battery voltage vs engine state
            if "battery_voltage" in sensor_data and "rpm" in sensor_data:
                voltage = float(sensor_data["battery_voltage"])
                rpm = float(sensor_data["rpm"])
                
                # When engine is running, voltage should be higher (alternator charging)
                if rpm > 1000 and voltage < 12.5:
                    result["warnings"].append("Inconsistent: Low battery voltage with engine running")
            
            if result["warnings"]:
                result["consistent"] = False
            
        except Exception as e:
            logger.error(f"Error checking data consistency: {e}")
            result["consistent"] = False
            result["warnings"].append(f"Consistency check error: {str(e)}")
        
        return result