"""
AIVONITY Feedback Agent
Advanced root cause analysis and maintenance event tracking
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple
import numpy as np
import pandas as pd
from collections import defaultdict, Counter
from dataclasses import dataclass
import json
import uuid

from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func, desc
from app.agents.base_agent import BaseAgent, AgentMessage
from app.db.database import get_db
from app.db.models import (
    Vehicle, TelemetryData, MaintenancePrediction, ServiceBooking,
    User, ServiceCenter, AgentLog
)
from app.utils.logging_config import get_logger

@dataclass
class MaintenanceEvent:
    """Structured maintenance event data"""
    id: str
    vehicle_id: str
    event_type: str  # failure, repair, service, inspection
    component: str
    timestamp: datetime
    description: str
    cost: Optional[float] = None
    duration_hours: Optional[float] = None
    service_center_id: Optional[str] = None
    technician_notes: Optional[str] = None
    parts_replaced: Optional[List[str]] = None
    root_cause: Optional[str] = None
    severity: str = "medium"  # low, medium, high, critical
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "vehicle_id": self.vehicle_id,
            "event_type": self.event_type,
            "component": self.component,
            "timestamp": self.timestamp.isoformat(),
            "description": self.description,
            "cost": self.cost,
            "duration_hours": self.duration_hours,
            "service_center_id": self.service_center_id,
            "technician_notes": self.technician_notes,
            "parts_replaced": self.parts_replaced or [],
            "root_cause": self.root_cause,
            "severity": self.severity
        }

@dataclass
class FailurePattern:
    """Identified failure pattern"""
    pattern_id: str
    component: str
    failure_mode: str
    frequency: int
    vehicles_affected: List[str]
    average_mileage_at_failure: float
    average_age_at_failure: float
    common_conditions: Dict[str, Any]
    confidence_score: float
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "pattern_id": self.pattern_id,
            "component": self.component,
            "failure_mode": self.failure_mode,
            "frequency": self.frequency,
            "vehicles_affected": self.vehicles_affected,
            "average_mileage_at_failure": self.average_mileage_at_failure,
            "average_age_at_failure": self.average_age_at_failure,
            "common_conditions": self.common_conditions,
            "confidence_score": self.confidence_score
        }

@dataclass
class RCAReport:
    """Root Cause Analysis report"""
    report_id: str
    title: str
    component: str
    failure_mode: str
    affected_vehicles: List[str]
    root_causes: List[Dict[str, Any]]
    contributing_factors: List[Dict[str, Any]]
    recommendations: List[Dict[str, Any]]
    capa_actions: List[Dict[str, Any]]
    severity_level: str
    business_impact: Dict[str, Any]
    generated_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "report_id": self.report_id,
            "title": self.title,
            "component": self.component,
            "failure_mode": self.failure_mode,
            "affected_vehicles": self.affected_vehicles,
            "root_causes": self.root_causes,
            "contributing_factors": self.contributing_factors,
            "recommendations": self.recommendations,
            "capa_actions": self.capa_actions,
            "severity_level": self.severity_level,
            "business_impact": self.business_impact,
            "generated_at": self.generated_at.isoformat()
        }

class FeedbackAgent(BaseAgent):
    """
    Advanced Feedback Agent for root cause analysis and maintenance insights
    Implements pattern recognition, statistical analysis, and CAPA generation
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("feedback_agent", config)
        
        # Analysis configuration
        self.min_pattern_frequency = config.get("min_pattern_frequency", 3)
        self.confidence_threshold = config.get("confidence_threshold", 0.7)
        self.analysis_window_days = config.get("analysis_window_days", 365)
        
        # Pattern recognition parameters
        self.similarity_threshold = config.get("similarity_threshold", 0.8)
        self.clustering_epsilon = config.get("clustering_epsilon", 0.3)
        
        # Storage for maintenance events and patterns
        self.maintenance_events: Dict[str, MaintenanceEvent] = {}
        self.failure_patterns: Dict[str, FailurePattern] = {}
        self.rca_reports: Dict[str, RCAReport] = {}
        
        # Statistical analysis cache
        self.analysis_cache = {}
        self.cache_expiry = timedelta(hours=1)
        
        self.logger.info("🔍 Feedback Agent initialized for root cause analysis")

    def _define_capabilities(self) -> List[str]:
        """Define agent capabilities"""
        return [
            "maintenance_event_tracking",
            "failure_pattern_recognition",
            "statistical_analysis",
            "root_cause_analysis",
            "capa_generation",
            "trend_identification",
            "fleet_insights"
        ]

    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process incoming messages for feedback analysis"""
        try:
            message_type = message.message_type
            payload = message.payload
            
            if message_type == "maintenance_event":
                return await self._handle_maintenance_event(message)
            elif message_type == "analyze_patterns":
                return await self._handle_pattern_analysis(message)
            elif message_type == "generate_rca":
                return await self._handle_rca_generation(message)
            elif message_type == "fleet_insights":
                return await self._handle_fleet_insights(message)
            elif message_type == "trend_analysis":
                return await self._handle_trend_analysis(message)
            else:
                self.logger.warning(f"Unknown message type: {message_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"Error processing message: {e}")
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="error",
                payload={"error": str(e), "original_message_id": message.id}
            )

    async def health_check(self) -> Dict[str, Any]:
        """Perform health check"""
        try:
            # Check database connectivity
            async with get_db() as db:
                result = await db.execute("SELECT 1")
                db_healthy = result is not None
            
            # Check analysis capabilities
            analysis_healthy = len(self.maintenance_events) >= 0
            
            # Check cache status
            cache_healthy = isinstance(self.analysis_cache, dict)
            
            is_healthy = db_healthy and analysis_healthy and cache_healthy
            
            return {
                "healthy": is_healthy,
                "database_connection": db_healthy,
                "analysis_engine": analysis_healthy,
                "cache_status": cache_healthy,
                "maintenance_events_count": len(self.maintenance_events),
                "failure_patterns_count": len(self.failure_patterns),
                "rca_reports_count": len(self.rca_reports),
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Health check failed: {e}")
            return {
                "healthy": False,
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }

    async def _handle_maintenance_event(self, message: AgentMessage) -> AgentMessage:
        """Handle maintenance event tracking"""
        try:
            payload = message.payload
            
            # Create maintenance event
            event = MaintenanceEvent(
                id=str(uuid.uuid4()),
                vehicle_id=payload["vehicle_id"],
                event_type=payload["event_type"],
                component=payload["component"],
                timestamp=datetime.fromisoformat(payload["timestamp"]),
                description=payload["description"],
                cost=payload.get("cost"),
                duration_hours=payload.get("duration_hours"),
                service_center_id=payload.get("service_center_id"),
                technician_notes=payload.get("technician_notes"),
                parts_replaced=payload.get("parts_replaced"),
                root_cause=payload.get("root_cause"),
                severity=payload.get("severity", "medium")
            )
            
            # Store event
            self.maintenance_events[event.id] = event
            
            # Store in database
            await self._store_maintenance_event(event)
            
            # Trigger pattern analysis if enough events
            if len(self.maintenance_events) % 10 == 0:
                await self._trigger_pattern_analysis()
            
            self.logger.info(f"📝 Maintenance event recorded: {event.component} - {event.event_type}")
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="maintenance_event_recorded",
                payload={
                    "event_id": event.id,
                    "status": "recorded",
                    "analysis_triggered": len(self.maintenance_events) % 10 == 0
                }
            )
            
        except Exception as e:
            self.logger.error(f"Error handling maintenance event: {e}")
            raise

    async def _handle_pattern_analysis(self, message: AgentMessage) -> AgentMessage:
        """Handle failure pattern analysis request"""
        try:
            payload = message.payload
            component = payload.get("component")
            time_window_days = payload.get("time_window_days", self.analysis_window_days)
            
            # Perform pattern analysis
            patterns = await self._analyze_failure_patterns(component, time_window_days)
            
            # Store patterns
            for pattern in patterns:
                self.failure_patterns[pattern.pattern_id] = pattern
            
            self.logger.info(f"🔍 Pattern analysis completed: {len(patterns)} patterns identified")
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="pattern_analysis_complete",
                payload={
                    "patterns_found": len(patterns),
                    "patterns": [pattern.to_dict() for pattern in patterns],
                    "analysis_timestamp": datetime.utcnow().isoformat()
                }
            )
            
        except Exception as e:
            self.logger.error(f"Error in pattern analysis: {e}")
            raise

    async def _analyze_failure_patterns(self, component: Optional[str] = None, 
                                      time_window_days: int = 365) -> List[FailurePattern]:
        """Analyze failure patterns using statistical methods"""
        try:
            # Get maintenance events from database
            events = await self._get_maintenance_events(component, time_window_days)
            
            if len(events) < self.min_pattern_frequency:
                self.logger.info(f"Insufficient data for pattern analysis: {len(events)} events")
                return []
            
            # Convert to DataFrame for analysis
            df = pd.DataFrame([event.to_dict() for event in events])
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            
            patterns = []
            
            # Group by component and failure mode
            for (comp, failure_mode), group in df.groupby(['component', 'event_type']):
                if len(group) >= self.min_pattern_frequency:
                    pattern = await self._create_failure_pattern(comp, failure_mode, group)
                    if pattern.confidence_score >= self.confidence_threshold:
                        patterns.append(pattern)
            
            # Sort by frequency and confidence
            patterns.sort(key=lambda p: (p.frequency, p.confidence_score), reverse=True)
            
            return patterns
            
        except Exception as e:
            self.logger.error(f"Error analyzing failure patterns: {e}")
            return []

    async def _create_failure_pattern(self, component: str, failure_mode: str, 
                                    group_data: pd.DataFrame) -> FailurePattern:
        """Create failure pattern from grouped data"""
        try:
            # Calculate statistics
            frequency = len(group_data)
            vehicles_affected = group_data['vehicle_id'].unique().tolist()
            
            # Get vehicle information for affected vehicles
            vehicle_stats = await self._get_vehicle_statistics(vehicles_affected)
            
            avg_mileage = np.mean([stats.get('mileage_at_failure', 0) for stats in vehicle_stats])
            avg_age = np.mean([stats.get('age_at_failure', 0) for stats in vehicle_stats])
            
            # Identify common conditions
            common_conditions = await self._identify_common_conditions(group_data, vehicle_stats)
            
            # Calculate confidence score
            confidence_score = self._calculate_pattern_confidence(frequency, len(vehicles_affected), common_conditions)
            
            pattern = FailurePattern(
                pattern_id=str(uuid.uuid4()),
                component=component,
                failure_mode=failure_mode,
                frequency=frequency,
                vehicles_affected=vehicles_affected,
                average_mileage_at_failure=avg_mileage,
                average_age_at_failure=avg_age,
                common_conditions=common_conditions,
                confidence_score=confidence_score
            )
            
            return pattern
            
        except Exception as e:
            self.logger.error(f"Error creating failure pattern: {e}")
            raise

    async def _get_maintenance_events(self, component: Optional[str] = None, 
                                    time_window_days: int = 365) -> List[MaintenanceEvent]:
        """Get maintenance events from database"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=time_window_days)
            
            # For now, return stored events (in production, query database)
            events = []
            for event in self.maintenance_events.values():
                if event.timestamp >= cutoff_date:
                    if component is None or event.component == component:
                        events.append(event)
            
            return events
            
        except Exception as e:
            self.logger.error(f"Error getting maintenance events: {e}")
            return []

    async def _get_vehicle_statistics(self, vehicle_ids: List[str]) -> List[Dict[str, Any]]:
        """Get vehicle statistics for pattern analysis"""
        try:
            # Mock vehicle statistics (in production, query database)
            stats = []
            for vehicle_id in vehicle_ids:
                stats.append({
                    'vehicle_id': vehicle_id,
                    'mileage_at_failure': np.random.randint(50000, 150000),
                    'age_at_failure': np.random.randint(2, 10),
                    'make': 'Toyota',  # Mock data
                    'model': 'Camry',
                    'year': 2020
                })
            
            return stats
            
        except Exception as e:
            self.logger.error(f"Error getting vehicle statistics: {e}")
            return []

    async def _identify_common_conditions(self, group_data: pd.DataFrame, 
                                        vehicle_stats: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Identify common conditions leading to failures"""
        try:
            conditions = {}
            
            # Analyze severity distribution
            severity_counts = group_data['severity'].value_counts().to_dict()
            conditions['severity_distribution'] = severity_counts
            
            # Analyze cost patterns
            if 'cost' in group_data.columns:
                costs = group_data['cost'].dropna()
                if len(costs) > 0:
                    conditions['average_cost'] = float(costs.mean())
                    conditions['cost_range'] = [float(costs.min()), float(costs.max())]
            
            # Analyze temporal patterns
            group_data['hour'] = group_data['timestamp'].dt.hour
            group_data['day_of_week'] = group_data['timestamp'].dt.dayofweek
            group_data['month'] = group_data['timestamp'].dt.month
            
            conditions['temporal_patterns'] = {
                'common_hours': group_data['hour'].mode().tolist(),
                'common_days': group_data['day_of_week'].mode().tolist(),
                'common_months': group_data['month'].mode().tolist()
            }
            
            # Analyze vehicle characteristics
            if vehicle_stats:
                makes = [stat['make'] for stat in vehicle_stats]
                models = [stat['model'] for stat in vehicle_stats]
                
                conditions['vehicle_patterns'] = {
                    'common_makes': Counter(makes).most_common(3),
                    'common_models': Counter(models).most_common(3)
                }
            
            return conditions
            
        except Exception as e:
            self.logger.error(f"Error identifying common conditions: {e}")
            return {}

    def _calculate_pattern_confidence(self, frequency: int, vehicles_affected: int, 
                                    common_conditions: Dict[str, Any]) -> float:
        """Calculate confidence score for failure pattern"""
        try:
            # Base confidence from frequency
            frequency_score = min(frequency / 10.0, 1.0)
            
            # Vehicle diversity score
            diversity_score = min(vehicles_affected / 5.0, 1.0)
            
            # Conditions consistency score
            conditions_score = 0.5  # Default
            if 'severity_distribution' in common_conditions:
                # Higher score if severity is consistent
                severity_dist = common_conditions['severity_distribution']
                max_severity_ratio = max(severity_dist.values()) / sum(severity_dist.values())
                conditions_score = max_severity_ratio
            
            # Weighted average
            confidence = (frequency_score * 0.4 + diversity_score * 0.3 + conditions_score * 0.3)
            
            return min(confidence, 1.0)
            
        except Exception as e:
            self.logger.error(f"Error calculating pattern confidence: {e}")
            return 0.0

    async def _store_maintenance_event(self, event: MaintenanceEvent):
        """Store maintenance event in database"""
        try:
            # In production, store in database
            # For now, just log
            self.logger.debug(f"Storing maintenance event: {event.id}")
            
        except Exception as e:
            self.logger.error(f"Error storing maintenance event: {e}")

    async def _trigger_pattern_analysis(self):
        """Trigger automatic pattern analysis"""
        try:
            message = AgentMessage(
                sender=self.agent_name,
                recipient=self.agent_name,
                message_type="analyze_patterns",
                payload={"auto_triggered": True}
            )
            
            await self.receive_message(message)
            
        except Exception as e:
            self.logger.error(f"Error triggering pattern analysis: {e}")

    async def _initialize_resources(self):
        """Initialize agent resources"""
        try:
            # Load existing maintenance events from database
            await self._load_maintenance_events()
            
            # Load existing patterns
            await self._load_failure_patterns()
            
            self.logger.info("✅ Feedback Agent resources initialized")
            
        except Exception as e:
            self.logger.error(f"Error initializing resources: {e}")

    async def _load_maintenance_events(self):
        """Load maintenance events from database"""
        try:
            # In production, load from database
            # For now, create some sample events for testing
            sample_events = [
                MaintenanceEvent(
                    id=str(uuid.uuid4()),
                    vehicle_id="sample-vehicle-1",
                    event_type="failure",
                    component="brake_pads",
                    timestamp=datetime.utcnow() - timedelta(days=30),
                    description="Brake pads worn out",
                    cost=250.0,
                    severity="medium"
                ),
                MaintenanceEvent(
                    id=str(uuid.uuid4()),
                    vehicle_id="sample-vehicle-2",
                    event_type="failure",
                    component="brake_pads",
                    timestamp=datetime.utcnow() - timedelta(days=45),
                    description="Brake pads replacement needed",
                    cost=280.0,
                    severity="medium"
                )
            ]
            
            for event in sample_events:
                self.maintenance_events[event.id] = event
            
            self.logger.info(f"Loaded {len(sample_events)} sample maintenance events")
            
        except Exception as e:
            self.logger.error(f"Error loading maintenance events: {e}")

    async def _load_failure_patterns(self):
        """Load existing failure patterns"""
        try:
            # In production, load from database
            self.logger.info("Failure patterns loaded")
            
        except Exception as e:
            self.logger.error(f"Error loading failure patterns: {e}")

    async def _cleanup(self):
        """Cleanup agent resources"""
        try:
            # Save current state
            await self._save_analysis_state()
            
            self.logger.info("🧹 Feedback Agent cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

    async def _save_analysis_state(self):
        """Save current analysis state"""
        try:
            # In production, save to database
            self.logger.debug("Analysis state saved")
            
        except Exception as e:
            self.logger.error(f"Error saving analysis state: {e}")

    async def _handle_rca_generation(self, message: AgentMessage) -> AgentMessage:
        """Handle RCA report generation request"""
        try:
            payload = message.payload
            pattern_id = payload.get("pattern_id")
            component = payload.get("component")
            failure_mode = payload.get("failure_mode")
            
            # Generate RCA report
            rca_report = await self._generate_rca_report(pattern_id, component, failure_mode)
            
            # Store report
            self.rca_reports[rca_report.report_id] = rca_report
            
            # Store in database
            await self._store_rca_report(rca_report)
            
            self.logger.info(f"📊 RCA report generated: {rca_report.title}")
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="rca_report_generated",
                payload={
                    "report_id": rca_report.report_id,
                    "report": rca_report.to_dict(),
                    "status": "completed"
                }
            )
            
        except Exception as e:
            self.logger.error(f"Error generating RCA report: {e}")
            raise

    async def _handle_fleet_insights(self, message: AgentMessage) -> AgentMessage:
        """Handle fleet-wide insights request"""
        try:
            payload = message.payload
            oem_id = payload.get("oem_id")
            time_period = payload.get("time_period", "last_quarter")
            
            # Generate fleet insights
            insights = await self._generate_fleet_insights(oem_id, time_period)
            
            self.logger.info(f"📈 Fleet insights generated for OEM: {oem_id}")
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="fleet_insights_generated",
                payload={
                    "insights": insights,
                    "generated_at": datetime.utcnow().isoformat()
                }
            )
            
        except Exception as e:
            self.logger.error(f"Error generating fleet insights: {e}")
            raise

    async def _handle_trend_analysis(self, message: AgentMessage) -> AgentMessage:
        """Handle trend analysis request"""
        try:
            payload = message.payload
            component = payload.get("component")
            time_window = payload.get("time_window", "6_months")
            
            # Perform trend analysis
            trends = await self._analyze_trends(component, time_window)
            
            self.logger.info(f"📊 Trend analysis completed for {component}")
            
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="trend_analysis_complete",
                payload={
                    "trends": trends,
                    "component": component,
                    "time_window": time_window
                }
            )
            
        except Exception as e:
            self.logger.error(f"Error in trend analysis: {e}")
            raise

    async def _generate_rca_report(self, pattern_id: Optional[str] = None, 
                                 component: Optional[str] = None, 
                                 failure_mode: Optional[str] = None) -> RCAReport:
        """Generate comprehensive RCA report"""
        try:
            # Get failure pattern
            pattern = None
            if pattern_id and pattern_id in self.failure_patterns:
                pattern = self.failure_patterns[pattern_id]
            elif component and failure_mode:
                # Find pattern by component and failure mode
                for p in self.failure_patterns.values():
                    if p.component == component and p.failure_mode == failure_mode:
                        pattern = p
                        break
            
            if not pattern:
                raise ValueError("No pattern found for RCA generation")
            
            # Analyze root causes
            root_causes = await self._analyze_root_causes(pattern)
            
            # Identify contributing factors
            contributing_factors = await self._identify_contributing_factors(pattern)
            
            # Generate recommendations
            recommendations = await self._generate_recommendations(pattern, root_causes)
            
            # Generate CAPA actions
            capa_actions = await self._generate_capa_actions(pattern, root_causes, recommendations)
            
            # Calculate business impact
            business_impact = await self._calculate_business_impact(pattern)
            
            # Determine severity level
            severity_level = self._determine_severity_level(pattern, business_impact)
            
            # Create RCA report
            rca_report = RCAReport(
                report_id=str(uuid.uuid4()),
                title=f"RCA Report: {pattern.component} - {pattern.failure_mode}",
                component=pattern.component,
                failure_mode=pattern.failure_mode,
                affected_vehicles=pattern.vehicles_affected,
                root_causes=root_causes,
                contributing_factors=contributing_factors,
                recommendations=recommendations,
                capa_actions=capa_actions,
                severity_level=severity_level,
                business_impact=business_impact,
                generated_at=datetime.utcnow()
            )
            
            return rca_report
            
        except Exception as e:
            self.logger.error(f"Error generating RCA report: {e}")
            raise

    async def _analyze_root_causes(self, pattern: FailurePattern) -> List[Dict[str, Any]]:
        """Analyze root causes using statistical methods and domain knowledge"""
        try:
            root_causes = []
            
            # Analyze based on component type
            component_causes = self._get_component_specific_causes(pattern.component)
            
            # Analyze based on failure frequency and conditions
            if pattern.frequency > 10:
                root_causes.append({
                    "cause": "Design Deficiency",
                    "description": f"High failure frequency ({pattern.frequency} occurrences) suggests potential design issues",
                    "probability": 0.8,
                    "evidence": f"Pattern observed across {len(pattern.vehicles_affected)} vehicles",
                    "category": "design"
                })
            
            # Analyze based on mileage patterns
            if pattern.average_mileage_at_failure < 50000:
                root_causes.append({
                    "cause": "Manufacturing Defect",
                    "description": "Early failure suggests manufacturing quality issues",
                    "probability": 0.7,
                    "evidence": f"Average failure at {pattern.average_mileage_at_failure:.0f} miles",
                    "category": "manufacturing"
                })
            
            # Analyze based on age patterns
            if pattern.average_age_at_failure < 3:
                root_causes.append({
                    "cause": "Material Quality",
                    "description": "Premature aging suggests material quality issues",
                    "probability": 0.6,
                    "evidence": f"Average failure at {pattern.average_age_at_failure:.1f} years",
                    "category": "materials"
                })
            
            # Add component-specific causes
            root_causes.extend(component_causes)
            
            # Sort by probability
            root_causes.sort(key=lambda x: x["probability"], reverse=True)
            
            return root_causes[:5]  # Top 5 root causes
            
        except Exception as e:
            self.logger.error(f"Error analyzing root causes: {e}")
            return []

    def _get_component_specific_causes(self, component: str) -> List[Dict[str, Any]]:
        """Get component-specific root causes"""
        component_causes = {
            "brake_pads": [
                {
                    "cause": "Aggressive Driving Patterns",
                    "description": "Frequent hard braking accelerates brake pad wear",
                    "probability": 0.6,
                    "evidence": "Common in urban driving conditions",
                    "category": "usage"
                },
                {
                    "cause": "Inferior Brake Pad Material",
                    "description": "Low-quality friction material leads to premature wear",
                    "probability": 0.5,
                    "evidence": "Material composition analysis needed",
                    "category": "materials"
                }
            ],
            "engine": [
                {
                    "cause": "Inadequate Maintenance",
                    "description": "Irregular oil changes and maintenance lead to engine problems",
                    "probability": 0.7,
                    "evidence": "Maintenance history analysis",
                    "category": "maintenance"
                },
                {
                    "cause": "Fuel Quality Issues",
                    "description": "Poor fuel quality affects engine performance and longevity",
                    "probability": 0.4,
                    "evidence": "Regional fuel quality variations",
                    "category": "external"
                }
            ],
            "transmission": [
                {
                    "cause": "Fluid Degradation",
                    "description": "Transmission fluid breakdown affects component lubrication",
                    "probability": 0.6,
                    "evidence": "Fluid analysis and change intervals",
                    "category": "maintenance"
                }
            ]
        }
        
        return component_causes.get(component, [])

    async def _identify_contributing_factors(self, pattern: FailurePattern) -> List[Dict[str, Any]]:
        """Identify contributing factors to failures"""
        try:
            factors = []
            
            # Environmental factors
            if 'temporal_patterns' in pattern.common_conditions:
                temporal = pattern.common_conditions['temporal_patterns']
                if temporal.get('common_months'):
                    factors.append({
                        "factor": "Seasonal Variation",
                        "description": "Failures show seasonal patterns",
                        "impact": "medium",
                        "evidence": f"Common failure months: {temporal['common_months']}"
                    })
            
            # Usage patterns
            if pattern.average_mileage_at_failure > 100000:
                factors.append({
                    "factor": "High Mileage Usage",
                    "description": "Component wear due to high mileage operation",
                    "impact": "high",
                    "evidence": f"Average failure at {pattern.average_mileage_at_failure:.0f} miles"
                })
            
            # Vehicle characteristics
            if 'vehicle_patterns' in pattern.common_conditions:
                vehicle_patterns = pattern.common_conditions['vehicle_patterns']
                if vehicle_patterns.get('common_makes'):
                    factors.append({
                        "factor": "Vehicle Make Dependency",
                        "description": "Failures concentrated in specific vehicle makes",
                        "impact": "medium",
                        "evidence": f"Common makes: {vehicle_patterns['common_makes']}"
                    })
            
            # Cost patterns
            if 'average_cost' in pattern.common_conditions:
                avg_cost = pattern.common_conditions['average_cost']
                if avg_cost > 500:
                    factors.append({
                        "factor": "High Repair Cost",
                        "description": "Expensive repairs indicate complex failures",
                        "impact": "high",
                        "evidence": f"Average repair cost: ${avg_cost:.2f}"
                    })
            
            return factors
            
        except Exception as e:
            self.logger.error(f"Error identifying contributing factors: {e}")
            return []

    async def _generate_recommendations(self, pattern: FailurePattern, 
                                      root_causes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate actionable recommendations"""
        try:
            recommendations = []
            
            # Design recommendations
            design_causes = [c for c in root_causes if c["category"] == "design"]
            if design_causes:
                recommendations.append({
                    "recommendation": "Design Review and Improvement",
                    "description": "Conduct comprehensive design review to address identified deficiencies",
                    "priority": "high",
                    "timeline": "6-12 months",
                    "responsible_team": "Engineering",
                    "estimated_cost": "high",
                    "expected_impact": "Reduce failure rate by 60-80%"
                })
            
            # Manufacturing recommendations
            manufacturing_causes = [c for c in root_causes if c["category"] == "manufacturing"]
            if manufacturing_causes:
                recommendations.append({
                    "recommendation": "Manufacturing Process Improvement",
                    "description": "Enhance quality control and manufacturing processes",
                    "priority": "high",
                    "timeline": "3-6 months",
                    "responsible_team": "Manufacturing",
                    "estimated_cost": "medium",
                    "expected_impact": "Reduce early failures by 50-70%"
                })
            
            # Material recommendations
            material_causes = [c for c in root_causes if c["category"] == "materials"]
            if material_causes:
                recommendations.append({
                    "recommendation": "Material Specification Update",
                    "description": "Review and upgrade material specifications",
                    "priority": "medium",
                    "timeline": "4-8 months",
                    "responsible_team": "Materials Engineering",
                    "estimated_cost": "medium",
                    "expected_impact": "Improve component durability by 40-60%"
                })
            
            # Maintenance recommendations
            maintenance_causes = [c for c in root_causes if c["category"] == "maintenance"]
            if maintenance_causes:
                recommendations.append({
                    "recommendation": "Enhanced Maintenance Guidelines",
                    "description": "Update maintenance schedules and procedures",
                    "priority": "medium",
                    "timeline": "1-3 months",
                    "responsible_team": "Service Engineering",
                    "estimated_cost": "low",
                    "expected_impact": "Extend component life by 20-40%"
                })
            
            # Monitoring recommendations
            if pattern.frequency > 5:
                recommendations.append({
                    "recommendation": "Enhanced Monitoring System",
                    "description": "Implement predictive monitoring for early detection",
                    "priority": "medium",
                    "timeline": "2-4 months",
                    "responsible_team": "Software Engineering",
                    "estimated_cost": "medium",
                    "expected_impact": "Early detection in 80% of cases"
                })
            
            return recommendations
            
        except Exception as e:
            self.logger.error(f"Error generating recommendations: {e}")
            return []

    async def _generate_capa_actions(self, pattern: FailurePattern, 
                                   root_causes: List[Dict[str, Any]], 
                                   recommendations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate CAPA (Corrective and Preventive Action) actions"""
        try:
            capa_actions = []
            
            # Immediate corrective actions
            if pattern.frequency > 10 or any(rc["probability"] > 0.7 for rc in root_causes):
                capa_actions.append({
                    "action_type": "corrective",
                    "action": "Immediate Field Investigation",
                    "description": "Deploy field engineers to investigate affected vehicles",
                    "timeline": "1-2 weeks",
                    "responsible": "Field Engineering Team",
                    "success_criteria": "Root cause confirmed in field conditions",
                    "status": "planned"
                })
            
            # Short-term corrective actions
            capa_actions.append({
                "action_type": "corrective",
                "action": "Enhanced Inspection Protocol",
                "description": "Implement enhanced inspection for affected components",
                "timeline": "2-4 weeks",
                "responsible": "Quality Assurance",
                "success_criteria": "100% inspection coverage for new production",
                "status": "planned"
            })
            
            # Long-term preventive actions
            for rec in recommendations:
                if rec["priority"] == "high":
                    capa_actions.append({
                        "action_type": "preventive",
                        "action": rec["recommendation"],
                        "description": rec["description"],
                        "timeline": rec["timeline"],
                        "responsible": rec["responsible_team"],
                        "success_criteria": rec["expected_impact"],
                        "status": "planned"
                    })
            
            # Monitoring and verification actions
            capa_actions.append({
                "action_type": "verification",
                "action": "Effectiveness Monitoring",
                "description": "Monitor failure rates to verify CAPA effectiveness",
                "timeline": "ongoing",
                "responsible": "Data Analytics Team",
                "success_criteria": "50% reduction in failure rate within 6 months",
                "status": "planned"
            })
            
            # Customer communication actions
            if len(pattern.vehicles_affected) > 20:
                capa_actions.append({
                    "action_type": "communication",
                    "action": "Customer Notification",
                    "description": "Notify affected customers about potential issues and solutions",
                    "timeline": "1-2 weeks",
                    "responsible": "Customer Service",
                    "success_criteria": "100% customer notification completion",
                    "status": "planned"
                })
            
            return capa_actions
            
        except Exception as e:
            self.logger.error(f"Error generating CAPA actions: {e}")
            return []

    async def _calculate_business_impact(self, pattern: FailurePattern) -> Dict[str, Any]:
        """Calculate business impact of failure pattern"""
        try:
            # Estimate costs
            avg_repair_cost = pattern.common_conditions.get('average_cost', 500.0)
            total_repair_cost = avg_repair_cost * pattern.frequency
            
            # Estimate warranty costs (assuming 60% under warranty)
            warranty_cost = total_repair_cost * 0.6
            
            # Estimate customer satisfaction impact
            satisfaction_impact = min(pattern.frequency / 100.0, 1.0)  # Scale 0-1
            
            # Estimate brand reputation impact
            reputation_impact = "low"
            if pattern.frequency > 50:
                reputation_impact = "high"
            elif pattern.frequency > 20:
                reputation_impact = "medium"
            
            # Estimate recall risk
            recall_risk = "low"
            if pattern.frequency > 100 and any(rc["probability"] > 0.8 for rc in []):
                recall_risk = "high"
            elif pattern.frequency > 50:
                recall_risk = "medium"
            
            business_impact = {
                "total_repair_cost": total_repair_cost,
                "warranty_cost": warranty_cost,
                "affected_vehicles_count": len(pattern.vehicles_affected),
                "customer_satisfaction_impact": satisfaction_impact,
                "brand_reputation_impact": reputation_impact,
                "recall_risk": recall_risk,
                "estimated_annual_cost": total_repair_cost * 2,  # Extrapolate
                "market_share_risk": "low" if pattern.frequency < 20 else "medium"
            }
            
            return business_impact
            
        except Exception as e:
            self.logger.error(f"Error calculating business impact: {e}")
            return {}

    def _determine_severity_level(self, pattern: FailurePattern, 
                                business_impact: Dict[str, Any]) -> str:
        """Determine severity level based on pattern and business impact"""
        try:
            # Critical: High frequency + high cost + safety implications
            if (pattern.frequency > 50 and 
                business_impact.get("total_repair_cost", 0) > 50000 and
                pattern.component in ["brake_pads", "engine", "transmission"]):
                return "critical"
            
            # High: Moderate frequency + significant cost
            elif (pattern.frequency > 20 and 
                  business_impact.get("total_repair_cost", 0) > 20000):
                return "high"
            
            # Medium: Some frequency + moderate cost
            elif (pattern.frequency > 10 and 
                  business_impact.get("total_repair_cost", 0) > 5000):
                return "medium"
            
            # Low: Low frequency or low cost
            else:
                return "low"
                
        except Exception as e:
            self.logger.error(f"Error determining severity level: {e}")
            return "medium"

    async def _generate_fleet_insights(self, oem_id: Optional[str], 
                                     time_period: str) -> Dict[str, Any]:
        """Generate fleet-wide insights for OEM dashboard"""
        try:
            insights = {
                "summary": {
                    "total_patterns_identified": len(self.failure_patterns),
                    "total_vehicles_analyzed": len(set().union(*[p.vehicles_affected for p in self.failure_patterns.values()])),
                    "total_maintenance_events": len(self.maintenance_events),
                    "analysis_period": time_period
                },
                "top_failure_patterns": [],
                "component_reliability": {},
                "cost_analysis": {},
                "recommendations": []
            }
            
            # Top failure patterns
            sorted_patterns = sorted(
                self.failure_patterns.values(), 
                key=lambda p: p.frequency, 
                reverse=True
            )[:10]
            
            for pattern in sorted_patterns:
                insights["top_failure_patterns"].append({
                    "component": pattern.component,
                    "failure_mode": pattern.failure_mode,
                    "frequency": pattern.frequency,
                    "vehicles_affected": len(pattern.vehicles_affected),
                    "confidence_score": pattern.confidence_score
                })
            
            # Component reliability analysis
            component_stats = defaultdict(lambda: {"failures": 0, "vehicles": set()})
            for pattern in self.failure_patterns.values():
                component_stats[pattern.component]["failures"] += pattern.frequency
                component_stats[pattern.component]["vehicles"].update(pattern.vehicles_affected)
            
            for component, stats in component_stats.items():
                insights["component_reliability"][component] = {
                    "total_failures": stats["failures"],
                    "vehicles_affected": len(stats["vehicles"]),
                    "reliability_score": max(0, 1 - (stats["failures"] / 100))  # Simple scoring
                }
            
            # Cost analysis
            total_cost = sum(
                event.cost for event in self.maintenance_events.values() 
                if event.cost is not None
            )
            
            insights["cost_analysis"] = {
                "total_maintenance_cost": total_cost,
                "average_cost_per_event": total_cost / max(len(self.maintenance_events), 1),
                "cost_by_component": self._calculate_cost_by_component()
            }
            
            # Fleet-level recommendations
            insights["recommendations"] = await self._generate_fleet_recommendations(sorted_patterns)
            
            return insights
            
        except Exception as e:
            self.logger.error(f"Error generating fleet insights: {e}")
            return {}

    def _calculate_cost_by_component(self) -> Dict[str, float]:
        """Calculate maintenance costs by component"""
        try:
            cost_by_component = defaultdict(float)
            
            for event in self.maintenance_events.values():
                if event.cost is not None:
                    cost_by_component[event.component] += event.cost
            
            return dict(cost_by_component)
            
        except Exception as e:
            self.logger.error(f"Error calculating cost by component: {e}")
            return {}

    async def _generate_fleet_recommendations(self, top_patterns: List[FailurePattern]) -> List[Dict[str, Any]]:
        """Generate fleet-level recommendations"""
        try:
            recommendations = []
            
            # High-frequency pattern recommendations
            if top_patterns and top_patterns[0].frequency > 20:
                recommendations.append({
                    "type": "urgent",
                    "title": "Address Critical Failure Pattern",
                    "description": f"Immediate attention needed for {top_patterns[0].component} failures",
                    "impact": "high",
                    "timeline": "immediate"
                })
            
            # Design improvement recommendations
            design_issues = [p for p in top_patterns if p.average_mileage_at_failure < 50000]
            if design_issues:
                recommendations.append({
                    "type": "design",
                    "title": "Design Review Required",
                    "description": "Multiple components showing early failure patterns",
                    "impact": "high",
                    "timeline": "6-12 months"
                })
            
            # Predictive maintenance recommendations
            if len(top_patterns) > 5:
                recommendations.append({
                    "type": "predictive",
                    "title": "Enhanced Predictive Maintenance",
                    "description": "Implement advanced predictive maintenance for identified patterns",
                    "impact": "medium",
                    "timeline": "3-6 months"
                })
            
            return recommendations
            
        except Exception as e:
            self.logger.error(f"Error generating fleet recommendations: {e}")
            return []

    async def _analyze_trends(self, component: Optional[str], time_window: str) -> Dict[str, Any]:
        """Analyze failure trends over time"""
        try:
            # Convert time window to days
            window_days = {
                "1_month": 30,
                "3_months": 90,
                "6_months": 180,
                "1_year": 365
            }.get(time_window, 180)
            
            # Get events in time window
            cutoff_date = datetime.utcnow() - timedelta(days=window_days)
            events = [
                event for event in self.maintenance_events.values()
                if event.timestamp >= cutoff_date and 
                (component is None or event.component == component)
            ]
            
            if not events:
                return {"trend": "insufficient_data", "events_count": 0}
            
            # Create time series
            df = pd.DataFrame([{
                'timestamp': event.timestamp,
                'component': event.component,
                'cost': event.cost or 0
            } for event in events])
            
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            df.set_index('timestamp', inplace=True)
            
            # Analyze trends
            monthly_counts = df.resample('M').size()
            monthly_costs = df.resample('M')['cost'].sum()
            
            # Calculate trend direction
            if len(monthly_counts) >= 3:
                recent_avg = monthly_counts[-3:].mean()
                earlier_avg = monthly_counts[:-3].mean() if len(monthly_counts) > 3 else monthly_counts.mean()
                
                if recent_avg > earlier_avg * 1.2:
                    trend_direction = "increasing"
                elif recent_avg < earlier_avg * 0.8:
                    trend_direction = "decreasing"
                else:
                    trend_direction = "stable"
            else:
                trend_direction = "insufficient_data"
            
            trends = {
                "trend_direction": trend_direction,
                "events_count": len(events),
                "time_window": time_window,
                "monthly_failure_counts": monthly_counts.to_dict(),
                "monthly_costs": monthly_costs.to_dict(),
                "average_monthly_failures": monthly_counts.mean(),
                "total_cost": monthly_costs.sum(),
                "peak_failure_month": monthly_counts.idxmax().strftime('%Y-%m') if len(monthly_counts) > 0 else None
            }
            
            return trends
            
        except Exception as e:
            self.logger.error(f"Error analyzing trends: {e}")
            return {"trend": "error", "error": str(e)}

    async def _store_rca_report(self, rca_report: RCAReport):
        """Store RCA report in database"""
        try:
            # In production, store in database
            self.logger.debug(f"Storing RCA report: {rca_report.report_id}")
            
        except Exception as e:
            self.logger.error(f"Error storing RCA report: {e}")

    # Public API methods for external access
    async def get_maintenance_events(self, vehicle_id: Optional[str] = None, 
                                   component: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get maintenance events with optional filtering"""
        try:
            events = []
            for event in self.maintenance_events.values():
                if vehicle_id and event.vehicle_id != vehicle_id:
                    continue
                if component and event.component != component:
                    continue
                events.append(event.to_dict())
            
            return events
            
        except Exception as e:
            self.logger.error(f"Error getting maintenance events: {e}")
            return []

    async def get_failure_patterns(self, component: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get failure patterns with optional filtering"""
        try:
            patterns = []
            for pattern in self.failure_patterns.values():
                if component and pattern.component != component:
                    continue
                patterns.append(pattern.to_dict())
            
            return patterns
            
        except Exception as e:
            self.logger.error(f"Error getting failure patterns: {e}")
            return []

    async def get_rca_reports(self, component: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get RCA reports with optional filtering"""
        try:
            reports = []
            for report in self.rca_reports.values():
                if component and report.component != component:
                    continue
                reports.append(report.to_dict())
            
            return reports
            
        except Exception as e:
            self.logger.error(f"Error getting RCA reports: {e}")
            return []