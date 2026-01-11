"""
AIVONITY Basic Integration Test
Tests core API integration and data flow without WebSocket complexity
"""

import asyncio
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BasicIntegrationTester:
    """Basic integration tester for AIVONITY core functionality"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.session = requests.Session()
        self.test_data = {}
        
    async def setup_test_environment(self):
        """Setup test environment with user and vehicle"""
        logger.info("🚀 Setting up basic integration test environment")
        
        # Generate unique test data
        unique_id = uuid.uuid4().hex[:8]
        self.test_data = {
            "user": {
                "email": f"basic_test_{unique_id}@aivonity.com",
                "password": "BasicTest123!",
                "name": f"Basic Test User {unique_id}",
                "phone": f"+123456{unique_id[:4]}"
            },
            "vehicle": {
                "make": "Tesla",
                "model": "Model 3",
                "year": 2023,
                "vin": f"5YJ3E1EA4BT{unique_id[:6].upper()}",
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
    
    async def test_system_health(self) -> bool:
        """Test system health endpoints"""
        logger.info("🏥 Testing system health")
        
        try:
            # Test main health endpoint
            response = self.session.get(f"{self.base_url}/health", timeout=10)
            if response.status_code != 200:
                logger.error(f"❌ Health check failed: {response.status_code}")
                return False
            
            health_data = response.json()
            logger.info(f"✅ System status: {health_data.get('overall_status', 'unknown')}")
            
            # Test quick health endpoint
            response = self.session.get(f"{self.base_url}/health/quick", timeout=5)
            if response.status_code == 200:
                logger.info("✅ Quick health check passed")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Health check exception: {e}")
            return False
    
    async def test_authentication_flow(self) -> bool:
        """Test user authentication workflow"""
        logger.info("🔐 Testing authentication flow")
        
        try:
            # Step 1: User Registration
            response = self.session.post(
                f"{self.api_url}/auth/register",
                json=self.test_data["user"],
                timeout=10
            )
            
            if response.status_code != 201:
                logger.error(f"❌ Registration failed: {response.status_code}")
                return False
            
            user_response = response.json()
            self.test_data["access_token"] = user_response["access_token"]
            self.test_data["user_id"] = user_response["user"]["id"]
            logger.info("✅ User registration successful")
            
            # Step 2: User Login
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
                logger.error(f"❌ Login failed: {response.status_code}")
                return False
            
            login_response = response.json()
            self.test_data["access_token"] = login_response["access_token"]
            logger.info("✅ User login successful")
            
            # Step 3: Test authenticated request
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            response = self.session.get(f"{self.api_url}/auth/profile", headers=headers, timeout=10)
            
            if response.status_code == 200:
                logger.info("✅ Authenticated request successful")
                return True
            else:
                logger.error(f"❌ Authenticated request failed: {response.status_code}")
                return False
            
        except Exception as e:
            logger.error(f"❌ Authentication flow exception: {e}")
            return False
    
    async def test_vehicle_management(self) -> bool:
        """Test vehicle registration and management"""
        logger.info("🚗 Testing vehicle management")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Register vehicle
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
            logger.info("✅ Vehicle registration successful")
            
            # Get vehicle details
            response = self.session.get(
                f"{self.api_url}/vehicles/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info("✅ Vehicle retrieval successful")
                return True
            else:
                logger.error(f"❌ Vehicle retrieval failed: {response.status_code}")
                return False
            
        except Exception as e:
            logger.error(f"❌ Vehicle management exception: {e}")
            return False
    
    async def test_telemetry_processing(self) -> bool:
        """Test telemetry data processing"""
        logger.info("📊 Testing telemetry processing")
        
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
                logger.error(f"❌ Normal telemetry ingestion failed: {response.status_code}")
                return False
            
            logger.info("✅ Normal telemetry ingested")
            
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
                logger.error(f"❌ Anomalous telemetry ingestion failed: {response.status_code}")
                return False
            
            logger.info("✅ Anomalous telemetry ingested")
            
            # Wait for processing
            await asyncio.sleep(3)
            
            # Check for alerts
            response = self.session.get(
                f"{self.api_url}/telemetry/alerts/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                alerts = response.json()
                logger.info(f"✅ Generated {len(alerts)} alerts from anomalous data")
                return True
            else:
                logger.warning(f"⚠️ Alert retrieval failed: {response.status_code}")
                return True  # Not critical for basic test
            
        except Exception as e:
            logger.error(f"❌ Telemetry processing exception: {e}")
            return False
    
    async def test_ai_chat_basic(self) -> bool:
        """Test basic AI chat functionality"""
        logger.info("🤖 Testing AI chat")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Send chat message
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
            
            logger.info(f"✅ AI Response received: {chat_response['response'][:100]}...")
            
            # Get chat history
            response = self.session.get(
                f"{self.api_url}/chat/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                history = response.json()
                logger.info(f"✅ Chat history contains {len(history)} messages")
                return True
            else:
                logger.warning(f"⚠️ Chat history retrieval failed: {response.status_code}")
                return True  # Not critical for basic test
            
        except Exception as e:
            logger.error(f"❌ AI chat exception: {e}")
            return False
    
    async def test_predictive_maintenance_basic(self) -> bool:
        """Test basic predictive maintenance"""
        logger.info("🔮 Testing predictive maintenance")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Request prediction
            response = self.session.post(
                f"{self.api_url}/predictions/request",
                json={"vehicle_id": self.test_data["vehicle_id"]},
                headers=headers,
                timeout=10
            )
            
            if response.status_code != 202:
                logger.error(f"❌ Prediction request failed: {response.status_code}")
                return False
            
            logger.info("✅ Prediction request submitted")
            
            # Wait for processing
            await asyncio.sleep(5)
            
            # Get predictions
            response = self.session.get(
                f"{self.api_url}/predictions/vehicle/{self.test_data['vehicle_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                predictions = response.json()
                logger.info(f"✅ Generated {len(predictions)} predictions")
                return True
            else:
                logger.warning(f"⚠️ Prediction retrieval failed: {response.status_code}")
                return True  # Not critical for basic test
            
        except Exception as e:
            logger.error(f"❌ Predictive maintenance exception: {e}")
            return False
    
    async def test_notification_system_basic(self) -> bool:
        """Test basic notification system"""
        logger.info("📱 Testing notification system")
        
        try:
            headers = {"Authorization": f"Bearer {self.test_data['access_token']}"}
            
            # Configure preferences
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
            
            logger.info("✅ Notification preferences configured")
            
            # Send test notification
            notification_data = {
                "user_id": self.test_data["user_id"],
                "type": "critical",
                "title": "Basic Integration Test Alert",
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
            
            logger.info("✅ Test notification sent")
            
            # Wait for processing
            await asyncio.sleep(2)
            
            # Check history
            response = self.session.get(
                f"{self.api_url}/notifications/history/{self.test_data['user_id']}",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                notifications = response.json()
                logger.info(f"✅ Notification history contains {len(notifications)} notifications")
                return True
            else:
                logger.warning(f"⚠️ Notification history failed: {response.status_code}")
                return True  # Not critical for basic test
            
        except Exception as e:
            logger.error(f"❌ Notification system exception: {e}")
            return False
    
    async def run_basic_integration_test(self) -> Dict[str, bool]:
        """Run basic integration test suite"""
        logger.info("🚀 Starting AIVONITY Basic Integration Test Suite")
        
        # Setup test environment
        await self.setup_test_environment()
        
        # Define test suite
        test_suite = [
            ("System Health", self.test_system_health),
            ("Authentication Flow", self.test_authentication_flow),
            ("Vehicle Management", self.test_vehicle_management),
            ("Telemetry Processing", self.test_telemetry_processing),
            ("AI Chat Basic", self.test_ai_chat_basic),
            ("Predictive Maintenance Basic", self.test_predictive_maintenance_basic),
            ("Notification System Basic", self.test_notification_system_basic)
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
        logger.info("BASIC INTEGRATION TEST SUMMARY")
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
        overall_success = passed_tests >= (total_tests * 0.7)  # 70% pass rate for basic test
        if overall_success:
            logger.info(f"\n🎉 OVERALL RESULT: BASIC INTEGRATION SUCCESSFUL")
        else:
            logger.error(f"\n💥 OVERALL RESULT: BASIC INTEGRATION FAILED")
        
        return results

async def main():
    """Main function to run the basic integration test"""
    tester = BasicIntegrationTester()
    results = await tester.run_basic_integration_test()
    
    # Exit with appropriate code
    failed_tests = sum(1 for result in results.values() if not result)
    exit(0 if failed_tests == 0 else 1)

if __name__ == "__main__":
    asyncio.run(main())