"""
Test UEBA Agent Implementation
"""

import asyncio
import json
from datetime import datetime, timedelta
from app.agents.ueba_agent import UEBAAgent
from app.services.security_service import security_service
from app.utils.logging_config import setup_logging

async def test_ueba_agent():
    """Test UEBA agent functionality"""
    print("🔒 Testing UEBA Agent Implementation")
    
    # Setup logging
    setup_logging()
    
    # Initialize security service
    await security_service.initialize()
    
    # Create UEBA agent
    config = {
        "monitoring_interval": 60,  # 1 minute for testing
        "anomaly_threshold": 0.7,
        "alert_threshold": 0.8
    }
    
    ueba_agent = UEBAAgent(config)
    
    try:
        # Initialize agent
        await ueba_agent._initialize_resources()
        print("✅ UEBA Agent initialized successfully")
        
        # Test health check
        health_status = await ueba_agent.health_check()
        print(f"📊 Health Status: {health_status}")
        
        # Test user behavior analysis
        print("\n🔍 Testing User Behavior Analysis")
        user_behavior_data = {
            "user_id": "test_user_123",
            "session_duration": 7200,  # 2 hours - unusually long
            "actions_per_session": 150,  # High activity
            "api_calls_count": 500,
            "failed_requests": 15,  # High failure rate
            "new_device": True,
            "mobile_device": False,
            "location": {"latitude": 37.7749, "longitude": -122.4194}
        }
        
        is_anomaly, score, reasons = await security_service.detect_user_behavior_anomaly(
            "test_user_123", user_behavior_data
        )
        
        print(f"User Behavior Anomaly: {is_anomaly}")
        print(f"Anomaly Score: {score:.3f}")
        print(f"Reasons: {reasons}")
        
        # Test API usage analysis
        print("\n🔌 Testing API Usage Analysis")
        api_usage_data = {
            "user_id": "test_user_123",
            "requests_per_minute": 120,  # High rate
            "requests_per_hour": 5000,
            "total_requests": 5000,
            "error_rate": 0.25,  # 25% error rate - very high
            "timeout_rate": 0.05,
            "rate_limit_hits": 10,
            "unique_endpoints": 5,
            "endpoint_concentration": 0.8,
            "avg_response_time": 1500,
            "max_response_time": 8000,
            "total_bytes_sent": 1024000,
            "total_bytes_received": 15728640  # 15MB - large download
        }
        
        is_anomaly, score, reasons = await security_service.detect_api_usage_anomaly(
            "test_user_123", api_usage_data
        )
        
        print(f"API Usage Anomaly: {is_anomaly}")
        print(f"Anomaly Score: {score:.3f}")
        print(f"Reasons: {reasons}")
        
        # Test system metrics analysis
        print("\n🖥️ Testing System Metrics Analysis")
        system_data = {
            "cpu_usage": 95,  # Very high
            "memory_usage": 88,  # High
            "disk_usage": 75,
            "network_io": 1000000,
            "db_connections": 150,
            "db_query_time": 2500,  # Slow queries
            "db_lock_waits": 50,
            "active_sessions": 500,
            "error_count": 100,  # High error count
            "response_time": 3000,  # Slow responses
            "failed_logins": 75,  # High failed logins
            "blocked_requests": 25
        }
        
        is_anomaly, score, reasons = await security_service.detect_system_anomaly(system_data)
        
        print(f"System Anomaly: {is_anomaly}")
        print(f"Anomaly Score: {score:.3f}")
        print(f"Reasons: {reasons}")
        
        # Test alert generation
        print("\n🚨 Testing Alert Generation")
        alert_id = await security_service.generate_security_alert(
            alert_type="test_alert",
            entity_id="test_user_123",
            severity="high",
            details={
                "test_reason": "Testing alert generation",
                "anomaly_score": 0.85,
                "detected_patterns": ["high_api_usage", "unusual_session_duration"]
            }
        )
        
        print(f"Generated Alert ID: {alert_id}")
        
        # Test incident response
        print("\n⚡ Testing Incident Response")
        responses = await security_service.execute_incident_response(
            alert_id, ["rate_limit", "notify_admin"]
        )
        
        for response in responses:
            print(f"Response: {response.action_type} - Success: {response.success}")
        
        # Test threat intelligence
        print("\n🎯 Testing Threat Intelligence")
        threat_indicators = [
            {
                "type": "ip_address",
                "value": "192.168.1.100",
                "severity": "medium",
                "confidence": 0.7,
                "context": {"source": "test", "description": "Suspicious IP"}
            },
            {
                "type": "user_agent",
                "value": "SuspiciousBot/1.0",
                "severity": "high",
                "confidence": 0.9,
                "context": {"source": "test", "description": "Known malicious user agent"}
            }
        ]
        
        await security_service.update_threat_intelligence(threat_indicators)
        print(f"Updated threat intelligence with {len(threat_indicators)} indicators")
        
        # Test threat indicator checking
        context = {
            "ip_address": "192.168.1.100",
            "user_agent": "SuspiciousBot/1.0"
        }
        
        matched_indicators = await security_service.check_threat_indicators("test_user_123", context)
        print(f"Matched {len(matched_indicators)} threat indicators")
        
        for indicator in matched_indicators:
            print(f"  - {indicator.indicator_type}: {indicator.value} (Severity: {indicator.severity})")
        
        # Test dashboard data
        print("\n📊 Testing Dashboard Data")
        dashboard_data = await ueba_agent.get_security_dashboard_data()
        print(f"Dashboard Summary:")
        print(f"  - Entities Monitored: {dashboard_data['summary']['total_entities_monitored']}")
        print(f"  - Active Alerts: {dashboard_data['summary']['active_alerts']}")
        print(f"  - Alerts Last 24h: {dashboard_data['summary']['alerts_last_24h']}")
        
        # Test security metrics
        print("\n📈 Testing Security Metrics")
        security_metrics = await security_service.get_security_metrics()
        print(f"Security Metrics:")
        print(f"  - Anomalies Detected: {security_metrics['detection_stats']['anomalies_detected']}")
        print(f"  - Alerts Sent: {security_metrics['detection_stats']['alerts_sent']}")
        print(f"  - Active Blocks: {security_metrics['active_blocks']}")
        
        print("\n✅ All UEBA Agent tests completed successfully!")
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Cleanup
        await ueba_agent._cleanup()

if __name__ == "__main__":
    asyncio.run(test_ueba_agent())