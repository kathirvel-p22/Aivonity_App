"""
AIVONITY ML Model Trainer
Advanced ML model training for XGBoost and LSTM failure prediction
"""

import asyncio
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
from sklearn.ensemble import RandomForestClassifier, IsolationForest
from sklearn.preprocessing import StandardScaler, LabelEncoder, MinMaxScaler
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
import xgboost as xgb
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import LSTM, Dense, Dropout, BatchNormalization, GRU
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from tensorflow.keras.regularizers import l2
import joblib
import json
import os
from pathlib import Path
import pickle
import hashlib
import logging
from dataclasses import dataclass

@dataclass
class ModelMetrics:
    """Data class for storing model performance metrics"""
    accuracy: float
    precision: float
    recall: float
    f1_score: float
    roc_auc: float
    training_samples: int
    test_samples: int
    training_time: float

class MLModelTrainer:
    """
    Advanced ML Model Trainer for AIVONITY
    Handles XGBoost and LSTM model training with hyperparameter optimization
    """
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.logger = logging.getLogger(__name__)
        
        # Model paths
        self.model_base_path = Path(config.get("model_path", "data/models"))
        self.model_base_path.mkdir(parents=True, exist_ok=True)
        
        # Training configuration
        self.xgb_params = {
            "n_estimators": 200,
            "max_depth": 8,
            "learning_rate": 0.1,
            "subsample": 0.8,
            "colsample_bytree": 0.8,
            "random_state": 42,
            "eval_metric": "logloss",
            "objective": "binary:logistic"
        }
        
        self.lstm_params = {
            "epochs": 100,
            "batch_size": 32,
            "validation_split": 0.2,
            "patience": 15,
            "min_delta": 0.001
        }
        
        # Hyperparameter search spaces
        self.xgb_param_grid = {
            "n_estimators": [100, 200, 300],
            "max_depth": [6, 8, 10],
            "learning_rate": [0.05, 0.1, 0.15],
            "subsample": [0.8, 0.9, 1.0],
            "colsample_bytree": [0.8, 0.9, 1.0]
        }
        
        # Component failure patterns
        self.component_patterns = {
            "engine": {
                "sensors": ["engine_temp", "oil_pressure", "rpm", "engine_load", "fuel_consumption"],
                "failure_indicators": ["overheating", "low_oil_pressure", "irregular_rpm"],
                "normal_ranges": {
                    "engine_temp": (80, 105),
                    "oil_pressure": (20, 80),
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
                    "brake_pressure": (0, 2000),
                    "brake_temp": (20, 300)
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
                    "fuel_pressure": (30, 80),
                    "fuel_level": (0, 100)
                }
            }
        }

    async def train_xgboost_model(self, component: str, training_data: pd.DataFrame, 
                                 optimize_hyperparams: bool = True) -> Tuple[xgb.XGBClassifier, ModelMetrics]:
        """
        Train XGBoost model for component failure prediction
        
        Args:
            component: Component name (e.g., 'engine', 'transmission')
            training_data: Historical telemetry data with labels
            optimize_hyperparams: Whether to perform hyperparameter optimization
            
        Returns:
            Trained XGBoost model and performance metrics
        """
        try:
            start_time = datetime.now()
            self.logger.info(f"🔄 Training XGBoost model for {component}")
            
            # Prepare features and labels
            X, y = self._prepare_xgboost_features(training_data, component)
            
            if len(X) == 0:
                raise ValueError(f"No valid features extracted for {component}")
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42, stratify=y
            )
            
            # Handle class imbalance
            scale_pos_weight = len(y_train[y_train == 0]) / len(y_train[y_train == 1])
            
            if optimize_hyperparams:
                # Hyperparameter optimization
                model = self._optimize_xgboost_hyperparams(X_train, y_train, scale_pos_weight)
            else:
                # Use default parameters
                params = self.xgb_params.copy()
                params["scale_pos_weight"] = scale_pos_weight
                model = xgb.XGBClassifier(**params)
            
            # Train model with early stopping
            model.fit(
                X_train, y_train,
                eval_set=[(X_test, y_test)],
                early_stopping_rounds=20,
                verbose=False
            )
            
            # Evaluate model
            metrics = self._evaluate_xgboost_model(model, X_test, y_test, X_train, y_train)
            metrics.training_time = (datetime.now() - start_time).total_seconds()
            
            self.logger.info(f"✅ XGBoost model for {component} - Accuracy: {metrics.accuracy:.3f}, F1: {metrics.f1_score:.3f}")
            
            return model, metrics
            
        except Exception as e:
            self.logger.error(f"❌ Error training XGBoost model for {component}: {e}")
            raise

    def _optimize_xgboost_hyperparams(self, X_train: np.ndarray, y_train: np.ndarray, 
                                    scale_pos_weight: float) -> xgb.XGBClassifier:
        """Optimize XGBoost hyperparameters using GridSearchCV"""
        try:
            # Create base model
            base_model = xgb.XGBClassifier(
                random_state=42,
                scale_pos_weight=scale_pos_weight,
                eval_metric="logloss"
            )
            
            # Perform grid search
            grid_search = GridSearchCV(
                base_model,
                self.xgb_param_grid,
                cv=3,
                scoring='f1',
                n_jobs=-1,
                verbose=0
            )
            
            grid_search.fit(X_train, y_train)
            
            self.logger.info(f"✅ Best XGBoost params: {grid_search.best_params_}")
            
            return grid_search.best_estimator_
            
        except Exception as e:
            self.logger.error(f"❌ Error optimizing XGBoost hyperparams: {e}")
            # Return model with default params
            params = self.xgb_params.copy()
            params["scale_pos_weight"] = scale_pos_weight
            return xgb.XGBClassifier(**params)

    def _evaluate_xgboost_model(self, model: xgb.XGBClassifier, X_test: np.ndarray, 
                              y_test: np.ndarray, X_train: np.ndarray, y_train: np.ndarray) -> ModelMetrics:
        """Evaluate XGBoost model performance"""
        try:
            # Predictions
            y_pred = model.predict(X_test)
            y_pred_proba = model.predict_proba(X_test)[:, 1]
            
            # Calculate metrics
            accuracy = accuracy_score(y_test, y_pred)
            precision = precision_score(y_test, y_pred, average='weighted', zero_division=0)
            recall = recall_score(y_test, y_pred, average='weighted', zero_division=0)
            f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)
            roc_auc = roc_auc_score(y_test, y_pred_proba) if len(np.unique(y_test)) > 1 else 0.5
            
            return ModelMetrics(
                accuracy=accuracy,
                precision=precision,
                recall=recall,
                f1_score=f1,
                roc_auc=roc_auc,
                training_samples=len(X_train),
                test_samples=len(X_test),
                training_time=0.0  # Will be set by caller
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error evaluating XGBoost model: {e}")
            return ModelMetrics(0.5, 0.5, 0.5, 0.5, 0.5, len(X_train), len(X_test), 0.0)

    async def train_lstm_model(self, component: str, training_data: pd.DataFrame, 
                             sequence_length: int = 15) -> Tuple[Sequential, ModelMetrics, MinMaxScaler]:
        """
        Train LSTM model for trend analysis and forecasting
        
        Args:
            component: Component name
            training_data: Historical telemetry data
            sequence_length: Length of input sequences
            
        Returns:
            Trained LSTM model, metrics, and scaler
        """
        try:
            start_time = datetime.now()
            self.logger.info(f"🔄 Training LSTM model for {component}")
            
            # Prepare sequence data
            sequences, labels, scaler = self._prepare_lstm_sequences(training_data, component, sequence_length)
            
            if len(sequences) < 20:
                raise ValueError(f"Insufficient sequences for LSTM training: {len(sequences)}")
            
            # Convert to numpy arrays
            X = np.array(sequences)
            y = np.array(labels)
            
            # Split data
            split_idx = int(len(X) * 0.8)
            X_train, X_test = X[:split_idx], X[split_idx:]
            y_train, y_test = y[:split_idx], y[split_idx:]
            
            # Build LSTM model
            model = self._build_lstm_architecture(X.shape[1], X.shape[2])
            
            # Train model
            history = self._train_lstm_with_callbacks(model, X_train, y_train, X_test, y_test, component)
            
            # Evaluate model
            metrics = self._evaluate_lstm_model(model, X_test, y_test, X_train, y_train)
            metrics.training_time = (datetime.now() - start_time).total_seconds()
            
            self.logger.info(f"✅ LSTM model for {component} - Accuracy: {metrics.accuracy:.3f}, Loss: {history.history['val_loss'][-1]:.3f}")
            
            return model, metrics, scaler
            
        except Exception as e:
            self.logger.error(f"❌ Error training LSTM model for {component}: {e}")
            raise

    def _build_lstm_architecture(self, sequence_length: int, n_features: int) -> Sequential:
        """Build optimized LSTM architecture"""
        try:
            model = Sequential([
                # First LSTM layer with return sequences
                LSTM(
                    64, 
                    return_sequences=True, 
                    input_shape=(sequence_length, n_features),
                    kernel_regularizer=l2(0.001),
                    recurrent_regularizer=l2(0.001)
                ),
                Dropout(0.2),
                BatchNormalization(),
                
                # Second LSTM layer
                LSTM(
                    32, 
                    return_sequences=False,
                    kernel_regularizer=l2(0.001),
                    recurrent_regularizer=l2(0.001)
                ),
                Dropout(0.2),
                BatchNormalization(),
                
                # Dense layers
                Dense(16, activation='relu', kernel_regularizer=l2(0.001)),
                Dropout(0.1),
                Dense(8, activation='relu'),
                Dense(1, activation='sigmoid')
            ])
            
            # Compile model
            model.compile(
                optimizer=Adam(learning_rate=0.001, clipnorm=1.0),
                loss='binary_crossentropy',
                metrics=['accuracy', 'precision', 'recall']
            )
            
            return model
            
        except Exception as e:
            self.logger.error(f"❌ Error building LSTM architecture: {e}")
            raise

    def _train_lstm_with_callbacks(self, model: Sequential, X_train: np.ndarray, y_train: np.ndarray,
                                 X_test: np.ndarray, y_test: np.ndarray, component: str):
        """Train LSTM model with advanced callbacks"""
        try:
            # Create model checkpoint path
            checkpoint_path = self.model_base_path / f"{component}_lstm_checkpoint.h5"
            
            # Define callbacks
            callbacks = [
                EarlyStopping(
                    monitor='val_loss',
                    patience=self.lstm_params['patience'],
                    min_delta=self.lstm_params['min_delta'],
                    restore_best_weights=True,
                    verbose=0
                ),
                ReduceLROnPlateau(
                    monitor='val_loss',
                    factor=0.5,
                    patience=10,
                    min_lr=1e-7,
                    verbose=0
                ),
                ModelCheckpoint(
                    checkpoint_path,
                    monitor='val_loss',
                    save_best_only=True,
                    verbose=0
                )
            ]
            
            # Train model
            history = model.fit(
                X_train, y_train,
                epochs=self.lstm_params['epochs'],
                batch_size=self.lstm_params['batch_size'],
                validation_data=(X_test, y_test),
                callbacks=callbacks,
                verbose=0,
                shuffle=True
            )
            
            return history
            
        except Exception as e:
            self.logger.error(f"❌ Error training LSTM with callbacks: {e}")
            raise

    def _evaluate_lstm_model(self, model: Sequential, X_test: np.ndarray, y_test: np.ndarray,
                           X_train: np.ndarray, y_train: np.ndarray) -> ModelMetrics:
        """Evaluate LSTM model performance"""
        try:
            # Predictions
            y_pred_proba = model.predict(X_test, verbose=0)
            y_pred = (y_pred_proba > 0.5).astype(int).flatten()
            y_pred_proba = y_pred_proba.flatten()
            
            # Calculate metrics
            accuracy = accuracy_score(y_test, y_pred)
            precision = precision_score(y_test, y_pred, average='weighted', zero_division=0)
            recall = recall_score(y_test, y_pred, average='weighted', zero_division=0)
            f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)
            roc_auc = roc_auc_score(y_test, y_pred_proba) if len(np.unique(y_test)) > 1 else 0.5
            
            return ModelMetrics(
                accuracy=accuracy,
                precision=precision,
                recall=recall,
                f1_score=f1,
                roc_auc=roc_auc,
                training_samples=len(X_train),
                test_samples=len(X_test),
                training_time=0.0  # Will be set by caller
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error evaluating LSTM model: {e}")
            return ModelMetrics(0.5, 0.5, 0.5, 0.5, 0.5, len(X_train), len(X_test), 0.0)

    def _prepare_xgboost_features(self, training_data: pd.DataFrame, component: str) -> Tuple[np.ndarray, np.ndarray]:
        """Prepare features and labels for XGBoost training"""
        try:
            # Get component sensors
            sensors = self.component_patterns[component]["sensors"]
            available_sensors = [s for s in sensors if s in training_data.columns]
            
            if not available_sensors:
                return np.array([]), np.array([])
            
            # Extract features
            features = []
            labels = []
            
            # Create sliding window features
            window_size = 10
            for i in range(window_size, len(training_data)):
                window_data = training_data.iloc[i-window_size:i]
                current_data = training_data.iloc[i]
                
                # Statistical features for each sensor
                feature_vector = []
                for sensor in available_sensors:
                    if sensor in window_data.columns:
                        sensor_data = window_data[sensor]
                        feature_vector.extend([
                            sensor_data.mean(),
                            sensor_data.std(),
                            sensor_data.min(),
                            sensor_data.max(),
                            sensor_data.quantile(0.25),
                            sensor_data.quantile(0.75),
                            current_data[sensor] if sensor in current_data else 0
                        ])
                
                # Add temporal and contextual features
                feature_vector.extend([
                    len(window_data),  # Window size
                    i / len(training_data),  # Position in sequence
                    window_data[available_sensors[0]].std() if available_sensors else 0,  # Volatility
                ])
                
                features.append(feature_vector)
                
                # Create label (failure within next N readings)
                future_window = min(5, len(training_data) - i - 1)
                if future_window > 0:
                    future_data = training_data.iloc[i:i+future_window]
                    # Label as failure if anomaly score is high in future
                    label = 1 if future_data.get('anomaly_score', pd.Series([0])).max() > 0.8 else 0
                else:
                    label = 0
                
                labels.append(label)
            
            return np.array(features), np.array(labels)
            
        except Exception as e:
            self.logger.error(f"❌ Error preparing XGBoost features: {e}")
            return np.array([]), np.array([])

    def _prepare_lstm_sequences(self, training_data: pd.DataFrame, component: str, 
                              sequence_length: int) -> Tuple[List, List, MinMaxScaler]:
        """Prepare sequence data for LSTM training"""
        try:
            sensors = self.component_patterns[component]["sensors"]
            available_sensors = [s for s in sensors if s in training_data.columns]
            
            if not available_sensors:
                return [], [], MinMaxScaler()
            
            # Extract sensor data
            sensor_data = training_data[available_sensors].fillna(method='ffill').fillna(0)
            
            # Normalize features
            scaler = MinMaxScaler()
            normalized_data = scaler.fit_transform(sensor_data)
            
            sequences = []
            labels = []
            
            # Create sequences
            for i in range(sequence_length, len(normalized_data) - 5):
                # Input sequence
                sequence = normalized_data[i-sequence_length:i]
                sequences.append(sequence)
                
                # Label (failure in next 5 time steps)
                future_anomalies = training_data.iloc[i:i+5].get('anomaly_score', pd.Series([0]))
                label = 1 if future_anomalies.max() > 0.8 else 0
                labels.append(label)
            
            return sequences, labels, scaler
            
        except Exception as e:
            self.logger.error(f"❌ Error preparing LSTM sequences: {e}")
            return [], [], MinMaxScaler()

    async def save_models(self, component: str, xgb_model: xgb.XGBClassifier, 
                         lstm_model: Sequential, scaler: MinMaxScaler, 
                         xgb_metrics: ModelMetrics, lstm_metrics: ModelMetrics):
        """Save trained models and metadata"""
        try:
            # Save XGBoost model
            xgb_path = self.model_base_path / f"{component}_xgboost.joblib"
            joblib.dump(xgb_model, xgb_path)
            
            # Save LSTM model
            lstm_path = self.model_base_path / f"{component}_lstm.h5"
            lstm_model.save(lstm_path)
            
            # Save scaler
            scaler_path = self.model_base_path / f"{component}_scaler.joblib"
            joblib.dump(scaler, scaler_path)
            
            # Save model metadata
            metadata = {
                "component": component,
                "training_date": datetime.utcnow().isoformat(),
                "model_versions": {
                    "xgboost": "2.0.2",
                    "lstm": "tensorflow-2.15.0"
                },
                "xgboost_metrics": {
                    "accuracy": xgb_metrics.accuracy,
                    "precision": xgb_metrics.precision,
                    "recall": xgb_metrics.recall,
                    "f1_score": xgb_metrics.f1_score,
                    "roc_auc": xgb_metrics.roc_auc,
                    "training_samples": xgb_metrics.training_samples,
                    "test_samples": xgb_metrics.test_samples,
                    "training_time": xgb_metrics.training_time
                },
                "lstm_metrics": {
                    "accuracy": lstm_metrics.accuracy,
                    "precision": lstm_metrics.precision,
                    "recall": lstm_metrics.recall,
                    "f1_score": lstm_metrics.f1_score,
                    "roc_auc": lstm_metrics.roc_auc,
                    "training_samples": lstm_metrics.training_samples,
                    "test_samples": lstm_metrics.test_samples,
                    "training_time": lstm_metrics.training_time
                }
            }
            
            metadata_path = self.model_base_path / f"{component}_metadata.json"
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            self.logger.info(f"✅ Saved models and metadata for component: {component}")
            
        except Exception as e:
            self.logger.error(f"❌ Error saving models for {component}: {e}")
            raise

    def generate_synthetic_training_data(self, component: str, num_samples: int = 1000) -> pd.DataFrame:
        """Generate synthetic training data for initial model training"""
        try:
            self.logger.info(f"🔄 Generating synthetic training data for {component}")
            
            sensors = self.component_patterns[component]["sensors"]
            normal_ranges = self.component_patterns[component]["normal_ranges"]
            
            data = []
            
            for i in range(num_samples):
                sample = {}
                
                # Generate normal operation data (80% of samples)
                is_normal = np.random.random() > 0.2
                
                for sensor in sensors:
                    if sensor in normal_ranges:
                        min_val, max_val = normal_ranges[sensor]
                        
                        if is_normal:
                            # Normal operation
                            value = np.random.uniform(min_val, max_val)
                        else:
                            # Anomalous operation
                            if np.random.random() > 0.5:
                                value = np.random.uniform(max_val, max_val * 1.5)  # High anomaly
                            else:
                                value = np.random.uniform(min_val * 0.5, min_val)  # Low anomaly
                    else:
                        # Generate random values for sensors without defined ranges
                        base_value = np.random.uniform(0, 100)
                        if not is_normal:
                            base_value *= np.random.uniform(1.5, 3.0)  # Anomalous multiplier
                        value = base_value
                    
                    sample[sensor] = value
                
                # Add anomaly score
                sample['anomaly_score'] = 0.1 if is_normal else np.random.uniform(0.8, 1.0)
                
                # Add timestamp
                sample['timestamp'] = datetime.utcnow() - timedelta(minutes=i)
                
                data.append(sample)
            
            df = pd.DataFrame(data)
            self.logger.info(f"✅ Generated {len(df)} synthetic samples for {component}")
            
            return df
            
        except Exception as e:
            self.logger.error(f"❌ Error generating synthetic data for {component}: {e}")
            return pd.DataFrame()