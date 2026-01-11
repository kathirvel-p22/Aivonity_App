"""
Test script for AIVONITY Feedback Agent
Tests maintenance event tracking, pattern analysis, and RCA generation
"""

import asyncio
import json
import sys
import os
from datetime import datetime, timedelta
import uuid

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.agents.feedback_agent import FeedbackAgent, MaintenanceEvent
from app.agents.base_agent import AgentMessage

async def test_feedback_agent():
    """Test the Feedback Agent functionality"""
    print("🔍 Testing AIVONITY Feedback Agent")
    print("=" * 50)
    
    # Initialize agent
    config = {
        "min_pattern_frequency": 2,  # Lower for testing
        "confidence_threshold": 0.5,
        "analysis_window_days": 365
    }
    
    agent = FeedbackAgent(config)
    await agent.start()
    
    # Test 1: Health Check
    print("\n1. Testing Health Check...")
    health = await agent.health_check()
    print(f"   Health Status: {'✅ Healthy' if health['healthy'] else '❌ Unhealthy'}")
    print(f"   Database Connection: {health['database_connection']}")
    print(f"   Analysis Engine: {health['analysis_engine']}")
    
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
    
    if patterns:
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
    
    # Final status
    print("\n8. Final Agent Status...")
    status = agent.get_status()
    print(f"   Agent Name: {status['agent_name']}")
    print(f"   Running: {status['is_running']}")
    print(f"   Healthy: {status['is_healthy']}")
    print(f"   Messages Processed: {status['messages_processed']}")
    print(f"   Error Rate: {status['error_rate']:.2%}")
    print(f"   Uptime: {status['uptime']:.1f} seconds")
    
    # Stop agent
    await agent.stop()
    print("\n✅ Feedback Agent testing completed successfully!")

if __name__ == "__main__":
    asyncio.run(test_feedback_agent())