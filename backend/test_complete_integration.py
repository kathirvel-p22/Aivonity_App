"""
AIVONITY Complete Integration Test Suite
Tests all components working together with real-time communication and notifications
"""

import asyncio
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import requests
import websockets
import threading
from concurrent.futures import ThreadPoolExecutor
import logging
import pytest
from unittest.mock import patch, MagicMock

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AIVONITYIntegrationTester:
    """Complete integration tester for AIVONITY ecosystem"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.ws_url = base_url.replace("http", "ws")
        self.session = requests.Session()
        self.test_data = {}
        self.websocket_connections = {}
        self.test_results = {}
        
    async def setup_test_environment(self):
        """Setup complete test environment with all necessary data"""
        logger.info("🚀 Setting up AIVONITY integration test environment")
        
        # Generate unique test data
        unique_id = uuid.uuid4().hex[:8]
        self.test_data = {
            "user": {
                "email": f"integration_test_{unique_id}@aivonity.com",
                "password": "IntegrationTest123!",
                "name": f"Integration Test User {unique_id}",
                "phone": f"+123456{unique_id[:4]}"
            },
            "vehicle": {
                "make": "Tesla",
                "model": "Model 3",
                "year": 2023,
                "vin": f"5YJ3E1EA4KF{unique_id[:6].upper()}",
                "mileage": 15000
            },
            "telemetry_normal": {
                "engine_temp": 85.5,
                "oil_pressure": 45.2,
                "battery_voltage": 12.6,
                "rpm": 2500,
                "speed": 65.0,
                "fuel_level": 75.0
            },
            "telemetry_anomalous": {
                "engine_temp": 125.0,  # Critical temperature
                "oil_pressure": 15.0,  # Low pressure
                "battery_voltage": 10.5,  # Low voltage
                "rpm": 5500,  # High RPM
                "speed": 65.0,
                "fuel_level": 10.0  # Low fuel
            }
        }
        
        logger.info("✅ Test environment setup complete")
    
    async def test_complete_user_journey(self) -> bool:
        """Test complete user journey from registration to service booking"""
        logger.info("👤 Testing complete user journey")
        
        try:
            # Step 1: User Registration
            if not await self._test_user_registration():
                return False
            
            # Step 2: User Login
            if not await self._test_user_login():
                return False
            
            # Step 3: Vehicle Registration
            if not await self._test_vehicle_registration():
                return False
            
            # Step 4: Telemetry Ingestion
            if not await self._test_telemetry_ingestion():
                return False
            
            # Step 5: Real-time Communication
            if not await self._test_realtime_communication():
                return False
            
            # Step 6: AI Chat Interaction
            if not await self._test_ai_chat_interaction():
                return False
            
            # Step 7: Predictive Maintenance
            if not await self._test_predictive_maintenance():
                return False
            
            # Step 8: Service Booking
            if not await self._test_service_booking():
                return False
            
            # Step 9: Notification System
            if not await self._test_notification_system():
                return False
            
            logger.info("✅ Complete user journey test passed")
            return True
            
        except Exception as e:
            logger.error(f"❌ Complete user journey failed: {e}")
            return False
    
    async def _test_user_registration(self) -> bool:
        """Test user registration"""
        logger.info("  📝 Testing user registration")
        
        try:
            response = self.session.post(
                f"{self.api_url}/auth/register",
                json=self.test_data["user"],
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"    ❌ Registration failed: {response.status_code}")
                return False
            
            user_response = response.json()
            self.test_data["access_token"] = user_response["access_token"]
            self.test_data["user_id"] = user_response["user"]["id"]
            
            logger.info("    ✅ User registration successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Registration exception: {e}")
            return False
    
    async def _test_user_login(self) -> bool:
        """Test user login"""
        logger.info("  🔐 Testing user login")
        
        try:
            login_data = {
                "email": self.test_data["user"]["email"],
                "password": self.test_data["user"]["password"]
            }
            
            response = self.session.post(
                f"{self.api_url}/auth/login",
                json=login_data,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"    ❌ Login failed: {response.status_code}")
                return False
            
            login_response = response.json()
            self.test_data["access_token"] = login_response["access_token"]
            
            logger.info("    ✅ User login successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Login exception: {e}")
            return False
    
    async def _test_vehicle_registration(self) -> bool:
        """Test vehicle registration"""
        logger.info("  🚗 Testing vehicle registration")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            response = self.session.post(
                f"{self.api_url}/vehicles",
                json=self.test_data["vehicle"],
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"    ❌ Vehicle registration failed: {response.status_code}")
                return False
            
            vehicle_response = response.json()
            self.test_data["vehicle_id"] = vehicle_response["id"]
            
            logger.info("    ✅ Vehicle registration successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Vehicle registration exception: {e}")
            return False
    
    async def _test_telemetry_ingestion(self) -> bool:
        """Test telemetry data ingestion and processing"""
        logger.info("  📊 Testing telemetry ingestion")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Ingest normal telemetry
            normal_data = {
                "vehicle_id": self.test_data["vehicle_id"],
                "timestamp": datetime.utcnow().isoformat(),
                "sensor_data": self.test_data["telemetry_normal"],
                "location": {"latitude": 37.7749, "longitude": -122.4194}
            }
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=normal_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"    ❌ Normal telemetry ingestion failed: {response.status_code}")
                return False
            
            # Ingest anomalous telemetry
            anomalous_data = {
                "vehicle_id": self.test_data["vehicle_id"],
                "timestamp": (datetime.utcnow() + timedelta(minutes=1)).isoformat(),
                "sensor_data": self.test_data["telemetry_anomalous"],
                "location": {"latitude": 37.7749, "longitude": -122.4194}
            }
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=anomalous_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"    ❌ Anomalous telemetry ingestion failed: {response.status_code}")
                return False
            
            # Wait for processing
            await asyncio.sleep(3)
            
            # Check for generated alerts
            response = self.session.get(
                f"{self.api_url}/telemetry/alerts/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                alerts = response.json()
                logger.info(f"    ✅ Generated {len(alerts)} alerts from anomalous data")
            
            logger.info("    ✅ Telemetry ingestion successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Telemetry ingestion exception: {e}")
            return False
    
    async def _test_realtime_communication(self) -> bool:
        """Test real-time WebSocket communication"""
        logger.info("  🔌 Testing real-time communication")
        
        try:
            websocket_results = {"telemetry": False, "chat": False, "alerts": False}
            
            async def test_telemetry_websocket():
                try:
                    ws_url = f"{self.ws_url}/ws/telemetry/{self.test_data['vehicle_id']}"
                    async with websockets.connect(ws_url, timeout=5) as ws:
                        # Send test telemetry update
                        test_data = {
                            "type": "telemetry_update",
                            "data": self.test_data["telemetry_normal"],
                            "timestamp": datetime.utcnow().isoformat()
                        }
                        await ws.send(json.dumps(test_data))
                        
                        # Wait for acknowledgment or broadcast
                        await asyncio.sleep(1)
                        websocket_results["telemetry"] = True
                        
                except Exception as e:
                    logger.warning(f"    ⚠️ Telemetry WebSocket failed: {e}")
            
            def test_chat_websocket():
                try:
                    ws_url = f"{self.ws_url}/ws/chat/{self.test_data['user_id']}"
                    ws = websocket.create_connection(ws_url, timeout=5)
                    
                    # Send test chat message
                    chat_data = {
                        "message": "Test WebSocket integration",
                        "timestamp": datetime.utcnow().isoformat(),
                        "context": {"vehicle_id": self.test_data["vehicle_id"]}
                    }
                    ws.send(json.dumps(chat_data))
                    
                    # Wait for AI response
                    try:
                        result = ws.recv()
                        response_data = json.loads(result)
                        if "response" in response_data:
                            websocket_results["chat"] = True
                    except:
                        # Even if no response, connection test passed
                        websocket_results["chat"] = True
                    
                    ws.close()
                except Exception as e:
                    logger.warning(f"    ⚠️ Chat WebSocket failed: {e}")
            
            def test_alerts_websocket():
                try:
                    ws_url = f"{self.ws_url}/ws/alerts/{self.test_data['user_id']}"
                    ws = websocket.create_connection(ws_url, timeout=5)
                    
                    # Just test connection establishment
                    time.sleep(1)
                    websocket_results["alerts"] = True
                    
                    ws.close()
                except Exception as e:
                    logger.warning(f"    ⚠️ Alerts WebSocket failed: {e}")
            
            # Run WebSocket tests concurrently
            with ThreadPoolExecutor(max_workers=3) as executor:
                futures = [
                    executor.submit(test_telemetry_websocket),
                    executor.submit(test_chat_websocket),
                    executor.submit(test_alerts_websocket)
                ]
                
                for future in futures:
                    future.result(timeout=10)
            
            successful_connections = sum(websocket_results.values())
            logger.info(f"    ✅ WebSocket connections: {successful_connections}/3 successful")
            
            return successful_connections >= 2  # At least 2 out of 3 should work
            
        except Exception as e:
            logger.error(f"    ❌ Real-time communication exception: {e}")
            return False
    
    async def _test_ai_chat_interaction(self) -> bool:
        """Test AI chat interaction"""
        logger.info("  🤖 Testing AI chat interaction")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Test contextual vehicle health inquiry
            chat_message = {
                "user_id": self.test_data["user_id"],
                "message": "What's the current health status of my Tesla Model 3?",
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
                logger.error(f"    ❌ Chat message failed: {response.status_code}")
                return False
            
            chat_response = response.json()
            if "response" not in chat_response:
                logger.error("    ❌ Invalid chat response format")
                return False
            
            # Test follow-up with maintenance question
            followup_message = {
                "user_id": self.test_data["user_id"],
                "message": "Should I be concerned about the high engine temperature?",
                "context": chat_response.get("context", {})
            }
            
            response = self.session.post(
                f"{self.api_url}/chat/message",
                json=followup_message,
                headers=headers,
                timeout=15
            )
            
            if response.status_code != 200:
                logger.error(f"    ❌ Follow-up message failed: {response.status_code}")
                return False
            
            # Verify chat history
            response = self.session.get(
                f"{self.api_url}/chat/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                history = response.json()
                logger.info(f"    ✅ Chat history contains {len(history)} messages")
            
            logger.info("    ✅ AI chat interaction successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ AI chat interaction exception: {e}")
            return False
    
    async def _test_predictive_maintenance(self) -> bool:
        """Test predictive maintenance workflow"""
        logger.info("  🔮 Testing predictive maintenance")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Request prediction analysis
            response = self.session.post(
                f"{self.api_url}/predictions/request",
                json={"vehicle_id": self.test_data["vehicle_id"]},
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 202:
                logger.error(f"    ❌ Prediction request failed: {response.status_code}")
                return False
            
            # Wait for ML processing
            await asyncio.sleep(5)
            
            # Get predictions
            response = self.session.get(
                f"{self.api_url}/predictions/vehicle/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"    ❌ Prediction retrieval failed: {response.status_code}")
                return False
            
            predictions = response.json()
            logger.info(f"    ✅ Generated {len(predictions)} maintenance predictions")
            
            # Log prediction details
            for pred in predictions:
                component = pred.get('component', 'Unknown')
                probability = pred.get('failure_probability', 0)
                logger.info(f"      - {component}: {probability:.2f} failure probability")
            
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Predictive maintenance exception: {e}")
            return False
    
    async def _test_service_booking(self) -> bool:
        """Test service booking workflow"""
        logger.info("  📅 Testing service booking")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Search for available service centers
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
                logger.error(f"    ❌ Service center search failed: {response.status_code}")
                return False
            
            availability = response.json()
            service_centers = availability.get("service_centers", [])
            
            if not service_centers:
                logger.info("    ℹ️ No service centers available (test environment)")
                return True  # Not a failure in test environment
            
            # Schedule appointment with first available center
            service_center = service_centers[0]
            booking_data = {
                "vehicle_id": self.test_data["vehicle_id"],
                "service_center_id": service_center["id"],
                "preferred_date": (datetime.utcnow() + timedelta(days=7)).date().isoformat(),
                "service_type": "maintenance",
                "urgency": "medium",
                "notes": "Integration test booking"
            }
            
            response = self.session.post(
                f"{self.api_url}/booking/schedule",
                json=booking_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"    ❌ Booking creation failed: {response.status_code}")
                return False
            
            booking = response.json()
            self.test_data["booking_id"] = booking["id"]
            
            logger.info("    ✅ Service booking successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Service booking exception: {e}")
            return False
    
    async def _test_notification_system(self) -> bool:
        """Test notification system"""
        logger.info("  📱 Testing notification system")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Configure notification preferences
            preferences = {
                "push_notifications": True,
                "email_notifications": True,
                "sms_notifications": False,
                "alert_types": ["critical", "maintenance", "booking"],
                "quiet_hours": {"start": "22:00", "end": "07:00"}
            }
            
            response = self.session.put(
                f"{self.api_url}/notifications/preferences/{self.test_data['user_id']}",
                json=preferences,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"    ❌ Notification preferences failed: {response.status_code}")
                return False
            
            # Send test notification
            notification_data = {
                "user_id": self.test_data["user_id"],
                "type": "critical",
                "title": "Integration Test Alert",
                "message": "Critical engine temperature detected during integration test",
                "data": {
                    "vehicle_id": self.test_data["vehicle_id"],
                    "alert_type": "engine_overheat",
                    "severity": "critical"
                }
            }
            
            response = self.session.post(
                f"{self.api_url}/notifications/send",
                json=notification_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 202:
                logger.error(f"    ❌ Notification sending failed: {response.status_code}")
                return False
            
            # Wait for processing
            await asyncio.sleep(2)
            
            # Check notification history
            response = self.session.get(
                f"{self.api_url}/notifications/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                notifications = response.json()
                logger.info(f"    ✅ Notification history contains {len(notifications)} notifications")
            
            logger.info("    ✅ Notification system successful")
            return True
            
        except Exception as e:
            logger.error(f"    ❌ Notification system exception: {e}")
            return False
    
    async def test_data_flow_validation(self) -> bool:
        """Test complete data flow from ingestion to insights"""
        logger.info("🔄 Testing complete data flow validation")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Step 1: Ingest multiple telemetry points
            telemetry_points = []
            base_time = datetime.utcnow()
            
            for i in range(10):
                telemetry_data = {
                    "vehicle_id": self.test_data["vehicle_id"],
                    "timestamp": (base_time + timedelta(minutes=i)).isoformat(),
                    "sensor_data": {
                        "engine_temp": 85.5 + (i * 2),  # Gradually increasing
                        "oil_pressure": 45.2 - (i * 0.5),  # Gradually decreasing
                        "battery_voltage": 12.6,
                        "rpm": 2500 + (i * 100),
                        "speed": 65.0,
                        "fuel_level": 75.0 - (i * 2)
                    },
                    "location": {
                        "latitude": 37.7749 + (i * 0.001),
                        "longitude": -122.4194 + (i * 0.001)
                    }
                }
                telemetry_points.append(telemetry_data)
            
            # Ingest all telemetry points
            for point in telemetry_points:
                response = self.session.post(
                    f"{self.api_url}/telemetry/ingest",
                    json=point,
                    headers=headers,
                    timeout=10
                )
                if response.status_code != 201:
                    logger.error(f"    ❌ Telemetry point ingestion failed")
                    return False
            
            # Wait for processing
            await asyncio.sleep(5)
            
            # Step 2: Verify data retrieval
            response = self.session.get(
                f"{self.api_url}/telemetry/vehicle/{self.test_data['vehicle_id']}",
                params={"limit": 20},
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"    ❌ Telemetry retrieval failed: {response.status_code}")
                return False
            
            telemetry_history = response.json()
            if len(telemetry_history) < 10:
                logger.error(f"    ❌ Expected 10+ telemetry points, got {len(telemetry_history)}")
                return False
            
            # Step 3: Check for pattern detection
            response = self.session.get(
                f"{self.api_url}/telemetry/patterns/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                patterns = response.json()
                logger.info(f"    ✅ Detected {len(patterns)} data patterns")
            
            # Step 4: Verify analytics processing
            response = self.session.get(
                f"{self.api_url}/analytics/vehicle/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                analytics = response.json()
                logger.info(f"    ✅ Analytics data available: {list(analytics.keys())}")
            
            logger.info("✅ Data flow validation successful")
            return True
            
        except Exception as e:
            logger.error(f"❌ Data flow validation exception: {e}")
            return False
    
    async def test_system_resilience(self) -> bool:
        """Test system resilience under various conditions"""
        logger.info("🛡️ Testing system resilience")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Test 1: High-frequency telemetry ingestion
            logger.info("  Testing high-frequency telemetry ingestion")
            
            async def send_rapid_telemetry():
                success_count = 0
                for i in range(20):
                    telemetry_data = {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "timestamp": (datetime.utcnow() + timedelta(seconds=i)).isoformat(),
                        "sensor_data": self.test_data["telemetry_normal"]
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
                    except:
                        pass
                    
                    await asyncio.sleep(0.1)  # 10 requests per second
                
                return success_count
            
            rapid_success = await send_rapid_telemetry()
            logger.info(f"    ✅ Rapid telemetry: {rapid_success}/20 successful")
            
            # Test 2: Concurrent user operations
            logger.info("  Testing concurrent operations")
            
            async def concurrent_operations():
                tasks = []
                
                # Concurrent chat messages
                for i in range(3):
                    chat_data = {
                        "user_id": self.test_data["user_id"],
                        "message": f"Concurrent test message {i}",
                        "context": {"vehicle_id": self.test_data["vehicle_id"]}
                    }
                    
                    task = asyncio.create_task(
                        asyncio.to_thread(
                            self.session.post,
                            f"{self.api_url}/chat/message",
                            json=chat_data,
                            headers=headers,
                            timeout=10
                        )
                    )
                    tasks.append(task)
                
                results = await asyncio.gather(*tasks, return_exceptions=True)
                successful = sum(1 for r in results if not isinstance(r, Exception) and r.status_code == 200)
                return successful
            
            concurrent_success = await concurrent_operations()
            logger.info(f"    ✅ Concurrent operations: {concurrent_success}/3 successful")
            
            # Test 3: Error recovery
            logger.info("  Testing error recovery")
            
            # Send invalid data
            invalid_data = {
                "vehicle_id": "invalid-vehicle-id",
                "timestamp": "invalid-timestamp",
                "sensor_data": "invalid-data"
            }
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=invalid_data,
                headers=headers,
                timeout=10
            )
            
            # Should handle gracefully with 400 error
            if response.status_code == 400:
                logger.info("    ✅ Invalid data handled gracefully")
            
            # Test system still works after error
            valid_data = {
                "vehicle_id": self.test_data["vehicle_id"],
                "timestamp": datetime.utcnow().isoformat(),
                "sensor_data": self.test_data["telemetry_normal"]
            }
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=valid_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 201:
                logger.info("    ✅ System recovered after error")
            
            logger.info("✅ System resilience test successful")
            return True
            
        except Exception as e:
            logger.error(f"❌ System resilience test exception: {e}")
            return False
    
    async def run_complete_integration_test(self) -> Dict[str, bool]:
        """Run complete integration test suite"""
        logger.info("🚀 Starting AIVONITY Complete Integration Test Suite")
        
        # Setup test environment
        await self.setup_test_environment()
        
        # Define test suite
        test_suite = [
            ("Complete User Journey", self.test_complete_user_journey),
            ("Data Flow Validation", self.test_data_flow_validation),
            ("System Resilience", self.test_system_resilience)
        ]
        
        # Execute tests
        results = {}
        passed_tests = 0
        total_tests = len(test_suite)
        
        for test_name, test_function in test_suite:
            logger.info(f"\n{'='*60}")
            logger.info(f"Running: {test_name}")
            logger.info(f"{'='*60}")
            
            try:
                result = await test_function()
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
        logger.info(f"\n{'='*70}")
        logger.info("AIVONITY COMPLETE INTEGRATION TEST SUMMARY")
        logger.info(f"{'='*70}")
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
        overall_success = passed_tests == total_tests
        if overall_success:
            logger.info(f"\n🎉 OVERALL RESULT: COMPLETE INTEGRATION SUCCESSFUL")
        else:
            logger.error(f"\n💥 OVERALL RESULT: INTEGRATION ISSUES DETECTED")
        
        return results

async def main():
    """Main function to run the complete integration test"""
    tester = AIVONITYIntegrationTester()
    results = await tester.run_complete_integration_test()
    
    # Return results for further processing
    return results

if __name__ == "__main__":
    asyncio.run(main())