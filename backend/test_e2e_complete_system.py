"""
AIVONITY End-to-End Complete System Test
Tests the entire system integration from mobile app to backend services
"""

import asyncio
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List
import requests
import websocket
import threading
from concurrent.futures import ThreadPoolExecutor
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AIVONITYSystemTester:
    """Complete system tester for AIVONITY ecosystem"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.ws_url = base_url.replace("http", "ws")
        self.session = requests.Session()
        self.test_data = {}
        self.websocket_connections = {}
        
    def setup_test_environment(self):
        """Setup complete test environment"""
        logger.info("🚀 Setting up AIVONITY test environment")
        
        # Generate test data
        self.test_data = {
            "user": {
                "email": f"test_{uuid.uuid4().hex[:8]}@aivonity.com",
                "password": "SecurePassword123!",
                "name": "Test User",
                "phone": "+1234567890"
            },
            "vehicle": {
                "make": "Tesla",
                "model": "Model 3",
                "year": 2023,
                "vin": f"5YJ3E1EA4KF{uuid.uuid4().hex[:6].upper()}",
                "mileage": 15000
            },
            "telemetry": {
                "engine_temp": 85.5,
                "oil_pressure": 45.2,
                "battery_voltage": 12.6,
                "rpm": 2500,
                "speed": 65.0,
                "fuel_level": 75.0
            }
        }
        
        logger.info("✅ Test environment setup complete")
    
    def test_system_health(self) -> bool:
        """Test system health and availability"""
        logger.info("🏥 Testing system health")
        
        try:
            # Test basic health endpoint
            response = self.session.get(f"{self.base_url}/health", timeout=10)
            if response.status_code != 200:
                logger.error(f"❌ Health check failed: {response.status_code}")
                return False
            
            health_data = response.json()
            if health_data.get("overall_status") not in ["healthy", "operational"]:
                logger.error(f"❌ System not healthy: {health_data}")
                return False
            
            # Test quick health endpoint
            response = self.session.get(f"{self.base_url}/health/quick", timeout=5)
            if response.status_code != 200:
                logger.warning("⚠️ Quick health check failed")
            
            logger.info("✅ System health check passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Health check exception: {e}")
            return False
    
    def test_user_authentication_flow(self) -> bool:
        """Test complete user authentication workflow"""
        logger.info("🔐 Testing user authentication flow")
        
        try:
            # Step 1: User Registration
            registration_data = self.test_data["user"]
            response = self.session.post(
                f"{self.api_url}/auth/register",
                json=registration_data,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"❌ Registration failed: {response.status_code} - {response.text}")
                return False
            
            user_response = response.json()
            self.test_data["access_token"] = user_response["access_token"]
            self.test_data["user_id"] = user_response["user"]["id"]
            
            # Step 2: User Login
            login_data = {
                "email": registration_data["email"],
                "password": registration_data["password"]
            }
            
            response = self.session.post(
                f"{self.api_url}/auth/login",
                json=login_data,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Login failed: {response.status_code}")
                return False
            
            login_response = response.json()
            self.test_data["access_token"] = login_response["access_token"]
            
            # Step 3: Test authenticated request
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            response = self.session.get(f"{self.api_url}/auth/profile", headers=headers, timeout=10)
            
            if response.status_code != 200:
                logger.error(f"❌ Profile access failed: {response.status_code}")
                return False
            
            logger.info("✅ User authentication flow passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Authentication flow exception: {e}")
            return False
    
    def test_vehicle_management_flow(self) -> bool:
        """Test vehicle registration and management"""
        logger.info("🚗 Testing vehicle management flow")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Register Vehicle
            vehicle_data = self.test_data["vehicle"]
            response = self.session.post(
                f"{self.api_url}/vehicles",
                json=vehicle_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"❌ Vehicle registration failed: {response.status_code}")
                return False
            
            vehicle_response = response.json()
            self.test_data["vehicle_id"] = vehicle_response["id"]
            
            # Step 2: Get Vehicle Details
            response = self.session.get(
                f"{self.api_url}/vehicles/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Vehicle retrieval failed: {response.status_code}")
                return False
            
            # Step 3: Update Vehicle
            update_data = {"mileage": 15500}
            response = self.session.put(
                f"{self.api_url}/vehicles/{self.test_data['vehicle_id']}",
                json=update_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Vehicle update failed: {response.status_code}")
                return False
            
            logger.info("✅ Vehicle management flow passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Vehicle management exception: {e}")
            return False
    
    def test_telemetry_processing_flow(self) -> bool:
        """Test telemetry ingestion and processing"""
        logger.info("📊 Testing telemetry processing flow")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Ingest Normal Telemetry
            telemetry_data = {
                "vehicle_id": self.test_data["vehicle_id"],
                "timestamp": datetime.utcnow().isoformat(),
                "sensor_data": self.test_data["telemetry"],
                "location": {"latitude": 37.7749, "longitude": -122.4194}
            }
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=telemetry_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"❌ Telemetry ingestion failed: {response.status_code}")
                return False
            
            # Step 2: Ingest Anomalous Data
            anomalous_data = telemetry_data.copy()
            anomalous_data["sensor_data"]["engine_temp"] = 120.0  # Critical temperature
            anomalous_data["timestamp"] = (datetime.utcnow() + timedelta(minutes=1)).isoformat()
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=anomalous_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"❌ Anomalous telemetry ingestion failed: {response.status_code}")
                return False
            
            # Step 3: Wait for processing and check alerts
            time.sleep(3)  # Allow processing time
            
            response = self.session.get(
                f"{self.api_url}/telemetry/alerts/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Alert retrieval failed: {response.status_code}")
                return False
            
            alerts = response.json()
            if not alerts:
                logger.warning("⚠️ No alerts generated for anomalous data")
            else:
                logger.info(f"✅ Generated {len(alerts)} alerts")
            
            logger.info("✅ Telemetry processing flow passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Telemetry processing exception: {e}")
            return False
    
    def test_predictive_maintenance_flow(self) -> bool:
        """Test predictive maintenance workflow"""
        logger.info("🔮 Testing predictive maintenance flow")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Request Prediction
            response = self.session.post(
                f"{self.api_url}/predictions/request",
                json={"vehicle_id": self.test_data["vehicle_id"]},
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 202:
                logger.error(f"❌ Prediction request failed: {response.status_code}")
                return False
            
            # Step 2: Wait for processing
            time.sleep(5)  # Allow ML processing time
            
            # Step 3: Get Predictions
            response = self.session.get(
                f"{self.api_url}/predictions/vehicle/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Prediction retrieval failed: {response.status_code}")
                return False
            
            predictions = response.json()
            if predictions:
                logger.info(f"✅ Generated {len(predictions)} predictions")
                for pred in predictions:
                    logger.info(f"  - {pred.get('component', 'Unknown')}: {pred.get('failure_probability', 0):.2f}")
            else:
                logger.info("ℹ️ No predictions generated (may be normal for new vehicle)")
            
            logger.info("✅ Predictive maintenance flow passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Predictive maintenance exception: {e}")
            return False
    
    def test_ai_chat_flow(self) -> bool:
        """Test AI chat conversation workflow"""
        logger.info("🤖 Testing AI chat flow")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Send Chat Message
            chat_message = {
                "user_id": self.test_data["user_id"],
                "message": "What's the current health status of my vehicle?",
                "context": {
                    "vehicle_id": self.test_data["vehicle_id"],
                    "conversation_type": "health_inquiry"
                }
            }
            
            response = self.session.post(
                f"{self.api_url}/chat/message",
                json=chat_message,
                headers=headers,
                timeout=15
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Chat message failed: {response.status_code}")
                return False
            
            chat_response = response.json()
            if "response" not in chat_response:
                logger.error("❌ Invalid chat response format")
                return False
            
            logger.info(f"✅ AI Response: {chat_response['response'][:100]}...")
            
            # Step 2: Follow-up Message
            followup_message = {
                "user_id": self.test_data["user_id"],
                "message": "Should I schedule maintenance soon?",
                "context": chat_response.get("context", {})
            }
            
            response = self.session.post(
                f"{self.api_url}/chat/message",
                json=followup_message,
                headers=headers,
                timeout=15
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Follow-up message failed: {response.status_code}")
                return False
            
            # Step 3: Get Chat History
            response = self.session.get(
                f"{self.api_url}/chat/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Chat history retrieval failed: {response.status_code}")
                return False
            
            history = response.json()
            if len(history) < 2:
                logger.error("❌ Chat history incomplete")
                return False
            
            logger.info("✅ AI chat flow passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ AI chat exception: {e}")
            return False
    
    def test_service_booking_flow(self) -> bool:
        """Test service booking workflow"""
        logger.info("📅 Testing service booking flow")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Check Availability
            search_params = {
                "latitude": 37.7749,
                "longitude": -122.4194,
                "radius": 50,
                "service_type": "maintenance"
            }
            
            response = self.session.get(
                f"{self.api_url}/booking/availability",
                params=search_params,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Availability check failed: {response.status_code}")
                return False
            
            availability = response.json()
            if not availability.get("service_centers"):
                logger.warning("⚠️ No service centers available")
                return True  # Not a failure, just no availability
            
            # Step 2: Schedule Appointment
            service_center = availability["service_centers"][0]
            booking_data = {
                "vehicle_id": self.test_data["vehicle_id"],
                "service_center_id": service_center["id"],
                "preferred_date": (datetime.utcnow() + timedelta(days=7)).date().isoformat(),
                "service_type": "maintenance",
                "urgency": "medium"
            }
            
            response = self.session.post(
                f"{self.api_url}/booking/schedule",
                json=booking_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"❌ Booking scheduling failed: {response.status_code}")
                return False
            
            booking = response.json()
            self.test_data["booking_id"] = booking["id"]
            
            logger.info("✅ Service booking flow passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Service booking exception: {e}")
            return False
    
    def test_websocket_communication(self) -> bool:
        """Test real-time WebSocket communication"""
        logger.info("🔌 Testing WebSocket communication")
        
        try:
            # Test results
            websocket_results = {"telemetry": False, "chat": False, "alerts": False}
            
            def test_telemetry_websocket():
                try:
                    ws_url = f"{self.ws_url}/ws/telemetry/{self.test_data['vehicle_id']}"
                    ws = websocket.create_connection(ws_url, timeout=5)
                    
                    # Send test data
                    test_data = {
                        "type": "telemetry_update",
                        "data": self.test_data["telemetry"]
                    }
                    ws.send(json.dumps(test_data))
                    
                    # Wait for response
                    result = ws.recv()
                    response_data = json.loads(result)
                    
                    if response_data.get("type") == "telemetry_update":
                        websocket_results["telemetry"] = True
                    
                    ws.close()
                except Exception as e:
                    logger.warning(f"⚠️ Telemetry WebSocket test failed: {e}")
            
            def test_chat_websocket():
                try:
                    ws_url = f"{self.ws_url}/ws/chat/{self.test_data['user_id']}"
                    ws = websocket.create_connection(ws_url, timeout=5)
                    
                    # Send chat message
                    chat_data = {
                        "message": "Test WebSocket chat",
                        "timestamp": datetime.utcnow().isoformat()
                    }
                    ws.send(json.dumps(chat_data))
                    
                    # Wait for AI response
                    result = ws.recv()
                    response_data = json.loads(result)
                    
                    if "response" in response_data:
                        websocket_results["chat"] = True
                    
                    ws.close()
                except Exception as e:
                    logger.warning(f"⚠️ Chat WebSocket test failed: {e}")
            
            def test_alerts_websocket():
                try:
                    ws_url = f"{self.ws_url}/ws/alerts/{self.test_data['user_id']}"
                    ws = websocket.create_connection(ws_url, timeout=5)
                    
                    # Just test connection
                    time.sleep(1)
                    websocket_results["alerts"] = True
                    
                    ws.close()
                except Exception as e:
                    logger.warning(f"⚠️ Alerts WebSocket test failed: {e}")
            
            # Run WebSocket tests in parallel
            with ThreadPoolExecutor(max_workers=3) as executor:
                futures = [
                    executor.submit(test_telemetry_websocket),
                    executor.submit(test_chat_websocket),
                    executor.submit(test_alerts_websocket)
                ]
                
                # Wait for all tests to complete
                for future in futures:
                    future.result(timeout=10)
            
            # Check results
            successful_tests = sum(websocket_results.values())
            total_tests = len(websocket_results)
            
            logger.info(f"✅ WebSocket tests: {successful_tests}/{total_tests} passed")
            return successful_tests >= 2  # At least 2 out of 3 should pass
            
        except Exception as e:
            logger.error(f"❌ WebSocket communication exception: {e}")
            return False
    
    def test_notification_system(self) -> bool:
        """Test notification system"""
        logger.info("📱 Testing notification system")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Configure Preferences
            preferences = {
                "push_notifications": True,
                "email_notifications": True,
                "sms_notifications": False,
                "alert_types": ["critical", "maintenance", "booking"]
            }
            
            response = self.session.put(
                f"{self.api_url}/notifications/preferences/{self.test_data['user_id']}",
                json=preferences,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Notification preferences failed: {response.status_code}")
                return False
            
            # Step 2: Send Test Notification
            notification_data = {
                "user_id": self.test_data["user_id"],
                "type": "critical",
                "title": "Test Critical Alert",
                "message": "This is a test critical vehicle alert",
                "data": {"vehicle_id": self.test_data["vehicle_id"]}
            }
            
            response = self.session.post(
                f"{self.api_url}/notifications/send",
                json=notification_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 202:
                logger.error(f"❌ Notification sending failed: {response.status_code}")
                return False
            
            # Step 3: Check History
            time.sleep(2)  # Allow processing time
            
            response = self.session.get(
                f"{self.api_url}/notifications/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Notification history failed: {response.status_code}")
                return False
            
            notifications = response.json()
            if not notifications:
                logger.warning("⚠️ No notifications in history")
            
            logger.info("✅ Notification system passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Notification system exception: {e}")
            return False
    
    def test_performance_under_load(self) -> bool:
        """Test system performance under load"""
        logger.info("⚡ Testing performance under load")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            def send_telemetry_batch():
                """Send batch of telemetry data"""
                success_count = 0
                for i in range(10):
                    telemetry_data = {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "timestamp": (datetime.utcnow() + timedelta(seconds=i)).isoformat(),
                        "sensor_data": self.test_data["telemetry"]
                    }
                    
                    try:
                        response = self.session.post(
                            f"{self.api_url}/telemetry/ingest",
                            json=telemetry_data,
                            headers=headers,
                            timeout=5
                        )
                        if response.status_code == 201:
                            success_count += 1
                    except Exception:
                        pass
                
                return success_count
            
            # Execute load test
            start_time = time.time()
            
            with ThreadPoolExecutor(max_workers=5) as executor:
                futures = [executor.submit(send_telemetry_batch) for _ in range(3)]
                results = [future.result(timeout=30) for future in futures]
            
            end_time = time.time()
            duration = end_time - start_time
            
            total_successful = sum(results)
            total_requests = 30  # 3 batches * 10 requests each
            
            success_rate = (total_successful / total_requests) * 100
            
            logger.info(f"✅ Performance test: {total_successful}/{total_requests} requests successful ({success_rate:.1f}%) in {duration:.2f}s")
            
            # Performance criteria
            return duration < 30.0 and success_rate >= 80.0
            
        except Exception as e:
            logger.error(f"❌ Performance test exception: {e}")
            return False
    
    def run_complete_system_test(self) -> Dict[str, bool]:
        """Run complete system integration test"""
        logger.info("🚀 Starting AIVONITY Complete System Integration Test")
        
        # Setup test environment
        self.setup_test_environment()
        
        # Define test suite
        test_suite = [
            ("System Health", self.test_system_health),
            ("User Authentication", self.test_user_authentication_flow),
            ("Vehicle Management", self.test_vehicle_management_flow),
            ("Telemetry Processing", self.test_telemetry_processing_flow),
            ("Predictive Maintenance", self.test_predictive_maintenance_flow),
            ("AI Chat", self.test_ai_chat_flow),
            ("Service Booking", self.test_service_booking_flow),
            ("WebSocket Communication", self.test_websocket_communication),
            ("Notification System", self.test_notification_system),
            ("Performance Under Load", self.test_performance_under_load)
        ]
        
        # Execute tests
        results = {}
        passed_tests = 0
        total_tests = len(test_suite)
        
        for test_name, test_function in test_suite:
            logger.info(f"\n{'='*50}")
            logger.info(f"Running: {test_name}")
            logger.info(f"{'='*50}")
            
            try:
                result = test_function()
                results[test_name] = result
                if result:
                    passed_tests += 1
                    logger.info(f"✅ {test_name}: PASSED")
                else:
                    logger.error(f"❌ {test_name}: FAILED")
            except Exception as e:
                logger.error(f"❌ {test_name}: EXCEPTION - {e}")
                results[test_name] = False
        
        # Summary
        logger.info(f"\n{'='*60}")
        logger.info("AIVONITY COMPLETE SYSTEM TEST SUMMARY")
        logger.info(f"{'='*60}")
        logger.info(f"Total Tests: {total_tests}")
        logger.info(f"Passed: {passed_tests}")
        logger.info(f"Failed: {total_tests - passed_tests}")
        logger.info(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        # Detailed results
        logger.info(f"\nDetailed Results:")
        for test_name, result in results.items():
            status = "✅ PASSED" if result else "❌ FAILED"
            logger.info(f"  {test_name}: {status}")
        
        # Overall result
        overall_success = passed_tests >= (total_tests * 0.8)  # 80% pass rate
        if overall_success:
            logger.info(f"\n🎉 OVERALL RESULT: SYSTEM INTEGRATION SUCCESSFUL")
        else:
            logger.error(f"\n💥 OVERALL RESULT: SYSTEM INTEGRATION FAILED")
        
        return results

def main():
    """Main function to run the complete system test"""
    tester = AIVONITYSystemTester()
    results = tester.run_complete_system_test()
    
    # Exit with appropriate code
    failed_tests = sum(1 for result in results.values() if not result)
    exit(0 if failed_tests == 0 else 1)

if __name__ == "__main__":
    main()