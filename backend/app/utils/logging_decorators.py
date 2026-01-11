"""
AIVONITY Logging Decorators
Decorators for automatic logging of function calls, performance, and audit trails
"""

import asyncio
import functools
import logging
import time
from typing import Any, Callable, Dict, Optional, Union
from datetime import datetime
import inspect

from app.utils.logging_config import performance_logger, security_logger, audit_logger
from app.utils.audit_trail import (
    audit_trail_manager, 
    AuditEventType, 
    AuditSeverity,
    AuditContext
)
from app.utils.metrics import metrics_collector, timer


def log_function_call(
    logger_name: Optional[str] = None,
    level: str = "INFO",
    include_args: bool = False,
    include_result: bool = False,
    sensitive_params: Optional[list] = None
):
    """
    Decorator to log function calls with optional parameters and results
    
    Args:
        logger_name: Name of logger to use (defaults to module name)
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        include_args: Whether to include function arguments in log
        include_result: Whether to include function result in log
        sensitive_params: List of parameter names to redact from logs
    """
    def decorator(func: Callable) -> Callable:
        # Get logger
        logger = logging.getLogger(logger_name or func.__module__)
        log_level = getattr(logging, level.upper())
        sensitive_params_set = set(sensitive_params or [])
        
        if asyncio.iscoroutinefunction(func):
            @functools.wraps(func)
            async def async_wrapper(*args, **kwargs):
                start_time = time.time()
                
                # Prepare log data
                log_data = {
                    "function": func.__name__,
                    "module": func.__module__,
                    "start_time": datetime.utcnow().isoformat()
                }
                
                # Include arguments if requested
                if include_args:
                    # Get function signature
                    sig = inspect.signature(func)
                    bound_args = sig.bind(*args, **kwargs)
                    bound_args.apply_defaults()
                    
                    # Redact sensitive parameters
                    safe_args = {}
                    for param_name, value in bound_args.arguments.items():
                        if param_name in sensitive_params_set:
                            safe_args[param_name] = "[REDACTED]"
                        else:
                            safe_args[param_name] = str(value)[:200]  # Limit length
                    
                    log_data["arguments"] = safe_args
                
                try:
                    # Execute function
                    result = await func(*args, **kwargs)
                    
                    # Calculate execution time
                    execution_time = time.time() - start_time
                    log_data["execution_time_ms"] = execution_time * 1000
                    log_data["success"] = True
                    
                    # Include result if requested
                    if include_result and result is not None:
                        log_data["result"] = str(result)[:500]  # Limit length
                    
                    # Log successful execution
                    logger.log(log_level, f"Function {func.__name__} completed successfully", extra=log_data)
                    
                    return result
                    
                except Exception as e:
                    # Calculate execution time for failed calls
                    execution_time = time.time() - start_time
                    log_data["execution_time_ms"] = execution_time * 1000
                    log_data["success"] = False
                    log_data["error"] = str(e)
                    log_data["error_type"] = type(e).__name__
                    
                    # Log failed execution
                    logger.error(f"Function {func.__name__} failed: {str(e)}", extra=log_data)
                    
                    raise
            
            return async_wrapper
        else:
            @functools.wraps(func)
            def sync_wrapper(*args, **kwargs):
                start_time = time.time()
                
                # Prepare log data
                log_data = {
                    "function": func.__name__,
                    "module": func.__module__,
                    "start_time": datetime.utcnow().isoformat()
                }
                
                # Include arguments if requested
                if include_args:
                    # Get function signature
                    sig = inspect.signature(func)
                    bound_args = sig.bind(*args, **kwargs)
                    bound_args.apply_defaults()
                    
                    # Redact sensitive parameters
                    safe_args = {}
                    for param_name, value in bound_args.arguments.items():
                        if param_name in sensitive_params_set:
                            safe_args[param_name] = "[REDACTED]"
                        else:
                            safe_args[param_name] = str(value)[:200]  # Limit length
                    
                    log_data["arguments"] = safe_args
                
                try:
                    # Execute function
                    result = func(*args, **kwargs)
                    
                    # Calculate execution time
                    execution_time = time.time() - start_time
                    log_data["execution_time_ms"] = execution_time * 1000
                    log_data["success"] = True
                    
                    # Include result if requested
                    if include_result and result is not None:
                        log_data["result"] = str(result)[:500]  # Limit length
                    
                    # Log successful execution
                    logger.log(log_level, f"Function {func.__name__} completed successfully", extra=log_data)
                    
                    return result
                    
                except Exception as e:
                    # Calculate execution time for failed calls
                    execution_time = time.time() - start_time
                    log_data["execution_time_ms"] = execution_time * 1000
                    log_data["success"] = False
                    log_data["error"] = str(e)
                    log_data["error_type"] = type(e).__name__
                    
                    # Log failed execution
                    logger.error(f"Function {func.__name__} failed: {str(e)}", extra=log_data)
                    
                    raise
            
            return sync_wrapper
    
    return decorator


def log_performance(
    metric_name: Optional[str] = None,
    include_args: bool = False,
    threshold_ms: float = 1000.0
):
    """
    Decorator to log performance metrics for functions
    
    Args:
        metric_name: Custom metric name (defaults to function name)
        include_args: Whether to include function arguments in performance log
        threshold_ms: Log warning if execution time exceeds this threshold
    """
    def decorator(func: Callable) -> Callable:
        perf_metric_name = metric_name or f"{func.__module__}.{func.__name__}"
        
        if asyncio.iscoroutinefunction(func):
            @functools.wraps(func)
            async def async_wrapper(*args, **kwargs):
                start_time = time.time()
                
                try:
                    result = await func(*args, **kwargs)
                    execution_time = time.time() - start_time
                    
                    # Record performance metrics
                    performance_logger.log_api_performance(
                        endpoint=func.__name__,
                        method="FUNCTION",
                        duration=execution_time,
                        status_code=200
                    )
                    
                    # Record in metrics collector
                    metrics_collector.record_timer(
                        f"function_execution_time_ms",
                        execution_time * 1000,
                        {"function": perf_metric_name}
                    )
                    
                    # Log warning if slow
                    if execution_time * 1000 > threshold_ms:
                        logging.getLogger("performance").warning(
                            f"Slow function execution: {func.__name__} took {execution_time*1000:.0f}ms",
                            extra={
                                "function": func.__name__,
                                "execution_time_ms": execution_time * 1000,
                                "threshold_ms": threshold_ms,
                                "arguments": str(args)[:200] if include_args else None
                            }
                        )
                    
                    return result
                    
                except Exception as e:
                    execution_time = time.time() - start_time
                    
                    # Record failed performance
                    performance_logger.log_api_performance(
                        endpoint=func.__name__,
                        method="FUNCTION",
                        duration=execution_time,
                        status_code=500
                    )
                    
                    raise
            
            return async_wrapper
        else:
            @functools.wraps(func)
            def sync_wrapper(*args, **kwargs):
                start_time = time.time()
                
                try:
                    result = func(*args, **kwargs)
                    execution_time = time.time() - start_time
                    
                    # Record performance metrics
                    performance_logger.log_api_performance(
                        endpoint=func.__name__,
                        method="FUNCTION",
                        duration=execution_time,
                        status_code=200
                    )
                    
                    # Record in metrics collector
                    metrics_collector.record_timer(
                        f"function_execution_time_ms",
                        execution_time * 1000,
                        {"function": perf_metric_name}
                    )
                    
                    # Log warning if slow
                    if execution_time * 1000 > threshold_ms:
                        logging.getLogger("performance").warning(
                            f"Slow function execution: {func.__name__} took {execution_time*1000:.0f}ms",
                            extra={
                                "function": func.__name__,
                                "execution_time_ms": execution_time * 1000,
                                "threshold_ms": threshold_ms,
                                "arguments": str(args)[:200] if include_args else None
                            }
                        )
                    
                    return result
                    
                except Exception as e:
                    execution_time = time.time() - start_time
                    
                    # Record failed performance
                    performance_logger.log_api_performance(
                        endpoint=func.__name__,
                        method="FUNCTION",
                        duration=execution_time,
                        status_code=500
                    )
                    
                    raise
            
            return sync_wrapper
    
    return decorator


def audit_data_access(
    resource_type: str,
    action: str = "read",
    resource_id_param: str = "id",
    user_id_param: str = "user_id",
    severity: AuditSeverity = AuditSeverity.LOW
):
    """
    Decorator to audit data access operations
    
    Args:
        resource_type: Type of resource being accessed
        action: Action being performed (read, create, update, delete)
        resource_id_param: Parameter name containing resource ID
        user_id_param: Parameter name containing user ID
        severity: Audit severity level
    """
    def decorator(func: Callable) -> Callable:
        if asyncio.iscoroutinefunction(func):
            @functools.wraps(func)
            async def async_wrapper(*args, **kwargs):
                # Extract parameters
                sig = inspect.signature(func)
                bound_args = sig.bind(*args, **kwargs)
                bound_args.apply_defaults()
                
                resource_id = bound_args.arguments.get(resource_id_param)
                user_id = bound_args.arguments.get(user_id_param)
                
                # Create audit context
                context = AuditContext(audit_trail_manager)
                if user_id:
                    context.set_user(str(user_id))
                
                try:
                    result = await func(*args, **kwargs)
                    
                    # Log successful data access
                    await context.log_event(
                        event_type=getattr(AuditEventType, f"DATA_{action.upper()}", AuditEventType.DATA_ACCESS),
                        action=action,
                        resource_type=resource_type,
                        resource_id=str(resource_id) if resource_id else None,
                        details={
                            "function": func.__name__,
                            "module": func.__module__,
                            "success": True
                        },
                        severity=severity,
                        success=True
                    )
                    
                    return result
                    
                except Exception as e:
                    # Log failed data access
                    await context.log_event(
                        event_type=getattr(AuditEventType, f"DATA_{action.upper()}", AuditEventType.DATA_ACCESS),
                        action=action,
                        resource_type=resource_type,
                        resource_id=str(resource_id) if resource_id else None,
                        details={
                            "function": func.__name__,
                            "module": func.__module__,
                            "error": str(e),
                            "error_type": type(e).__name__
                        },
                        severity=AuditSeverity.HIGH,
                        success=False,
                        error_message=str(e)
                    )
                    
                    raise
            
            return async_wrapper
        else:
            @functools.wraps(func)
            def sync_wrapper(*args, **kwargs):
                # Extract parameters
                sig = inspect.signature(func)
                bound_args = sig.bind(*args, **kwargs)
                bound_args.apply_defaults()
                
                resource_id = bound_args.arguments.get(resource_id_param)
                user_id = bound_args.arguments.get(user_id_param)
                
                # Create audit context
                context = AuditContext(audit_trail_manager)
                if user_id:
                    context.set_user(str(user_id))
                
                try:
                    result = func(*args, **kwargs)
                    
                    # Log successful data access (sync version would need to be handled differently)
                    # For now, just log to audit logger
                    audit_logger.log_data_access(
                        user_id=str(user_id) if user_id else "unknown",
                        resource_type=resource_type,
                        resource_id=str(resource_id) if resource_id else "unknown",
                        action=action
                    )
                    
                    return result
                    
                except Exception as e:
                    # Log failed data access
                    audit_logger.log_system_event(
                        event_type=f"data_access_failed",
                        details={
                            "function": func.__name__,
                            "resource_type": resource_type,
                            "action": action,
                            "error": str(e)
                        },
                        severity="error"
                    )
                    
                    raise
            
            return sync_wrapper
    
    return decorator


def log_security_event(
    event_type: str = "security_event",
    severity: str = "medium",
    include_request_info: bool = True
):
    """
    Decorator to log security-related events
    
    Args:
        event_type: Type of security event
        severity: Severity level (low, medium, high, critical)
        include_request_info: Whether to include request information
    """
    def decorator(func: Callable) -> Callable:
        if asyncio.iscoroutinefunction(func):
            @functools.wraps(func)
            async def async_wrapper(*args, **kwargs):
                try:
                    result = await func(*args, **kwargs)
                    
                    # Log successful security event
                    security_logger.log_suspicious_activity(
                        user_id="unknown",  # Would extract from context in real implementation
                        activity_type=event_type,
                        details={
                            "function": func.__name__,
                            "module": func.__module__,
                            "success": True,
                            "arguments": str(kwargs) if kwargs else None
                        },
                        risk_score=0.1 if severity == "low" else 0.5 if severity == "medium" else 0.8
                    )
                    
                    return result
                    
                except Exception as e:
                    # Log failed security event
                    security_logger.log_suspicious_activity(
                        user_id="unknown",
                        activity_type=f"{event_type}_failed",
                        details={
                            "function": func.__name__,
                            "module": func.__module__,
                            "error": str(e),
                            "error_type": type(e).__name__
                        },
                        risk_score=0.7  # Higher risk for failed security operations
                    )
                    
                    raise
            
            return async_wrapper
        else:
            @functools.wraps(func)
            def sync_wrapper(*args, **kwargs):
                try:
                    result = func(*args, **kwargs)
                    
                    # Log successful security event
                    security_logger.log_suspicious_activity(
                        user_id="unknown",
                        activity_type=event_type,
                        details={
                            "function": func.__name__,
                            "module": func.__module__,
                            "success": True
                        },
                        risk_score=0.1 if severity == "low" else 0.5 if severity == "medium" else 0.8
                    )
                    
                    return result
                    
                except Exception as e:
                    # Log failed security event
                    security_logger.log_suspicious_activity(
                        user_id="unknown",
                        activity_type=f"{event_type}_failed",
                        details={
                            "function": func.__name__,
                            "error": str(e)
                        },
                        risk_score=0.7
                    )
                    
                    raise
            
            return sync_wrapper
    
    return decorator


# Convenience decorators combining multiple logging aspects
def comprehensive_logging(
    include_performance: bool = True,
    include_audit: bool = False,
    resource_type: Optional[str] = None,
    audit_action: str = "access",
    sensitive_params: Optional[list] = None
):
    """
    Comprehensive logging decorator that combines function logging and performance monitoring
    
    Args:
        include_performance: Whether to include performance monitoring
        include_audit: Whether to include audit logging
        resource_type: Resource type for audit logging
        audit_action: Action type for audit logging
        sensitive_params: List of sensitive parameter names to redact
    """
    def decorator(func: Callable) -> Callable:
        # Apply function call logging
        func = log_function_call(
            include_args=True,
            sensitive_params=sensitive_params
        )(func)
        
        # Apply performance logging if requested
        if include_performance:
            func = log_performance()(func)
        
        # Apply audit logging if requested
        if include_audit and resource_type:
            func = audit_data_access(
                resource_type=resource_type,
                action=audit_action
            )(func)
        
        return func
    
    return decorator