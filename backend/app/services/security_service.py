"""
AIVONITY Security Service
Advanced security anomaly detection and alerting system
"""

import asyncio
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, field
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from collections import defaultdict, deque
import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.db.database import get_async_session
from app.db.models import AgentLog, User, SystemMetrics
from app.config import settings
from app.utils.logging_config import get_logger, security_logger, audit_logger

@dataclass
class ThreatIndicator:
    """Threat indicator for security analysis"""
    indicator_type: str  # ip_address, user_agent, behavior_pattern, etc.
    value: str
    severity: str  # low, medium, high, critical
    confidence: float
    first_seen: datetime
    last_seen: datetime
    occurrence_count: int = 1
    context: Dict[str, Any] = field(default_factory=dict)

@dataclass
class SecurityRule:
    """Security rule for automated detection"""
    rule_id: str
    name: str
    description: str
    rule_type: str  # threshold, pattern, ml_based, statistical
    conditions: Dict[str, Any]
    severity: str
    enabled: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)

@dataclass
class IncidentResponse:
    """Incident response action"""
    action_type: str  # block_user, rate_limit, alert, quarantine
    target: str
    parameters: Dict[str, Any]
    executed_at: Optional[datetime] = None
    success: bool = False
    error_message: Optional[str] = None

class SecurityService:
    """
    Advanced Security Service for anomaly detection and alerting
    """
    
    def __init__(self):
        self.logger = get_logger(__name__)
        
        # ML Models for anomaly detection
        self.user_behavior_model = IsolationForest(contamination=0.1, random_state=42)
        self.api_usage_model = IsolationForest(contamination=0.05, random_state=42)
        self.system_metrics_model = IsolationForest(contamination=0.1, random_state=42)
        
        # Scalers for feature normalization
        self.user_scaler = StandardScaler()
        self.api_scaler = StandardScaler()
        self.system_scaler = StandardScaler()
        
        # Threat intelligence
        self.threat_indicators: Dict[str, ThreatIndicator] = {}
        self.security_rules: Dict[str, SecurityRule] = {}
        
        # Rate limiting and blocking
        self.rate_limits: Dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        self.blocked_entities: Dict[str, datetime] = {}
        
        # Alert management
        self.alert_channels = []
        self.incident_responses: List[IncidentResponse] = []
        
        # Redis for real-time data
        self.redis_client = None
        
        # Model training data buffers
        self.user_behavior_buffer = deque(maxlen=10000)
        self.api_usage_buffer = deque(maxlen=10000)
        self.system_metrics_buffer = deque(maxlen=10000)
        
        # Statistics
        self.detection_stats = {
            "anomalies_detected": 0,
            "alerts_sent": 0,
            "incidents_responded": 0,
            "false_positives": 0,
            "model_accuracy": 0.0
        }
        
        self.logger.info("🔒 Security Service initialized")

    async def initialize(self):
        """Initialize security service"""
        try:
            # Initialize Redis connection
            self.redis_client = redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            await self.redis_client.ping()
            
            # Load security rules
            await self._load_security_rules()
            
            # Load threat indicators
            await self._load_threat_indicators()
            
            # Initialize ML models with historical data
            await self._initialize_ml_models()
            
            # Start background tasks
            asyncio.create_task(self._model_training_loop())
            asyncio.create_task(self._threat_intelligence_update_loop())
            asyncio.create_task(self._cleanup_loop())
            
            self.logger.info("✅ Security Service initialized successfully")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize Security Service: {e}")
            raise

    async def detect_user_behavior_anomaly(self, user_id: str, behavior_data: Dict[str, Any]) -> Tuple[bool, float, List[str]]:
        """Detect anomalies in user behavior"""
        try:
            # Extract features from behavior data
            features = self._extract_user_behavior_features(behavior_data)
            
            if len(features) == 0:
                return False, 0.0, []
            
            # Normalize features
            features_array = np.array(features).reshape(1, -1)
            
            # Check if model is trained
            if hasattr(self.user_behavior_model, 'decision_function'):
                # Get anomaly score
                anomaly_score = self.user_behavior_model.decision_function(features_array)[0]
                is_anomaly = self.user_behavior_model.predict(features_array)[0] == -1
                
                # Convert score to probability (0-1 range)
                anomaly_probability = max(0, min(1, (0.5 - anomaly_score) * 2))
                
                # Generate detailed anomaly reasons
                anomaly_reasons = []
                if is_anomaly:
                    anomaly_reasons = await self._analyze_user_behavior_anomaly(user_id, behavior_data, features)
                
                # Log detection
                security_logger.log_suspicious_activity(
                    user_id=user_id,
                    activity_type="behavior_analysis",
                    details={
                        "anomaly_detected": is_anomaly,
                        "anomaly_score": anomaly_probability,
                        "features": dict(zip(self._get_user_feature_names(), features))
                    },
                    risk_score=anomaly_probability
                )
                
                return is_anomaly, anomaly_probability, anomaly_reasons
            else:
                # Model not trained yet, use rule-based detection
                return await self._rule_based_user_detection(user_id, behavior_data)
                
        except Exception as e:
            self.logger.error(f"❌ Error detecting user behavior anomaly: {e}")
            return False, 0.0, []

    async def detect_api_usage_anomaly(self, user_id: str, api_data: Dict[str, Any]) -> Tuple[bool, float, List[str]]:
        """Detect anomalies in API usage patterns"""
        try:
            # Extract API usage features
            features = self._extract_api_usage_features(api_data)
            
            if len(features) == 0:
                return False, 0.0, []
            
            # Normalize features
            features_array = np.array(features).reshape(1, -1)
            
            # Check if model is trained
            if hasattr(self.api_usage_model, 'decision_function'):
                # Get anomaly score
                anomaly_score = self.api_usage_model.decision_function(features_array)[0]
                is_anomaly = self.api_usage_model.predict(features_array)[0] == -1
                
                # Convert score to probability
                anomaly_probability = max(0, min(1, (0.5 - anomaly_score) * 2))
                
                # Generate detailed reasons
                anomaly_reasons = []
                if is_anomaly:
                    anomaly_reasons = await self._analyze_api_usage_anomaly(user_id, api_data, features)
                
                return is_anomaly, anomaly_probability, anomaly_reasons
            else:
                # Use rule-based detection
                return await self._rule_based_api_detection(user_id, api_data)
                
        except Exception as e:
            self.logger.error(f"❌ Error detecting API usage anomaly: {e}")
            return False, 0.0, []

    async def detect_system_anomaly(self, system_data: Dict[str, Any]) -> Tuple[bool, float, List[str]]:
        """Detect system-level anomalies"""
        try:
            # Extract system features
            features = self._extract_system_features(system_data)
            
            if len(features) == 0:
                return False, 0.0, []
            
            # Normalize features
            features_array = np.array(features).reshape(1, -1)
            
            # Check if model is trained
            if hasattr(self.system_metrics_model, 'decision_function'):
                # Get anomaly score
                anomaly_score = self.system_metrics_model.decision_function(features_array)[0]
                is_anomaly = self.system_metrics_model.predict(features_array)[0] == -1
                
                # Convert score to probability
                anomaly_probability = max(0, min(1, (0.5 - anomaly_score) * 2))
                
                # Generate detailed reasons
                anomaly_reasons = []
                if is_anomaly:
                    anomaly_reasons = await self._analyze_system_anomaly(system_data, features)
                
                return is_anomaly, anomaly_probability, anomaly_reasons
            else:
                # Use rule-based detection
                return await self._rule_based_system_detection(system_data)
                
        except Exception as e:
            self.logger.error(f"❌ Error detecting system anomaly: {e}")
            return False, 0.0, []

    async def generate_security_alert(self, alert_type: str, entity_id: str, 
                                    severity: str, details: Dict[str, Any]) -> str:
        """Generate and send security alert"""
        try:
            alert_id = f"alert_{int(time.time())}_{entity_id}"
            
            alert_data = {
                "alert_id": alert_id,
                "alert_type": alert_type,
                "entity_id": entity_id,
                "severity": severity,
                "details": details,
                "timestamp": datetime.utcnow().isoformat(),
                "status": "new"
            }
            
            # Store alert in Redis
            await self.redis_client.setex(
                f"security_alert:{alert_id}",
                86400,  # 24 hours TTL
                json.dumps(alert_data)
            )
            
            # Send alert notifications
            await self._send_alert_notifications(alert_data)
            
            # Execute automated response if configured
            await self._execute_automated_response(alert_data)
            
            self.detection_stats["alerts_sent"] += 1
            
            self.logger.warning(f"🚨 Security alert generated: {alert_id} (Severity: {severity})")
            
            return alert_id
            
        except Exception as e:
            self.logger.error(f"❌ Error generating security alert: {e}")
            return ""

    async def execute_incident_response(self, alert_id: str, response_actions: List[str]) -> List[IncidentResponse]:
        """Execute incident response actions"""
        try:
            responses = []
            
            # Get alert details
            alert_data = await self.redis_client.get(f"security_alert:{alert_id}")
            if not alert_data:
                self.logger.error(f"Alert not found: {alert_id}")
                return responses
            
            alert = json.loads(alert_data)
            entity_id = alert["entity_id"]
            
            for action in response_actions:
                response = await self._execute_response_action(action, entity_id, alert)
                responses.append(response)
                self.incident_responses.append(response)
            
            self.detection_stats["incidents_responded"] += 1
            
            # Log incident response
            audit_logger.log_system_event(
                event_type="incident_response",
                details={
                    "alert_id": alert_id,
                    "entity_id": entity_id,
                    "actions": response_actions,
                    "responses": [r.__dict__ for r in responses]
                },
                severity="warning"
            )
            
            return responses
            
        except Exception as e:
            self.logger.error(f"❌ Error executing incident response: {e}")
            return []

    async def update_threat_intelligence(self, indicators: List[Dict[str, Any]]):
        """Update threat intelligence with new indicators"""
        try:
            for indicator_data in indicators:
                indicator = ThreatIndicator(
                    indicator_type=indicator_data["type"],
                    value=indicator_data["value"],
                    severity=indicator_data.get("severity", "medium"),
                    confidence=indicator_data.get("confidence", 0.5),
                    first_seen=datetime.utcnow(),
                    last_seen=datetime.utcnow(),
                    context=indicator_data.get("context", {})
                )
                
                indicator_key = f"{indicator.indicator_type}:{indicator.value}"
                
                if indicator_key in self.threat_indicators:
                    # Update existing indicator
                    existing = self.threat_indicators[indicator_key]
                    existing.last_seen = datetime.utcnow()
                    existing.occurrence_count += 1
                    existing.confidence = max(existing.confidence, indicator.confidence)
                else:
                    # Add new indicator
                    self.threat_indicators[indicator_key] = indicator
                
                # Store in Redis
                await self.redis_client.setex(
                    f"threat_indicator:{indicator_key}",
                    86400 * 7,  # 7 days TTL
                    json.dumps({
                        "type": indicator.indicator_type,
                        "value": indicator.value,
                        "severity": indicator.severity,
                        "confidence": indicator.confidence,
                        "first_seen": indicator.first_seen.isoformat(),
                        "last_seen": indicator.last_seen.isoformat(),
                        "occurrence_count": indicator.occurrence_count,
                        "context": indicator.context
                    })
                )
            
            self.logger.info(f"📊 Updated threat intelligence with {len(indicators)} indicators")
            
        except Exception as e:
            self.logger.error(f"❌ Error updating threat intelligence: {e}")

    async def check_threat_indicators(self, entity_id: str, context: Dict[str, Any]) -> List[ThreatIndicator]:
        """Check entity against threat indicators"""
        try:
            matched_indicators = []
            
            # Check various indicator types
            checks = [
                ("user_id", entity_id),
                ("ip_address", context.get("ip_address")),
                ("user_agent", context.get("user_agent")),
                ("email", context.get("email"))
            ]
            
            for indicator_type, value in checks:
                if value:
                    indicator_key = f"{indicator_type}:{value}"
                    if indicator_key in self.threat_indicators:
                        matched_indicators.append(self.threat_indicators[indicator_key])
            
            return matched_indicators
            
        except Exception as e:
            self.logger.error(f"❌ Error checking threat indicators: {e}")
            return []

    def _extract_user_behavior_features(self, behavior_data: Dict[str, Any]) -> List[float]:
        """Extract features from user behavior data"""
        try:
            features = []
            
            # Time-based features
            current_hour = datetime.utcnow().hour
            features.append(current_hour)
            features.append(1 if 9 <= current_hour <= 17 else 0)  # Business hours
            features.append(1 if current_hour >= 22 or current_hour <= 6 else 0)  # Night hours
            
            # Session features
            features.append(behavior_data.get("session_duration", 0))
            features.append(behavior_data.get("actions_per_session", 0))
            features.append(behavior_data.get("pages_visited", 0))
            
            # API usage features
            features.append(behavior_data.get("api_calls_count", 0))
            features.append(behavior_data.get("failed_requests", 0))
            features.append(behavior_data.get("unique_endpoints", 0))
            
            # Location features (if available)
            if "location" in behavior_data:
                features.append(behavior_data["location"].get("latitude", 0))
                features.append(behavior_data["location"].get("longitude", 0))
            else:
                features.extend([0, 0])
            
            # Device features
            features.append(1 if behavior_data.get("new_device", False) else 0)
            features.append(1 if behavior_data.get("mobile_device", False) else 0)
            
            return features
            
        except Exception as e:
            self.logger.error(f"❌ Error extracting user behavior features: {e}")
            return []

    def _extract_api_usage_features(self, api_data: Dict[str, Any]) -> List[float]:
        """Extract features from API usage data"""
        try:
            features = []
            
            # Request volume features
            features.append(api_data.get("requests_per_minute", 0))
            features.append(api_data.get("requests_per_hour", 0))
            features.append(api_data.get("total_requests", 0))
            
            # Error rate features
            features.append(api_data.get("error_rate", 0))
            features.append(api_data.get("timeout_rate", 0))
            features.append(api_data.get("rate_limit_hits", 0))
            
            # Endpoint diversity
            features.append(api_data.get("unique_endpoints", 0))
            features.append(api_data.get("endpoint_concentration", 0))  # How concentrated requests are
            
            # Response time features
            features.append(api_data.get("avg_response_time", 0))
            features.append(api_data.get("max_response_time", 0))
            
            # Data volume features
            features.append(api_data.get("total_bytes_sent", 0))
            features.append(api_data.get("total_bytes_received", 0))
            
            return features
            
        except Exception as e:
            self.logger.error(f"❌ Error extracting API usage features: {e}")
            return []

    def _extract_system_features(self, system_data: Dict[str, Any]) -> List[float]:
        """Extract features from system data"""
        try:
            features = []
            
            # Performance metrics
            features.append(system_data.get("cpu_usage", 0))
            features.append(system_data.get("memory_usage", 0))
            features.append(system_data.get("disk_usage", 0))
            features.append(system_data.get("network_io", 0))
            
            # Database metrics
            features.append(system_data.get("db_connections", 0))
            features.append(system_data.get("db_query_time", 0))
            features.append(system_data.get("db_lock_waits", 0))
            
            # Application metrics
            features.append(system_data.get("active_sessions", 0))
            features.append(system_data.get("error_count", 0))
            features.append(system_data.get("response_time", 0))
            
            # Security metrics
            features.append(system_data.get("failed_logins", 0))
            features.append(system_data.get("blocked_requests", 0))
            
            return features
            
        except Exception as e:
            self.logger.error(f"❌ Error extracting system features: {e}")
            return []

    def _get_user_feature_names(self) -> List[str]:
        """Get user behavior feature names"""
        return [
            "current_hour", "business_hours", "night_hours",
            "session_duration", "actions_per_session", "pages_visited",
            "api_calls_count", "failed_requests", "unique_endpoints",
            "latitude", "longitude", "new_device", "mobile_device"
        ]

    async def _rule_based_user_detection(self, user_id: str, behavior_data: Dict[str, Any]) -> Tuple[bool, float, List[str]]:
        """Rule-based user behavior anomaly detection"""
        try:
            anomalies = []
            anomaly_score = 0.0
            
            # Check for suspicious patterns
            if behavior_data.get("failed_requests", 0) > 10:
                anomalies.append("High number of failed requests")
                anomaly_score += 0.3
            
            if behavior_data.get("api_calls_count", 0) > 1000:
                anomalies.append("Unusually high API usage")
                anomaly_score += 0.4
            
            if behavior_data.get("new_device", False) and behavior_data.get("session_duration", 0) > 3600:
                anomalies.append("Long session from new device")
                anomaly_score += 0.2
            
            # Check time-based anomalies
            current_hour = datetime.utcnow().hour
            if current_hour >= 22 or current_hour <= 6:
                if behavior_data.get("actions_per_session", 0) > 50:
                    anomalies.append("High activity during night hours")
                    anomaly_score += 0.3
            
            is_anomaly = anomaly_score > 0.5
            return is_anomaly, min(anomaly_score, 1.0), anomalies
            
        except Exception as e:
            self.logger.error(f"❌ Error in rule-based user detection: {e}")
            return False, 0.0, []    async
 def _rule_based_api_detection(self, user_id: str, api_data: Dict[str, Any]) -> Tuple[bool, float, List[str]]:
        """Rule-based API usage anomaly detection"""
        try:
            anomalies = []
            anomaly_score = 0.0
            
            # Rate limiting checks
            requests_per_minute = api_data.get("requests_per_minute", 0)
            if requests_per_minute > 100:
                anomalies.append(f"High request rate: {requests_per_minute} req/min")
                anomaly_score += 0.4
            
            # Error rate checks
            error_rate = api_data.get("error_rate", 0)
            if error_rate > 0.2:  # 20% error rate
                anomalies.append(f"High error rate: {error_rate:.2%}")
                anomaly_score += 0.3
            
            # Endpoint concentration
            unique_endpoints = api_data.get("unique_endpoints", 0)
            total_requests = api_data.get("total_requests", 0)
            if total_requests > 0 and unique_endpoints / total_requests < 0.1:
                anomalies.append("Highly concentrated API usage pattern")
                anomaly_score += 0.2
            
            # Response time anomalies
            avg_response_time = api_data.get("avg_response_time", 0)
            if avg_response_time > 5000:  # 5 seconds
                anomalies.append(f"Slow API responses: {avg_response_time}ms")
                anomaly_score += 0.2
            
            is_anomaly = anomaly_score > 0.5
            return is_anomaly, min(anomaly_score, 1.0), anomalies
            
        except Exception as e:
            self.logger.error(f"❌ Error in rule-based API detection: {e}")
            return False, 0.0, []

    async def _rule_based_system_detection(self, system_data: Dict[str, Any]) -> Tuple[bool, float, List[str]]:
        """Rule-based system anomaly detection"""
        try:
            anomalies = []
            anomaly_score = 0.0
            
            # Resource usage checks
            cpu_usage = system_data.get("cpu_usage", 0)
            if cpu_usage > 90:
                anomalies.append(f"High CPU usage: {cpu_usage}%")
                anomaly_score += 0.3
            
            memory_usage = system_data.get("memory_usage", 0)
            if memory_usage > 85:
                anomalies.append(f"High memory usage: {memory_usage}%")
                anomaly_score += 0.3
            
            # Database performance
            db_query_time = system_data.get("db_query_time", 0)
            if db_query_time > 1000:  # 1 second
                anomalies.append(f"Slow database queries: {db_query_time}ms")
                anomaly_score += 0.2
            
            # Security metrics
            failed_logins = system_data.get("failed_logins", 0)
            if failed_logins > 50:
                anomalies.append(f"High failed login attempts: {failed_logins}")
                anomaly_score += 0.4
            
            is_anomaly = anomaly_score > 0.5
            return is_anomaly, min(anomaly_score, 1.0), anomalies
            
        except Exception as e:
            self.logger.error(f"❌ Error in rule-based system detection: {e}")
            return False, 0.0, []

    async def _analyze_user_behavior_anomaly(self, user_id: str, behavior_data: Dict[str, Any], 
                                           features: List[float]) -> List[str]:
        """Analyze user behavior anomaly in detail"""
        try:
            reasons = []
            feature_names = self._get_user_feature_names()
            
            # Get historical data for comparison
            historical_data = await self._get_historical_user_data(user_id)
            
            if historical_data:
                # Compare current behavior with historical patterns
                for i, (feature_name, current_value) in enumerate(zip(feature_names, features)):
                    if feature_name in historical_data:
                        historical_values = historical_data[feature_name]
                        if len(historical_values) > 5:
                            mean_val = np.mean(historical_values)
                            std_val = np.std(historical_values)
                            
                            if std_val > 0:
                                z_score = abs(current_value - mean_val) / std_val
                                if z_score > 2.5:  # 2.5 standard deviations
                                    reasons.append(f"Unusual {feature_name}: {current_value:.2f} (typical: {mean_val:.2f}±{std_val:.2f})")
            
            # Add specific behavioral anomalies
            if behavior_data.get("new_device", False):
                reasons.append("Access from new device")
            
            if behavior_data.get("session_duration", 0) > 7200:  # 2 hours
                reasons.append("Unusually long session duration")
            
            return reasons
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing user behavior anomaly: {e}")
            return ["Behavioral anomaly detected"]

    async def _analyze_api_usage_anomaly(self, user_id: str, api_data: Dict[str, Any], 
                                       features: List[float]) -> List[str]:
        """Analyze API usage anomaly in detail"""
        try:
            reasons = []
            
            # Check for specific API abuse patterns
            if api_data.get("requests_per_minute", 0) > 50:
                reasons.append(f"High request rate: {api_data['requests_per_minute']} req/min")
            
            if api_data.get("error_rate", 0) > 0.15:
                reasons.append(f"High error rate: {api_data['error_rate']:.2%}")
            
            if api_data.get("rate_limit_hits", 0) > 0:
                reasons.append(f"Rate limit violations: {api_data['rate_limit_hits']}")
            
            # Check for data scraping patterns
            total_bytes = api_data.get("total_bytes_received", 0)
            if total_bytes > 10 * 1024 * 1024:  # 10MB
                reasons.append(f"Large data download: {total_bytes / (1024*1024):.1f}MB")
            
            return reasons
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing API usage anomaly: {e}")
            return ["API usage anomaly detected"]

    async def _analyze_system_anomaly(self, system_data: Dict[str, Any], 
                                    features: List[float]) -> List[str]:
        """Analyze system anomaly in detail"""
        try:
            reasons = []
            
            # Resource usage anomalies
            if system_data.get("cpu_usage", 0) > 80:
                reasons.append(f"High CPU usage: {system_data['cpu_usage']}%")
            
            if system_data.get("memory_usage", 0) > 80:
                reasons.append(f"High memory usage: {system_data['memory_usage']}%")
            
            # Performance anomalies
            if system_data.get("response_time", 0) > 2000:
                reasons.append(f"Slow response time: {system_data['response_time']}ms")
            
            # Security anomalies
            if system_data.get("failed_logins", 0) > 20:
                reasons.append(f"Multiple failed logins: {system_data['failed_logins']}")
            
            return reasons
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing system anomaly: {e}")
            return ["System anomaly detected"]

    async def _send_alert_notifications(self, alert_data: Dict[str, Any]):
        """Send alert notifications through configured channels"""
        try:
            alert_id = alert_data["alert_id"]
            severity = alert_data["severity"]
            
            # Email notification for high/critical alerts
            if severity in ["high", "critical"] and settings.SENDGRID_API_KEY:
                await self._send_email_alert(alert_data)
            
            # Slack notification (if configured)
            # await self._send_slack_alert(alert_data)
            
            # SMS notification for critical alerts
            if severity == "critical" and settings.TWILIO_ACCOUNT_SID:
                await self._send_sms_alert(alert_data)
            
            # Store notification in Redis for dashboard
            await self.redis_client.lpush(
                "security_notifications",
                json.dumps({
                    "alert_id": alert_id,
                    "message": f"Security Alert: {alert_data['alert_type']} - {severity.upper()}",
                    "timestamp": datetime.utcnow().isoformat(),
                    "severity": severity
                })
            )
            
            # Keep only recent notifications
            await self.redis_client.ltrim("security_notifications", 0, 99)
            
        except Exception as e:
            self.logger.error(f"❌ Error sending alert notifications: {e}")

    async def _send_email_alert(self, alert_data: Dict[str, Any]):
        """Send email alert notification"""
        try:
            # This would integrate with SendGrid or similar service
            # For now, just log the alert
            self.logger.info(f"📧 Email alert would be sent: {alert_data['alert_id']}")
            
        except Exception as e:
            self.logger.error(f"❌ Error sending email alert: {e}")

    async def _send_sms_alert(self, alert_data: Dict[str, Any]):
        """Send SMS alert notification"""
        try:
            # This would integrate with Twilio or similar service
            # For now, just log the alert
            self.logger.info(f"📱 SMS alert would be sent: {alert_data['alert_id']}")
            
        except Exception as e:
            self.logger.error(f"❌ Error sending SMS alert: {e}")

    async def _execute_automated_response(self, alert_data: Dict[str, Any]):
        """Execute automated response based on alert type and severity"""
        try:
            alert_type = alert_data["alert_type"]
            severity = alert_data["severity"]
            entity_id = alert_data["entity_id"]
            
            # Define automated responses based on alert type
            if alert_type == "brute_force_attack" and severity in ["high", "critical"]:
                await self._block_entity(entity_id, duration_minutes=60)
            
            elif alert_type == "api_abuse" and severity == "high":
                await self._rate_limit_entity(entity_id, limit=10, window_minutes=60)
            
            elif alert_type == "data_exfiltration" and severity == "critical":
                await self._quarantine_entity(entity_id)
                await self._notify_security_team(alert_data)
            
            elif alert_type == "system_compromise" and severity == "critical":
                await self._emergency_lockdown()
            
        except Exception as e:
            self.logger.error(f"❌ Error executing automated response: {e}")

    async def _execute_response_action(self, action: str, entity_id: str, 
                                     alert: Dict[str, Any]) -> IncidentResponse:
        """Execute specific incident response action"""
        try:
            response = IncidentResponse(
                action_type=action,
                target=entity_id,
                parameters={"alert_id": alert["alert_id"]}
            )
            
            if action == "block_user":
                success = await self._block_entity(entity_id, duration_minutes=60)
                response.success = success
                response.executed_at = datetime.utcnow()
                
            elif action == "rate_limit":
                success = await self._rate_limit_entity(entity_id, limit=5, window_minutes=60)
                response.success = success
                response.executed_at = datetime.utcnow()
                
            elif action == "quarantine":
                success = await self._quarantine_entity(entity_id)
                response.success = success
                response.executed_at = datetime.utcnow()
                
            elif action == "notify_admin":
                success = await self._notify_security_team(alert)
                response.success = success
                response.executed_at = datetime.utcnow()
                
            else:
                response.success = False
                response.error_message = f"Unknown action: {action}"
            
            return response
            
        except Exception as e:
            self.logger.error(f"❌ Error executing response action {action}: {e}")
            return IncidentResponse(
                action_type=action,
                target=entity_id,
                parameters={},
                success=False,
                error_message=str(e)
            )

    async def _block_entity(self, entity_id: str, duration_minutes: int = 60) -> bool:
        """Block entity for specified duration"""
        try:
            block_until = datetime.utcnow() + timedelta(minutes=duration_minutes)
            self.blocked_entities[entity_id] = block_until
            
            # Store in Redis
            await self.redis_client.setex(
                f"blocked_entity:{entity_id}",
                duration_minutes * 60,
                block_until.isoformat()
            )
            
            audit_logger.log_system_event(
                event_type="entity_blocked",
                details={
                    "entity_id": entity_id,
                    "duration_minutes": duration_minutes,
                    "block_until": block_until.isoformat()
                },
                severity="warning"
            )
            
            self.logger.warning(f"🚫 Entity blocked: {entity_id} for {duration_minutes} minutes")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error blocking entity: {e}")
            return False

    async def _rate_limit_entity(self, entity_id: str, limit: int, window_minutes: int) -> bool:
        """Apply rate limiting to entity"""
        try:
            # Store rate limit in Redis
            rate_limit_key = f"rate_limit:{entity_id}"
            await self.redis_client.setex(
                rate_limit_key,
                window_minutes * 60,
                json.dumps({
                    "limit": limit,
                    "window_minutes": window_minutes,
                    "applied_at": datetime.utcnow().isoformat()
                })
            )
            
            audit_logger.log_system_event(
                event_type="rate_limit_applied",
                details={
                    "entity_id": entity_id,
                    "limit": limit,
                    "window_minutes": window_minutes
                },
                severity="info"
            )
            
            self.logger.info(f"⏱️ Rate limit applied: {entity_id} - {limit} requests per {window_minutes} minutes")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error applying rate limit: {e}")
            return False

    async def _quarantine_entity(self, entity_id: str) -> bool:
        """Quarantine entity (severe restriction)"""
        try:
            # Store quarantine status
            await self.redis_client.setex(
                f"quarantined_entity:{entity_id}",
                86400,  # 24 hours
                json.dumps({
                    "quarantined_at": datetime.utcnow().isoformat(),
                    "reason": "Security threat detected"
                })
            )
            
            audit_logger.log_system_event(
                event_type="entity_quarantined",
                details={
                    "entity_id": entity_id,
                    "reason": "Security threat detected"
                },
                severity="error"
            )
            
            self.logger.error(f"🔒 Entity quarantined: {entity_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error quarantining entity: {e}")
            return False

    async def _notify_security_team(self, alert_data: Dict[str, Any]) -> bool:
        """Notify security team of critical alert"""
        try:
            # This would send notifications to security team
            # For now, just log the notification
            self.logger.critical(f"🚨 SECURITY TEAM NOTIFICATION: {alert_data['alert_type']} - {alert_data['entity_id']}")
            
            # Store high-priority notification
            await self.redis_client.lpush(
                "security_team_notifications",
                json.dumps({
                    "alert_id": alert_data["alert_id"],
                    "alert_type": alert_data["alert_type"],
                    "entity_id": alert_data["entity_id"],
                    "severity": alert_data["severity"],
                    "timestamp": datetime.utcnow().isoformat(),
                    "requires_immediate_attention": True
                })
            )
            
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error notifying security team: {e}")
            return False

    async def _emergency_lockdown(self) -> bool:
        """Execute emergency system lockdown"""
        try:
            # This would implement emergency lockdown procedures
            # For now, just log the action
            self.logger.critical("🚨 EMERGENCY LOCKDOWN INITIATED")
            
            # Store lockdown status
            await self.redis_client.setex(
                "emergency_lockdown",
                3600,  # 1 hour
                json.dumps({
                    "initiated_at": datetime.utcnow().isoformat(),
                    "reason": "Critical security threat detected"
                })
            )
            
            audit_logger.log_system_event(
                event_type="emergency_lockdown",
                details={
                    "reason": "Critical security threat detected",
                    "initiated_at": datetime.utcnow().isoformat()
                },
                severity="critical"
            )
            
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Error executing emergency lockdown: {e}")
            return False

    async def _model_training_loop(self):
        """Periodically retrain ML models with new data"""
        while True:
            try:
                await asyncio.sleep(3600)  # Train every hour
                
                # Train user behavior model
                if len(self.user_behavior_buffer) > 100:
                    await self._train_user_behavior_model()
                
                # Train API usage model
                if len(self.api_usage_buffer) > 100:
                    await self._train_api_usage_model()
                
                # Train system metrics model
                if len(self.system_metrics_buffer) > 100:
                    await self._train_system_metrics_model()
                
                self.logger.info("🤖 ML models retrained with latest data")
                
            except Exception as e:
                self.logger.error(f"❌ Error in model training loop: {e}")
                await asyncio.sleep(3600)

    async def _train_user_behavior_model(self):
        """Train user behavior anomaly detection model"""
        try:
            # Prepare training data
            training_data = list(self.user_behavior_buffer)
            if len(training_data) < 50:
                return
            
            # Extract features
            features_list = []
            for data in training_data:
                features = self._extract_user_behavior_features(data)
                if features:
                    features_list.append(features)
            
            if len(features_list) < 50:
                return
            
            # Convert to numpy array and normalize
            X = np.array(features_list)
            X_scaled = self.user_scaler.fit_transform(X)
            
            # Train model
            self.user_behavior_model.fit(X_scaled)
            
            # Calculate model accuracy (simplified)
            predictions = self.user_behavior_model.predict(X_scaled)
            anomaly_rate = np.sum(predictions == -1) / len(predictions)
            self.detection_stats["model_accuracy"] = 1.0 - abs(anomaly_rate - 0.1)  # Target 10% anomaly rate
            
            self.logger.info(f"👤 User behavior model trained with {len(features_list)} samples")
            
        except Exception as e:
            self.logger.error(f"❌ Error training user behavior model: {e}")

    async def _train_api_usage_model(self):
        """Train API usage anomaly detection model"""
        try:
            # Similar to user behavior model training
            training_data = list(self.api_usage_buffer)
            features_list = []
            
            for data in training_data:
                features = self._extract_api_usage_features(data)
                if features:
                    features_list.append(features)
            
            if len(features_list) < 50:
                return
            
            X = np.array(features_list)
            X_scaled = self.api_scaler.fit_transform(X)
            
            self.api_usage_model.fit(X_scaled)
            
            self.logger.info(f"🔌 API usage model trained with {len(features_list)} samples")
            
        except Exception as e:
            self.logger.error(f"❌ Error training API usage model: {e}")

    async def _train_system_metrics_model(self):
        """Train system metrics anomaly detection model"""
        try:
            training_data = list(self.system_metrics_buffer)
            features_list = []
            
            for data in training_data:
                features = self._extract_system_features(data)
                if features:
                    features_list.append(features)
            
            if len(features_list) < 50:
                return
            
            X = np.array(features_list)
            X_scaled = self.system_scaler.fit_transform(X)
            
            self.system_metrics_model.fit(X_scaled)
            
            self.logger.info(f"🖥️ System metrics model trained with {len(features_list)} samples")
            
        except Exception as e:
            self.logger.error(f"❌ Error training system metrics model: {e}")

    async def _initialize_ml_models(self):
        """Initialize ML models with historical data"""
        try:
            # Load historical data from database
            async with get_async_session() as session:
                # Get recent agent logs for training
                recent_time = datetime.utcnow() - timedelta(days=7)
                
                logs_query = select(AgentLog).where(
                    AgentLog.timestamp >= recent_time
                ).limit(1000)
                
                logs = await session.execute(logs_query)
                
                # Process logs for training data
                for log in logs.scalars():
                    if log.context:
                        # Extract behavior data from log context
                        behavior_data = self._extract_behavior_from_log(log)
                        if behavior_data:
                            self.user_behavior_buffer.append(behavior_data)
            
            self.logger.info("🤖 ML models initialized with historical data")
            
        except Exception as e:
            self.logger.error(f"❌ Error initializing ML models: {e}")

    def _extract_behavior_from_log(self, log: AgentLog) -> Optional[Dict[str, Any]]:
        """Extract behavior data from agent log"""
        try:
            if not log.context:
                return None
            
            # Extract relevant behavior features from log context
            behavior_data = {
                "session_duration": log.context.get("session_duration", 0),
                "actions_per_session": log.context.get("actions_count", 0),
                "api_calls_count": log.context.get("api_calls", 0),
                "failed_requests": log.context.get("failed_requests", 0),
                "new_device": log.context.get("new_device", False),
                "mobile_device": log.context.get("mobile_device", False)
            }
            
            return behavior_data
            
        except Exception as e:
            self.logger.error(f"❌ Error extracting behavior from log: {e}")
            return None

    async def _get_historical_user_data(self, user_id: str) -> Dict[str, List[float]]:
        """Get historical user data for comparison"""
        try:
            # Get from Redis cache first
            cache_key = f"user_history:{user_id}"
            cached_data = await self.redis_client.get(cache_key)
            
            if cached_data:
                return json.loads(cached_data)
            
            # If not in cache, return empty dict
            return {}
            
        except Exception as e:
            self.logger.error(f"❌ Error getting historical user data: {e}")
            return {}

    async def _load_security_rules(self):
        """Load security rules from configuration"""
        try:
            # Default security rules
            default_rules = [
                SecurityRule(
                    rule_id="high_api_usage",
                    name="High API Usage",
                    description="Detect unusually high API usage",
                    rule_type="threshold",
                    conditions={"requests_per_minute": 100},
                    severity="medium"
                ),
                SecurityRule(
                    rule_id="failed_login_attempts",
                    name="Multiple Failed Logins",
                    description="Detect brute force login attempts",
                    rule_type="threshold",
                    conditions={"failed_logins": 10, "time_window": 300},
                    severity="high"
                ),
                SecurityRule(
                    rule_id="night_activity",
                    name="Unusual Night Activity",
                    description="Detect high activity during night hours",
                    rule_type="pattern",
                    conditions={"hours": [22, 23, 0, 1, 2, 3, 4, 5, 6], "activity_threshold": 50},
                    severity="low"
                )
            ]
            
            for rule in default_rules:
                self.security_rules[rule.rule_id] = rule
            
            self.logger.info(f"📋 Loaded {len(self.security_rules)} security rules")
            
        except Exception as e:
            self.logger.error(f"❌ Error loading security rules: {e}")

    async def _load_threat_indicators(self):
        """Load threat indicators from Redis"""
        try:
            # Load from Redis
            indicator_keys = await self.redis_client.keys("threat_indicator:*")
            
            for key in indicator_keys:
                try:
                    indicator_data = await self.redis_client.get(key)
                    if indicator_data:
                        data = json.loads(indicator_data)
                        
                        indicator = ThreatIndicator(
                            indicator_type=data["type"],
                            value=data["value"],
                            severity=data["severity"],
                            confidence=data["confidence"],
                            first_seen=datetime.fromisoformat(data["first_seen"]),
                            last_seen=datetime.fromisoformat(data["last_seen"]),
                            occurrence_count=data["occurrence_count"],
                            context=data["context"]
                        )
                        
                        indicator_key = f"{data['type']}:{data['value']}"
                        self.threat_indicators[indicator_key] = indicator
                        
                except Exception as e:
                    self.logger.debug(f"Could not load threat indicator {key}: {e}")
            
            self.logger.info(f"🎯 Loaded {len(self.threat_indicators)} threat indicators")
            
        except Exception as e:
            self.logger.error(f"❌ Error loading threat indicators: {e}")

    async def _threat_intelligence_update_loop(self):
        """Periodically update threat intelligence"""
        while True:
            try:
                await asyncio.sleep(3600)  # Update every hour
                
                # Clean up old indicators
                current_time = datetime.utcnow()
                expired_indicators = []
                
                for key, indicator in self.threat_indicators.items():
                    if (current_time - indicator.last_seen).days > 30:  # 30 days old
                        expired_indicators.append(key)
                
                for key in expired_indicators:
                    del self.threat_indicators[key]
                    await self.redis_client.delete(f"threat_indicator:{key}")
                
                if expired_indicators:
                    self.logger.info(f"🧹 Cleaned up {len(expired_indicators)} expired threat indicators")
                
            except Exception as e:
                self.logger.error(f"❌ Error in threat intelligence update loop: {e}")
                await asyncio.sleep(3600)

    async def _cleanup_loop(self):
        """Cleanup old data and expired blocks"""
        while True:
            try:
                await asyncio.sleep(1800)  # Cleanup every 30 minutes
                
                current_time = datetime.utcnow()
                
                # Clean up expired blocks
                expired_blocks = []
                for entity_id, block_until in self.blocked_entities.items():
                    if current_time > block_until:
                        expired_blocks.append(entity_id)
                
                for entity_id in expired_blocks:
                    del self.blocked_entities[entity_id]
                    await self.redis_client.delete(f"blocked_entity:{entity_id}")
                
                if expired_blocks:
                    self.logger.info(f"🧹 Cleaned up {len(expired_blocks)} expired blocks")
                
                # Clean up old incident responses
                self.incident_responses = [
                    r for r in self.incident_responses
                    if r.executed_at and (current_time - r.executed_at).days <= 7
                ]
                
            except Exception as e:
                self.logger.error(f"❌ Error in cleanup loop: {e}")
                await asyncio.sleep(1800)

    async def get_security_metrics(self) -> Dict[str, Any]:
        """Get security metrics for monitoring"""
        try:
            current_time = datetime.utcnow()
            
            # Active threats
            active_blocks = len(self.blocked_entities)
            active_indicators = len(self.threat_indicators)
            
            # Recent activity
            recent_alerts = await self.redis_client.llen("security_notifications")
            
            metrics = {
                "detection_stats": self.detection_stats,
                "active_blocks": active_blocks,
                "active_threat_indicators": active_indicators,
                "recent_alerts": recent_alerts,
                "security_rules_count": len(self.security_rules),
                "ml_models_trained": {
                    "user_behavior": hasattr(self.user_behavior_model, 'decision_function'),
                    "api_usage": hasattr(self.api_usage_model, 'decision_function'),
                    "system_metrics": hasattr(self.system_metrics_model, 'decision_function')
                },
                "timestamp": current_time.isoformat()
            }
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"❌ Error getting security metrics: {e}")
            return {"error": str(e)}

# Global security service instance
security_service = SecurityService()