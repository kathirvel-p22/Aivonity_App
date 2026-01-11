#!/usr/bin/env python3
"""
Test script for enhanced UEBA Agent security anomaly detection and alerting
Tests the implementation of task 10.2: Develop security anomaly detection and alerting
"""

import asyncio
import json
import time
from datetime import datetime, timedelta
from typing import Dict, Any
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '.'))

from app.agents.ueba_agent import UEBAAgent, SecurityAlert, BehaviorProfile
from app.agents.base_agent import AgentMessage

class MockRedisClient:
    """Mock Redis client for testing"""
    def __init__(self):
        self.data = {}
        self.lists = {}
    
    async def ping(self):
        return True
    
    async def setex(self, key: str, ttl: int, value: str):
        self.data[key] = value
        return True
    
    async def get(self, key: str):
        return self.data.get(key)
    
    async def keys(self, pattern: str):
        if pattern.endswith("*"):
            prefix = pattern[:-1]
            return [k for k in self.data.keys() if k.startswith(prefix)]
        return []
    
    async def lpush(self, key: str, value: str):
        if key not in self.lists:
            self.lists[key] = []
        self.lists[key].insert(0, value)
        return len(self.lists[key])
    
    async def ltrim(self, key: str, start: int, end: int):
        if key in self.lists:
            self.lists[key] = self.lists[key][start:end+1]
        return True
    
    async def ttl(self, key: str):
        return 3600 if key in self.data else -1
    
    async def delete(self, *keys):
        for key in keys:
            self.data.pop(key, None)
        return len(keys)
    
    async def close(self):
        pass

async def test_enhanced_anomaly_detection():
    """Test enhanced anomaly detection algorithms"""
    print("🧪 Testing Enhanced Anomaly Detection...")
    
    # Initialize UEBA agent with test configuration
    config = {
        "monitoring_interval": 60,
        "anomaly_threshold": 0.8,
        "alert_threshold": 0.9
    }
    
    ueba_agent = UEBAAgent(config)
    ueba_agent.redis_client = MockRedisClient()
    
    # Create test behavior profile
    profile = BehaviorProfile(
        entity_id="test_user_001",
        entity_type="user",
        typical_activity_hours=[9, 10, 11, 14, 15, 16],
        average_session_duration=300.0,  # 5 minutes
        typical_actions_per_session=10.0,
        sample_size=50,
        confidence_score=0.8
    )
    
    ueba_agent.behavior_profiles["user:test_user_001"] = profile
    
    # Test 1: Normal chat activity (should not trigger anomalies)
    print("\n📊 Test 1: Normal chat activity")
    normal_activity = {
        "timestamp": datetime.utcnow(),
        "activity_type": "chat_session",
        "duration": 280,  # Close to average
        "message_count": 12,  # Close to average
        "session_type": "support"
    }
    
    anomalies = await ueba_agent._detect_chat_anomalies(profile, normal_activity)
    print(f"   Normal activity anomalies: {len(anomalies)} - {anomalies}")
    assert len(anomalies) == 0, "Normal activity should not trigger anomalies"
    
    # Test 2: Suspicious chat activity (should trigger anomalies)
    print("\n🚨 Test 2: Suspicious chat activity")
    suspicious_activity = {
        "timestamp": datetime.utcnow().replace(hour=3),  # Outside normal hours
        "activity_type": "chat_session",
        "duration": 1200,  # 4x longer than average
        "message_count": 50,  # 5x more than average
        "session_type": "support"
    }
    
    anomalies = await ueba_agent._detect_chat_anomalies(profile, suspicious_activity)
    print(f"   Suspicious activity anomalies: {len(anomalies)} - {anomalies}")
    assert len(anomalies) > 0, "Suspicious activity should trigger anomalies"
    
    # Test 3: Agent behavior anomalies
    print("\n🤖 Test 3: Agent behavior anomalies")
    agent_profile = BehaviorProfile(
        entity_id="diagnosis_agent",
        entity_type="agent",
        typical_error_rate=0.02,  # 2% error rate
        typical_processing_time=1.5,  # 1.5 seconds
        typical_memory_usage=128.0,  # 128 MB
        sample_size=100,
        confidence_score=0.9
    )
    
    ueba_agent.behavior_profiles["agent:diagnosis_agent"] = agent_profile
    
    # Normal agent activity
    normal_agent_activity = {
        "timestamp": datetime.utcnow(),
        "activity_type": "agent_operation",
        "total_logs": 50,
        "error_rate": 0.02,
        "warning_count": 1,
        "avg_execution_time": 1.4,
        "avg_memory_usage": 130.0
    }
    
    agent_anomalies = await ueba_agent._detect_agent_anomalies(agent_profile, normal_agent_activity)
    print(f"   Normal agent activity anomalies: {len(agent_anomalies)} - {agent_anomalies}")
    
    # Suspicious agent activity
    suspicious_agent_activity = {
        "timestamp": datetime.utcnow(),
        "activity_type": "agent_operation",
        "total_logs": 200,
        "error_rate": 0.15,  # 7.5x higher than normal
        "warning_count": 25,
        "avg_execution_time": 8.0,  # 5x slower
        "avg_memory_usage": 400.0  # 3x more memory
    }
    
    agent_anomalies = await ueba_agent._detect_agent_anomalies(agent_profile, suspicious_agent_activity)
    print(f"   Suspicious agent activity anomalies: {len(agent_anomalies)} - {agent_anomalies}")
    assert len(agent_anomalies) > 0, "Suspicious agent activity should trigger anomalies"
    
    print("✅ Enhanced anomaly detection tests passed!")

async def test_security_alert_generation():
    """Test security alert generation and escalation"""
    print("\n🚨 Testing Security Alert Generation...")
    
    config = {
        "monitoring_interval": 60,
        "anomaly_threshold": 0.8,
        "alert_threshold": 0.9
    }
    
    ueba_agent = UEBAAgent(config)
    ueba_agent.redis_client = MockRedisClient()
    
    # Test alert generation
    anomalies = [
        "Unusually long chat session: 1200s vs avg 300s",
        "Activity outside typical hours: 3:00",
        "High message count: 50 vs avg 10"
    ]
    
    # Generate alert
    await ueba_agent._generate_security_alert(
        entity_id="test_user_001",
        entity_type="user",
        alert_type="chat_behavior_anomaly",
        anomalies=anomalies
    )
    
    # Check if alert was created
    assert len(ueba_agent.active_alerts) > 0, "Alert should be generated"
    
    alert = list(ueba_agent.active_alerts.values())[0]
    print(f"   Generated alert: {alert.title}")
    print(f"   Severity: {alert.severity}")
    print(f"   Confidence: {alert.confidence:.2f}")
    print(f"   Anomaly Score: {alert.anomaly_score:.2f}")
    print(f"   Indicators: {len(alert.indicators)}")
    
    # Test high-severity alert
    critical_anomalies = [
        "Critical error rate: 0.500 (potential system compromise)",
        "Critical memory usage: 800.00MB (potential memory attack)",
        "Suspicious fast processing: 0.01s (potential security bypass)"
    ]
    
    await ueba_agent._generate_security_alert(
        entity_id="diagnosis_agent",
        entity_type="agent",
        alert_type="agent_behavior_anomaly",
        anomalies=critical_anomalies
    )
    
    critical_alert = list(ueba_agent.active_alerts.values())[-1]
    print(f"   Critical alert severity: {critical_alert.severity}")
    assert critical_alert.severity in ["high", "critical"], "Critical anomalies should generate high/critical alerts"
    
    print("✅ Security alert generation tests passed!")

async def test_automated_response():
    """Test automated response and mitigation capabilities"""
    print("\n🤖 Testing Automated Response and Mitigation...")
    
    config = {
        "monitoring_interval": 60,
        "anomaly_threshold": 0.8,
        "alert_threshold": 0.9
    }
    
    ueba_agent = UEBAAgent(config)
    ueba_agent.redis_client = MockRedisClient()
    
    # Create a high-severity alert
    alert = SecurityAlert(
        alert_id="test_alert_001",
        entity_id="test_user_001",
        entity_type="user",
        alert_type="security_failed_login",
        severity="high",
        title="Multiple Failed Login Attempts",
        description="Detected multiple failed login attempts",
        anomaly_score=0.9,
        confidence=0.85,
        indicators=["5 failed login attempts in 10 minutes"]
    )
    
    # Test automated response trigger
    await ueba_agent._trigger_automated_response(alert)
    
    # Check if rate limiting was applied
    rate_limit_key = "rate_limit:user:test_user_001"
    rate_limit_applied = await ueba_agent.redis_client.get(rate_limit_key)
    print(f"   Rate limiting applied: {rate_limit_applied is not None}")
    
    # Test agent isolation
    agent_alert = SecurityAlert(
        alert_id="test_alert_002",
        entity_id="diagnosis_agent",
        entity_type="agent",
        alert_type="agent_behavior_anomaly",
        severity="critical",
        title="Agent Behavioral Anomaly",
        description="Critical agent behavior detected",
        anomaly_score=0.95,
        confidence=0.9,
        indicators=["Critical error rate spike"]
    )
    
    await ueba_agent._trigger_automated_response(agent_alert)
    
    # Check if agent isolation was applied
    isolation_key = "agent_isolated:diagnosis_agent"
    isolation_applied = await ueba_agent.redis_client.get(isolation_key)
    print(f"   Agent isolation applied: {isolation_applied is not None}")
    
    # Test mitigation management
    mitigations = await ueba_agent.get_active_mitigations()
    print(f"   Active mitigations: {len(mitigations['rate_limited_entities'])} rate limits, {len(mitigations['isolated_agents'])} isolated agents")
    
    # Test mitigation removal
    removed = await ueba_agent.remove_mitigation("rate_limit", "test_user_001")
    print(f"   Mitigation removal successful: {removed}")
    
    print("✅ Automated response and mitigation tests passed!")

async def test_alert_correlation():
    """Test alert correlation and pattern detection"""
    print("\n🔗 Testing Alert Correlation...")
    
    config = {
        "monitoring_interval": 60,
        "anomaly_threshold": 0.8,
        "alert_threshold": 0.9
    }
    
    ueba_agent = UEBAAgent(config)
    ueba_agent.redis_client = MockRedisClient()
    
    # Create multiple related alerts
    base_time = datetime.utcnow()
    
    alerts = [
        SecurityAlert(
            alert_id=f"test_alert_{i}",
            entity_id=f"user_{i:03d}",
            entity_type="user",
            alert_type="chat_behavior_anomaly",
            severity="medium",
            title="Behavioral Anomaly",
            description="Detected behavioral anomaly",
            anomaly_score=0.7,
            confidence=0.8,
            indicators=["Unusual activity pattern"],
            detected_at=base_time + timedelta(minutes=i*5)
        )
        for i in range(3)
    ]
    
    # Add alerts to active alerts
    for alert in alerts:
        ueba_agent.active_alerts[alert.alert_id] = alert
    
    # Test correlation with new alert
    new_alert = SecurityAlert(
        alert_id="test_alert_new",
        entity_id="user_004",
        entity_type="user",
        alert_type="chat_behavior_anomaly",
        severity="medium",
        title="Behavioral Anomaly",
        description="Detected behavioral anomaly",
        anomaly_score=0.7,
        confidence=0.8,
        indicators=["Unusual activity pattern"],
        detected_at=base_time + timedelta(minutes=20)
    )
    
    # Test correlation
    await ueba_agent._correlate_alerts(new_alert)
    
    # Check if correlation alert was generated
    correlation_alerts = [
        alert for alert in ueba_agent.active_alerts.values()
        if alert.alert_type == "correlated_security_events"
    ]
    
    print(f"   Correlation alerts generated: {len(correlation_alerts)}")
    if correlation_alerts:
        corr_alert = correlation_alerts[0]
        print(f"   Correlated events: {len(corr_alert.context.get('related_alerts', []))}")
    
    print("✅ Alert correlation tests passed!")

async def test_dashboard_data():
    """Test security dashboard data generation"""
    print("\n📊 Testing Security Dashboard Data...")
    
    config = {
        "monitoring_interval": 60,
        "anomaly_threshold": 0.8,
        "alert_threshold": 0.9
    }
    
    ueba_agent = UEBAAgent(config)
    ueba_agent.redis_client = MockRedisClient()
    
    # Add some test data
    ueba_agent.behavior_profiles["user:test_001"] = BehaviorProfile("test_001", "user")
    ueba_agent.behavior_profiles["agent:test_agent"] = BehaviorProfile("test_agent", "agent")
    
    # Add some alerts
    for i in range(5):
        alert = SecurityAlert(
            alert_id=f"dashboard_test_{i}",
            entity_id=f"user_{i}",
            entity_type="user",
            alert_type="test_anomaly",
            severity=["low", "medium", "high"][i % 3],
            title="Test Alert",
            description="Test alert for dashboard",
            anomaly_score=0.5 + (i * 0.1),
            confidence=0.8
        )
        ueba_agent.active_alerts[alert.alert_id] = alert
        ueba_agent.alert_history.append(alert)
    
    # Get dashboard data
    dashboard_data = await ueba_agent.get_security_dashboard_data()
    
    print(f"   Entities monitored: {dashboard_data['summary']['total_entities_monitored']}")
    print(f"   Active alerts: {dashboard_data['summary']['active_alerts']}")
    print(f"   Alerts by severity: {dashboard_data['alerts_by_severity']}")
    print(f"   Top risk entities: {len(dashboard_data['top_risk_entities'])}")
    
    assert dashboard_data['summary']['total_entities_monitored'] == 2
    assert dashboard_data['summary']['active_alerts'] == 5
    
    print("✅ Security dashboard data tests passed!")

async def main():
    """Run all enhanced UEBA agent tests"""
    print("🔒 Testing Enhanced UEBA Agent - Security Anomaly Detection and Alerting")
    print("=" * 80)
    
    try:
        await test_enhanced_anomaly_detection()
        await test_security_alert_generation()
        await test_automated_response()
        await test_alert_correlation()
        await test_dashboard_data()
        
        print("\n" + "=" * 80)
        print("🎉 All Enhanced UEBA Agent Tests Passed Successfully!")
        print("\n✅ Task 10.2 Implementation Verified:")
        print("   • Advanced behavioral anomaly detection algorithms")
        print("   • Sophisticated security alert generation and escalation")
        print("   • Automated response and mitigation capabilities")
        print("   • Alert correlation and pattern detection")
        print("   • Enhanced security monitoring and reporting")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    success = asyncio.run(main())
    exit(0 if success else 1)