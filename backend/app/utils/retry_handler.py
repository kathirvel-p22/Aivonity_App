"""
AIVONITY Retry Handler with Exponential Backoff
Advanced retry logic for resilient API calls and external service integration
"""

import asyncio
import random
import time
from typing import Any, Callable, Optional, Type, Union, List, Dict
from functools import wraps
import logging
from dataclasses import dataclass
from enum import Enum

from app.utils.exceptions import (
    AIVONITYException, 
    ExternalServiceError, 
    NetworkError, 
    DatabaseError,
    RateLimitError,
    AgentTimeoutError
)


class RetryStrategy(str, Enum):
    """Retry strategy types"""
    EXPONENTIAL_BACKOFF = "exponential_backoff"
    LINEAR_BACKOFF = "linear_backoff"
    FIXED_DELAY = "fixed_delay"
    IMMEDIATE = "immediate"


@dataclass
class RetryConfig:
    """Configuration for retry behavior"""
    max_attempts: int = 3
    base_delay: float = 1.0  # seconds
    max_delay: float = 60.0  # seconds
    exponential_base: float = 2.0
    jitter: bool = True
    jitter_range: float = 0.1  # 10% jitter
    strategy: RetryStrategy = RetryStrategy.EXPONENTIAL_BACKOFF
    retryable_exceptions: List[Type[Exception]] = None
    non_retryable_exceptions: List[Type[Exception]] = None
    
    def __post_init__(self):
        if self.retryable_exceptions is None:
            self.retryable_exceptions = [
                ExternalServiceError,
                NetworkError,
                DatabaseError,
                AgentTimeoutError,
                ConnectionError,
                TimeoutError,
                asyncio.TimeoutError
            ]
        
        if self.non_retryable_exceptions is None:
            self.non_retryable_exceptions = [
                RateLimitError,  # Handle separately with retry_after
                KeyboardInterrupt,
                SystemExit
            ]


class RetryHandler:
    """Advanced retry handler with multiple strategies and comprehensive logging"""
    
    def __init__(self, config: RetryConfig = None):
        self.config = config or RetryConfig()
        self.logger = logging.getLogger(__name__)
    
    def _calculate_delay(self, attempt: int) -> float:
        """Calculate delay based on retry strategy"""
        if self.config.strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            delay = self.config.base_delay * (self.config.exponential_base ** (attempt - 1))
        elif self.config.strategy == RetryStrategy.LINEAR_BACKOFF:
            delay = self.config.base_delay * attempt
        elif self.config.strategy == RetryStrategy.FIXED_DELAY:
            delay = self.config.base_delay
        else:  # IMMEDIATE
            delay = 0
        
        # Apply maximum delay limit
        delay = min(delay, self.config.max_delay)
        
        # Add jitter to prevent thundering herd
        if self.config.jitter and delay > 0:
            jitter_amount = delay * self.config.jitter_range
            delay += random.uniform(-jitter_amount, jitter_amount)
        
        return max(0, delay)
    
    def _should_retry(self, exception: Exception, attempt: int) -> bool:
        """Determine if an exception should trigger a retry"""
        # Check if we've exceeded max attempts
        if attempt >= self.config.max_attempts:
            return False
        
        # Check for non-retryable exceptions
        for non_retryable in self.config.non_retryable_exceptions:
            if isinstance(exception, non_retryable):
                return False
        
        # Check for retryable exceptions
        for retryable in self.config.retryable_exceptions:
            if isinstance(exception, retryable):
                return True
        
        # Default: don't retry unknown exceptions
        return False
    
    def _handle_rate_limit(self, exception: RateLimitError) -> float:
        """Handle rate limit exceptions with retry_after"""
        if exception.retry_after:
            return min(exception.retry_after, self.config.max_delay)
        return self.config.base_delay
    
    async def execute_async(
        self, 
        func: Callable, 
        *args, 
        context: Optional[Dict[str, Any]] = None,
        **kwargs
    ) -> Any:
        """Execute async function with retry logic"""
        context = context or {}
        last_exception = None
        
        for attempt in range(1, self.config.max_attempts + 1):
            try:
                self.logger.debug(
                    f"Executing {func.__name__} (attempt {attempt}/{self.config.max_attempts})",
                    extra={
                        'function': func.__name__,
                        'attempt': attempt,
                        'max_attempts': self.config.max_attempts,
                        **context
                    }
                )
                
                result = await func(*args, **kwargs)
                
                if attempt > 1:
                    self.logger.info(
                        f"Function {func.__name__} succeeded on attempt {attempt}",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'success_after_retry': True,
                            **context
                        }
                    )
                
                return result
                
            except Exception as e:
                last_exception = e
                
                # Special handling for rate limits
                if isinstance(e, RateLimitError):
                    if attempt < self.config.max_attempts:
                        delay = self._handle_rate_limit(e)
                        self.logger.warning(
                            f"Rate limit hit for {func.__name__}, waiting {delay}s",
                            extra={
                                'function': func.__name__,
                                'attempt': attempt,
                                'delay': delay,
                                'rate_limit_error': True,
                                **context
                            }
                        )
                        await asyncio.sleep(delay)
                        continue
                    else:
                        break
                
                # Check if we should retry
                if not self._should_retry(e, attempt):
                    self.logger.error(
                        f"Function {func.__name__} failed with non-retryable error",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'error': str(e),
                            'error_type': type(e).__name__,
                            'non_retryable': True,
                            **context
                        }
                    )
                    break
                
                # Calculate delay for next attempt
                if attempt < self.config.max_attempts:
                    delay = self._calculate_delay(attempt)
                    
                    self.logger.warning(
                        f"Function {func.__name__} failed on attempt {attempt}, retrying in {delay:.2f}s",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'delay': delay,
                            'error': str(e),
                            'error_type': type(e).__name__,
                            **context
                        }
                    )
                    
                    await asyncio.sleep(delay)
                else:
                    self.logger.error(
                        f"Function {func.__name__} failed after {attempt} attempts",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'max_attempts_reached': True,
                            'error': str(e),
                            'error_type': type(e).__name__,
                            **context
                        }
                    )
        
        # All attempts failed, raise the last exception
        raise last_exception
    
    def execute_sync(
        self, 
        func: Callable, 
        *args, 
        context: Optional[Dict[str, Any]] = None,
        **kwargs
    ) -> Any:
        """Execute sync function with retry logic"""
        context = context or {}
        last_exception = None
        
        for attempt in range(1, self.config.max_attempts + 1):
            try:
                self.logger.debug(
                    f"Executing {func.__name__} (attempt {attempt}/{self.config.max_attempts})",
                    extra={
                        'function': func.__name__,
                        'attempt': attempt,
                        'max_attempts': self.config.max_attempts,
                        **context
                    }
                )
                
                result = func(*args, **kwargs)
                
                if attempt > 1:
                    self.logger.info(
                        f"Function {func.__name__} succeeded on attempt {attempt}",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'success_after_retry': True,
                            **context
                        }
                    )
                
                return result
                
            except Exception as e:
                last_exception = e
                
                # Special handling for rate limits
                if isinstance(e, RateLimitError):
                    if attempt < self.config.max_attempts:
                        delay = self._handle_rate_limit(e)
                        self.logger.warning(
                            f"Rate limit hit for {func.__name__}, waiting {delay}s",
                            extra={
                                'function': func.__name__,
                                'attempt': attempt,
                                'delay': delay,
                                'rate_limit_error': True,
                                **context
                            }
                        )
                        time.sleep(delay)
                        continue
                    else:
                        break
                
                # Check if we should retry
                if not self._should_retry(e, attempt):
                    self.logger.error(
                        f"Function {func.__name__} failed with non-retryable error",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'error': str(e),
                            'error_type': type(e).__name__,
                            'non_retryable': True,
                            **context
                        }
                    )
                    break
                
                # Calculate delay for next attempt
                if attempt < self.config.max_attempts:
                    delay = self._calculate_delay(attempt)
                    
                    self.logger.warning(
                        f"Function {func.__name__} failed on attempt {attempt}, retrying in {delay:.2f}s",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'delay': delay,
                            'error': str(e),
                            'error_type': type(e).__name__,
                            **context
                        }
                    )
                    
                    time.sleep(delay)
                else:
                    self.logger.error(
                        f"Function {func.__name__} failed after {attempt} attempts",
                        extra={
                            'function': func.__name__,
                            'attempt': attempt,
                            'max_attempts_reached': True,
                            'error': str(e),
                            'error_type': type(e).__name__,
                            **context
                        }
                    )
        
        # All attempts failed, raise the last exception
        raise last_exception


# Decorator functions for easy usage
def retry_async(config: RetryConfig = None, context: Dict[str, Any] = None):
    """Decorator for async functions with retry logic"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            handler = RetryHandler(config)
            return await handler.execute_async(func, *args, context=context, **kwargs)
        return wrapper
    return decorator


def retry_sync(config: RetryConfig = None, context: Dict[str, Any] = None):
    """Decorator for sync functions with retry logic"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            handler = RetryHandler(config)
            return handler.execute_sync(func, *args, context=context, **kwargs)
        return wrapper
    return decorator


# Predefined retry configurations
class RetryConfigs:
    """Predefined retry configurations for common scenarios"""
    
    # Quick retry for fast operations
    QUICK = RetryConfig(
        max_attempts=3,
        base_delay=0.5,
        max_delay=5.0,
        strategy=RetryStrategy.EXPONENTIAL_BACKOFF
    )
    
    # Standard retry for most operations
    STANDARD = RetryConfig(
        max_attempts=3,
        base_delay=1.0,
        max_delay=30.0,
        strategy=RetryStrategy.EXPONENTIAL_BACKOFF
    )
    
    # Aggressive retry for critical operations
    AGGRESSIVE = RetryConfig(
        max_attempts=5,
        base_delay=1.0,
        max_delay=60.0,
        strategy=RetryStrategy.EXPONENTIAL_BACKOFF
    )
    
    # External service retry with longer delays
    EXTERNAL_SERVICE = RetryConfig(
        max_attempts=4,
        base_delay=2.0,
        max_delay=120.0,
        strategy=RetryStrategy.EXPONENTIAL_BACKOFF,
        retryable_exceptions=[
            ExternalServiceError,
            NetworkError,
            ConnectionError,
            TimeoutError,
            asyncio.TimeoutError
        ]
    )
    
    # Database retry with shorter delays
    DATABASE = RetryConfig(
        max_attempts=3,
        base_delay=0.5,
        max_delay=10.0,
        strategy=RetryStrategy.EXPONENTIAL_BACKOFF,
        retryable_exceptions=[
            DatabaseError,
            ConnectionError
        ]
    )
    
    # AI model retry with custom handling
    AI_MODEL = RetryConfig(
        max_attempts=3,
        base_delay=2.0,
        max_delay=30.0,
        strategy=RetryStrategy.EXPONENTIAL_BACKOFF,
        retryable_exceptions=[
            ExternalServiceError,
            AgentTimeoutError,
            NetworkError
        ]
    )


# Global retry handler instances
default_retry_handler = RetryHandler()
quick_retry_handler = RetryHandler(RetryConfigs.QUICK)
aggressive_retry_handler = RetryHandler(RetryConfigs.AGGRESSIVE)
external_service_retry_handler = RetryHandler(RetryConfigs.EXTERNAL_SERVICE)
database_retry_handler = RetryHandler(RetryConfigs.DATABASE)
ai_model_retry_handler = RetryHandler(RetryConfigs.AI_MODEL)