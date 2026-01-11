#!/usr/bin/env python3
"""
AIVONITY Integration Test Runner
Orchestrates complete system integration testing
"""

import os
import sys
import subprocess
import time
import json
import logging
from pathlib import Path
from typing import Dict, List, Tuple
import docker
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class AIVONITYIntegrationTestRunner:
    """Orchestrates complete AIVONITY integration testing"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.backend_path = self.project_root / "backend"
        self.mobile_path = self.project_root / "mobile"
        self.docker_client = None
        self.test_containers = []
        self.test_results = {}
        
    def setup_test_environment(self) -> bool:
        """Setup complete test environment"""
        logger.info("🚀 Setting up AIVONITY integration test environment")
        
        try:
            # Initialize Docker client
            self.docker_client = docker.from_env()
            logger.info("✅ Docker client initialized")
            
            # Check if backend is running
            if not self.check_backend_health():
                logger.info("🐳 Starting backend services with Docker Compose")
                if not self.start_backend_services():
                    return False
            
            # Wait for services to be ready
            if not self.wait_for_services():
                return False
            
            logger.info("✅ Test environment setup complete")
            return True
            
        except Exception as e:
            logger.error(f"❌ Test environment setup failed: {e}")
            return False
    
    def check_backend_health(self) -> bool:
        """Check if backend services are healthy"""
        try:
            response = requests.get("http://localhost:8000/health", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def start_backend_services(self) -> bool:
        """Start backend services using Docker Compose"""
        try:
            # Change to project root directory
            os.chdir(self.project_root)
            
            # Start services
            result = subprocess.run([
                "docker-compose", "up", "-d", "--build"
            ], capture_output=True, text=True, timeout=300)
            
            if result.returncode != 0:
                logger.error(f"❌ Docker Compose failed: {result.stderr}")
                return False
            
            logger.info("✅ Backend services started")
            return True
            
        except subprocess.TimeoutExpired:
            logger.error("❌ Docker Compose startup timed out")
            return False
        except Exception as e:
            logger.error(f"❌ Failed to start backend services: {e}")
            return False
    
    def wait_for_services(self, max_wait: int = 120) -> bool:
        """Wait for all services to be ready"""
        logger.info("⏳ Waiting for services to be ready...")
        
        services = [
            ("Backend API", "http://localhost:8000/health"),
            ("Database", "http://localhost:8000/health"),  # Backend health includes DB check
        ]
        
        start_time = time.time()
        
        while time.time() - start_time < max_wait:
            all_ready = True
            
            for service_name, health_url in services:
                try:
                    response = requests.get(health_url, timeout=5)
                    if response.status_code != 200:
                        all_ready = False
                        break
                except:
                    all_ready = False
                    break
            
            if all_ready:
                logger.info("✅ All services are ready")
                return True
            
            time.sleep(5)
            logger.info("⏳ Still waiting for services...")
        
        logger.error("❌ Services failed to become ready within timeout")
        return False
    
    def run_backend_unit_tests(self) -> Tuple[bool, Dict]:
        """Run backend unit tests"""
        logger.info("🧪 Running backend unit tests")
        
        try:
            os.chdir(self.backend_path)
            
            # Run pytest with coverage
            result = subprocess.run([
                "python", "-m", "pytest", 
                ".", 
                "-v", 
                "--tb=short",
                "--cov=app",
                "--cov-report=json",
                "--cov-report=term-missing",
                "--asyncio-mode=auto"
            ], capture_output=True, text=True, timeout=300)
            
            # Parse results
            success = result.returncode == 0
            
            # Try to load coverage data
            coverage_data = {}
            try:
                with open("coverage.json", "r") as f:
                    coverage_data = json.load(f)
            except:
                pass
            
            test_results = {
                "success": success,
                "output": result.stdout,
                "errors": result.stderr,
                "coverage": coverage_data.get("totals", {}).get("percent_covered", 0)
            }
            
            if success:
                logger.info("✅ Backend unit tests passed")
            else:
                logger.error("❌ Backend unit tests failed")
                logger.error(result.stderr)
            
            return success, test_results
            
        except Exception as e:
            logger.error(f"❌ Backend unit tests exception: {e}")
            return False, {"success": False, "error": str(e)}
    
    def run_backend_integration_tests(self) -> Tuple[bool, Dict]:
        """Run backend integration tests"""
        logger.info("🔗 Running backend integration tests")
        
        try:
            os.chdir(self.backend_path)
            
            # Run integration test suite
            result = subprocess.run([
                "python", "-m", "pytest", 
                "test_integration_complete.py",
                "-v", 
                "--tb=short",
                "--asyncio-mode=auto"
            ], capture_output=True, text=True, timeout=600)
            
            success = result.returncode == 0
            
            test_results = {
                "success": success,
                "output": result.stdout,
                "errors": result.stderr
            }
            
            if success:
                logger.info("✅ Backend integration tests passed")
            else:
                logger.error("❌ Backend integration tests failed")
                logger.error(result.stderr)
            
            return success, test_results
            
        except Exception as e:
            logger.error(f"❌ Backend integration tests exception: {e}")
            return False, {"success": False, "error": str(e)}
    
    def run_e2e_system_tests(self) -> Tuple[bool, Dict]:
        """Run end-to-end system tests"""
        logger.info("🌐 Running end-to-end system tests")
        
        try:
            os.chdir(self.backend_path)
            
            # Run E2E test suite
            result = subprocess.run([
                "python", "test_e2e_complete_system.py"
            ], capture_output=True, text=True, timeout=900)
            
            success = result.returncode == 0
            
            test_results = {
                "success": success,
                "output": result.stdout,
                "errors": result.stderr
            }
            
            if success:
                logger.info("✅ End-to-end system tests passed")
            else:
                logger.error("❌ End-to-end system tests failed")
                logger.error(result.stderr)
            
            return success, test_results
            
        except Exception as e:
            logger.error(f"❌ End-to-end system tests exception: {e}")
            return False, {"success": False, "error": str(e)}
    
    def run_mobile_tests(self) -> Tuple[bool, Dict]:
        """Run mobile app tests"""
        logger.info("📱 Running mobile app tests")
        
        try:
            os.chdir(self.mobile_path)
            
            # Check if Flutter is available
            flutter_check = subprocess.run(["flutter", "--version"], 
                                         capture_output=True, text=True, timeout=30)
            
            if flutter_check.returncode != 0:
                logger.warning("⚠️ Flutter not available, skipping mobile tests")
                return True, {"success": True, "skipped": True, "reason": "Flutter not available"}
            
            # Run Flutter tests
            result = subprocess.run([
                "flutter", "test", 
                "--coverage",
                "--reporter=json"
            ], capture_output=True, text=True, timeout=300)
            
            success = result.returncode == 0
            
            test_results = {
                "success": success,
                "output": result.stdout,
                "errors": result.stderr
            }
            
            if success:
                logger.info("✅ Mobile app tests passed")
            else:
                logger.error("❌ Mobile app tests failed")
                logger.error(result.stderr)
            
            return success, test_results
            
        except Exception as e:
            logger.error(f"❌ Mobile app tests exception: {e}")
            return False, {"success": False, "error": str(e)}
    
    def run_mobile_integration_tests(self) -> Tuple[bool, Dict]:
        """Run mobile integration tests"""
        logger.info("📱🔗 Running mobile integration tests")
        
        try:
            os.chdir(self.mobile_path)
            
            # Check if Flutter is available
            flutter_check = subprocess.run(["flutter", "--version"], 
                                         capture_output=True, text=True, timeout=30)
            
            if flutter_check.returncode != 0:
                logger.warning("⚠️ Flutter not available, skipping mobile integration tests")
                return True, {"success": True, "skipped": True, "reason": "Flutter not available"}
            
            # Run integration tests
            result = subprocess.run([
                "flutter", "test", "integration_test/",
                "--reporter=json"
            ], capture_output=True, text=True, timeout=600)
            
            success = result.returncode == 0
            
            test_results = {
                "success": success,
                "output": result.stdout,
                "errors": result.stderr
            }
            
            if success:
                logger.info("✅ Mobile integration tests passed")
            else:
                logger.error("❌ Mobile integration tests failed")
                logger.error(result.stderr)
            
            return success, test_results
            
        except Exception as e:
            logger.error(f"❌ Mobile integration tests exception: {e}")
            return False, {"success": False, "error": str(e)}
    
    def run_performance_tests(self) -> Tuple[bool, Dict]:
        """Run performance and load tests"""
        logger.info("⚡ Running performance tests")
        
        try:
            # Performance tests are included in the E2E system tests
            # But we can run additional load testing here
            
            os.chdir(self.backend_path)
            
            # Run performance-specific tests
            result = subprocess.run([
                "python", "-c", """
import asyncio
from test_e2e_complete_system import AIVONITYSystemTester

async def run_performance_only():
    tester = AIVONITYSystemTester()
    tester.setup_test_environment()
    
    # Run only performance tests
    results = {}
    results['health'] = tester.test_system_health()
    results['auth'] = tester.test_user_authentication_flow()
    results['performance'] = tester.test_performance_under_load()
    
    return results

results = asyncio.run(run_performance_only())
success = all(results.values())
print(f'Performance test results: {results}')
exit(0 if success else 1)
"""
            ], capture_output=True, text=True, timeout=300)
            
            success = result.returncode == 0
            
            test_results = {
                "success": success,
                "output": result.stdout,
                "errors": result.stderr
            }
            
            if success:
                logger.info("✅ Performance tests passed")
            else:
                logger.error("❌ Performance tests failed")
                logger.error(result.stderr)
            
            return success, test_results
            
        except Exception as e:
            logger.error(f"❌ Performance tests exception: {e}")
            return False, {"success": False, "error": str(e)}
    
    def generate_test_report(self) -> str:
        """Generate comprehensive test report"""
        logger.info("📊 Generating test report")
        
        report = []
        report.append("=" * 80)
        report.append("AIVONITY COMPLETE INTEGRATION TEST REPORT")
        report.append("=" * 80)
        report.append(f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        # Summary
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results.values() if result[0])
        
        report.append("SUMMARY")
        report.append("-" * 40)
        report.append(f"Total Test Suites: {total_tests}")
        report.append(f"Passed: {passed_tests}")
        report.append(f"Failed: {total_tests - passed_tests}")
        report.append(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        report.append("")
        
        # Detailed Results
        report.append("DETAILED RESULTS")
        report.append("-" * 40)
        
        for test_name, (success, details) in self.test_results.items():
            status = "✅ PASSED" if success else "❌ FAILED"
            report.append(f"{test_name}: {status}")
            
            if details.get("skipped"):
                report.append(f"  Reason: {details.get('reason', 'Unknown')}")
            elif details.get("coverage"):
                report.append(f"  Coverage: {details['coverage']:.1f}%")
            
            if not success and details.get("errors"):
                report.append(f"  Error: {details['errors'][:200]}...")
            
            report.append("")
        
        # Recommendations
        report.append("RECOMMENDATIONS")
        report.append("-" * 40)
        
        failed_tests = [name for name, (success, _) in self.test_results.items() if not success]
        
        if not failed_tests:
            report.append("🎉 All tests passed! System is ready for deployment.")
        else:
            report.append("⚠️ The following test suites failed and need attention:")
            for test_name in failed_tests:
                report.append(f"  - {test_name}")
            
            report.append("")
            report.append("Please review the detailed error messages above and fix the issues.")
        
        report.append("")
        report.append("=" * 80)
        
        return "\n".join(report)
    
    def cleanup_test_environment(self):
        """Cleanup test environment"""
        logger.info("🧹 Cleaning up test environment")
        
        try:
            # Stop test containers
            for container in self.test_containers:
                try:
                    container.stop()
                    container.remove()
                except:
                    pass
            
            # Clean up Docker Compose services (optional)
            # Uncomment if you want to stop services after tests
            # os.chdir(self.project_root)
            # subprocess.run(["docker-compose", "down"], capture_output=True)
            
            logger.info("✅ Test environment cleanup complete")
            
        except Exception as e:
            logger.warning(f"⚠️ Cleanup warning: {e}")
    
    def run_all_tests(self) -> bool:
        """Run complete integration test suite"""
        logger.info("🚀 Starting AIVONITY Complete Integration Test Suite")
        
        # Setup test environment
        if not self.setup_test_environment():
            logger.error("❌ Failed to setup test environment")
            return False
        
        # Define test suite
        test_suite = [
            ("Backend Unit Tests", self.run_backend_unit_tests),
            ("Backend Integration Tests", self.run_backend_integration_tests),
            ("Mobile App Tests", self.run_mobile_tests),
            ("Mobile Integration Tests", self.run_mobile_integration_tests),
            ("End-to-End System Tests", self.run_e2e_system_tests),
            ("Performance Tests", self.run_performance_tests),
        ]
        
        # Run tests in parallel where possible
        with ThreadPoolExecutor(max_workers=3) as executor:
            # Submit all test jobs
            future_to_test = {
                executor.submit(test_func): test_name 
                for test_name, test_func in test_suite
            }
            
            # Collect results
            for future in as_completed(future_to_test):
                test_name = future_to_test[future]
                try:
                    success, details = future.result(timeout=1200)  # 20 minute timeout
                    self.test_results[test_name] = (success, details)
                    
                    if success:
                        logger.info(f"✅ {test_name}: COMPLETED SUCCESSFULLY")
                    else:
                        logger.error(f"❌ {test_name}: FAILED")
                        
                except Exception as e:
                    logger.error(f"❌ {test_name}: EXCEPTION - {e}")
                    self.test_results[test_name] = (False, {"error": str(e)})
        
        # Generate and display report
        report = self.generate_test_report()
        print("\n" + report)
        
        # Save report to file
        report_file = self.project_root / "test_report.txt"
        with open(report_file, "w") as f:
            f.write(report)
        logger.info(f"📄 Test report saved to: {report_file}")
        
        # Cleanup
        self.cleanup_test_environment()
        
        # Determine overall success
        overall_success = all(result[0] for result in self.test_results.values())
        
        if overall_success:
            logger.info("🎉 ALL INTEGRATION TESTS PASSED!")
            return True
        else:
            logger.error("💥 SOME INTEGRATION TESTS FAILED!")
            return False

def main():
    """Main function"""
    runner = AIVONITYIntegrationTestRunner()
    success = runner.run_all_tests()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()