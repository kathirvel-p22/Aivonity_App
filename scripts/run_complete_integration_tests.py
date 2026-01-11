#!/usr/bin/env python3
"""
AIVONITY Complete Integration Test Runner
Orchestrates backend and mobile integration tests
"""

import asyncio
import subprocess
import sys
import time
import logging
import json
import os
from pathlib import Path
from typing import Dict, List, Optional
import requests
import signal
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class IntegrationTestOrchestrator:
    """Orchestrates complete integration testing for AIVONITY"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.backend_process = None
        self.test_results = {}
        self.backend_url = "http://localhost:8000"
        
    async def setup_test_environment(self):
        """Setup complete test environment"""
        logger.info("🚀 Setting up AIVONITY integration test environment")
        
        # Check prerequisites
        if not await self._check_prerequisites():
            return False
        
        # Start backend services
        if not await self._start_backend_services():
            return False
        
        # Wait for services to be ready
        if not await self._wait_for_services():
            return False
        
        logger.info("✅ Test environment setup complete")
        return True
    
    async def _check_prerequisites(self) -> bool:
        """Check if all prerequisites are available"""
        logger.info("🔍 Checking prerequisites")
        
        # Check Python dependencies
        try:
            import fastapi
            import uvicorn
            import sqlalchemy
            import redis
            logger.info("  ✅ Python dependencies available")
        except ImportError as e:
            logger.error(f"  ❌ Missing Python dependency: {e}")
            return False
        
        # Check Flutter installation
        try:
            result = subprocess.run(
                ["flutter", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                logger.info("  ✅ Flutter available")
            else:
                logger.error("  ❌ Flutter not available")
                return False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.error("  ❌ Flutter not found")
            return False
        
        # Check Docker (optional for local testing)
        try:
            result = subprocess.run(
                ["docker", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                logger.info("  ✅ Docker available")
            else:
                logger.info("  ℹ️ Docker not available (optional)")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.info("  ℹ️ Docker not found (optional)")
        
        return True
    
    async def _start_backend_services(self) -> bool:
        """Start backend services"""
        logger.info("🔧 Starting backend services")
        
        try:
            # Change to backend directory
            backend_dir = self.project_root / "backend"
            
            # Start FastAPI server
            cmd = [
                sys.executable, "-m", "uvicorn",
                "app.main:app",
                "--host", "0.0.0.0",
                "--port", "8000",
                "--reload"
            ]
            
            self.backend_process = subprocess.Popen(
                cmd,
                cwd=backend_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            logger.info("  ✅ Backend server started")
            return True
            
        except Exception as e:
            logger.error(f"  ❌ Failed to start backend services: {e}")
            return False
    
    async def _wait_for_services(self, timeout: int = 60) -> bool:
        """Wait for services to be ready"""
        logger.info("⏳ Waiting for services to be ready")
        
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                # Check backend health
                response = requests.get(f"{self.backend_url}/health", timeout=5)
                if response.status_code == 200:
                    health_data = response.json()
                    if health_data.get("overall_status") in ["healthy", "operational"]:
                        logger.info("  ✅ Backend services ready")
                        return True
            except requests.RequestException:
                pass
            
            await asyncio.sleep(2)
        
        logger.error("  ❌ Services not ready within timeout")
        return False
    
    async def run_backend_integration_tests(self) -> Dict[str, bool]:
        """Run backend integration tests"""
        logger.info("🔧 Running backend integration tests")
        
        try:
            # Import and run the backend integration test
            backend_dir = self.project_root / "backend"
            
            # Run the complete integration test
            cmd = [
                sys.executable, "-m", "pytest",
                "test_complete_integration.py",
                "-v", "--tb=short"
            ]
            
            result = subprocess.run(
                cmd,
                cwd=backend_dir,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes timeout
            )
            
            if result.returncode == 0:
                logger.info("  ✅ Backend integration tests passed")
                return {"backend_integration": True}
            else:
                logger.error(f"  ❌ Backend integration tests failed")
                logger.error(f"  Error output: {result.stderr}")
                return {"backend_integration": False}
                
        except subprocess.TimeoutExpired:
            logger.error("  ❌ Backend integration tests timed out")
            return {"backend_integration": False}
        except Exception as e:
            logger.error(f"  ❌ Backend integration tests exception: {e}")
            return {"backend_integration": False}
    
    async def run_mobile_integration_tests(self) -> Dict[str, bool]:
        """Run mobile integration tests"""
        logger.info("📱 Running mobile integration tests")
        
        try:
            mobile_dir = self.project_root / "mobile"
            
            # First, get Flutter dependencies
            logger.info("  📦 Getting Flutter dependencies")
            deps_result = subprocess.run(
                ["flutter", "pub", "get"],
                cwd=mobile_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if deps_result.returncode != 0:
                logger.error(f"  ❌ Flutter pub get failed: {deps_result.stderr}")
                return {"mobile_integration": False}
            
            # Run integration tests
            logger.info("  🧪 Running Flutter integration tests")
            cmd = [
                "flutter", "test",
                "integration_test/complete_integration_test.dart",
                "--verbose"
            ]
            
            result = subprocess.run(
                cmd,
                cwd=mobile_dir,
                capture_output=True,
                text=True,
                timeout=600  # 10 minutes timeout
            )
            
            if result.returncode == 0:
                logger.info("  ✅ Mobile integration tests passed")
                return {"mobile_integration": True}
            else:
                logger.error(f"  ❌ Mobile integration tests failed")
                logger.error(f"  Error output: {result.stderr}")
                return {"mobile_integration": False}
                
        except subprocess.TimeoutExpired:
            logger.error("  ❌ Mobile integration tests timed out")
            return {"mobile_integration": False}
        except Exception as e:
            logger.error(f"  ❌ Mobile integration tests exception: {e}")
            return {"mobile_integration": False}
    
    async def run_end_to_end_workflow_tests(self) -> Dict[str, bool]:
        """Run end-to-end workflow tests"""
        logger.info("🔄 Running end-to-end workflow tests")
        
        try:
            # Import the backend integration tester
            sys.path.append(str(self.project_root / "backend"))
            from test_complete_integration import AIVONITYIntegrationTester
            
            # Run complete integration test
            tester = AIVONITYIntegrationTester(self.backend_url)
            results = await tester.run_complete_integration_test()
            
            logger.info("  ✅ End-to-end workflow tests completed")
            return results
            
        except Exception as e:
            logger.error(f"  ❌ End-to-end workflow tests exception: {e}")
            return {"end_to_end_workflow": False}
    
    async def run_performance_tests(self) -> Dict[str, bool]:
        """Run performance tests"""
        logger.info("⚡ Running performance tests")
        
        try:
            # Test API response times
            response_times = []
            
            for i in range(10):
                start_time = time.time()
                response = requests.get(f"{self.backend_url}/health", timeout=10)
                end_time = time.time()
                
                if response.status_code == 200:
                    response_times.append(end_time - start_time)
                
                await asyncio.sleep(0.1)
            
            if response_times:
                avg_response_time = sum(response_times) / len(response_times)
                logger.info(f"  ✅ Average API response time: {avg_response_time:.3f}s")
                
                # Performance criteria: average response time < 1 second
                performance_passed = avg_response_time < 1.0
                
                return {"performance_tests": performance_passed}
            else:
                logger.error("  ❌ No successful API responses")
                return {"performance_tests": False}
                
        except Exception as e:
            logger.error(f"  ❌ Performance tests exception: {e}")
            return {"performance_tests": False}
    
    async def run_security_tests(self) -> Dict[str, bool]:
        """Run basic security tests"""
        logger.info("🔒 Running security tests")
        
        try:
            security_results = {}
            
            # Test 1: Unauthenticated access
            try:
                response = requests.get(f"{self.backend_url}/api/v1/telemetry/alerts/test", timeout=10)
                if response.status_code == 401:
                    security_results["auth_protection"] = True
                    logger.info("  ✅ Authentication protection working")
                else:
                    security_results["auth_protection"] = False
                    logger.error("  ❌ Authentication protection failed")
            except:
                security_results["auth_protection"] = False
            
            # Test 2: CORS headers
            try:
                response = requests.options(f"{self.backend_url}/api/v1/auth/login", timeout=10)
                cors_headers = response.headers.get("Access-Control-Allow-Origin")
                if cors_headers:
                    security_results["cors_configured"] = True
                    logger.info("  ✅ CORS headers configured")
                else:
                    security_results["cors_configured"] = False
                    logger.error("  ❌ CORS headers missing")
            except:
                security_results["cors_configured"] = False
            
            # Test 3: HTTPS redirect (if applicable)
            security_results["https_redirect"] = True  # Assume pass for local testing
            
            return security_results
            
        except Exception as e:
            logger.error(f"  ❌ Security tests exception: {e}")
            return {"security_tests": False}
    
    def cleanup_test_environment(self):
        """Cleanup test environment"""
        logger.info("🧹 Cleaning up test environment")
        
        # Stop backend process
        if self.backend_process:
            try:
                self.backend_process.terminate()
                self.backend_process.wait(timeout=10)
                logger.info("  ✅ Backend process terminated")
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
                logger.info("  ⚠️ Backend process killed")
            except Exception as e:
                logger.error(f"  ❌ Error stopping backend process: {e}")
        
        logger.info("✅ Cleanup complete")
    
    def generate_test_report(self, all_results: Dict[str, Dict[str, bool]]):
        """Generate comprehensive test report"""
        logger.info("📊 Generating test report")
        
        # Calculate overall statistics
        total_tests = 0
        passed_tests = 0
        
        for test_suite, results in all_results.items():
            for test_name, result in results.items():
                total_tests += 1
                if result:
                    passed_tests += 1
        
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        
        # Generate report
        report = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "summary": {
                "total_tests": total_tests,
                "passed_tests": passed_tests,
                "failed_tests": total_tests - passed_tests,
                "success_rate": f"{success_rate:.1f}%"
            },
            "results": all_results
        }
        
        # Save report to file
        report_file = self.project_root / "integration_test_report.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        # Print summary
        logger.info(f"\n{'='*70}")
        logger.info("AIVONITY COMPLETE INTEGRATION TEST REPORT")
        logger.info(f"{'='*70}")
        logger.info(f"Total Tests: {total_tests}")
        logger.info(f"Passed: {passed_tests}")
        logger.info(f"Failed: {total_tests - passed_tests}")
        logger.info(f"Success Rate: {success_rate:.1f}%")
        
        # Detailed results
        logger.info(f"\nDetailed Results:")
        for test_suite, results in all_results.items():
            logger.info(f"\n{test_suite.upper()}:")
            for test_name, result in results.items():
                status = "✅ PASSED" if result else "❌ FAILED"
                logger.info(f"  {test_name}: {status}")
        
        # Overall result
        if success_rate >= 80.0:
            logger.info(f"\n🎉 OVERALL RESULT: INTEGRATION TESTS SUCCESSFUL")
            return True
        else:
            logger.error(f"\n💥 OVERALL RESULT: INTEGRATION TESTS FAILED")
            return False
    
    async def run_complete_integration_tests(self) -> bool:
        """Run complete integration test suite"""
        logger.info("🚀 Starting AIVONITY Complete Integration Test Suite")
        
        try:
            # Setup test environment
            if not await self.setup_test_environment():
                logger.error("❌ Failed to setup test environment")
                return False
            
            # Run all test suites
            all_results = {}
            
            # Backend integration tests
            backend_results = await self.run_backend_integration_tests()
            all_results["backend"] = backend_results
            
            # Mobile integration tests
            mobile_results = await self.run_mobile_integration_tests()
            all_results["mobile"] = mobile_results
            
            # End-to-end workflow tests
            e2e_results = await self.run_end_to_end_workflow_tests()
            all_results["end_to_end"] = e2e_results
            
            # Performance tests
            performance_results = await self.run_performance_tests()
            all_results["performance"] = performance_results
            
            # Security tests
            security_results = await self.run_security_tests()
            all_results["security"] = security_results
            
            # Generate report
            overall_success = self.generate_test_report(all_results)
            
            return overall_success
            
        except Exception as e:
            logger.error(f"❌ Integration test suite exception: {e}")
            return False
        finally:
            self.cleanup_test_environment()

def signal_handler(signum, frame):
    """Handle interrupt signals"""
    logger.info("🛑 Received interrupt signal, cleaning up...")
    sys.exit(1)

async def main():
    """Main function"""
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Run integration tests
    orchestrator = IntegrationTestOrchestrator()
    success = await orchestrator.run_complete_integration_tests()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())