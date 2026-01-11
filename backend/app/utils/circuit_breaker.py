"""
AIVONITY Circuit Breaker Pattern Implementation
Advanced circuit breaker for service resilience and failure isolation
"""

import asyncio
import time
from typing import Any, Callable, Optional, Dict, List, Union
from enum import Enum
from dataclasses import dataclass, field
from functools import wraps
import logging
from collections import deque
import threading

from app.utils.exceptions import (
    AIVONITYException, 
    ExternalServiceError, 
    NetworkError, 
    DatabaseError,
    SystemError
)


class CircuitState(str, Enum):
    """Circuit breaker states"""
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Circuit is open, failing fast
    HALF_OPEN = "half_open"  # Testing if service is back


@dataclass
class CircuitBreakerConfig:
    """Configuration for circuit breaker behavior"""
    failure_threshold: int = 5  # Number of failures to open circuit
    recovery_timeout: int = 60  # Seconds to wait before trying half-open
    success_threshold: int = 3  # Successful calls needed to close circuit
    timeout: float = 30.0  # Request timeout in seconds
    expected_exception: tuple = (
        ExternalServiceError,
        NetworkError,
        DatabaseError,
        ConnectionError,
        TimeoutError,
        asyncio.TimeoutError
    )
    # Sliding window for failure tracking
    window_size: int = 100  # Number of recent calls to track
    minimum_calls: int = 10  # Minimum calls before circuit can open


@dataclass
class CircuitBreakerStats:
    """Statistics for circuit breaker monitoring"""
    total_calls: int = 0
    successful_calls: int = 0
    failed_calls: int = 0
    circuit_opens: int = 0
    circuit_closes: int = 0
    last_failure_time: Optional[float] = None
    last_success_time: Optional[float] = None
    current_state: CircuitState = CircuitState.CLOSED
    failure_rate: float = 0.0


class CircuitBreakerOpenException(AIVONITYException):
    """Exception raised when circuit breaker is open"""
    
    def __init__(self, service_name: str, retry_after: int, **kwargs):
        super().__init__(
            message=f"Circuit breaker is open for {service_name}",
            error_code="CB_001",
            status_code=503,
            retry_after=retry_after,
            user_message=f"Service {service_name} is temporarily unavailable. Please try again later.",
            details={'service_name': service_name},
            **kwargs
        )
c
lass CircuitBreaker:
    """Advanced circuit breaker implementation with comprehensive monitoring"""
    
    def __init__(self, name: str, config: CircuitBreakerConfig = None):
        self.name = name
        self.config = config or CircuitBreakerConfig()
        self.logger = logging.getLogger(f"circuit_breaker.{name}")
        
        # State management
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure_time = None
        self._next_attempt_time = None
        
        # Sliding window for failure tracking
        self._call_history = deque(maxlen=self.config.window_size)
        
        # Statistics
        self.stats = CircuitBreakerStats()
        
        # Thread safety
        self._lock = threading.RLock()
    
    @property
    def state(self) -> CircuitState:
        """Get current circuit state"""
        with self._lock:
            return self._state
    
    @property
    def is_closed(self) -> bool:
        """Check if circuit is closed (normal operation)"""
        return self.state == CircuitState.CLOSED
    
    @property
    def is_open(self) -> bool:
        """Check if circuit is open (failing fast)"""
        return self.state == CircuitState.OPEN
    
    @property
    def is_half_open(self) -> bool:
        """Check if circuit is half-open (testing)"""
        return self.state == CircuitState.HALF_OPEN
    
    def _should_attempt_reset(self) -> bool:
        """Check if we should attempt to reset the circuit"""
        if self._state != CircuitState.OPEN:
            return False
        
        if self._next_attempt_time is None:
            return True
        
        return time.time() >= self._next_attempt_time
    
    def _record_success(self):
        """Record a successful call"""
        with self._lock:
            current_time = time.time()
            self._call_history.append((current_time, True))
            self.stats.total_calls += 1
            self.stats.successful_calls += 1
            self.stats.last_success_time = current_time
            
            if self._state == CircuitState.HALF_OPEN:
                self._success_count += 1
                if self._success_count >= self.config.success_threshold:
                    self._close_circuit()
            elif self._state == CircuitState.CLOSED:
                # Reset failure count on success
                self._failure_count = 0
            
            self._update_failure_rate()
    
    def _record_failure(self, exception: Exception):
        """Record a failed call"""
        with self._lock:
            current_time = time.time()
            self._call_history.append((current_time, False))
            self.stats.total_calls += 1
            self.stats.failed_calls += 1
            self.stats.last_failure_time = current_time
            
            # Only count expected exceptions as failures
            if isinstance(exception, self.config.expected_exception):
                self._failure_count += 1
                self._last_failure_time = current_time
                
                if self._state == CircuitState.HALF_OPEN:
                    # Failed during half-open, go back to open
                    self._open_circuit()
                elif self._state == CircuitState.CLOSED:
                    # Check if we should open the circuit
                    if (self._failure_count >= self.config.failure_threshold and 
                        len(self._call_history) >= self.config.minimum_calls):
                        self._open_circuit()
            
            self._update_failure_rate()
    
    def _update_failure_rate(self):
        """Update the current failure rate"""
        if not self._call_history:
            self.stats.failure_rate = 0.0
            return
        
        failures = sum(1 for _, success in self._call_history if not success)
        self.stats.failure_rate = failures / len(self._call_history)
    
    def _open_circuit(self):
        """Open the circuit breaker"""
        if self._state != CircuitState.OPEN:
            self._state = CircuitState.OPEN
            self._next_attempt_time = time.time() + self.config.recovery_timeout
            self._success_count = 0
            self.stats.circuit_opens += 1
            self.stats.current_state = CircuitState.OPEN
            
            self.logger.warning(
                f"Circuit breaker {self.name} opened after {self._failure_count} failures",
                extra={
                    'circuit_breaker': self.name,
                    'state': 'open',
                    'failure_count': self._failure_count,
                    'failure_rate': self.stats.failure_rate,
                    'recovery_timeout': self.config.recovery_timeout
                }
            )
    
    def _close_circuit(self):
        """Close the circuit breaker"""
        if self._state != CircuitState.CLOSED:
            self._state = CircuitState.CLOSED
            self._failure_count = 0
            self._success_count = 0
            self._next_attempt_time = None
            self.stats.circuit_closes += 1
            self.stats.current_state = CircuitState.CLOSED
            
            self.logger.info(
                f"Circuit breaker {self.name} closed after successful recovery",
                extra={
                    'circuit_breaker': self.name,
                    'state': 'closed',
                    'success_count': self._success_count
                }
            )
    
    def _half_open_circuit(self):
        """Set circuit to half-open state"""
        if self._state == CircuitState.OPEN:
            self._state = CircuitState.HALF_OPEN
            self._success_count = 0
            self.stats.current_state = CircuitState.HALF_OPEN
            
            self.logger.info(
                f"Circuit breaker {self.name} entering half-open state",
                extra={
                    'circuit_breaker': self.name,
                    'state': 'half_open'
                }
            )
    
    async def call_async(self, func: Callable, *args, **kwargs) -> Any:
        """Execute async function with circuit breaker protection"""
        with self._lock:
            # Check if circuit is open
            if self._state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self._half_open_circuit()
                else:
                    retry_after = int(self._next_attempt_time - time.time()) if self._next_attempt_time else self.config.recovery_timeout
                    raise CircuitBreakerOpenException(
                        service_name=self.name,
                        retry_after=max(1, retry_after)
                    )
        
        # Execute the function
        start_time = time.time()
        try:
            # Apply timeout if configured
            if self.config.timeout > 0:
                result = await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=self.config.timeout
                )
            else:
                result = await func(*args, **kwargs)
            
            # Record success
            self._record_success()
            
            # Log performance
            duration = time.time() - start_time
            self.logger.debug(
                f"Circuit breaker {self.name} call succeeded",
                extra={
                    'circuit_breaker': self.name,
                    'duration': duration,
                    'state': self._state.value
                }
            )
            
            return result
            
        except Exception as e:
            # Record failure
            self._record_failure(e)
            
            # Log failure
            duration = time.time() - start_time
            self.logger.warning(
                f"Circuit breaker {self.name} call failed",
                extra={
                    'circuit_breaker': self.name,
                    'duration': duration,
                    'error': str(e),
                    'error_type': type(e).__name__,
                    'state': self._state.value,
                    'failure_count': self._failure_count
                }
            )
            
            raise
    
    def get_stats(self) -> Dict[str, Any]:
        """Get circuit breaker statistics"""
        with self._lock:
            return {
                'name': self.name,
                'state': self._state.value,
                'total_calls': self.stats.total_calls,
                'successful_calls': self.stats.successful_calls,
                'failed_calls': self.stats.failed_calls,
                'failure_rate': self.stats.failure_rate,
                'circuit_opens': self.stats.circuit_opens,
                'circuit_closes': self.stats.circuit_closes,
                'last_failure_time': self.stats.last_failure_time,
                'last_success_time': self.stats.last_success_time,
                'failure_count': self._failure_count,
                'success_count': self._success_count,
                'next_attempt_time': self._next_attempt_time
            }
    
    def reset(self):
        """Manually reset the circuit breaker"""
        with self._lock:
            self._close_circuit()
            self._call_history.clear()
            self.logger.info(
                f"Circuit breaker {self.name} manually reset",
                extra={'circuit_breaker': self.name, 'action': 'manual_reset'}
            )


class CircuitBreakerManager:
    """Manager for multiple circuit breakers"""
    
    def __init__(self):
        self._circuit_breakers: Dict[str, CircuitBreaker] = {}
        self._lock = threading.RLock()
        self.logger = logging.getLogger("circuit_breaker_manager")
    
    def get_circuit_breaker(self, name: str, config: CircuitBreakerConfig = None) -> CircuitBreaker:
        """Get or create a circuit breaker"""
        with self._lock:
            if name not in self._circuit_breakers:
                self._circuit_breakers[name] = CircuitBreaker(name, config)
                self.logger.info(
                    f"Created circuit breaker: {name}",
                    extra={'circuit_breaker': name, 'action': 'created'}
                )
            return self._circuit_breakers[name]
    
    def get_all_stats(self) -> Dict[str, Dict[str, Any]]:
        """Get statistics for all circuit breakers"""
        with self._lock:
            return {
                name: cb.get_stats() 
                for name, cb in self._circuit_breakers.items()
            }


# Global circuit breaker manager
circuit_breaker_manager = CircuitBreakerManager()


# Decorator functions
def circuit_breaker_async(name: str, config: CircuitBreakerConfig = None):
    """Decorator for async functions with circuit breaker protection"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            cb = circuit_breaker_manager.get_circuit_breaker(name, config)
            return await cb.call_async(func, *args, **kwargs)
        return wrapper
    return decorator


# Predefined circuit breaker configurations
class CircuitBreakerConfigs:
    """Predefined circuit breaker configurations"""
    
    # Fast-failing for external APIs
    EXTERNAL_API = CircuitBreakerConfig(
        failure_threshold=3,
        recovery_timeout=30,
        success_threshold=2,
        timeout=10.0
    )
    
    # Database connections
    DATABASE = CircuitBreakerConfig(
        failure_threshold=5,
        recovery_timeout=60,
        success_threshold=3,
        timeout=30.0
    )
    
    # AI service calls
    AI_SERVICE = CircuitBreakerConfig(
        failure_threshold=3,
        recovery_timeout=120,
        success_threshold=2,
        timeout=60.0
    )