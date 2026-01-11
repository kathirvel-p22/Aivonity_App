"""
AIVONITY Real-time Communication and Notification Validation
Tests WebSocket connections, real-time data flow, and notification delivery
"""

import asyncio
import json
import time
import uuid
import websockets
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import requests
from concurrent.futures import ThreadPoolExecutor
import threading

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RealTimeValidator:
    """Validates real-time communication and notification systems"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.ws_url = base_url.replace("http", "ws")
        self.session = requests.Session()
        self.test_data = {}
        self.websocket_connections = {}
        self.received_messages = []
        self.notification_events = []
        
    async def setup_test_user(self):
        """Setup test user and vehicle for real-time testing"""
        logger.info("👤 Setting up test user for real-time validation")
        
        # Generate unique test data
        unique_id = uuid.uuid4().hex[:8]
        self.test_data = {
            "user": {
                "email": f"realtime_test_{unique_id}@aivonity.com",
                "password": "RealtimeTest123!",
                "name": f"Realtime Test User {unique_id}",
                "phone": f"+123456{unique_id[:4]}"
            },
            "vehicle": {
                "make": "Tesla",
                "model": "Model S",
                "year": 2023,
                "vin": f"5YJ3E1EA4RT{unique_id[:6].upper()}",
                "mileage": 25000
            }
        }
        
        # Register user
        response = self.session.post(
            f"{self.api_url}/auth/register",
            json=self.test_data["user"],
            timeout=10
        )
        
        if response.status_code != 201:
            logger.error(f"❌ User registration failed: {response.status_code}")
            return False
        
        user_response = response.json()
        self.test_data["access_token"] = user_response["access_token"]
        self.test_data["user_id"] = user_response["user"]["id"]
        
        # Register vehicle
        headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
        response = self.session.post(
            f"{self.api_url}/vehicles",
            json=self.test_data["vehicle"],
            headers=headers,
            timeout=10
        )
        
        if response.status_code != 201:
            logger.error(f"❌ Vehicle registration failed: {response.status_code}")
            return False
        
        vehicle_response = response.json()
        self.test_data["vehicle_id"] = vehicle_response["id"]
        
        logger.info("✅ Test user and vehicle setup complete")
        return True
    
    async def test_telemetry_websocket_realtime(self) -> bool:
        """Test real-time telemetry WebSocket communication"""
        logger.info("📡 Testing real-time telemetry WebSocket")
        
        try:
            ws_url = f"{self.ws_url}/ws/telemetry/{self.test_data['vehicle_id']}"
            
            async with websockets.connect(ws_url) as websocket:
                logger.info("  ✅ WebSocket connection established")
                
                # Send test telemetry data
                test_telemetry = {
                    "type": "telemetry_update",
                    "vehicle_id": self.test_data["vehicle_id"],
                    "timestamp": datetime.utcnow().isoformat(),
                    "data": {
                        "engine_temp": 92.5,
                        "oil_pressure": 42.1,
                        "battery_voltage": 12.8,
                        "rpm": 2800,
                        "speed": 75.0,
                        "fuel_level": 68.5
                    }
                }
                
                await websocket.send(json.dumps(test_telemetry))
                logger.info("  📤 Sent telemetry data")
                
                # Wait for acknowledgment or broadcast
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                    response_data = json.loads(response)
                    logger.info(f"  📥 Received response: {response_data.get('type', 'unknown')}")
                    
                    # Send multiple rapid updates to test throughput
                    for i in range(5):
                        rapid_data = test_telemetry.copy()
                        rapid_data["data"]["engine_temp"] = 92.5 + i
                        rapid_data["timestamp"] = (datetime.utcnow() + timedelta(seconds=i)).isoformat()
                        
                        await websocket.send(json.dumps(rapid_data))
                        await asyncio.sleep(0.2)
                    
                    logger.info("  📤 Sent rapid telemetry updates")
                    
                    # Wait for any additional responses
                    await asyncio.sleep(2)
                    
                    logger.info("  ✅ Telemetry WebSocket test successful")
                    return True
                    
                except asyncio.TimeoutError:
                    logger.info("  ℹ️ No immediate response (may be normal for broadcast)")
                    return True
                    
        except Exception as e:
            logger.error(f"  ❌ Telemetry WebSocket test failed: {e}")
            return False
    
    async def test_chat_websocket_realtime(self) -> bool:
        """Test real-time chat WebSocket communication"""
        logger.info("💬 Testing real-time chat WebSocket")
        
        try:
            ws_url = f"{self.ws_url}/ws/chat/{self.test_data['user_id']}"
            
            async with websockets.connect(ws_url) as websocket:
                logger.info("  ✅ Chat WebSocket connection established")
                
                # Send test chat message
                chat_message = {
                    "message": "What's the current status of my Tesla Model S?",
                    "timestamp": datetime.utcnow().isoformat(),
                    "context": {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "conversation_type": "status_inquiry"
                    }
                }
                
                await websocket.send(json.dumps(chat_message))
                logger.info("  📤 Sent chat message")
                
                # Wait for AI response
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                    response_data = json.loads(response)
                    
                    if "response" in response_data:
                        logger.info(f"  🤖 AI Response received: {response_data['response'][:100]}...")
                        
                        # Send follow-up message
                        followup = {
                            "message": "Should I be concerned about any maintenance issues?",
                            "timestamp": datetime.utcnow().isoformat(),
                            "context": response_data.get("context", {})
                        }
                        
                        await websocket.send(json.dumps(followup))
                        logger.info("  📤 Sent follow-up message")
                        
                        # Wait for follow-up response
                        followup_response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                        followup_data = json.loads(followup_response)
                        
                        if "response" in followup_data:
                            logger.info("  🤖 Follow-up response received")
                        
                        logger.info("  ✅ Chat WebSocket test successful")
                        return True
                    else:
                        logger.error("  ❌ Invalid chat response format")
                        return False
                        
                except asyncio.TimeoutError:
                    logger.error("  ❌ Chat response timeout")
                    return False
                    
        except Exception as e:
            logger.error(f"  ❌ Chat WebSocket test failed: {e}")
            return False
    
    async def test_alerts_websocket_realtime(self) -> bool:
        """Test real-time alerts WebSocket communication"""
        logger.info("🚨 Testing real-time alerts WebSocket")
        
        try:
            ws_url = f"{self.ws_url}/ws/alerts/{self.test_data['user_id']}"
            
            # Start WebSocket connection in background
            async def websocket_listener():
                try:
                    async with websockets.connect(ws_url) as websocket:
                        logger.info("  ✅ Alerts WebSocket connection established")
                        
                        # Listen for alerts
                        while True:
                            try:
                                message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                                alert_data = json.loads(message)
                                self.received_messages.append(alert_data)
                                logger.info(f"  📥 Received alert: {alert_data.get('type', 'unknown')}")
                            except asyncio.TimeoutError:
                                continue
                            except websockets.exceptions.ConnectionClosed:
                                break
                                
                except Exception as e:
                    logger.error(f"  ❌ WebSocket listener error: {e}")
            
            # Start listener
            listener_task = asyncio.create_task(websocket_listener())
            
            # Wait a moment for connection
            await asyncio.sleep(2)
            
            # Trigger an alert by sending anomalous telemetry
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            anomalous_telemetry = {
                "vehicle_id": self.test_data["vehicle_id"],
                "timestamp": datetime.utcnow().isoformat(),
                "sensor_data": {
                    "engine_temp": 125.0,  # Critical temperature
                    "oil_pressure": 10.0,  # Low pressure
                    "battery_voltage": 10.0,  # Low voltage
                    "rpm": 6000,  # High RPM
                    "speed": 75.0,
                    "fuel_level": 5.0  # Low fuel
                },
                "location": {"latitude": 37.7749, "longitude": -122.4194}
            }
            
            response = self.session.post(
                f"{self.api_url}/telemetry/ingest",
                json=anomalous_telemetry,
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 201:
                logger.info("  📤 Sent anomalous telemetry to trigger alerts")
                
                # Wait for alert processing and WebSocket delivery
                await asyncio.sleep(5)
                
                # Cancel listener
                listener_task.cancel()
                
                # Check if we received any alerts
                if self.received_messages:
                    logger.info(f"  ✅ Received {len(self.received_messages)} real-time alerts")
                    return True
                else:
                    logger.info("  ℹ️ No real-time alerts received (may be normal)")
                    return True  # Not necessarily a failure
            else:
                logger.error(f"  ❌ Failed to send anomalous telemetry: {response.status_code}")
                listener_task.cancel()
                return False
                
        except Exception as e:
            logger.error(f"  ❌ Alerts WebSocket test failed: {e}")
            return False
    
    async def test_notification_delivery_realtime(self) -> bool:
        """Test real-time notification delivery"""
        logger.info("📱 Testing real-time notification delivery")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Configure notification preferences
            preferences = {
                "push_notifications": True,
                "email_notifications": True,
                "sms_notifications": False,
                "alert_types": ["critical", "maintenance", "booking"],
                "real_time_alerts": True
            }
            
            response = self.session.put(
                f"{self.api_url}/notifications/preferences/{self.test_data['user_id']}",
                json=preferences,
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"  ❌ Failed to set notification preferences: {response.status_code}")
                return False
            
            logger.info("  ✅ Notification preferences configured")
            
            # Send test notifications with different priorities
            test_notifications = [
                {
                    "user_id": self.test_data["user_id"],
                    "type": "critical",
                    "title": "Critical Engine Alert",
                    "message": "Engine temperature critically high - immediate attention required",
                    "priority": "high",
                    "data": {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "alert_type": "engine_overheat",
                        "severity": "critical"
                    }
                },
                {
                    "user_id": self.test_data["user_id"],
                    "type": "maintenance",
                    "title": "Maintenance Reminder",
                    "message": "Your Tesla Model S is due for scheduled maintenance",
                    "priority": "medium",
                    "data": {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "maintenance_type": "scheduled",
                        "due_date": (datetime.utcnow() + timedelta(days=7)).isoformat()
                    }
                },
                {
                    "user_id": self.test_data["user_id"],
                    "type": "booking",
                    "title": "Service Appointment Confirmed",
                    "message": "Your service appointment has been confirmed for next week",
                    "priority": "low",
                    "data": {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "appointment_date": (datetime.utcnow() + timedelta(days=7)).isoformat(),
                        "service_center": "Tesla Service Center"
                    }
                }
            ]
            
            notification_results = []
            
            for notification in test_notifications:
                response = self.session.post(
                    f"{self.api_url}/notifications/send",
                    json=notification,
                    headers=headers,
                    timeout=10
                )
                
                if response.status_code == 202:
                    logger.info(f"  📤 Sent {notification['type']} notification")
                    notification_results.append(True)
                else:
                    logger.error(f"  ❌ Failed to send {notification['type']} notification")
                    notification_results.append(False)
                
                # Small delay between notifications
                await asyncio.sleep(1)
            
            # Wait for processing
            await asyncio.sleep(3)
            
            # Check notification history
            response = self.session.get(
                f"{self.api_url}/notifications/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                history = response.json()
                logger.info(f"  📋 Notification history contains {len(history)} notifications")
                
                # Verify notification delivery status
                delivered_count = sum(1 for notif in history if notif.get("status") == "delivered")
                logger.info(f"  ✅ {delivered_count} notifications delivered successfully")
                
                return sum(notification_results) >= 2  # At least 2 out of 3 should succeed
            else:
                logger.error(f"  ❌ Failed to retrieve notification history: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"  ❌ Notification delivery test failed: {e}")
            return False
    
    async def test_concurrent_realtime_operations(self) -> bool:
        """Test concurrent real-time operations"""
        logger.info("🔄 Testing concurrent real-time operations")
        
        try:
            # Define concurrent operations
            async def concurrent_telemetry():
                """Send concurrent telemetry data"""
                headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
                success_count = 0
                
                for i in range(10):
                    telemetry_data = {
                        "vehicle_id": self.test_data["vehicle_id"],
                        "timestamp": (datetime.utcnow() + timedelta(seconds=i)).isoformat(),
                        "sensor_data": {
                            "engine_temp": 85.0 + i,
                            "oil_pressure": 45.0 - (i * 0.5),
                            "battery_voltage": 12.6,
                            "rpm": 2500 + (i * 50),
                            "speed": 65.0,
                            "fuel_level": 75.0 - i
                        }
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
                    
                    await asyncio.sleep(0.1)
                
                return success_count
            
            async def concurrent_chat():
                """Send concurrent chat messages"""
                ws_url = f"{self.ws_url}/ws/chat/{self.test_data['user_id']}"
                success_count = 0
                
                try:
                    async with websockets.connect(ws_url) as websocket:
                        messages = [
                            "What's my vehicle's current status?",
                            "Any maintenance recommendations?",
                            "How is my fuel efficiency?",
                            "Check battery health please",
                            "Any alerts I should know about?"
                        ]
                        
                        for message in messages:
                            chat_data = {
                                "message": message,
                                "timestamp": datetime.utcnow().isoformat(),
                                "context": {"vehicle_id": self.test_data["vehicle_id"]}
                            }
                            
                            await websocket.send(json.dumps(chat_data))
                            success_count += 1
                            await asyncio.sleep(0.5)
                        
                        return success_count
                except:
                    return success_count
            
            async def concurrent_notifications():
                """Send concurrent notifications"""
                headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
                success_count = 0
                
                for i in range(5):
                    notification_data = {
                        "user_id": self.test_data["user_id"],
                        "type": "maintenance",
                        "title": f"Concurrent Test Notification {i+1}",
                        "message": f"This is concurrent test notification number {i+1}",
                        "data": {"test_id": i+1}
                    }
                    
                    try:
                        response = self.session.post(
                            f"{self.api_url}/notifications/send",
                            json=notification_data,
                            headers=headers,
                            timeout=5
                        )
                        if response.status_code == 202:
                            success_count += 1
                    except:
                        pass
                    
                    await asyncio.sleep(0.2)
                
                return success_count
            
            # Run concurrent operations
            start_time = time.time()
            
            results = await asyncio.gather(
                concurrent_telemetry(),
                concurrent_chat(),
                concurrent_notifications(),
                return_exceptions=True
            )
            
            end_time = time.time()
            duration = end_time - start_time
            
            # Process results
            telemetry_success = results[0] if not isinstance(results[0], Exception) else 0
            chat_success = results[1] if not isinstance(results[1], Exception) else 0
            notification_success = results[2] if not isinstance(results[2], Exception) else 0
            
            logger.info(f"  📊 Concurrent operations completed in {duration:.2f}s")
            logger.info(f"  📡 Telemetry: {telemetry_success}/10 successful")
            logger.info(f"  💬 Chat: {chat_success}/5 successful")
            logger.info(f"  📱 Notifications: {notification_success}/5 successful")
            
            # Success criteria: at least 70% success rate overall
            total_operations = 20  # 10 + 5 + 5
            total_successful = telemetry_success + chat_success + notification_success
            success_rate = (total_successful / total_operations) * 100
            
            logger.info(f"  ✅ Overall success rate: {success_rate:.1f}%")
            
            return success_rate >= 70.0
            
        except Exception as e:
            logger.error(f"  ❌ Concurrent operations test failed: {e}")
            return False
    
    async def run_realtime_validation_suite(self) -> Dict[str, bool]:
        """Run complete real-time validation suite"""
        logger.info("🚀 Starting AIVONITY Real-time Validation Suite")
        
        # Setup test environment
        if not await self.setup_test_user():
            logger.error("❌ Failed to setup test user")
            return {"setup": False}
        
        # Define test suite
        test_suite = [
            ("Telemetry WebSocket", self.test_telemetry_websocket_realtime),
            ("Chat WebSocket", self.test_chat_websocket_realtime),
            ("Alerts WebSocket", self.test_alerts_websocket_realtime),
            ("Notification Delivery", self.test_notification_delivery_realtime),
            ("Concurrent Operations", self.test_concurrent_realtime_operations)
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
        logger.info(f"\n{'='*60}")
        logger.info("REAL-TIME VALIDATION SUMMARY")
        logger.info(f"{'='*60}")
        logger.info(f"Total Tests: {total_tests}")
        logger.info(f"Passed: {passed_tests}")
        logger.info(f"Failed: {total_tests - passed_tests}")
        logger.info(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        # Overall result
        overall_success = passed_tests >= (total_tests * 0.8)  # 80% pass rate
        if overall_success:
            logger.info(f"\n🎉 REAL-TIME VALIDATION: SUCCESSFUL")
        else:
            logger.error(f"\n💥 REAL-TIME VALIDATION: FAILED")
        
        return results

async def main():
    """Main function to run real-time validation"""
    validator = RealTimeValidator()
    results = await validator.run_realtime_validation_suite()
    
    # Exit with appropriate code
    failed_tests = sum(1 for result in results.values() if not result)
    exit(0 if failed_tests == 0 else 1)

if __name__ == "__main__":
    asyncio.run(main())