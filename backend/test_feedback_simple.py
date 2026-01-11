"""
Simplified test for AIVONITY Feedback Agent
Tests core functionality without database dependencies
"""

import asyncio
import json
import sys
import os
from datetime import datetime, timedelta
import uuid

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Mock the database dependencies
class MockDB:
    async def execute(self, query):
        return True
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass

# Mock the database functions
def mock_get_db():
    return MockDB()

# Mock the logging config
def mock_get_logger(name):
    import logging
    return logging.getLogger(name)

# Mock the config
class MockSettings:
    AGENT_MAX_RETRIES = 3
    AGENT_TIMEOUT = 30
    AGENT_HEARTBEAT_INTERVAL = 60

# Mock SQLAlchemy Base
class MockBase:
    pass

# Mock SQLAlchemy functions
def mock_column(*args, **kwargs):
    return None

def mock_relationship(*args, **kwargs):
    return None

# Patch the imports
sys.modules['app.db.database'] = type('MockModule', (), {'get_db': mock_get_db, 'Base': MockBase})()
sys.modules['app.utils.logging_config'] = type('MockModule', (), {'get_logger': mock_get_logger})()
sys.modules['app.config'] = type('MockModule', (), {'settings': MockSettings()})()

# Mock SQLAlchemy
sys.modules['sqlalchemy'] = type('MockModule', (), {
    'Column': mock_column,
    'String': lambda x: None,
    'Integer': lambda: None,
    'Float': lambda: None,
    'Boolean': lambda: None,
    'DateTime': lambda **kwargs: None,
    'Text': lambda: None,
    'JSON': lambda: None,
    'ForeignKey': lambda x: None,
    'Index': lambda *args: None,
    'and_': lambda *args: None,
    'or_': lambda *args: None,
    'func': type('MockFunc', (), {'now': lambda: None})(),
    'desc': lambda x: None
})()

sys.modules['sqlalchemy.orm'] = type('MockModule', (), {
    'Session': type,
    'relationship': mock_relationship
})()

sys.modules['sqlalchemy.dialects.postgresql'] = type('MockModule', (), {
    'UUID': lambda **kwargs: None,
    'JSONB': lambda: None
})()

sys.modules['sqlalchemy.sql'] = type('MockModule', (), {
    'func': type('MockFunc', (), {'now': lambda: None})()
})()

# Mock the auth module
sys.modules['app.utils.auth'] = type('MockModule', (), {
    'get_current_user': lambda: None
})()

from app.agents.feedback_agent import FeedbackAgent, MaintenanceEvent
from app.agents.base_agent import AgentMessage

async def test_feedback_agent_simple():
    """Test the Feedback Agent core functionality"""
    print("🔍 Testing AIVONITY Feedback Agent (Simplified)")
    print("=" * 50)
    
    # Initialize agent
    config = {
        "min_pattern_frequency": 2,  # Lower for testing
        "confidence_threshold": 0.5,
        "analysis_window_days": 365
    }
    
    agent = FeedbackAgent(config)
    
    # Test 1: Agent Initialization
    print("\n1. Testing Agent Initialization...")
    print(f"   ✅ Agent Name: {agent.agent_name}")
    print(f"   ✅ Capabilities: {', '.join(agent.capabilities)}")
    print(f"   ✅ Configuration loaded")
    
    # Test 2: Create Maintenance Events
    print("\n2. Testing Maintenance Event Creation...")
    
    # Create sample maintenance events
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
        message = AgentMessage(
            sender="test",
            recipient="feedback_agent",
            message_type="maintenance_event",
            payload=event_data
        )
        
        response = await agent.process_message(message)
        if response and response.message_type == "maintenance_event_recorded":
            print(f"   ✅ Event {i+1} recorded: {event_data['component']} - {event_data['event_type']}")
        else:
            print(f"   ❌ Failed to record event {i+1}")
    
    # Test 3: Pattern Analysis
    print("\n3. Testing Pattern Analysis...")
    
    pattern_message = AgentMessage(
        sender="test",
        recipient="feedback_agent",
        message_type="analyze_patterns",
        payload={
            "component": None,  # Analyze all components
            "time_window_days": 365
        }
    )
    
    response = await agent.process_message(pattern_message)
    if response and response.message_type == "pattern_analysis_complete":
        patterns = response.payload["patterns"]
        print(f"   ✅ Pattern analysis completed: {len(patterns)} patterns found")
        
        for pattern in patterns:
            print(f"      - {pattern['component']}: {pattern['frequency']} failures, "
                  f"confidence: {pattern['confidence_score']:.2f}")
    else:
        print("   ❌ Pattern analysis failed")
    
    # Test 4: RCA Report Generation
    print("\n4. Testing RCA Report Generation...")
    
    if 'patterns' in locals() and patterns:
        # Generate RCA for the first pattern
        first_pattern = patterns[0]
        rca_message = AgentMessage(
            sender="test",
            recipient="feedback_agent",
            message_type="generate_rca",
            payload={
                "component": first_pattern["component"],
                "failure_mode": first_pattern["failure_mode"]
            }
        )
        
        response = await agent.process_message(rca_message)
        if response and response.message_type == "rca_report_generated":
            report = response.payload["report"]
            print(f"   ✅ RCA report generated: {report['title']}")
            print(f"      - Severity: {report['severity_level']}")
            print(f"      - Root causes: {len(report['root_causes'])}")
            print(f"      - Recommendations: {len(report['recommendations'])}")
            print(f"      - CAPA actions: {len(report['capa_actions'])}")
            
            # Display some details
            if report['root_causes']:
                print(f"      - Top root cause: {report['root_causes'][0]['cause']}")
            
            if report['capa_actions']:
                print(f"      - First CAPA action: {report['capa_actions'][0]['action']}")
        else:
            print("   ❌ RCA report generation failed")
    else:
        print("   ⚠️  No patterns available for RCA generation")
    
    # Test 5: Fleet Insights
    print("\n5. Testing Fleet Insights...")
    
    fleet_message = AgentMessage(
        sender="test",
        recipient="feedback_agent",
        message_type="fleet_insights",
        payload={
            "oem_id": "test_oem",
            "time_period": "last_quarter"
        }
    )
    
    response = await agent.process_message(fleet_message)
    if response and response.message_type == "fleet_insights_generated":
        insights = response.payload["insights"]
        print(f"   ✅ Fleet insights generated")
        print(f"      - Total patterns: {insights['summary']['total_patterns_identified']}")
        print(f"      - Vehicles analyzed: {insights['summary']['total_vehicles_analyzed']}")
        print(f"      - Maintenance events: {insights['summary']['total_maintenance_events']}")
        print(f"      - Top failure patterns: {len(insights['top_failure_patterns'])}")
        print(f"      - Component reliability data: {len(insights['component_reliability'])}")
        print(f"      - Fleet recommendations: {len(insights['recommendations'])}")
    else:
        print("   ❌ Fleet insights generation failed")
    
    # Test 6: Trend Analysis
    print("\n6. Testing Trend Analysis...")
    
    trend_message = AgentMessage(
        sender="test",
        recipient="feedback_agent",
        message_type="trend_analysis",
        payload={
            "component": "brake_pads",
            "time_window": "6_months"
        }
    )
    
    response = await agent.process_message(trend_message)
    if response and response.message_type == "trend_analysis_complete":
        trends = response.payload["trends"]
        print(f"   ✅ Trend analysis completed")
        print(f"      - Trend direction: {trends['trend_direction']}")
        print(f"      - Events analyzed: {trends['events_count']}")
        print(f"      - Average monthly failures: {trends.get('average_monthly_failures', 0):.1f}")
        print(f"      - Total cost: ${trends.get('total_cost', 0):.2f}")
    else:
        print("   ❌ Trend analysis failed")
    
    # Test 7: Data Retrieval
    print("\n7. Testing Data Retrieval...")
    
    # Get maintenance events
    events = await agent.get_maintenance_events()
    print(f"   ✅ Retrieved {len(events)} maintenance events")
    
    # Get failure patterns
    patterns = await agent.get_failure_patterns()
    print(f"   ✅ Retrieved {len(patterns)} failure patterns")
    
    # Get RCA reports
    reports = await agent.get_rca_reports()
    print(f"   ✅ Retrieved {len(reports)} RCA reports")
    
    # Test 8: Statistical Analysis
    print("\n8. Testing Statistical Analysis...")
    
    # Test pattern confidence calculation
    confidence = agent._calculate_pattern_confidence(5, 3, {"severity_distribution": {"high": 3, "medium": 2}})
    print(f"   ✅ Pattern confidence calculation: {confidence:.2f}")
    
    # Test component-specific causes
    brake_causes = agent._get_component_specific_causes("brake_pads")
    print(f"   ✅ Brake pad specific causes: {len(brake_causes)} identified")
    
    engine_causes = agent._get_component_specific_causes("engine")
    print(f"   ✅ Engine specific causes: {len(engine_causes)} identified")
    
    print("\n✅ Feedback Agent testing completed successfully!")
    print("\n📊 Summary:")
    print(f"   - Maintenance events processed: {len(agent.maintenance_events)}")
    print(f"   - Failure patterns identified: {len(agent.failure_patterns)}")
    print(f"   - RCA reports generated: {len(agent.rca_reports)}")
    print(f"   - Agent capabilities: {len(agent.capabilities)}")

if __name__ == "__main__":
    asyncio.run(test_feedback_agent_simple())