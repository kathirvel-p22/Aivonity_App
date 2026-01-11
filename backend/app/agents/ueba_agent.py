"""
AIVONITY UEBA (User and Entity Behavior Analytics) Agent
Advanced security monitoring and behavioral analysis
"""

import asyncio
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, field
import numpy as np
from collections import defaultdict, deque
import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
import logging

from app.agents.base_agent import BaseAgent, AgentMessage
from app.db.database import get_async_session
from app.db.models import (
    AgentLog, User, Vehicle, TelemetryData, ChatSession, 
    ServiceBooking, SystemMetrics
)
from app.config import settings
from app.utils.logging_config import get_logger, security_logger, audit_logger

@dataclass
class BehaviorProfile:
    """User/Entity behavior profile for baseline comparison"""
    entity_id: str
    entity_type: str  # user, agent, system
    
    # Activity patterns
    typical_activity_hours: List[int] = field(default_factory=list)
    typical_activity_days: List[int] = field(default_factory=list)
    average_session_duration: float = 0.0
    typical_actions_per_session: float = 0.0
    
    # Location patterns (for users)
    typical_locations: List[Dict[str, float]] = field(default_factory=list)
    location_variance_threshold: float = 50.0  # km
    
    # API usage patterns
    typical_api_calls_per_hour: float = 0.0
    typical_endpoints: Dict[str, float] = field(default_factory=dict)
    
    # Agent-specific patterns
    typical_processing_time: float = 0.0
    typical_error_rate: float = 0.0
    typical_memory_usage: float = 0.0
    
    # Anomaly thresholds
    activity_anomaly_threshold: float = 2.0  # standard deviations
    location_anomaly_threshold: float = 3.0
    api_anomaly_threshold: float = 2.5
    
    # Profile metadata
    created_at: datetime = field(default_factory=datetime.utcnow)
    last_updated: datetime = field(default_factory=datetime.utcnow)
    sample_size: int = 0
    confidence_score: float = 0.0

@dataclass
class SecurityAlert:
    """Security alert with detailed information"""
    alert_id: str
    entity_id: str
    entity_type: str
    alert_type: str
    severity: str  # low, medium, high, critical
    
    # Alert details
    title: str
    description: str
    anomaly_score: float
    confidence: float
    
    # Context information
    context: Dict[str, Any] = field(default_factory=dict)
    indicators: List[str] = field(default_factory=list)
    
    # Timestamps
    detected_at: datetime = field(default_factory=datetime.utcnow)
    first_seen: Optional[datetime] = None
    last_seen: Optional[datetime] = None
    
    # Response tracking
    status: str = "new"  # new, investigating, resolved, false_positive
    assigned_to: Optional[str] = None
    resolution_notes: Optional[str] = None

class UEBAAgent(BaseAgent):
    """
    User and Entity Behavior Analytics Agent
    Monitors behavior patterns and detects security anomalies
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("ueba_agent", config)
        
        # Configuration
        self.monitoring_interval = config.get("monitoring_interval", 300)  # 5 minutes
        self.anomaly_threshold = config.get("anomaly_threshold", 0.8)
        self.alert_threshold = config.get("alert_threshold", 0.9)
        self.profile_update_interval = config.get("profile_update_interval", 3600)  # 1 hour
        
        # Behavior profiles storage
        self.behavior_profiles: Dict[str, BehaviorProfile] = {}
        self.activity_buffers: Dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        
        # Alert management
        self.active_alerts: Dict[str, SecurityAlert] = {}
        self.alert_history: deque = deque(maxlen=10000)
        
        # Redis for real-time data
        self.redis_client = None
        
        # Monitoring state
        self.last_profile_update = datetime.utcnow()
        self.monitoring_stats = {
            "entities_monitored": 0,
            "alerts_generated": 0,
            "anomalies_detected": 0,
            "profiles_updated": 0
        }
        
        self.logger.info("🔒 UEBA Agent initialized with behavioral monitoring")

    def _define_capabilities(self) -> List[str]:
        """Define UEBA agent capabilities"""
        return [
            "behavioral_monitoring",
            "anomaly_detection", 
            "security_alerting",
            "user_profiling",
            "agent_monitoring",
            "threat_detection",
            "compliance_monitoring"
        ]

    async def _initialize_resources(self):
        """Initialize UEBA agent resources"""
        try:
            # Initialize Redis connection
            self.redis_client = redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            await self.redis_client.ping()
            
            # Load existing behavior profiles
            await self._load_behavior_profiles()
            
            # Start monitoring tasks
            asyncio.create_task(self._behavioral_monitoring_loop())
            asyncio.create_task(self._profile_update_loop())
            asyncio.create_task(self._alert_processing_loop())
            
            self.logger.info("✅ UEBA Agent resources initialized")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize UEBA resources: {e}")
            raise

    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process incoming messages for behavioral analysis"""
        try:
            message_type = message.message_type
            payload = message.payload
            
            # Log the activity for behavioral analysis
            await self._log_agent_activity(
                entity_id=message.sender,
                entity_type="agent",
                activity_type="message_processing",
                details={
                    "message_type": message_type,
                    "recipient": message.recipient,
                    "payload_size": len(str(payload))
                }
            )
            
            if message_type == "security_event":
                return await self._handle_security_event(payload)
            
            elif message_type == "user_activity":
                return await self._handle_user_activity(payload)
            
            elif message_type == "agent_health":
                return await self._handle_agent_health(payload)
            
            elif message_type == "anomaly_report":
                return await self._handle_anomaly_report(payload)
            
            elif message_type == "get_security_status":
                return await self._handle_security_status_request(payload)
            
            else:
                self.logger.debug(f"📥 Processing message type: {message_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"❌ Error processing UEBA message: {e}")
            return None

    async def health_check(self) -> Dict[str, Any]:
        """Perform UEBA agent health check"""
        try:
            # Check Redis connection
            redis_healthy = False
            try:
                await self.redis_client.ping()
                redis_healthy = True
            except Exception:
                pass
            
            # Check database connection
            db_healthy = False
            try:
                async with get_async_session() as session:
                    result = await session.execute(select(func.count(AgentLog.id)))
                    db_healthy = True
            except Exception:
                pass
            
            # Calculate health metrics
            total_entities = len(self.behavior_profiles)
            active_alerts = len([a for a in self.active_alerts.values() if a.status == "new"])
            
            health_status = {
                "healthy": redis_healthy and db_healthy,
                "redis_connection": redis_healthy,
                "database_connection": db_healthy,
                "entities_monitored": total_entities,
                "active_alerts": active_alerts,
                "monitoring_stats": self.monitoring_stats,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            return health_status
            
        except Exception as e:
            self.logger.error(f"❌ UEBA health check failed: {e}")
            return {
                "healthy": False,
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }

    async def _behavioral_monitoring_loop(self):
        """Main behavioral monitoring loop"""
        while self.is_running:
            try:
                start_time = time.time()
                
                # Monitor user behavior
                await self._monitor_user_behavior()
                
                # Monitor agent behavior
                await self._monitor_agent_behavior()
                
                # Monitor system behavior
                await self._monitor_system_behavior()
                
                # Process anomalies
                await self._process_behavioral_anomalies()
                
                processing_time = time.time() - start_time
                self.logger.debug(f"🔍 Behavioral monitoring cycle completed in {processing_time:.2f}s")
                
                # Wait for next monitoring cycle
                await asyncio.sleep(self.monitoring_interval)
                
            except Exception as e:
                self.logger.error(f"❌ Error in behavioral monitoring loop: {e}")
                await asyncio.sleep(60)  # Wait before retrying

    async def _monitor_user_behavior(self):
        """Monitor user behavioral patterns"""
        try:
            async with get_async_session() as session:
                # Get recent user activities
                recent_time = datetime.utcnow() - timedelta(hours=1)
                
                # Monitor chat sessions
                chat_query = select(ChatSession).where(
                    ChatSession.created_at >= recent_time
                )
                chat_sessions = await session.execute(chat_query)
                
                for session_row in chat_sessions.scalars():
                    await self._analyze_user_chat_behavior(session_row)
                
                # Monitor service bookings
                booking_query = select(ServiceBooking).where(
                    ServiceBooking.created_at >= recent_time
                )
                bookings = await session.execute(booking_query)
                
                for booking in bookings.scalars():
                    await self._analyze_user_booking_behavior(booking)
                
                self.monitoring_stats["entities_monitored"] += 1
                
        except Exception as e:
            self.logger.error(f"❌ Error monitoring user behavior: {e}")

    async def _monitor_agent_behavior(self):
        """Monitor AI agent behavioral patterns"""
        try:
            async with get_async_session() as session:
                # Get recent agent logs
                recent_time = datetime.utcnow() - timedelta(minutes=30)
                
                agent_query = select(AgentLog).where(
                    AgentLog.timestamp >= recent_time
                )
                agent_logs = await session.execute(agent_query)
                
                # Group logs by agent
                agent_activities = defaultdict(list)
                for log in agent_logs.scalars():
                    agent_activities[log.agent_name].append(log)
                
                # Analyze each agent's behavior
                for agent_name, logs in agent_activities.items():
                    await self._analyze_agent_behavior(agent_name, logs)
                
        except Exception as e:
            self.logger.error(f"❌ Error monitoring agent behavior: {e}")

    async def _monitor_system_behavior(self):
        """Monitor system-level behavioral patterns"""
        try:
            async with get_async_session() as session:
                # Get recent system metrics
                recent_time = datetime.utcnow() - timedelta(minutes=15)
                
                metrics_query = select(SystemMetrics).where(
                    SystemMetrics.timestamp >= recent_time
                )
                metrics = await session.execute(metrics_query)
                
                # Analyze system performance patterns
                system_data = []
                for metric in metrics.scalars():
                    system_data.append({
                        "metric_name": metric.metric_name,
                        "value": metric.metric_value,
                        "timestamp": metric.timestamp,
                        "source": metric.source
                    })
                
                if system_data:
                    await self._analyze_system_behavior(system_data)
                
        except Exception as e:
            self.logger.error(f"❌ Error monitoring system behavior: {e}")

    async def _analyze_user_chat_behavior(self, chat_session: ChatSession):
        """Analyze user chat behavior patterns"""
        try:
            user_id = str(chat_session.user_id)
            
            # Get or create behavior profile
            profile = await self._get_or_create_profile(user_id, "user")
            
            # Analyze chat patterns
            session_duration = 0
            message_count = len(chat_session.messages)
            
            if chat_session.ended_at:
                session_duration = (chat_session.ended_at - chat_session.created_at).total_seconds()
            
            # Update activity buffer
            activity = {
                "timestamp": chat_session.created_at,
                "activity_type": "chat_session",
                "duration": session_duration,
                "message_count": message_count,
                "session_type": chat_session.session_type
            }
            
            self.activity_buffers[user_id].append(activity)
            
            # Check for anomalies
            anomalies = await self._detect_chat_anomalies(profile, activity)
            if anomalies:
                await self._generate_security_alert(
                    entity_id=user_id,
                    entity_type="user",
                    alert_type="chat_behavior_anomaly",
                    anomalies=anomalies
                )
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing user chat behavior: {e}")

    async def _analyze_user_booking_behavior(self, booking: ServiceBooking):
        """Analyze user booking behavior patterns"""
        try:
            user_id = str(booking.user_id)
            
            # Get or create behavior profile
            profile = await self._get_or_create_profile(user_id, "user")
            
            # Analyze booking patterns
            activity = {
                "timestamp": booking.created_at,
                "activity_type": "service_booking",
                "service_type": booking.service_type,
                "estimated_cost": booking.estimated_cost,
                "appointment_time": booking.appointment_datetime
            }
            
            self.activity_buffers[user_id].append(activity)
            
            # Check for anomalies
            anomalies = await self._detect_booking_anomalies(profile, activity)
            if anomalies:
                await self._generate_security_alert(
                    entity_id=user_id,
                    entity_type="user",
                    alert_type="booking_behavior_anomaly",
                    anomalies=anomalies
                )
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing user booking behavior: {e}")

    async def _analyze_agent_behavior(self, agent_name: str, logs: List[AgentLog]):
        """Analyze AI agent behavior patterns"""
        try:
            # Get or create behavior profile
            profile = await self._get_or_create_profile(agent_name, "agent")
            
            # Analyze agent activity patterns
            error_count = len([log for log in logs if log.log_level == "ERROR"])
            warning_count = len([log for log in logs if log.log_level == "WARNING"])
            total_logs = len(logs)
            
            # Calculate metrics
            error_rate = error_count / total_logs if total_logs > 0 else 0
            avg_execution_time = np.mean([log.execution_time for log in logs if log.execution_time])
            avg_memory_usage = np.mean([log.memory_usage for log in logs if log.memory_usage])
            
            activity = {
                "timestamp": datetime.utcnow(),
                "activity_type": "agent_operation",
                "total_logs": total_logs,
                "error_rate": error_rate,
                "warning_count": warning_count,
                "avg_execution_time": avg_execution_time,
                "avg_memory_usage": avg_memory_usage
            }
            
            self.activity_buffers[agent_name].append(activity)
            
            # Check for anomalies
            anomalies = await self._detect_agent_anomalies(profile, activity)
            if anomalies:
                await self._generate_security_alert(
                    entity_id=agent_name,
                    entity_type="agent",
                    alert_type="agent_behavior_anomaly",
                    anomalies=anomalies
                )
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing agent behavior: {e}")

    async def _analyze_system_behavior(self, system_data: List[Dict[str, Any]]):
        """Analyze system behavior patterns"""
        try:
            # Get or create system behavior profile
            profile = await self._get_or_create_profile("system", "system")
            
            # Group metrics by type
            metrics_by_type = defaultdict(list)
            for data in system_data:
                metrics_by_type[data["metric_name"]].append(data["value"])
            
            # Analyze each metric type
            for metric_name, values in metrics_by_type.items():
                if len(values) > 1:
                    avg_value = np.mean(values)
                    std_value = np.std(values)
                    max_value = np.max(values)
                    
                    activity = {
                        "timestamp": datetime.utcnow(),
                        "activity_type": "system_metric",
                        "metric_name": metric_name,
                        "avg_value": avg_value,
                        "std_value": std_value,
                        "max_value": max_value,
                        "sample_count": len(values)
                    }
                    
                    self.activity_buffers["system"].append(activity)
                    
                    # Check for system anomalies
                    anomalies = await self._detect_system_anomalies(profile, activity)
                    if anomalies:
                        await self._generate_security_alert(
                            entity_id="system",
                            entity_type="system",
                            alert_type="system_behavior_anomaly",
                            anomalies=anomalies
                        )
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing system behavior: {e}")

    async def _get_or_create_profile(self, entity_id: str, entity_type: str) -> BehaviorProfile:
        """Get existing behavior profile or create new one"""
        profile_key = f"{entity_type}:{entity_id}"
        
        if profile_key not in self.behavior_profiles:
            self.behavior_profiles[profile_key] = BehaviorProfile(
                entity_id=entity_id,
                entity_type=entity_type
            )
            
            # Try to load from Redis cache
            try:
                cached_profile = await self.redis_client.get(f"profile:{profile_key}")
                if cached_profile:
                    profile_data = json.loads(cached_profile)
                    # Update profile with cached data
                    profile = self.behavior_profiles[profile_key]
                    for key, value in profile_data.items():
                        if hasattr(profile, key):
                            setattr(profile, key, value)
            except Exception as e:
                self.logger.debug(f"Could not load cached profile: {e}")
        
        return self.behavior_profiles[profile_key]

    async def _detect_chat_anomalies(self, profile: BehaviorProfile, activity: Dict[str, Any]) -> List[str]:
        """Detect anomalies in chat behavior using advanced algorithms"""
        anomalies = []
        
        try:
            # Statistical anomaly detection for session duration
            if profile.average_session_duration > 0:
                duration_ratio = activity["duration"] / profile.average_session_duration
                if duration_ratio > 3.0:  # 3x longer than usual
                    anomalies.append(f"Unusually long chat session: {activity['duration']:.0f}s vs avg {profile.average_session_duration:.0f}s")
                elif duration_ratio < 0.1 and activity["duration"] > 0:  # Suspiciously short
                    anomalies.append(f"Suspiciously short chat session: {activity['duration']:.0f}s")
            
            # Message count anomaly with statistical analysis
            if profile.typical_actions_per_session > 0:
                message_ratio = activity["message_count"] / profile.typical_actions_per_session
                if message_ratio > 2.5:  # 2.5x more messages than usual
                    anomalies.append(f"Unusually high message count: {activity['message_count']} vs avg {profile.typical_actions_per_session:.0f}")
                elif message_ratio > 5.0:  # Potential spam or bot behavior
                    anomalies.append(f"Potential automated behavior: {activity['message_count']} messages (5x normal)")
            
            # Time-based anomalies with confidence scoring
            activity_hour = activity["timestamp"].hour
            if profile.typical_activity_hours:
                if activity_hour not in profile.typical_activity_hours:
                    # Check if it's significantly outside normal hours
                    hour_distances = [min(abs(activity_hour - h), 24 - abs(activity_hour - h)) for h in profile.typical_activity_hours]
                    min_distance = min(hour_distances)
                    if min_distance > 3:  # More than 3 hours from typical activity
                        anomalies.append(f"Activity outside typical hours: {activity_hour}:00 (min distance: {min_distance}h)")
            
            # Frequency-based anomalies
            recent_activities = [
                a for a in self.activity_buffers[profile.entity_id]
                if a.get("activity_type") == "chat_session" and
                (datetime.utcnow() - a["timestamp"]).minutes <= 60
            ]
            
            if len(recent_activities) > 5:  # More than 5 chat sessions in 1 hour
                anomalies.append(f"High chat frequency: {len(recent_activities)} sessions in 1 hour")
            
            # Session type anomalies
            if activity.get("session_type"):
                session_type_counts = defaultdict(int)
                for a in self.activity_buffers[profile.entity_id]:
                    if a.get("session_type"):
                        session_type_counts[a["session_type"]] += 1
                
                total_sessions = sum(session_type_counts.values())
                if total_sessions > 10:  # Only analyze if we have enough data
                    current_type = activity["session_type"]
                    type_frequency = session_type_counts.get(current_type, 0) / total_sessions
                    
                    if type_frequency < 0.05:  # Less than 5% of sessions are this type
                        anomalies.append(f"Unusual session type: {current_type} (rare: {type_frequency:.1%})")
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting chat anomalies: {e}")
        
        return anomalies

    async def _detect_booking_anomalies(self, profile: BehaviorProfile, activity: Dict[str, Any]) -> List[str]:
        """Detect anomalies in booking behavior"""
        anomalies = []
        
        try:
            # Check booking frequency
            recent_bookings = [
                a for a in self.activity_buffers[profile.entity_id]
                if a.get("activity_type") == "service_booking" and
                (datetime.utcnow() - a["timestamp"]).days <= 7
            ]
            
            if len(recent_bookings) > 3:  # More than 3 bookings in a week
                anomalies.append(f"High booking frequency: {len(recent_bookings)} bookings in 7 days")
            
            # Check cost anomalies
            if activity.get("estimated_cost"):
                recent_costs = [a.get("estimated_cost", 0) for a in recent_bookings if a.get("estimated_cost")]
                if recent_costs:
                    avg_cost = np.mean(recent_costs)
                    if activity["estimated_cost"] > avg_cost * 2:
                        anomalies.append(f"Unusually high booking cost: ${activity['estimated_cost']} vs avg ${avg_cost:.2f}")
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting booking anomalies: {e}")
        
        return anomalies

    async def _detect_agent_anomalies(self, profile: BehaviorProfile, activity: Dict[str, Any]) -> List[str]:
        """Detect anomalies in agent behavior using advanced statistical methods"""
        anomalies = []
        
        try:
            # Advanced error rate anomaly detection
            if profile.typical_error_rate > 0:
                error_rate_ratio = activity["error_rate"] / profile.typical_error_rate
                if error_rate_ratio > 3.0:  # 3x higher error rate
                    anomalies.append(f"High error rate: {activity['error_rate']:.3f} vs typical {profile.typical_error_rate:.3f}")
                elif error_rate_ratio > 10.0:  # Extremely high error rate
                    anomalies.append(f"Critical error rate spike: {activity['error_rate']:.3f} ({error_rate_ratio:.1f}x normal)")
            elif activity["error_rate"] > 0.1:  # 10% error rate when typically 0
                anomalies.append(f"Unexpected error rate: {activity['error_rate']:.3f}")
            elif activity["error_rate"] > 0.5:  # Critical error rate
                anomalies.append(f"Critical error rate: {activity['error_rate']:.3f} (potential system compromise)")
            
            # Execution time anomaly with trend analysis
            if profile.typical_processing_time > 0 and activity.get("avg_execution_time"):
                time_ratio = activity["avg_execution_time"] / profile.typical_processing_time
                if time_ratio > 2.0:  # 2x slower than usual
                    anomalies.append(f"Slow processing: {activity['avg_execution_time']:.2f}s vs typical {profile.typical_processing_time:.2f}s")
                elif time_ratio > 5.0:  # Extremely slow
                    anomalies.append(f"Critical performance degradation: {activity['avg_execution_time']:.2f}s ({time_ratio:.1f}x slower)")
                elif time_ratio < 0.1:  # Suspiciously fast (potential bypass)
                    anomalies.append(f"Suspiciously fast processing: {activity['avg_execution_time']:.2f}s (potential security bypass)")
            
            # Memory usage anomaly detection
            if profile.typical_memory_usage > 0 and activity.get("avg_memory_usage"):
                memory_ratio = activity["avg_memory_usage"] / profile.typical_memory_usage
                if memory_ratio > 1.5:  # 50% more memory usage
                    anomalies.append(f"High memory usage: {activity['avg_memory_usage']:.2f}MB vs typical {profile.typical_memory_usage:.2f}MB")
                elif memory_ratio > 3.0:  # Potential memory leak or attack
                    anomalies.append(f"Critical memory usage: {activity['avg_memory_usage']:.2f}MB (potential memory attack)")
            
            # Warning count anomaly
            if activity.get("warning_count", 0) > 0:
                recent_warnings = [
                    a.get("warning_count", 0) for a in self.activity_buffers[profile.entity_id]
                    if (datetime.utcnow() - a["timestamp"]).hours <= 24
                ]
                
                if recent_warnings:
                    avg_warnings = np.mean(recent_warnings)
                    if activity["warning_count"] > avg_warnings * 3:
                        anomalies.append(f"High warning count: {activity['warning_count']} vs avg {avg_warnings:.1f}")
            
            # Log volume anomaly
            if activity.get("total_logs", 0) > 0:
                recent_log_counts = [
                    a.get("total_logs", 0) for a in self.activity_buffers[profile.entity_id]
                    if (datetime.utcnow() - a["timestamp"]).hours <= 1
                ]
                
                if len(recent_log_counts) > 5:
                    avg_logs = np.mean(recent_log_counts)
                    std_logs = np.std(recent_log_counts)
                    
                    if std_logs > 0:
                        z_score = abs(activity["total_logs"] - avg_logs) / std_logs
                        if z_score > 3.0:  # 3 standard deviations
                            anomalies.append(f"Unusual log volume: {activity['total_logs']} logs (z-score: {z_score:.2f})")
            
            # Behavioral pattern analysis
            await self._analyze_agent_behavioral_patterns(profile, activity, anomalies)
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting agent anomalies: {e}")
        
        return anomalies

    async def _analyze_agent_behavioral_patterns(self, profile: BehaviorProfile, activity: Dict[str, Any], anomalies: List[str]):
        """Analyze agent behavioral patterns for advanced anomaly detection"""
        try:
            # Get recent activities for pattern analysis
            recent_activities = [
                a for a in self.activity_buffers[profile.entity_id]
                if (datetime.utcnow() - a["timestamp"]).hours <= 24
            ]
            
            if len(recent_activities) < 5:
                return  # Not enough data for pattern analysis
            
            # Detect unusual activity patterns
            activity_intervals = []
            for i in range(1, len(recent_activities)):
                interval = (recent_activities[i]["timestamp"] - recent_activities[i-1]["timestamp"]).total_seconds()
                activity_intervals.append(interval)
            
            if activity_intervals:
                avg_interval = np.mean(activity_intervals)
                std_interval = np.std(activity_intervals)
                
                # Check for unusual timing patterns
                if std_interval > avg_interval * 2:  # High variance in timing
                    anomalies.append(f"Irregular activity timing pattern (high variance: {std_interval:.1f}s)")
                
                # Check for potential automated behavior
                if std_interval < avg_interval * 0.1 and len(activity_intervals) > 10:
                    anomalies.append(f"Highly regular timing pattern (potential automation: std={std_interval:.1f}s)")
            
            # Detect resource usage patterns
            memory_values = [a.get("avg_memory_usage", 0) for a in recent_activities if a.get("avg_memory_usage")]
            if len(memory_values) > 5:
                memory_trend = np.polyfit(range(len(memory_values)), memory_values, 1)[0]
                if memory_trend > 10:  # Memory increasing by >10MB per measurement
                    anomalies.append(f"Memory leak detected: increasing by {memory_trend:.1f}MB per cycle")
            
            # Detect error clustering
            error_times = [
                a["timestamp"] for a in recent_activities
                if a.get("error_rate", 0) > 0.1
            ]
            
            if len(error_times) > 3:
                # Check if errors are clustered in time
                error_intervals = [
                    (error_times[i] - error_times[i-1]).total_seconds()
                    for i in range(1, len(error_times))
                ]
                
                if error_intervals and np.mean(error_intervals) < 300:  # Errors within 5 minutes
                    anomalies.append(f"Error clustering detected: {len(error_times)} errors in short timespan")
            
        except Exception as e:
            self.logger.error(f"❌ Error analyzing agent behavioral patterns: {e}")

    async def _detect_system_anomalies(self, profile: BehaviorProfile, activity: Dict[str, Any]) -> List[str]:
        """Detect anomalies in system behavior"""
        anomalies = []
        
        try:
            metric_name = activity["metric_name"]
            current_value = activity["avg_value"]
            
            # Get historical data for this metric
            historical_activities = [
                a for a in self.activity_buffers["system"]
                if a.get("metric_name") == metric_name and
                (datetime.utcnow() - a["timestamp"]).hours <= 24
            ]
            
            if len(historical_activities) > 5:
                historical_values = [a["avg_value"] for a in historical_activities]
                historical_mean = np.mean(historical_values)
                historical_std = np.std(historical_values)
                
                if historical_std > 0:
                    z_score = abs(current_value - historical_mean) / historical_std
                    if z_score > 3.0:  # 3 standard deviations
                        anomalies.append(f"System metric anomaly: {metric_name} = {current_value:.2f} (z-score: {z_score:.2f})")
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting system anomalies: {e}")
        
        return anomalies

    async def _generate_security_alert(self, entity_id: str, entity_type: str, 
                                     alert_type: str, anomalies: List[str]):
        """Generate security alert for detected anomalies with advanced scoring"""
        try:
            # Advanced anomaly score calculation
            anomaly_score = await self._calculate_advanced_anomaly_score(entity_id, entity_type, anomalies)
            
            # Determine severity with context awareness
            severity = await self._determine_alert_severity(entity_id, entity_type, alert_type, anomaly_score, anomalies)
            
            # Calculate confidence based on historical data and pattern strength
            confidence = await self._calculate_alert_confidence(entity_id, entity_type, anomalies)
            
            # Create alert with enhanced context
            alert = SecurityAlert(
                alert_id=f"alert_{int(time.time())}_{entity_id}_{hash(str(anomalies)) % 10000}",
                entity_id=entity_id,
                entity_type=entity_type,
                alert_type=alert_type,
                severity=severity,
                title=f"Behavioral Anomaly Detected - {entity_type.title()}",
                description=f"Detected {len(anomalies)} behavioral anomalies for {entity_type} {entity_id}",
                anomaly_score=anomaly_score,
                confidence=confidence,
                indicators=anomalies,
                context=await self._build_alert_context(entity_id, entity_type, alert_type)
            )
            
            # Check for alert correlation and deduplication
            if not await self._should_suppress_alert(alert):
                # Store alert
                self.active_alerts[alert.alert_id] = alert
                self.alert_history.append(alert)
                
                # Log security event with enhanced details
                security_logger.log_suspicious_activity(
                    user_id=entity_id if entity_type == "user" else "system",
                    activity_type=alert_type,
                    details={
                        "entity_type": entity_type,
                        "anomalies": anomalies,
                        "severity": severity,
                        "confidence": confidence,
                        "anomaly_score": anomaly_score,
                        "context": alert.context
                    },
                    risk_score=anomaly_score
                )
                
                # Send alert notification
                await self._send_alert_notification(alert)
                
                # Check for alert correlation
                await self._correlate_alerts(alert)
                
                self.monitoring_stats["alerts_generated"] += 1
                self.monitoring_stats["anomalies_detected"] += len(anomalies)
                
                self.logger.warning(f"🚨 Security alert generated: {alert.title} (Severity: {severity}, Confidence: {confidence:.2f})")
            else:
                self.logger.debug(f"🔇 Alert suppressed due to correlation/deduplication: {alert_type} for {entity_id}")
            
        except Exception as e:
            self.logger.error(f"❌ Error generating security alert: {e}")

    async def _calculate_advanced_anomaly_score(self, entity_id: str, entity_type: str, anomalies: List[str]) -> float:
        """Calculate advanced anomaly score based on multiple factors"""
        try:
            base_score = min(len(anomalies) * 0.3, 1.0)
            
            # Weight based on anomaly types
            severity_weights = {
                "critical": 1.0,
                "potential": 0.8,
                "unusual": 0.6,
                "suspicious": 0.9,
                "high": 0.9,
                "memory": 0.7,
                "error": 0.8
            }
            
            weighted_score = 0.0
            for anomaly in anomalies:
                anomaly_lower = anomaly.lower()
                weight = 0.5  # Default weight
                
                for keyword, w in severity_weights.items():
                    if keyword in anomaly_lower:
                        weight = max(weight, w)
                        break
                
                weighted_score += weight
            
            # Normalize weighted score
            if anomalies:
                weighted_score = weighted_score / len(anomalies)
            
            # Historical context adjustment
            recent_alerts = [
                alert for alert in self.alert_history
                if (alert.entity_id == entity_id and 
                    (datetime.utcnow() - alert.detected_at).hours <= 24)
            ]
            
            if len(recent_alerts) > 2:  # Multiple recent alerts increase severity
                weighted_score *= 1.2
            
            return min(max(base_score, weighted_score), 1.0)
            
        except Exception as e:
            self.logger.error(f"❌ Error calculating advanced anomaly score: {e}")
            return min(len(anomalies) * 0.3, 1.0)

    async def _determine_alert_severity(self, entity_id: str, entity_type: str, alert_type: str, 
                                      anomaly_score: float, anomalies: List[str]) -> str:
        """Determine alert severity with context awareness"""
        try:
            # Base severity from anomaly score
            if anomaly_score > 0.8:
                base_severity = "critical"
            elif anomaly_score > 0.6:
                base_severity = "high"
            elif anomaly_score > 0.4:
                base_severity = "medium"
            else:
                base_severity = "low"
            
            # Adjust based on alert type
            critical_types = ["security_failed_login", "security_unauthorized_access", "coordinated_anomaly"]
            high_types = ["persistent_anomaly", "agent_behavior_anomaly"]
            
            if alert_type in critical_types:
                if base_severity in ["low", "medium"]:
                    base_severity = "high"
                elif base_severity == "high":
                    base_severity = "critical"
            elif alert_type in high_types and base_severity == "low":
                base_severity = "medium"
            
            # Adjust based on specific anomaly indicators
            critical_indicators = ["critical", "compromise", "attack", "breach"]
            high_indicators = ["suspicious", "potential", "unusual"]
            
            for anomaly in anomalies:
                anomaly_lower = anomaly.lower()
                if any(indicator in anomaly_lower for indicator in critical_indicators):
                    if base_severity != "critical":
                        base_severity = "high" if base_severity == "low" else "critical"
                elif any(indicator in anomaly_lower for indicator in high_indicators):
                    if base_severity == "low":
                        base_severity = "medium"
            
            # Historical context
            recent_high_alerts = [
                alert for alert in self.alert_history
                if (alert.entity_id == entity_id and 
                    alert.severity in ["high", "critical"] and
                    (datetime.utcnow() - alert.detected_at).hours <= 48)
            ]
            
            if len(recent_high_alerts) > 1 and base_severity in ["low", "medium"]:
                base_severity = "high"
            
            return base_severity
            
        except Exception as e:
            self.logger.error(f"❌ Error determining alert severity: {e}")
            return "medium"

    async def _calculate_alert_confidence(self, entity_id: str, entity_type: str, anomalies: List[str]) -> float:
        """Calculate alert confidence based on data quality and pattern strength"""
        try:
            base_confidence = 0.7
            
            # Adjust based on profile maturity
            profile_key = f"{entity_type}:{entity_id}"
            if profile_key in self.behavior_profiles:
                profile = self.behavior_profiles[profile_key]
                base_confidence = min(profile.confidence_score + 0.3, 0.95)
            
            # Adjust based on anomaly strength
            strong_indicators = ["critical", "5x", "10x", "z-score"]
            moderate_indicators = ["3x", "2x", "unusual", "high"]
            
            strong_count = sum(1 for anomaly in anomalies 
                             if any(indicator in anomaly.lower() for indicator in strong_indicators))
            moderate_count = sum(1 for anomaly in anomalies 
                               if any(indicator in anomaly.lower() for indicator in moderate_indicators))
            
            if strong_count > 0:
                base_confidence += 0.1 * strong_count
            if moderate_count > 0:
                base_confidence += 0.05 * moderate_count
            
            # Adjust based on data volume
            activity_count = len(self.activity_buffers.get(entity_id, []))
            if activity_count > 100:
                base_confidence += 0.1
            elif activity_count < 10:
                base_confidence -= 0.2
            
            return min(max(base_confidence, 0.3), 0.95)
            
        except Exception as e:
            self.logger.error(f"❌ Error calculating alert confidence: {e}")
            return 0.7

    async def _build_alert_context(self, entity_id: str, entity_type: str, alert_type: str) -> Dict[str, Any]:
        """Build comprehensive alert context"""
        try:
            context = {
                "entity_profile": {},
                "recent_activity": {},
                "historical_alerts": {},
                "risk_factors": []
            }
            
            # Entity profile information
            profile_key = f"{entity_type}:{entity_id}"
            if profile_key in self.behavior_profiles:
                profile = self.behavior_profiles[profile_key]
                context["entity_profile"] = {
                    "confidence_score": profile.confidence_score,
                    "sample_size": profile.sample_size,
                    "last_updated": profile.last_updated.isoformat(),
                    "typical_activity_hours": profile.typical_activity_hours
                }
            
            # Recent activity summary
            recent_activities = self.activity_buffers.get(entity_id, [])
            if recent_activities:
                context["recent_activity"] = {
                    "total_activities": len(recent_activities),
                    "activity_types": list(set(a.get("activity_type", "unknown") for a in recent_activities)),
                    "last_activity": recent_activities[-1]["timestamp"].isoformat() if recent_activities else None
                }
            
            # Historical alerts
            entity_alerts = [
                alert for alert in self.alert_history
                if alert.entity_id == entity_id
            ]
            
            if entity_alerts:
                context["historical_alerts"] = {
                    "total_alerts": len(entity_alerts),
                    "recent_alerts_24h": len([
                        a for a in entity_alerts
                        if (datetime.utcnow() - a.detected_at).hours <= 24
                    ]),
                    "severity_distribution": {
                        severity: len([a for a in entity_alerts if a.severity == severity])
                        for severity in ["low", "medium", "high", "critical"]
                    }
                }
            
            # Risk factors
            if len(entity_alerts) > 5:
                context["risk_factors"].append("High alert frequency")
            
            if entity_type == "user":
                # Check for user-specific risk factors
                recent_failed_logins = [
                    a for a in entity_alerts
                    if "failed_login" in a.alert_type and
                    (datetime.utcnow() - a.detected_at).hours <= 24
                ]
                if len(recent_failed_logins) > 2:
                    context["risk_factors"].append("Multiple failed login attempts")
            
            return context
            
        except Exception as e:
            self.logger.error(f"❌ Error building alert context: {e}")
            return {}

    async def _should_suppress_alert(self, alert: SecurityAlert) -> bool:
        """Determine if alert should be suppressed due to correlation or deduplication"""
        try:
            # Check for duplicate alerts in the last hour
            recent_similar_alerts = [
                a for a in self.active_alerts.values()
                if (a.entity_id == alert.entity_id and
                    a.alert_type == alert.alert_type and
                    (datetime.utcnow() - a.detected_at).seconds <= 3600)
            ]
            
            if len(recent_similar_alerts) > 2:  # More than 2 similar alerts in 1 hour
                return True
            
            # Check for low-confidence alerts when high-confidence alerts exist
            if alert.confidence < 0.6:
                high_confidence_alerts = [
                    a for a in self.active_alerts.values()
                    if (a.entity_id == alert.entity_id and
                        a.confidence > 0.8 and
                        (datetime.utcnow() - a.detected_at).seconds <= 1800)  # 30 minutes
                ]
                if high_confidence_alerts:
                    return True
            
            return False
            
        except Exception as e:
            self.logger.error(f"❌ Error checking alert suppression: {e}")
            return False

    async def _correlate_alerts(self, new_alert: SecurityAlert):
        """Correlate new alert with existing alerts to identify patterns"""
        try:
            # Look for related alerts across different entities
            related_alerts = []
            
            for alert in self.active_alerts.values():
                if (alert.alert_id != new_alert.alert_id and
                    (datetime.utcnow() - alert.detected_at).hours <= 2):
                    
                    # Check for correlation factors
                    correlation_score = 0.0
                    
                    # Same alert type
                    if alert.alert_type == new_alert.alert_type:
                        correlation_score += 0.4
                    
                    # Similar timing (within 30 minutes)
                    time_diff = abs((new_alert.detected_at - alert.detected_at).total_seconds())
                    if time_diff <= 1800:  # 30 minutes
                        correlation_score += 0.3
                    
                    # Similar anomaly indicators
                    common_indicators = set(alert.indicators) & set(new_alert.indicators)
                    if common_indicators:
                        correlation_score += 0.2 * len(common_indicators)
                    
                    # Same entity type
                    if alert.entity_type == new_alert.entity_type:
                        correlation_score += 0.1
                    
                    if correlation_score >= 0.5:  # Significant correlation
                        related_alerts.append((alert, correlation_score))
            
            # Generate correlation alert if significant pattern detected
            if len(related_alerts) >= 2:
                await self._generate_correlation_alert(new_alert, related_alerts)
            
        except Exception as e:
            self.logger.error(f"❌ Error correlating alerts: {e}")

    async def _generate_correlation_alert(self, trigger_alert: SecurityAlert, related_alerts: List[Tuple[SecurityAlert, float]]):
        """Generate correlation alert for related security events"""
        try:
            correlation_alert = SecurityAlert(
                alert_id=f"correlation_{int(time.time())}_{trigger_alert.entity_id}",
                entity_id="multiple",
                entity_type="correlation",
                alert_type="correlated_security_events",
                severity="high",
                title="Correlated Security Events Detected",
                description=f"Detected {len(related_alerts) + 1} correlated security events",
                anomaly_score=0.9,
                confidence=0.85,
                context={
                    "trigger_alert": trigger_alert.alert_id,
                    "related_alerts": [alert.alert_id for alert, _ in related_alerts],
                    "correlation_scores": [score for _, score in related_alerts],
                    "affected_entities": list(set([trigger_alert.entity_id] + [alert.entity_id for alert, _ in related_alerts])),
                    "time_window": "2 hours"
                }
            )
            
            self.active_alerts[correlation_alert.alert_id] = correlation_alert
            await self._send_alert_notification(correlation_alert)
            
            self.logger.warning(f"🔗 Correlation alert generated: {len(related_alerts) + 1} related events")
            
        except Exception as e:
            self.logger.error(f"❌ Error generating correlation alert: {e}")

    async def _send_alert_notification(self, alert: SecurityAlert):
        """Send alert notification to relevant parties"""
        try:
            # Send to agent manager
            await self.send_message(
                recipient="agent_manager",
                message_type="security_alert",
                payload={
                    "alert_id": alert.alert_id,
                    "entity_id": alert.entity_id,
                    "entity_type": alert.entity_type,
                    "severity": alert.severity,
                    "title": alert.title,
                    "description": alert.description,
                    "anomaly_score": alert.anomaly_score,
                    "indicators": alert.indicators
                },
                priority=3 if alert.severity in ["high", "critical"] else 2
            )
            
            # Store in Redis for real-time access
            await self.redis_client.setex(
                f"alert:{alert.alert_id}",
                3600,  # 1 hour TTL
                json.dumps({
                    "alert_id": alert.alert_id,
                    "entity_id": alert.entity_id,
                    "entity_type": alert.entity_type,
                    "severity": alert.severity,
                    "title": alert.title,
                    "description": alert.description,
                    "detected_at": alert.detected_at.isoformat(),
                    "indicators": alert.indicators
                })
            )
            
            # Trigger automated response for high-severity alerts
            if alert.severity in ["high", "critical"]:
                await self._trigger_automated_response(alert)
            
        except Exception as e:
            self.logger.error(f"❌ Error sending alert notification: {e}")

    async def _log_agent_activity(self, entity_id: str, entity_type: str, 
                                activity_type: str, details: Dict[str, Any]):
        """Log agent activity for behavioral analysis"""
        try:
            # Store in database
            async with get_async_session() as session:
                agent_log = AgentLog(
                    agent_name=entity_id if entity_type == "agent" else "ueba_agent",
                    agent_version="1.0.0",
                    log_level="INFO",
                    message=f"Activity logged: {activity_type}",
                    context={
                        "entity_id": entity_id,
                        "entity_type": entity_type,
                        "activity_type": activity_type,
                        "details": details
                    },
                    user_id=entity_id if entity_type == "user" else None
                )
                
                session.add(agent_log)
                await session.commit()
            
            # Store in Redis for real-time access
            activity_data = {
                "entity_id": entity_id,
                "entity_type": entity_type,
                "activity_type": activity_type,
                "details": details,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            await self.redis_client.lpush(
                f"activity:{entity_type}:{entity_id}",
                json.dumps(activity_data)
            )
            
            # Keep only recent activities (last 100)
            await self.redis_client.ltrim(f"activity:{entity_type}:{entity_id}", 0, 99)
            
        except Exception as e:
            self.logger.error(f"❌ Error logging agent activity: {e}")

    async def _profile_update_loop(self):
        """Update behavior profiles periodically"""
        while self.is_running:
            try:
                if (datetime.utcnow() - self.last_profile_update).seconds >= self.profile_update_interval:
                    await self._update_behavior_profiles()
                    self.last_profile_update = datetime.utcnow()
                
                await asyncio.sleep(300)  # Check every 5 minutes
                
            except Exception as e:
                self.logger.error(f"❌ Error in profile update loop: {e}")
                await asyncio.sleep(600)  # Wait 10 minutes before retrying

    async def _update_behavior_profiles(self):
        """Update behavior profiles based on recent activity"""
        try:
            for profile_key, profile in self.behavior_profiles.items():
                entity_activities = self.activity_buffers.get(profile.entity_id, [])
                
                if len(entity_activities) >= 10:  # Minimum sample size
                    await self._update_profile_from_activities(profile, entity_activities)
                    
                    # Cache updated profile in Redis
                    profile_data = {
                        "entity_id": profile.entity_id,
                        "entity_type": profile.entity_type,
                        "typical_activity_hours": profile.typical_activity_hours,
                        "average_session_duration": profile.average_session_duration,
                        "typical_actions_per_session": profile.typical_actions_per_session,
                        "typical_processing_time": profile.typical_processing_time,
                        "typical_error_rate": profile.typical_error_rate,
                        "sample_size": profile.sample_size,
                        "confidence_score": profile.confidence_score,
                        "last_updated": profile.last_updated.isoformat()
                    }
                    
                    await self.redis_client.setex(
                        f"profile:{profile_key}",
                        86400,  # 24 hours TTL
                        json.dumps(profile_data)
                    )
                    
                    self.monitoring_stats["profiles_updated"] += 1
            
            self.logger.info(f"📊 Updated {len(self.behavior_profiles)} behavior profiles")
            
        except Exception as e:
            self.logger.error(f"❌ Error updating behavior profiles: {e}")

    async def _update_profile_from_activities(self, profile: BehaviorProfile, activities: List[Dict[str, Any]]):
        """Update behavior profile based on activity data"""
        try:
            # Update activity hours
            activity_hours = [a["timestamp"].hour for a in activities if "timestamp" in a]
            if activity_hours:
                profile.typical_activity_hours = list(set(activity_hours))
            
            # Update session durations (for users)
            if profile.entity_type == "user":
                durations = [a.get("duration", 0) for a in activities if a.get("duration")]
                if durations:
                    profile.average_session_duration = np.mean(durations)
                
                message_counts = [a.get("message_count", 0) for a in activities if a.get("message_count")]
                if message_counts:
                    profile.typical_actions_per_session = np.mean(message_counts)
            
            # Update agent-specific metrics
            elif profile.entity_type == "agent":
                error_rates = [a.get("error_rate", 0) for a in activities if "error_rate" in a]
                if error_rates:
                    profile.typical_error_rate = np.mean(error_rates)
                
                processing_times = [a.get("avg_execution_time", 0) for a in activities if a.get("avg_execution_time")]
                if processing_times:
                    profile.typical_processing_time = np.mean(processing_times)
                
                memory_usage = [a.get("avg_memory_usage", 0) for a in activities if a.get("avg_memory_usage")]
                if memory_usage:
                    profile.typical_memory_usage = np.mean(memory_usage)
            
            # Update metadata
            profile.sample_size = len(activities)
            profile.confidence_score = min(profile.sample_size / 100.0, 1.0)  # Max confidence at 100 samples
            profile.last_updated = datetime.utcnow()
            
        except Exception as e:
            self.logger.error(f"❌ Error updating profile from activities: {e}")

    async def _load_behavior_profiles(self):
        """Load existing behavior profiles from storage"""
        try:
            # Load from Redis cache
            profile_keys = await self.redis_client.keys("profile:*")
            
            for key in profile_keys:
                try:
                    profile_data = await self.redis_client.get(key)
                    if profile_data:
                        data = json.loads(profile_data)
                        
                        profile = BehaviorProfile(
                            entity_id=data["entity_id"],
                            entity_type=data["entity_type"]
                        )
                        
                        # Update profile with cached data
                        for field, value in data.items():
                            if hasattr(profile, field) and field not in ["entity_id", "entity_type"]:
                                setattr(profile, field, value)
                        
                        profile_key = f"{data['entity_type']}:{data['entity_id']}"
                        self.behavior_profiles[profile_key] = profile
                        
                except Exception as e:
                    self.logger.debug(f"Could not load profile {key}: {e}")
            
            self.logger.info(f"📊 Loaded {len(self.behavior_profiles)} behavior profiles")
            
        except Exception as e:
            self.logger.error(f"❌ Error loading behavior profiles: {e}")

    async def _alert_processing_loop(self):
        """Process and manage security alerts"""
        while self.is_running:
            try:
                # Clean up old resolved alerts
                current_time = datetime.utcnow()
                alerts_to_remove = []
                
                for alert_id, alert in self.active_alerts.items():
                    # Remove resolved alerts older than 24 hours
                    if (alert.status in ["resolved", "false_positive"] and 
                        (current_time - alert.detected_at).hours >= 24):
                        alerts_to_remove.append(alert_id)
                
                for alert_id in alerts_to_remove:
                    del self.active_alerts[alert_id]
                
                # Process escalation for high-severity alerts
                for alert in self.active_alerts.values():
                    if (alert.severity in ["high", "critical"] and 
                        alert.status == "new" and
                        (current_time - alert.detected_at).minutes >= 15):
                        await self._escalate_alert(alert)
                
                await asyncio.sleep(300)  # Check every 5 minutes
                
            except Exception as e:
                self.logger.error(f"❌ Error in alert processing loop: {e}")
                await asyncio.sleep(600)

    async def _escalate_alert(self, alert: SecurityAlert):
        """Escalate high-severity alerts"""
        try:
            # Update alert status
            alert.status = "escalated"
            
            # Send escalation notification
            await self.send_message(
                recipient="agent_manager",
                message_type="alert_escalation",
                payload={
                    "alert_id": alert.alert_id,
                    "entity_id": alert.entity_id,
                    "severity": alert.severity,
                    "title": alert.title,
                    "escalation_reason": "High severity alert not acknowledged within 15 minutes"
                },
                priority=4  # Critical priority
            )
            
            self.logger.warning(f"🚨 Alert escalated: {alert.alert_id}")
            
        except Exception as e:
            self.logger.error(f"❌ Error escalating alert: {e}")

    async def _process_behavioral_anomalies(self):
        """Process detected behavioral anomalies"""
        try:
            # Check for patterns across multiple entities
            await self._detect_coordinated_anomalies()
            
            # Check for persistent anomalies
            await self._detect_persistent_anomalies()
            
            # Update threat intelligence
            await self._update_threat_intelligence()
            
        except Exception as e:
            self.logger.error(f"❌ Error processing behavioral anomalies: {e}")

    async def _detect_coordinated_anomalies(self):
        """Detect coordinated anomalies across multiple entities"""
        try:
            # Look for similar anomalies across different users/agents
            recent_alerts = [
                alert for alert in self.alert_history
                if (datetime.utcnow() - alert.detected_at).hours <= 1
            ]
            
            # Group alerts by type
            alerts_by_type = defaultdict(list)
            for alert in recent_alerts:
                alerts_by_type[alert.alert_type].append(alert)
            
            # Check for coordinated patterns
            for alert_type, alerts in alerts_by_type.items():
                if len(alerts) >= 3:  # 3 or more similar alerts in 1 hour
                    await self._generate_coordinated_alert(alert_type, alerts)
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting coordinated anomalies: {e}")

    async def _generate_coordinated_alert(self, alert_type: str, alerts: List[SecurityAlert]):
        """Generate alert for coordinated anomalous behavior"""
        try:
            coordinated_alert = SecurityAlert(
                alert_id=f"coordinated_{int(time.time())}",
                entity_id="multiple",
                entity_type="coordinated",
                alert_type=f"coordinated_{alert_type}",
                severity="high",
                title="Coordinated Anomalous Behavior Detected",
                description=f"Detected {len(alerts)} similar {alert_type} alerts across multiple entities",
                anomaly_score=0.9,
                confidence=0.85,
                context={
                    "affected_entities": [alert.entity_id for alert in alerts],
                    "alert_count": len(alerts),
                    "time_window": "1 hour"
                }
            )
            
            self.active_alerts[coordinated_alert.alert_id] = coordinated_alert
            await self._send_alert_notification(coordinated_alert)
            
            self.logger.warning(f"🚨 Coordinated anomaly detected: {alert_type} ({len(alerts)} entities)")
            
        except Exception as e:
            self.logger.error(f"❌ Error generating coordinated alert: {e}")

    async def _detect_persistent_anomalies(self):
        """Detect persistent anomalous behavior"""
        try:
            # Check for entities with multiple alerts over time
            entity_alert_counts = defaultdict(int)
            
            for alert in self.alert_history:
                if (datetime.utcnow() - alert.detected_at).days <= 7:  # Last 7 days
                    entity_alert_counts[alert.entity_id] += 1
            
            # Generate persistent anomaly alerts
            for entity_id, alert_count in entity_alert_counts.items():
                if alert_count >= 5:  # 5 or more alerts in 7 days
                    await self._generate_persistent_anomaly_alert(entity_id, alert_count)
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting persistent anomalies: {e}")

    async def _generate_persistent_anomaly_alert(self, entity_id: str, alert_count: int):
        """Generate alert for persistent anomalous behavior"""
        try:
            # Check if we already have a persistent anomaly alert for this entity
            existing_alert = None
            for alert in self.active_alerts.values():
                if (alert.entity_id == entity_id and 
                    alert.alert_type == "persistent_anomaly" and
                    alert.status == "new"):
                    existing_alert = alert
                    break
            
            if not existing_alert:
                persistent_alert = SecurityAlert(
                    alert_id=f"persistent_{int(time.time())}_{entity_id}",
                    entity_id=entity_id,
                    entity_type="user",  # Assume user for now
                    alert_type="persistent_anomaly",
                    severity="high",
                    title="Persistent Anomalous Behavior",
                    description=f"Entity {entity_id} has generated {alert_count} alerts in the last 7 days",
                    anomaly_score=0.85,
                    confidence=0.9,
                    context={
                        "alert_count": alert_count,
                        "time_window": "7 days"
                    }
                )
                
                self.active_alerts[persistent_alert.alert_id] = persistent_alert
                await self._send_alert_notification(persistent_alert)
                
                self.logger.warning(f"🚨 Persistent anomaly detected for entity: {entity_id} ({alert_count} alerts)")
            
        except Exception as e:
            self.logger.error(f"❌ Error generating persistent anomaly alert: {e}")

    async def _update_threat_intelligence(self):
        """Update threat intelligence based on detected patterns"""
        try:
            # Analyze recent alerts for threat patterns
            recent_alerts = [
                alert for alert in self.alert_history
                if (datetime.utcnow() - alert.detected_at).days <= 1
            ]
            
            # Update threat indicators
            threat_indicators = {
                "high_risk_entities": [],
                "common_attack_patterns": [],
                "threat_trends": {}
            }
            
            # Identify high-risk entities
            entity_risk_scores = defaultdict(float)
            for alert in recent_alerts:
                entity_risk_scores[alert.entity_id] += alert.anomaly_score
            
            for entity_id, risk_score in entity_risk_scores.items():
                if risk_score > 2.0:  # High cumulative risk
                    threat_indicators["high_risk_entities"].append({
                        "entity_id": entity_id,
                        "risk_score": risk_score
                    })
            
            # Store threat intelligence in Redis
            await self.redis_client.setex(
                "threat_intelligence",
                3600,  # 1 hour TTL
                json.dumps(threat_indicators)
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error updating threat intelligence: {e}")

    # Message handlers
    async def _handle_security_event(self, payload: Dict[str, Any]) -> Optional[AgentMessage]:
        """Handle security event messages"""
        try:
            event_type = payload.get("event_type")
            entity_id = payload.get("entity_id")
            details = payload.get("details", {})
            
            # Log the security event
            await self._log_agent_activity(
                entity_id=entity_id,
                entity_type="security_event",
                activity_type=event_type,
                details=details
            )
            
            # Analyze for immediate threats
            if event_type in ["failed_login", "unauthorized_access", "data_breach"]:
                await self._generate_security_alert(
                    entity_id=entity_id,
                    entity_type="user",
                    alert_type=f"security_{event_type}",
                    anomalies=[f"Security event detected: {event_type}"]
                )
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Error handling security event: {e}")
            return None

    async def _handle_user_activity(self, payload: Dict[str, Any]) -> Optional[AgentMessage]:
        """Handle user activity messages"""
        try:
            user_id = payload.get("user_id")
            activity_type = payload.get("activity_type")
            details = payload.get("details", {})
            
            # Log user activity
            await self._log_agent_activity(
                entity_id=user_id,
                entity_type="user",
                activity_type=activity_type,
                details=details
            )
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Error handling user activity: {e}")
            return None

    async def _handle_agent_health(self, payload: Dict[str, Any]) -> Optional[AgentMessage]:
        """Handle agent health messages"""
        try:
            agent_name = payload.get("agent_name")
            health_data = payload.get("health_data", {})
            
            # Log agent health
            await self._log_agent_activity(
                entity_id=agent_name,
                entity_type="agent",
                activity_type="health_report",
                details=health_data
            )
            
            # Check for health anomalies
            if not health_data.get("healthy", True):
                await self._generate_security_alert(
                    entity_id=agent_name,
                    entity_type="agent",
                    alert_type="agent_health_issue",
                    anomalies=[f"Agent health issue: {health_data.get('error', 'Unknown error')}"]
                )
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Error handling agent health: {e}")
            return None

    async def _handle_anomaly_report(self, payload: Dict[str, Any]) -> Optional[AgentMessage]:
        """Handle anomaly report messages"""
        try:
            entity_id = payload.get("entity_id")
            entity_type = payload.get("entity_type", "unknown")
            anomalies = payload.get("anomalies", [])
            
            if anomalies:
                await self._generate_security_alert(
                    entity_id=entity_id,
                    entity_type=entity_type,
                    alert_type="reported_anomaly",
                    anomalies=anomalies
                )
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Error handling anomaly report: {e}")
            return None

    async def _handle_security_status_request(self, payload: Dict[str, Any]) -> Optional[AgentMessage]:
        """Handle security status request"""
        try:
            # Prepare security status response
            status = {
                "active_alerts": len(self.active_alerts),
                "entities_monitored": len(self.behavior_profiles),
                "recent_anomalies": len([
                    alert for alert in self.alert_history
                    if (datetime.utcnow() - alert.detected_at).hours <= 24
                ]),
                "high_severity_alerts": len([
                    alert for alert in self.active_alerts.values()
                    if alert.severity in ["high", "critical"]
                ]),
                "monitoring_stats": self.monitoring_stats,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=payload.get("requester", "unknown"),
                message_type="security_status_response",
                payload=status
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error handling security status request: {e}")
            return None

    async def get_security_dashboard_data(self) -> Dict[str, Any]:
        """Get security dashboard data"""
        try:
            current_time = datetime.utcnow()
            
            # Active alerts by severity
            alerts_by_severity = defaultdict(int)
            for alert in self.active_alerts.values():
                alerts_by_severity[alert.severity] += 1
            
            # Recent activity trends
            recent_activities = []
            for entity_id, activities in self.activity_buffers.items():
                recent_activities.extend([
                    a for a in activities
                    if (current_time - a["timestamp"]).hours <= 24
                ])
            
            # Top risk entities
            entity_risk_scores = defaultdict(float)
            for alert in self.alert_history:
                if (current_time - alert.detected_at).days <= 7:
                    entity_risk_scores[alert.entity_id] += alert.anomaly_score
            
            top_risk_entities = sorted(
                entity_risk_scores.items(),
                key=lambda x: x[1],
                reverse=True
            )[:10]
            
            dashboard_data = {
                "summary": {
                    "total_entities_monitored": len(self.behavior_profiles),
                    "active_alerts": len(self.active_alerts),
                    "alerts_last_24h": len([
                        alert for alert in self.alert_history
                        if (current_time - alert.detected_at).hours <= 24
                    ]),
                    "high_risk_entities": len([
                        score for _, score in entity_risk_scores.items()
                        if score > 2.0
                    ])
                },
                "alerts_by_severity": dict(alerts_by_severity),
                "recent_activity_count": len(recent_activities),
                "top_risk_entities": [
                    {"entity_id": entity_id, "risk_score": score}
                    for entity_id, score in top_risk_entities
                ],
                "monitoring_stats": self.monitoring_stats,
                "timestamp": current_time.isoformat()
            }
            
            return dashboard_data
            
        except Exception as e:
            self.logger.error(f"❌ Error getting security dashboard data: {e}")
            return {"error": str(e)}

    async def resolve_alert(self, alert_id: str, resolution_notes: str = None) -> bool:
        """Resolve a security alert"""
        try:
            if alert_id in self.active_alerts:
                alert = self.active_alerts[alert_id]
                alert.status = "resolved"
                alert.resolution_notes = resolution_notes
                
                # Log resolution
                audit_logger.log_system_event(
                    event_type="alert_resolved",
                    details={
                        "alert_id": alert_id,
                        "entity_id": alert.entity_id,
                        "resolution_notes": resolution_notes
                    }
                )
                
                self.logger.info(f"✅ Alert resolved: {alert_id}")
                return True
            
            return False
            
        except Exception as e:
            self.logger.error(f"❌ Error resolving alert: {e}")
            return False

    async def _trigger_automated_response(self, alert: SecurityAlert):
        """Trigger automated response and mitigation for high-severity alerts"""
        try:
            response_actions = []
            
            # Determine response actions based on alert type and severity
            if alert.alert_type in ["security_failed_login", "security_unauthorized_access"]:
                response_actions.extend([
                    "rate_limit_entity",
                    "require_additional_auth",
                    "notify_security_team"
                ])
            
            elif alert.alert_type in ["agent_behavior_anomaly", "agent_health_issue"]:
                response_actions.extend([
                    "isolate_agent",
                    "restart_agent_service",
                    "escalate_to_admin"
                ])
            
            elif alert.alert_type in ["coordinated_anomaly", "persistent_anomaly"]:
                response_actions.extend([
                    "block_entity_temporarily",
                    "increase_monitoring",
                    "alert_security_team"
                ])
            
            elif alert.alert_type == "system_behavior_anomaly":
                response_actions.extend([
                    "scale_resources",
                    "check_system_health",
                    "alert_operations_team"
                ])
            
            # Execute response actions
            for action in response_actions:
                await self._execute_response_action(alert, action)
            
            # Log automated response
            audit_logger.log_system_event(
                event_type="automated_response_triggered",
                details={
                    "alert_id": alert.alert_id,
                    "entity_id": alert.entity_id,
                    "severity": alert.severity,
                    "actions_taken": response_actions
                }
            )
            
            self.logger.info(f"🤖 Automated response triggered for alert {alert.alert_id}: {response_actions}")
            
        except Exception as e:
            self.logger.error(f"❌ Error triggering automated response: {e}")

    async def _execute_response_action(self, alert: SecurityAlert, action: str):
        """Execute specific response action"""
        try:
            if action == "rate_limit_entity":
                await self._apply_rate_limiting(alert.entity_id, alert.entity_type)
            
            elif action == "require_additional_auth":
                await self._require_additional_authentication(alert.entity_id)
            
            elif action == "isolate_agent":
                await self._isolate_agent(alert.entity_id)
            
            elif action == "restart_agent_service":
                await self._restart_agent_service(alert.entity_id)
            
            elif action == "block_entity_temporarily":
                await self._temporary_block_entity(alert.entity_id, alert.entity_type)
            
            elif action == "increase_monitoring":
                await self._increase_monitoring_level(alert.entity_id, alert.entity_type)
            
            elif action == "scale_resources":
                await self._trigger_resource_scaling()
            
            elif action == "check_system_health":
                await self._trigger_system_health_check()
            
            elif action in ["notify_security_team", "alert_security_team", "escalate_to_admin", "alert_operations_team"]:
                await self._send_team_notification(action, alert)
            
            self.logger.info(f"✅ Executed response action: {action} for alert {alert.alert_id}")
            
        except Exception as e:
            self.logger.error(f"❌ Error executing response action {action}: {e}")

    async def _apply_rate_limiting(self, entity_id: str, entity_type: str):
        """Apply rate limiting to an entity"""
        try:
            # Set rate limiting in Redis
            rate_limit_key = f"rate_limit:{entity_type}:{entity_id}"
            await self.redis_client.setex(rate_limit_key, 3600, "limited")  # 1 hour limit
            
            # Notify API gateway about rate limiting
            await self.send_message(
                recipient="api_gateway",
                message_type="apply_rate_limit",
                payload={
                    "entity_id": entity_id,
                    "entity_type": entity_type,
                    "duration": 3600,
                    "reason": "security_anomaly_detected"
                }
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error applying rate limiting: {e}")

    async def _require_additional_authentication(self, entity_id: str):
        """Require additional authentication for user"""
        try:
            # Set additional auth requirement in Redis
            auth_key = f"require_2fa:{entity_id}"
            await self.redis_client.setex(auth_key, 86400, "required")  # 24 hours
            
            # Notify authentication service
            await self.send_message(
                recipient="auth_service",
                message_type="require_additional_auth",
                payload={
                    "user_id": entity_id,
                    "reason": "security_anomaly_detected",
                    "duration": 86400
                }
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error requiring additional authentication: {e}")

    async def _isolate_agent(self, agent_name: str):
        """Isolate a misbehaving agent"""
        try:
            # Set isolation flag in Redis
            isolation_key = f"agent_isolated:{agent_name}"
            await self.redis_client.setex(isolation_key, 1800, "isolated")  # 30 minutes
            
            # Notify agent manager to isolate the agent
            await self.send_message(
                recipient="agent_manager",
                message_type="isolate_agent",
                payload={
                    "agent_name": agent_name,
                    "reason": "behavioral_anomaly_detected",
                    "duration": 1800
                }
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error isolating agent: {e}")

    async def _restart_agent_service(self, agent_name: str):
        """Request agent service restart"""
        try:
            # Notify agent manager to restart the agent
            await self.send_message(
                recipient="agent_manager",
                message_type="restart_agent",
                payload={
                    "agent_name": agent_name,
                    "reason": "health_issue_detected"
                }
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error requesting agent restart: {e}")

    async def _temporary_block_entity(self, entity_id: str, entity_type: str):
        """Temporarily block an entity"""
        try:
            # Set temporary block in Redis
            block_key = f"temp_block:{entity_type}:{entity_id}"
            await self.redis_client.setex(block_key, 7200, "blocked")  # 2 hours
            
            # Notify relevant services
            if entity_type == "user":
                await self.send_message(
                    recipient="auth_service",
                    message_type="temporary_block_user",
                    payload={
                        "user_id": entity_id,
                        "duration": 7200,
                        "reason": "persistent_anomalous_behavior"
                    }
                )
            
        except Exception as e:
            self.logger.error(f"❌ Error temporarily blocking entity: {e}")

    async def _increase_monitoring_level(self, entity_id: str, entity_type: str):
        """Increase monitoring level for an entity"""
        try:
            # Set enhanced monitoring flag
            monitoring_key = f"enhanced_monitoring:{entity_type}:{entity_id}"
            await self.redis_client.setex(monitoring_key, 86400, "enhanced")  # 24 hours
            
            # Update monitoring configuration
            if entity_id in self.behavior_profiles:
                profile = self.behavior_profiles[entity_id]
                # Reduce anomaly thresholds for more sensitive detection
                profile.activity_anomaly_threshold *= 0.7
                profile.location_anomaly_threshold *= 0.7
                profile.api_anomaly_threshold *= 0.7
            
        except Exception as e:
            self.logger.error(f"❌ Error increasing monitoring level: {e}")

    async def _trigger_resource_scaling(self):
        """Trigger system resource scaling"""
        try:
            # Notify infrastructure management
            await self.send_message(
                recipient="infrastructure_manager",
                message_type="scale_resources",
                payload={
                    "reason": "system_anomaly_detected",
                    "scale_factor": 1.5,
                    "duration": 3600
                }
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error triggering resource scaling: {e}")

    async def _trigger_system_health_check(self):
        """Trigger comprehensive system health check"""
        try:
            # Request health check from all agents
            await self.send_message(
                recipient="agent_manager",
                message_type="comprehensive_health_check",
                payload={
                    "reason": "system_anomaly_detected",
                    "priority": "high"
                }
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error triggering system health check: {e}")

    async def _send_team_notification(self, notification_type: str, alert: SecurityAlert):
        """Send notification to relevant team"""
        try:
            # Determine notification channel based on type
            channels = {
                "notify_security_team": ["security_team", "slack_security"],
                "alert_security_team": ["security_team", "email_security", "sms_security"],
                "escalate_to_admin": ["admin_team", "email_admin"],
                "alert_operations_team": ["ops_team", "slack_ops"]
            }
            
            notification_channels = channels.get(notification_type, ["default"])
            
            for channel in notification_channels:
                await self.send_message(
                    recipient="notification_service",
                    message_type="send_notification",
                    payload={
                        "channel": channel,
                        "alert_id": alert.alert_id,
                        "entity_id": alert.entity_id,
                        "severity": alert.severity,
                        "title": alert.title,
                        "description": alert.description,
                        "indicators": alert.indicators,
                        "timestamp": alert.detected_at.isoformat()
                    },
                    priority=4 if alert.severity == "critical" else 3
                )
            
        except Exception as e:
            self.logger.error(f"❌ Error sending team notification: {e}")

    async def get_active_mitigations(self) -> Dict[str, Any]:
        """Get currently active security mitigations"""
        try:
            mitigations = {
                "rate_limited_entities": [],
                "blocked_entities": [],
                "isolated_agents": [],
                "enhanced_monitoring": [],
                "additional_auth_required": []
            }
            
            # Check Redis for active mitigations
            rate_limit_keys = await self.redis_client.keys("rate_limit:*")
            for key in rate_limit_keys:
                entity_info = key.split(":")
                if len(entity_info) >= 3:
                    mitigations["rate_limited_entities"].append({
                        "entity_type": entity_info[1],
                        "entity_id": entity_info[2],
                        "ttl": await self.redis_client.ttl(key)
                    })
            
            block_keys = await self.redis_client.keys("temp_block:*")
            for key in block_keys:
                entity_info = key.split(":")
                if len(entity_info) >= 3:
                    mitigations["blocked_entities"].append({
                        "entity_type": entity_info[1],
                        "entity_id": entity_info[2],
                        "ttl": await self.redis_client.ttl(key)
                    })
            
            isolation_keys = await self.redis_client.keys("agent_isolated:*")
            for key in isolation_keys:
                agent_name = key.split(":", 1)[1]
                mitigations["isolated_agents"].append({
                    "agent_name": agent_name,
                    "ttl": await self.redis_client.ttl(key)
                })
            
            monitoring_keys = await self.redis_client.keys("enhanced_monitoring:*")
            for key in monitoring_keys:
                entity_info = key.split(":")
                if len(entity_info) >= 3:
                    mitigations["enhanced_monitoring"].append({
                        "entity_type": entity_info[1],
                        "entity_id": entity_info[2],
                        "ttl": await self.redis_client.ttl(key)
                    })
            
            auth_keys = await self.redis_client.keys("require_2fa:*")
            for key in auth_keys:
                user_id = key.split(":", 1)[1]
                mitigations["additional_auth_required"].append({
                    "user_id": user_id,
                    "ttl": await self.redis_client.ttl(key)
                })
            
            return mitigations
            
        except Exception as e:
            self.logger.error(f"❌ Error getting active mitigations: {e}")
            return {"error": str(e)}

    async def remove_mitigation(self, mitigation_type: str, entity_id: str) -> bool:
        """Remove a specific mitigation"""
        try:
            key_patterns = {
                "rate_limit": f"rate_limit:*:{entity_id}",
                "temp_block": f"temp_block:*:{entity_id}",
                "agent_isolation": f"agent_isolated:{entity_id}",
                "enhanced_monitoring": f"enhanced_monitoring:*:{entity_id}",
                "additional_auth": f"require_2fa:{entity_id}"
            }
            
            pattern = key_patterns.get(mitigation_type)
            if not pattern:
                return False
            
            keys = await self.redis_client.keys(pattern)
            if keys:
                await self.redis_client.delete(*keys)
                
                # Log mitigation removal
                audit_logger.log_system_event(
                    event_type="mitigation_removed",
                    details={
                        "mitigation_type": mitigation_type,
                        "entity_id": entity_id,
                        "removed_keys": keys
                    }
                )
                
                self.logger.info(f"✅ Removed {mitigation_type} mitigation for {entity_id}")
                return True
            
            return False
            
        except Exception as e:
            self.logger.error(f"❌ Error removing mitigation: {e}")
            return False

    async def _cleanup(self):
        """Cleanup UEBA agent resources"""
        try:
            # Close Redis connection
            if self.redis_client:
                await self.redis_client.close()
            
            # Save behavior profiles to persistent storage if needed
            # This could be implemented to save to database
            
            self.logger.info("🧹 UEBA Agent cleanup completed")
            
        except Exception as e:
            self.logger.error(f"❌ Error during UEBA cleanup: {e}")