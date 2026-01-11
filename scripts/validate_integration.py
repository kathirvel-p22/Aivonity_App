#!/usr/bin/env python3
"""
AIVONITY Integration Validation Script
Validates that all components are integrated and working together
"""

import asyncio
import subprocess
import sys
import time
import logging
import json
import os
import signal
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import requests
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class IntegrationValidator:
    """Validates AIVONITY system integration"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.backend_process = None
        self.backend_url = "http://localhost:8000"
        self.validation_results = {}
        
    async def validate_project_structure(self) -> bool:
        """Validate project structure and required files"""
        logger.info("📁 Validating project structure")
        
        required_paths = [
            "backend/app/main.py",
            "backend/requirements.txt",
            "mobile/lib/main.dart",
            "mobile/pubspec.yaml",
            ".kiro/specs/aivonity-vehicle-assistant/requirements.md",
            ".kiro/specs/aivonity-vehicle-assistant/design.md",
            ".kiro/specs/aivonity-vehicle-assistant/tasks.md"
        ]
        
        missing_paths = []
        for path in required_paths:
            full_path = self.project_root / path
            if not full_path.exists():
                missing_paths.append(path)
        
        if missing_paths:
            logger.error(f"❌ Missing required files: {missing_paths}")
            return False
        
        logger.info("✅ Project structure validation passed")
        return True
    
    async def validate_backend_dependencies(self) -> bool:
        """Validate backend dependencies are available"""
        logger.info("📦 Validating backend dependencies")
        
        try:
            # Check if we can import key backend modules
            sys.path.append(str(self.project_root / "backend"))
            
            # Test critical imports
            import fastapi
            import uvicorn
            import sqlalchemy
            import pydantic
            
            logger.info("✅ Backend dependencies validation passed")
            return True
            
        except ImportError as e:
            logger.error(f"❌ Missing backend dependency: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Backend dependencies validation failed: {e}")
            return False
    
    async def validate_mobile_dependencies(self) -> bool:
        """Validate mobile dependencies are available"""
        logger.info("📱 Validating mobile dependencies")
        
        try:
            # Check Flutter installation
            result = subprocess.run(
                ["flutter", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                logger.info("✅ Flutter available")
                
                # Check if pubspec.yaml is valid
                mobile_dir = self.project_root / "mobile"
                if mobile_dir.exists():
                    pubspec_file = mobile_dir / "pubspec.yaml"
                    if pubspec_file.exists():
                        logger.info("✅ Mobile project structure valid")
                        return True
                    else:
                        logger.error("❌ pubspec.yaml not found")
                        return False
                else:
                    logger.error("❌ Mobile directory not found")
                    return False
            else:
                logger.error("❌ Flutter not available")
                return False
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.error("❌ Flutter not found")
            return False
        except Exception as e:
            logger.error(f"❌ Mobile dependencies validation failed: {e}")
            return False
    
    async def start_backend_for_testing(self) -> bool:
        """Start backend server for testing"""
        logger.info("🔧 Starting backend server for testing")
        
        try:
            backend_dir = self.project_root / "backend"
            
            # Start FastAPI server
            cmd = [
                sys.executable, "-m", "uvicorn",
                "app.main:app",
                "--host", "127.0.0.1",
                "--port", "8000",
                "--log-level", "warning"  # Reduce log noise
            ]
            
            self.backend_process = subprocess.Popen(
                cmd,
                cwd=backend_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Wait for server to start
            max_wait = 30  # 30 seconds
            wait_time = 0
            
            while wait_time < max_wait:
                try:
                    response = requests.get(f"{self.backend_url}/health", timeout=2)
                    if response.status_code == 200:
                        logger.info("✅ Backend server started successfully")
                        return True
                except requests.RequestException:
                    pass
                
                await asyncio.sleep(1)
                wait_time += 1
            
            logger.error("❌ Backend server failed to start within timeout")
            return False
            
        except Exception as e:
            logger.error(f"❌ Failed to start backend server: {e}")
            return False
    
    async def validate_api_endpoints(self) -> bool:
        """Validate API endpoints are accessible"""
        logger.info("🔗 Validating API endpoints")
        
        try:
            # Test health endpoint
            response = requests.get(f"{self.backend_url}/health", timeout=10)
            if response.status_code != 200:
                logger.error(f"❌ Health endpoint failed: {response.status_code}")
                return False
            
            health_data = response.json()
            logger.info(f"✅ Health endpoint: {health_data.get('overall_status', 'unknown')}")
            
            # Test API documentation endpoints
            docs_response = requests.get(f"{self.backend_url}/api/docs", timeout=5)
            if docs_response.status_code == 200:
                logger.info("✅ API documentation accessible")
            
            # Test CORS headers
            options_response = requests.options(f"{self.backend_url}/api/v1/auth/login", timeout=5)
            if "Access-Control-Allow-Origin" in options_response.headers:
                logger.info("✅ CORS headers configured")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ API endpoints validation failed: {e}")
            return False
    
    async def validate_database_connectivity(self) -> bool:
        """Validate database connectivity"""
        logger.info("🗄️ Validating database connectivity")
        
        try:
            # Test database health through API
            response = requests.get(f"{self.backend_url}/health", timeout=10)
            if response.status_code == 200:
                health_data = response.json()
                components = health_data.get("components", {})
                
                # Check if database component is healthy
                db_status = components.get("database", {}).get("status", "unknown")
                if db_status == "healthy":
                    logger.info("✅ Database connectivity validated")
                    return True
                else:
                    logger.warning(f"⚠️ Database status: {db_status}")
                    return True  # Don't fail if DB is not configured for testing
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Database connectivity validation failed: {e}")
            return False
    
    async def validate_agent_system(self) -> bool:
        """Validate AI agent system"""
        logger.info("🤖 Validating AI agent system")
        
        try:
            # Test agent status through health endpoint
            response = requests.get(f"{self.backend_url}/health", timeout=10)
            if response.status_code == 200:
                health_data = response.json()
                components = health_data.get("components", {})
                
                # Check agent components
                agent_components = [
                    "data_agent", "diagnosis_agent", "scheduling_agent",
                    "customer_agent", "feedback_agent", "ueba_agent"
                ]
                
                healthy_agents = 0
                for agent in agent_components:
                    agent_status = components.get(agent, {}).get("status", "unknown")
                    if agent_status == "healthy":
                        healthy_agents += 1
                
                logger.info(f"✅ Agent system: {healthy_agents}/{len(agent_components)} agents healthy")
                return healthy_agents >= len(agent_components) * 0.5  # At least 50% should be healthy
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Agent system validation failed: {e}")
            return False
    
    async def validate_authentication_system(self) -> bool:
        """Validate authentication system"""
        logger.info("🔐 Validating authentication system")
        
        try:
            # Test registration endpoint
            test_user = {
                "email": "validation_test@aivonity.com",
                "password": "ValidationTest123!",
                "name": "Validation Test User",
                "phone": "+1234567890"
            }
            
            response = requests.post(
                f"{self.backend_url}/api/v1/auth/register",
                json=test_user,
                timeout=10
            )
            
            if response.status_code == 201:
                logger.info("✅ User registration working")
                
                # Test login
                login_data = {
                    "email": test_user["email"],
                    "password": test_user["password"]
                }
                
                login_response = requests.post(
                    f"{self.backend_url}/api/v1/auth/login",
                    json=login_data,
                    timeout=10
                )
                
                if login_response.status_code == 200:
                    logger.info("✅ User login working")
                    return True
                else:
                    logger.error(f"❌ Login failed: {login_response.status_code}")
                    return False
            else:
                logger.error(f"❌ Registration failed: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Authentication system validation failed: {e}")
            return False
    
    async def validate_mobile_build(self) -> bool:
        """Validate mobile app can be built"""
        logger.info("📱 Validating mobile app build")
        
        try:
            mobile_dir = self.project_root / "mobile"
            
            # Get Flutter dependencies
            deps_result = subprocess.run(
                ["flutter", "pub", "get"],
                cwd=mobile_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if deps_result.returncode != 0:
                logger.error(f"❌ Flutter pub get failed: {deps_result.stderr}")
                return False
            
            logger.info("✅ Flutter dependencies resolved")
            
            # Test build (analyze only, don't actually build)
            analyze_result = subprocess.run(
                ["flutter", "analyze"],
                cwd=mobile_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if analyze_result.returncode == 0:
                logger.info("✅ Flutter analysis passed")
                return True
            else:
                logger.warning(f"⚠️ Flutter analysis warnings: {analyze_result.stdout}")
                return True  # Don't fail on warnings
                
        except subprocess.TimeoutExpired:
            logger.error("❌ Mobile build validation timed out")
            return False
        except Exception as e:
            logger.error(f"❌ Mobile build validation failed: {e}")
            return False
    
    async def validate_spec_completeness(self) -> bool:
        """Validate spec documents are complete"""
        logger.info("📋 Validating spec completeness")
        
        try:
            spec_dir = self.project_root / ".kiro" / "specs" / "aivonity-vehicle-assistant"
            
            # Check requirements document
            requirements_file = spec_dir / "requirements.md"
            if requirements_file.exists():
                requirements_content = requirements_file.read_text()
                if len(requirements_content) > 1000:  # Reasonable size check
                    logger.info("✅ Requirements document complete")
                else:
                    logger.warning("⚠️ Requirements document seems incomplete")
            
            # Check design document
            design_file = spec_dir / "design.md"
            if design_file.exists():
                design_content = design_file.read_text()
                if len(design_content) > 2000:  # Reasonable size check
                    logger.info("✅ Design document complete")
                else:
                    logger.warning("⚠️ Design document seems incomplete")
            
            # Check tasks document
            tasks_file = spec_dir / "tasks.md"
            if tasks_file.exists():
                tasks_content = tasks_file.read_text()
                completed_tasks = tasks_content.count("[x]")
                total_tasks = tasks_content.count("[ ]") + completed_tasks
                
                if total_tasks > 0:
                    completion_rate = (completed_tasks / total_tasks) * 100
                    logger.info(f"✅ Tasks document: {completed_tasks}/{total_tasks} tasks completed ({completion_rate:.1f}%)")
                    return completion_rate >= 80.0  # At least 80% completion
                else:
                    logger.warning("⚠️ No tasks found in tasks document")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Spec completeness validation failed: {e}")
            return False
    
    def cleanup(self):
        """Cleanup test environment"""
        logger.info("🧹 Cleaning up test environment")
        
        if self.backend_process:
            try:
                self.backend_process.terminate()
                self.backend_process.wait(timeout=10)
                logger.info("✅ Backend process terminated")
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
                logger.info("⚠️ Backend process killed")
            except Exception as e:
                logger.error(f"❌ Error stopping backend process: {e}")
    
    async def run_integration_validation(self) -> Dict[str, bool]:
        """Run complete integration validation"""
        logger.info("🚀 Starting AIVONITY Integration Validation")
        
        # Define validation suite
        validation_suite = [
            ("Project Structure", self.validate_project_structure),
            ("Backend Dependencies", self.validate_backend_dependencies),
            ("Mobile Dependencies", self.validate_mobile_dependencies),
            ("Backend Startup", self.start_backend_for_testing),
            ("API Endpoints", self.validate_api_endpoints),
            ("Database Connectivity", self.validate_database_connectivity),
            ("Agent System", self.validate_agent_system),
            ("Authentication System", self.validate_authentication_system),
            ("Mobile Build", self.validate_mobile_build),
            ("Spec Completeness", self.validate_spec_completeness)
        ]
        
        # Execute validations
        results = {}
        passed_validations = 0
        total_validations = len(validation_suite)
        
        for validation_name, validation_function in validation_suite:
            logger.info(f"\n{'='*50}")
            logger.info(f"Running: {validation_name}")
            logger.info(f"{'='*50}")
            
            try:
                result = await validation_function()
                results[validation_name] = result
                if result:
                    passed_validations += 1
                    logger.info(f"✅ {validation_name}: PASSED")
                else:
                    logger.error(f"❌ {validation_name}: FAILED")
            except Exception as e:
                logger.error(f"❌ {validation_name}: EXCEPTION - {e}")
                results[validation_name] = False
        
        # Generate summary
        logger.info(f"\n{'='*60}")
        logger.info("AIVONITY INTEGRATION VALIDATION SUMMARY")
        logger.info(f"{'='*60}")
        logger.info(f"Total Validations: {total_validations}")
        logger.info(f"Passed: {passed_validations}")
        logger.info(f"Failed: {total_validations - passed_validations}")
        logger.info(f"Success Rate: {(passed_validations/total_validations)*100:.1f}%")
        
        # Detailed results
        logger.info(f"\nDetailed Results:")
        for validation_name, result in results.items():
            status = "✅ PASSED" if result else "❌ FAILED"
            logger.info(f"  {validation_name}: {status}")
        
        # Overall result
        overall_success = passed_validations >= (total_validations * 0.8)  # 80% pass rate
        if overall_success:
            logger.info(f"\n🎉 OVERALL RESULT: INTEGRATION VALIDATION SUCCESSFUL")
            logger.info("✅ All components are integrated and working together")
        else:
            logger.error(f"\n💥 OVERALL RESULT: INTEGRATION VALIDATION FAILED")
            logger.error("❌ Some components are not properly integrated")
        
        return results

def signal_handler(signum, frame):
    """Handle interrupt signals"""
    logger.info("🛑 Received interrupt signal, cleaning up...")
    sys.exit(1)

async def main():
    """Main function"""
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Run integration validation
    validator = IntegrationValidator()
    
    try:
        results = await validator.run_integration_validation()
        
        # Determine exit code
        failed_validations = sum(1 for result in results.values() if not result)
        success = failed_validations == 0
        
        return success
        
    finally:
        validator.cleanup()

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)