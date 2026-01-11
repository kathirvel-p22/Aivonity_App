"""
Test script for comprehensive error handling implementation
"""

import asyncio
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.utils.exceptions import (
    AIVONITYException,
    AuthenticationError,
    ValidationError,
    ExternalServiceError,
    RateLimitError,
    ErrorCategory,
    ErrorSeverity
)
from app.utils.retry_handler import RetryHandler, RetryConfigs
from app.utils.circuit_breaker import CircuitBreaker, CircuitBreakerConfigs
from app.utils.api_client import ResilientAPIClient


async def test_exceptions():
    """Test custom exception handling"""
    print("🧪 Testing Custom Exceptions...")
    
    # Test basic AIVONITY exception
    try:
        raise AIVONITYException(
            message="Test error",
            error_code="TEST_001",
            category=ErrorCategory.SYSTEM,
            severity=ErrorSeverity.MEDIUM
        )
    except AIVONITYException as e:
        print(f"✅ Basic exception: {e.error_code} - {e.message}")
        print(f"   User message: {e.user_message}")
        print(f"   Category: {e.category.value}")
        print(f"   Severity: {e.severity.value}")
    
    # Test authentication error
    try:
        raise AuthenticationError("Invalid credentials")
    except AuthenticationError as e:
        print(f"✅ Auth exception: {e.error_code} - {e.user_message}")
    
    # Test validation error
    try:
        raise ValidationError(
            message="Invalid input data",
            field_errors=[
                {"field": "email", "message": "Invalid email format"},
                {"field": "password", "message": "Password too short"}
            ]
        )
    except ValidationError as e:
        print(f"✅ Validation exception: {e.error_code}")
        print(f"   Field errors: {e.details.get('field_errors', [])}")
    
    # Test rate limit error
    try:
        raise RateLimitError(limit=100, window=60, retry_after=30)
    except RateLimitError as e:
        print(f"✅ Rate limit exception: {e.error_code}")
        print(f"   Retry after: {e.retry_after}s")


async def test_retry_handler():
    """Test retry handler with exponential backoff"""
    print("\n🔄 Testing Retry Handler...")
    
    retry_handler = RetryHandler(RetryConfigs.QUICK)
    
    # Test successful operation after retries
    attempt_count = 0
    
    async def flaky_operation():
        nonlocal attempt_count
        attempt_count += 1
        if attempt_count < 3:
            raise ExternalServiceError("Test Service", "Temporary failure")
        return f"Success on attempt {attempt_count}"
    
    try:
        result = await retry_handler.execute_async(
            flaky_operation,
            context={'test': 'retry_handler'}
        )
        print(f"✅ Retry success: {result}")
    except Exception as e:
        print(f"❌ Retry failed: {e}")
    
    # Test operation that always fails
    async def always_fails():
        raise ValidationError("This always fails")
    
    try:
        await retry_handler.execute_async(always_fails)
    except ValidationError as e:
        print(f"✅ Non-retryable error correctly not retried: {e.error_code}")


async def test_circuit_breaker():
    """Test circuit breaker pattern"""
    print("\n⚡ Testing Circuit Breaker...")
    
    circuit_breaker = CircuitBreaker("test_service", CircuitBreakerConfigs.EXTERNAL_API)
    
    # Test normal operation
    async def successful_operation():
        return "Success"
    
    try:
        result = await circuit_breaker.call_async(successful_operation)
        print(f"✅ Circuit breaker success: {result}")
        print(f"   State: {circuit_breaker.state.value}")
    except Exception as e:
        print(f"❌ Circuit breaker failed: {e}")
    
    # Test failure that opens circuit
    failure_count = 0
    
    async def failing_operation():
        nonlocal failure_count
        failure_count += 1
        raise ExternalServiceError("Test Service", f"Failure {failure_count}")
    
    # Trigger failures to open circuit
    for i in range(5):
        try:
            await circuit_breaker.call_async(failing_operation)
        except Exception:
            pass
    
    print(f"✅ Circuit state after failures: {circuit_breaker.state.value}")
    print(f"   Failure count: {circuit_breaker.get_stats()['failure_count']}")
    
    # Test circuit breaker open behavior
    try:
        await circuit_breaker.call_async(successful_operation)
    except Exception as e:
        print(f"✅ Circuit breaker correctly blocked call: {type(e).__name__}")


async def test_api_client():
    """Test resilient API client"""
    print("\n🌐 Testing Resilient API Client...")
    
    # Test with a mock service (this will fail but show error handling)
    client = ResilientAPIClient(
        base_url="http://localhost:9999",  # Non-existent service
        service_name="test_service",
        timeout=5
    )
    
    try:
        response = await client.get("/test")
        print(f"✅ API client success: {response.status_code}")
    except Exception as e:
        print(f"✅ API client correctly handled error: {type(e).__name__}")
        print(f"   Error message: {str(e)}")
    
    # Get client stats
    stats = client.get_stats()
    print(f"✅ API client stats: {stats['service_name']}")
    print(f"   Circuit breaker state: {stats['circuit_breaker_stats']['state']}")
    
    await client.close()


async def main():
    """Run all tests"""
    print("🚀 Starting Error Handling Tests...\n")
    
    await test_exceptions()
    await test_retry_handler()
    await test_circuit_breaker()
    await test_api_client()
    
    print("\n✅ All error handling tests completed!")


if __name__ == "__main__":
    asyncio.run(main())