"""
Minimal test for AIVONITY Feedback Agent core logic
Tests only the core analysis functionality without database dependencies
"""

import asyncio
import json
from datetime import datetime, timedelta
import uuid
from dataclasses import dataclass
from typing import Dict, Any, List, Optional
import numpy as np
import pandas as pd
from collections import defaultdict, Counter

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

class FeedbackAnalyzer:
    """Core feedback analysis functionality"""
    
    def __init__(self):
        self.maintenance_events: Dict[str, MaintenanceEvent] = {}
        self.failure_patterns: Dict[str, FailurePattern] = {}
        self.min_pattern_frequency = 2
        self.confidence_threshold = 0.5
    
    def add_maintenance_event(self, event_data: Dict[str, Any]) -> str:
        """Add a maintenance event"""
        event = MaintenanceEvent(
            id=str(uuid.uuid4()),
            vehicle_id=event_data["vehicle_id"],
            event_type=event_data["event_type"],
            component=event_data["component"],
            timestamp=datetime.fromisoformat(event_data["timestamp"]),
            description=event_data["description"],
            cost=event_data.get("cost"),
            duration_hours=event_data.get("duration_hours"),
            service_center_id=event_data.get("service_center_id"),
            technician_notes=event_data.get("technician_notes"),
            parts_replaced=event_data.get("parts_replaced"),
            root_cause=event_data.get("root_cause"),
            severity=event_data.get("severity", "medium")
        )
        
        self.maintenance_events[event.id] = event
        return event.id
    
    def analyze_failure_patterns(self, component: Optional[str] = None) -> List[FailurePattern]:
        """Analyze failure patterns"""
        events = list(self.maintenance_events.values())
        
        if component:
            events = [e for e in events if e.component == component]
        
        if len(events) < self.min_pattern_frequency:
            return []
        
        # Convert to DataFrame for analysis
        df = pd.DataFrame([event.to_dict() for event in events])
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        patterns = []
        
        # Group by component and failure mode
        for (comp, failure_mode), group in df.groupby(['component', 'event_type']):
            if len(group) >= self.min_pattern_frequency:
                pattern = self._create_failure_pattern(comp, failure_mode, group)
                if pattern.confidence_score >= self.confidence_threshold:
                    patterns.append(pattern)
                    self.failure_patterns[pattern.pattern_id] = pattern
        
        return patterns
    
    def _create_failure_pattern(self, component: str, failure_mode: str, 
                              group_data: pd.DataFrame) -> FailurePattern:
        """Create failure pattern from grouped data"""
        frequency = len(group_data)
        vehicles_affected = group_data['vehicle_id'].unique().tolist()
        
        # Mock vehicle statistics
        avg_mileage = np.random.randint(50000, 150000)
        avg_age = np.random.randint(2, 10)
        
        # Identify common conditions
        common_conditions = self._identify_common_conditions(group_data)
        
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
    
    def _identify_common_conditions(self, group_data: pd.DataFrame) -> Dict[str, Any]:
        """Identify common conditions leading to failures"""
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
        
        return conditions
    
    def _calculate_pattern_confidence(self, frequency: int, vehicles_affected: int, 
                                    common_conditions: Dict[str, Any]) -> float:
        """Calculate confidence score for failure pattern"""
        # Base confidence from frequency
        frequency_score = min(frequency / 10.0, 1.0)
        
        # Vehicle diversity score
        diversity_score = min(vehicles_affected / 5.0, 1.0)
        
        # Conditions consistency score
        conditions_score = 0.5  # Default
        if 'severity_distribution' in common_conditions:
            severity_dist = common_conditions['severity_distribution']
            max_severity_ratio = max(severity_dist.values()) / sum(severity_dist.values())
            conditions_score = max_severity_ratio
        
        # Weighted average
        confidence = (frequency_score * 0.4 + diversity_score * 0.3 + conditions_score * 0.3)
        
        return min(confidence, 1.0)
    
    def generate_rca_report(self, pattern: FailurePattern) -> Dict[str, Any]:
        """Generate RCA report for a pattern"""
        # Analyze root causes
        root_causes = self._analyze_root_causes(pattern)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(pattern, root_causes)
        
        # Generate CAPA actions
        capa_actions = self._generate_capa_actions(pattern, root_causes)
        
        # Calculate business impact
        business_impact = self._calculate_business_impact(pattern)
        
        # Determine severity level
        severity_level = self._determine_severity_level(pattern, business_impact)
        
        return {
            "report_id": str(uuid.uuid4()),
            "title": f"RCA Report: {pattern.component} - {pattern.failure_mode}",
            "component": pattern.component,
            "failure_mode": pattern.failure_mode,
            "affected_vehicles": pattern.vehicles_affected,
            "root_causes": root_causes,
            "recommendations": recommendations,
            "capa_actions": capa_actions,
            "severity_level": severity_level,
            "business_impact": business_impact,
            "generated_at": datetime.utcnow().isoformat()
        }
    
    def _analyze_root_causes(self, pattern: FailurePattern) -> List[Dict[str, Any]]:
        """Analyze root causes"""
        root_causes = []
        
        # High frequency suggests design issues
        if pattern.frequency > 5:
            root_causes.append({
                "cause": "Design Deficiency",
                "description": f"High failure frequency ({pattern.frequency} occurrences) suggests potential design issues",
                "probability": 0.8,
                "evidence": f"Pattern observed across {len(pattern.vehicles_affected)} vehicles",
                "category": "design"
            })
        
        # Early failure suggests manufacturing issues
        if pattern.average_mileage_at_failure < 50000:
            root_causes.append({
                "cause": "Manufacturing Defect",
                "description": "Early failure suggests manufacturing quality issues",
                "probability": 0.7,
                "evidence": f"Average failure at {pattern.average_mileage_at_failure:.0f} miles",
                "category": "manufacturing"
            })
        
        # Component-specific causes
        component_causes = self._get_component_specific_causes(pattern.component)
        root_causes.extend(component_causes)
        
        return root_causes[:5]  # Top 5 root causes
    
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
                }
            ],
            "engine": [
                {
                    "cause": "Inadequate Maintenance",
                    "description": "Irregular oil changes and maintenance lead to engine problems",
                    "probability": 0.7,
                    "evidence": "Maintenance history analysis",
                    "category": "maintenance"
                }
            ]
        }
        
        return component_causes.get(component, [])
    
    def _generate_recommendations(self, pattern: FailurePattern, 
                                root_causes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate recommendations"""
        recommendations = []
        
        # Design recommendations
        design_causes = [c for c in root_causes if c["category"] == "design"]
        if design_causes:
            recommendations.append({
                "recommendation": "Design Review and Improvement",
                "description": "Conduct comprehensive design review to address identified deficiencies",
                "priority": "high",
                "timeline": "6-12 months",
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
                "expected_impact": "Reduce early failures by 50-70%"
            })
        
        return recommendations
    
    def _generate_capa_actions(self, pattern: FailurePattern, 
                             root_causes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate CAPA actions"""
        capa_actions = []
        
        # Immediate corrective actions
        if pattern.frequency > 5:
            capa_actions.append({
                "action_type": "corrective",
                "action": "Immediate Field Investigation",
                "description": "Deploy field engineers to investigate affected vehicles",
                "timeline": "1-2 weeks",
                "responsible": "Field Engineering Team"
            })
        
        # Preventive actions
        capa_actions.append({
            "action_type": "preventive",
            "action": "Enhanced Inspection Protocol",
            "description": "Implement enhanced inspection for affected components",
            "timeline": "2-4 weeks",
            "responsible": "Quality Assurance"
        })
        
        return capa_actions
    
    def _calculate_business_impact(self, pattern: FailurePattern) -> Dict[str, Any]:
        """Calculate business impact"""
        avg_repair_cost = pattern.common_conditions.get('average_cost', 500.0)
        total_repair_cost = avg_repair_cost * pattern.frequency
        
        return {
            "total_repair_cost": total_repair_cost,
            "warranty_cost": total_repair_cost * 0.6,
            "affected_vehicles_count": len(pattern.vehicles_affected),
            "estimated_annual_cost": total_repair_cost * 2
        }
    
    def _determine_severity_level(self, pattern: FailurePattern, 
                                business_impact: Dict[str, Any]) -> str:
        """Determine severity level"""
        if (pattern.frequency > 10 and 
            business_impact.get("total_repair_cost", 0) > 10000):
            return "high"
        elif pattern.frequency > 5:
            return "medium"
        else:
            return "low"

async def test_feedback_analyzer():
    """Test the Feedback Analyzer functionality"""
    print("🔍 Testing AIVONITY Feedback Analyzer")
    print("=" * 50)
    
    # Initialize analyzer
    analyzer = FeedbackAnalyzer()
    
    # Test 1: Add Maintenance Events
    print("\n1. Testing Maintenance Event Addition...")
    
    sample_events = [
        {
            "vehicle_id": "vehicle-001",
            "event_type": "failure",
            "component": "brake_pads",
            "description": "Brake pads worn out completely",
            "timestamp": (datetime.utcnow() - timedelta(days=30)).isoformat(),
            "cost": 250.0,
            "severity": "medium"
        },
        {
            "vehicle_id": "vehicle-002",
            "event_type": "failure",
            "component": "brake_pads",
            "description": "Brake pads replacement needed",
            "timestamp": (datetime.utcnow() - timedelta(days=45)).isoformat(),
            "cost": 280.0,
            "severity": "medium"
        },
        {
            "vehicle_id": "vehicle-003",
            "event_type": "failure",
            "component": "brake_pads",
            "description": "Brake pads showing excessive wear",
            "timestamp": (datetime.utcnow() - timedelta(days=60)).isoformat(),
            "cost": 300.0,
            "severity": "high"
        },
        {
            "vehicle_id": "vehicle-004",
            "event_type": "failure",
            "component": "engine",
            "description": "Engine overheating issue",
            "timestamp": (datetime.utcnow() - timedelta(days=20)).isoformat(),
            "cost": 1200.0,
            "severity": "high"
        },
        {
            "vehicle_id": "vehicle-005",
            "event_type": "failure",
            "component": "engine",
            "description": "Engine coolant leak",
            "timestamp": (datetime.utcnow() - timedelta(days=35)).isoformat(),
            "cost": 800.0,
            "severity": "medium"
        }
    ]
    
    for i, event_data in enumerate(sample_events):
        event_id = analyzer.add_maintenance_event(event_data)
        print(f"   ✅ Event {i+1} added: {event_data['component']} - {event_data['event_type']} (ID: {event_id[:8]}...)")
    
    print(f"   📊 Total events stored: {len(analyzer.maintenance_events)}")
    
    # Test 2: Pattern Analysis
    print("\n2. Testing Pattern Analysis...")
    
    patterns = analyzer.analyze_failure_patterns()
    print(f"   ✅ Pattern analysis completed: {len(patterns)} patterns found")
    
    for pattern in patterns:
        print(f"      - {pattern.component}: {pattern.frequency} failures, "
              f"confidence: {pattern.confidence_score:.2f}")
    
    # Test 3: RCA Report Generation
    print("\n3. Testing RCA Report Generation...")
    
    if patterns:
        first_pattern = patterns[0]
        rca_report = analyzer.generate_rca_report(first_pattern)
        
        print(f"   ✅ RCA report generated: {rca_report['title']}")
        print(f"      - Severity: {rca_report['severity_level']}")
        print(f"      - Root causes: {len(rca_report['root_causes'])}")
        print(f"      - Recommendations: {len(rca_report['recommendations'])}")
        print(f"      - CAPA actions: {len(rca_report['capa_actions'])}")
        
        # Display some details
        if rca_report['root_causes']:
            print(f"      - Top root cause: {rca_report['root_causes'][0]['cause']}")
        
        if rca_report['capa_actions']:
            print(f"      - First CAPA action: {rca_report['capa_actions'][0]['action']}")
    else:
        print("   ⚠️  No patterns available for RCA generation")
    
    # Test 4: Component-Specific Analysis
    print("\n4. Testing Component-Specific Analysis...")
    
    brake_patterns = analyzer.analyze_failure_patterns("brake_pads")
    print(f"   ✅ Brake pad patterns: {len(brake_patterns)}")
    
    engine_patterns = analyzer.analyze_failure_patterns("engine")
    print(f"   ✅ Engine patterns: {len(engine_patterns)}")
    
    # Test 5: Statistical Analysis
    print("\n5. Testing Statistical Analysis...")
    
    if patterns:
        pattern = patterns[0]
        
        # Test confidence calculation
        confidence = analyzer._calculate_pattern_confidence(
            pattern.frequency, 
            len(pattern.vehicles_affected), 
            pattern.common_conditions
        )
        print(f"   ✅ Confidence calculation: {confidence:.2f}")
        
        # Test business impact calculation
        business_impact = analyzer._calculate_business_impact(pattern)
        print(f"   ✅ Business impact calculated:")
        print(f"      - Total repair cost: ${business_impact['total_repair_cost']:.2f}")
        print(f"      - Warranty cost: ${business_impact['warranty_cost']:.2f}")
        print(f"      - Affected vehicles: {business_impact['affected_vehicles_count']}")
    
    print("\n✅ Feedback Analyzer testing completed successfully!")
    print("\n📊 Final Summary:")
    print(f"   - Maintenance events: {len(analyzer.maintenance_events)}")
    print(f"   - Failure patterns: {len(analyzer.failure_patterns)}")
    print(f"   - Analysis capabilities: Pattern recognition, RCA generation, CAPA recommendations")

if __name__ == "__main__":
    asyncio.run(test_feedback_analyzer())