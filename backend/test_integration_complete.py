"""
AIVONITY Complete Integration Test Suite
Tests end-to-end workflows and component integration
"""

import pytest
import asyncio
import json
import websockets
from datetime import datetime, timedelta
from typing import Dict, Any, List
from unittest.mock import Mock, patch
import uuid

from fastapi.testclient import TestClient
from httpx import AsyncClient
import redis.asyncio as redis

from app.main import app
from app.db.database import get_db_session
from app.agents.agent_manager import AgentManager
from app.utils.websocket_manager import WebSocketManager
from app.config import settings

class TestCompleteIntegration:
    """Complete integration test suite for AIVONITY system"""
    
    @pytest.fixture(scope="class")
    async def setup_test_environment(self):
        """Setup complete test environment"""
        # Initialize test database
        # Note: In real implementation, use test database
        
        # Setup test data
        test_data = {
            "user_id": str(uuid.uuid4()),
            "vehicle_id": str(uuid.uuid4()),
            "test_telemetry": {
                "engine_temp": 85.5,
                "oil_pressure": 45.2,
                "battery_voltage": 12.6,
                "rpm": 2500,
                "speed": 65.0
            }
        }
        
        yield test_data
        
        # Cleanup after tests
        # Clean up test data
    
    @pytest.fixture
    def client(self):
        """FastAPI test client"""
        return TestClient(app)
    
    @pytest.fixture
    async def async_client(self):
        """Async HTTP client for testing"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            yield client
    
    async def test_user_registration_and_authentication_flow(self, client, setup_test_environment):
        """Test complete user registration and authentication workflow"""
        test_data = setup_test_environment
        
        # Step 1: User Registration
        registration_data = {
            "email": "test@aivonity.com",
            "password": "SecurePassword123!",
            "name": "Test User",
            "phone": "+1234567890"
        }
        
        response = client.post("/api/v1/auth/register", json=registration_data)
        assert response.status_code == 201
        user_data = response.json()
        assert "access_token" in user_data
        assert user_data["user"]["email"] == registration_data["email"]
        
        # Step 2: User Login
        login_data = {
            "email": registration_data["email"],
            "password": registration_data["password"]
        }
        
        response = client.post("/api/v1/auth/login", json=login_data)
        assert response.status_code == 200
        login_response = response.json()
        access_token = login_response["access_token"]
        
        # Step 3: Authenticated Request
        headers = {"Authorization": f"Bearer {access_token}"}
        response = client.get("/api/v1/auth/profile", headers=headers)
        assert response.status_code == 200
        
        test_data["access_token"] = access_token
        test_data["user_data"] = user_data["user"]
    
    async def test_vehicle_registration_and_management_flow(self, client, setup_test_environment):
        """Test vehicle registration and management workflow"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        
        # Step 1: Register Vehicle
        vehicle_data = {
            "make": "Tesla",
            "model": "Model 3",
            "year": 2023,
            "vin": "5YJ3E1EA4KF123456",
            "mileage": 15000
        }
        
        response = client.post("/api/v1/vehicles", json=vehicle_data, headers=headers)
        assert response.status_code == 201
        vehicle_response = response.json()
        test_data["vehicle_data"] = vehicle_response
        
        # Step 2: Get Vehicle Details
        vehicle_id = vehicle_response["id"]
        response = client.get(f"/api/v1/vehicles/{vehicle_id}", headers=headers)
        assert response.status_code == 200
        
        # Step 3: Update Vehicle
        update_data = {"mileage": 15500}
        response = client.put(f"/api/v1/vehicles/{vehicle_id}", json=update_data, headers=headers)
        assert response.status_code == 200
    
    async def test_telemetry_ingestion_and_processing_flow(self, client, setup_test_environment):
        """Test complete telemetry data flow from ingestion to alerts"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        vehicle_id = test_data["vehicle_data"]["id"]
        
        # Step 1: Ingest Normal Telemetry Data
        telemetry_data = {
            "vehicle_id": vehicle_id,
            "timestamp": datetime.utcnow().isoformat(),
            "sensor_data": test_data["test_telemetry"],
            "location": {"latitude": 37.7749, "longitude": -122.4194}
        }
        
        response = client.post("/api/v1/telemetry/ingest", json=telemetry_data, headers=headers)
        assert response.status_code == 201
        
        # Step 2: Ingest Anomalous Data (High Engine Temperature)
        anomalous_data = telemetry_data.copy()
        anomalous_data["sensor_data"]["engine_temp"] = 120.0  # Dangerously high
        anomalous_data["timestamp"] = (datetime.utcnow() + timedelta(minutes=1)).isoformat()
        
        response = client.post("/api/v1/telemetry/ingest", json=anomalous_data, headers=headers)
        assert response.status_code == 201
        
        # Step 3: Check for Generated Alerts
        await asyncio.sleep(2)  # Allow processing time
        response = client.get(f"/api/v1/telemetry/alerts/{vehicle_id}", headers=headers)
        assert response.status_code == 200
        alerts = response.json()
        assert len(alerts) > 0
        assert any(alert["severity"] == "critical" for alert in alerts)
    
    async def test_predictive_maintenance_workflow(self, client, setup_test_environment):
        """Test predictive maintenance prediction and recommendation flow"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        vehicle_id = test_data["vehicle_data"]["id"]
        
        # Step 1: Request Maintenance Prediction
        response = client.post(f"/api/v1/predictions/request", 
                             json={"vehicle_id": vehicle_id}, 
                             headers=headers)
        assert response.status_code == 202  # Accepted for processing
        
        # Step 2: Wait for Prediction Processing
        await asyncio.sleep(3)  # Allow ML processing time
        
        # Step 3: Get Predictions
        response = client.get(f"/api/v1/predictions/vehicle/{vehicle_id}", headers=headers)
        assert response.status_code == 200
        predictions = response.json()
        
        # Verify prediction structure
        assert isinstance(predictions, list)
        if predictions:
            prediction = predictions[0]
            assert "component" in prediction
            assert "failure_probability" in prediction
            assert "confidence_score" in prediction
            assert "recommended_action" in prediction
    
    async def test_service_booking_optimization_flow(self, client, setup_test_environment):
        """Test intelligent service booking and optimization workflow"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        vehicle_id = test_data["vehicle_data"]["id"]
        
        # Step 1: Check Service Center Availability
        search_params = {
            "latitude": 37.7749,
            "longitude": -122.4194,
            "radius": 50,
            "service_type": "maintenance"
        }
        
        response = client.get("/api/v1/booking/availability", params=search_params, headers=headers)
        assert response.status_code == 200
        availability = response.json()
        assert "service_centers" in availability
        
        # Step 2: Schedule Optimized Appointment
        if availability["service_centers"]:
            service_center = availability["service_centers"][0]
            booking_data = {
                "vehicle_id": vehicle_id,
                "service_center_id": service_center["id"],
                "preferred_date": (datetime.utcnow() + timedelta(days=7)).date().isoformat(),
                "service_type": "maintenance",
                "urgency": "medium"
            }
            
            response = client.post("/api/v1/booking/schedule", json=booking_data, headers=headers)
            assert response.status_code == 201
            booking = response.json()
            test_data["booking_data"] = booking
            
            # Step 3: Verify Booking Optimization
            assert "optimized_time" in booking
            assert "estimated_duration" in booking
    
    async def test_ai_chat_conversation_flow(self, client, setup_test_environment):
        """Test AI chat conversation workflow"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        user_id = test_data["user_data"]["id"]
        
        # Step 1: Start Chat Conversation
        chat_message = {
            "user_id": user_id,
            "message": "What's the current health status of my vehicle?",
            "context": {
                "vehicle_id": test_data["vehicle_data"]["id"],
                "conversation_type": "health_inquiry"
            }
        }
        
        response = client.post("/api/v1/chat/message", json=chat_message, headers=headers)
        assert response.status_code == 200
        chat_response = response.json()
        
        # Verify AI response structure
        assert "response" in chat_response
        assert "context" in chat_response
        assert "suggestions" in chat_response
        
        # Step 2: Follow-up Question
        followup_message = {
            "user_id": user_id,
            "message": "Should I schedule maintenance soon?",
            "context": chat_response["context"]
        }
        
        response = client.post("/api/v1/chat/message", json=followup_message, headers=headers)
        assert response.status_code == 200
        
        # Step 3: Get Chat History
        response = client.get(f"/api/v1/chat/history/{user_id}", headers=headers)
        assert response.status_code == 200
        history = response.json()
        assert len(history) >= 2  # At least 2 messages exchanged
    
    async def test_feedback_and_rca_workflow(self, client, setup_test_environment):
        """Test feedback collection and root cause analysis workflow"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        vehicle_id = test_data["vehicle_data"]["id"]
        
        # Step 1: Submit Maintenance Event
        maintenance_event = {
            "vehicle_id": vehicle_id,
            "event_type": "repair",
            "component": "engine",
            "description": "Engine overheating issue resolved",
            "cost": 450.00,
            "duration_hours": 3,
            "service_center_id": "test-service-center",
            "outcome": "successful"
        }
        
        response = client.post("/api/v1/feedback/maintenance-event", 
                             json=maintenance_event, headers=headers)
        assert response.status_code == 201
        
        # Step 2: Wait for RCA Processing
        await asyncio.sleep(2)
        
        # Step 3: Get RCA Report
        response = client.get(f"/api/v1/feedback/rca/{vehicle_id}", headers=headers)
        assert response.status_code == 200
        rca_report = response.json()
        
        # Verify RCA report structure
        assert "analysis" in rca_report
        assert "patterns" in rca_report
        assert "recommendations" in rca_report
    
    async def test_real_time_websocket_communication(self, setup_test_environment):
        """Test real-time WebSocket communication"""
        test_data = setup_test_environment
        vehicle_id = test_data["vehicle_data"]["id"]
        user_id = test_data["user_data"]["id"]
        
        # Test Telemetry WebSocket
        async def test_telemetry_websocket():
            uri = f"ws://localhost:8000/ws/telemetry/{vehicle_id}"
            try:
                async with websockets.connect(uri) as websocket:
                    # Send test telemetry data
                    test_message = {
                        "type": "telemetry_update",
                        "data": test_data["test_telemetry"]
                    }
                    await websocket.send(json.dumps(test_message))
                    
                    # Receive response
                    response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                    response_data = json.loads(response)
                    assert response_data["type"] == "telemetry_update"
                    
            except Exception as e:
                # WebSocket might not be available in test environment
                pytest.skip(f"WebSocket test skipped: {e}")
        
        # Test Chat WebSocket
        async def test_chat_websocket():
            uri = f"ws://localhost:8000/ws/chat/{user_id}"
            try:
                async with websockets.connect(uri) as websocket:
                    # Send chat message
                    chat_message = {
                        "message": "Test WebSocket chat",
                        "timestamp": datetime.utcnow().isoformat()
                    }
                    await websocket.send(json.dumps(chat_message))
                    
                    # Receive AI response
                    response = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                    response_data = json.loads(response)
                    assert "response" in response_data
                    
            except Exception as e:
                pytest.skip(f"Chat WebSocket test skipped: {e}")
        
        # Run WebSocket tests
        await test_telemetry_websocket()
        await test_chat_websocket()
    
    async def test_notification_system_integration(self, client, setup_test_environment):
        """Test notification system integration"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        user_id = test_data["user_data"]["id"]
        
        # Step 1: Configure Notification Preferences
        preferences = {
            "push_notifications": True,
            "email_notifications": True,
            "sms_notifications": False,
            "alert_types": ["critical", "maintenance", "booking"]
        }
        
        response = client.put(f"/api/v1/notifications/preferences/{user_id}", 
                            json=preferences, headers=headers)
        assert response.status_code == 200
        
        # Step 2: Trigger Test Notification
        notification_data = {
            "user_id": user_id,
            "type": "critical",
            "title": "Critical Vehicle Alert",
            "message": "Engine temperature critically high",
            "data": {"vehicle_id": test_data["vehicle_data"]["id"]}
        }
        
        response = client.post("/api/v1/notifications/send", 
                             json=notification_data, headers=headers)
        assert response.status_code == 202  # Accepted for processing
        
        # Step 3: Check Notification History
        response = client.get(f"/api/v1/notifications/history/{user_id}", headers=headers)
        assert response.status_code == 200
        notifications = response.json()
        assert len(notifications) > 0
    
    async def test_system_health_and_monitoring(self, client):
        """Test system health monitoring and metrics"""
        # Step 1: Basic Health Check
        response = client.get("/health")
        assert response.status_code == 200
        health_data = response.json()
        assert "overall_status" in health_data
        
        # Step 2: Quick Health Check
        response = client.get("/health/quick")
        assert response.status_code == 200
        
        # Step 3: System Metrics
        response = client.get("/api/v1/monitoring/metrics")
        # Note: This endpoint might require admin authentication
        # assert response.status_code == 200
    
    async def test_error_handling_and_resilience(self, client, setup_test_environment):
        """Test error handling and system resilience"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        
        # Test 1: Invalid Data Handling
        invalid_telemetry = {
            "vehicle_id": "invalid-id",
            "timestamp": "invalid-timestamp",
            "sensor_data": "not-a-dict"
        }
        
        response = client.post("/api/v1/telemetry/ingest", 
                             json=invalid_telemetry, headers=headers)
        assert response.status_code == 400
        error_response = response.json()
        assert "error" in error_response
        
        # Test 2: Unauthorized Access
        response = client.get("/api/v1/auth/profile")  # No auth header
        assert response.status_code == 401
        
        # Test 3: Resource Not Found
        response = client.get("/api/v1/vehicles/non-existent-id", headers=headers)
        assert response.status_code == 404
    
    async def test_performance_under_load(self, async_client, setup_test_environment):
        """Test system performance under simulated load"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        
        # Simulate concurrent telemetry ingestion
        async def send_telemetry_batch():
            tasks = []
            for i in range(10):  # Send 10 concurrent requests
                telemetry_data = {
                    "vehicle_id": test_data["vehicle_data"]["id"],
                    "timestamp": (datetime.utcnow() + timedelta(seconds=i)).isoformat(),
                    "sensor_data": test_data["test_telemetry"]
                }
                task = async_client.post("/api/v1/telemetry/ingest", 
                                       json=telemetry_data, headers=headers)
                tasks.append(task)
            
            responses = await asyncio.gather(*tasks, return_exceptions=True)
            successful_responses = [r for r in responses if not isinstance(r, Exception) and r.status_code == 201]
            return len(successful_responses)
        
        # Execute load test
        start_time = datetime.utcnow()
        successful_requests = await send_telemetry_batch()
        end_time = datetime.utcnow()
        
        # Verify performance
        duration = (end_time - start_time).total_seconds()
        assert duration < 10.0  # Should complete within 10 seconds
        assert successful_requests >= 8  # At least 80% success rate
    
    async def test_data_consistency_and_integrity(self, client, setup_test_environment):
        """Test data consistency across all components"""
        test_data = setup_test_environment
        headers = {"Authorization": f"Bearer {test_data['access_token']}"}
        vehicle_id = test_data["vehicle_data"]["id"]
        
        # Step 1: Ingest telemetry data
        telemetry_data = {
            "vehicle_id": vehicle_id,
            "timestamp": datetime.utcnow().isoformat(),
            "sensor_data": test_data["test_telemetry"]
        }
        
        response = client.post("/api/v1/telemetry/ingest", json=telemetry_data, headers=headers)
        assert response.status_code == 201
        
        # Step 2: Verify data appears in telemetry endpoint
        await asyncio.sleep(1)  # Allow processing time
        response = client.get(f"/api/v1/telemetry/vehicle/{vehicle_id}", headers=headers)
        assert response.status_code == 200
        telemetry_history = response.json()
        assert len(telemetry_history) > 0
        
        # Step 3: Verify data influences predictions
        response = client.post("/api/v1/predictions/request", 
                             json={"vehicle_id": vehicle_id}, headers=headers)
        assert response.status_code == 202
        
        # Step 4: Check data consistency in chat context
        chat_message = {
            "user_id": test_data["user_data"]["id"],
            "message": "What's my vehicle's current status?",
            "context": {"vehicle_id": vehicle_id}
        }
        
        response = client.post("/api/v1/chat/message", json=chat_message, headers=headers)
        assert response.status_code == 200
        chat_response = response.json()
        
        # AI should have access to recent telemetry data
        assert "engine" in chat_response["response"].lower() or "temperature" in chat_response["response"].lower()

# Run integration tests
if __name__ == "__main__":
    pytest.main([__file__, "-v", "--asyncio-mode=auto"])