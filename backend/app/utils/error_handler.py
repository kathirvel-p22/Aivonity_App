"""
AIVONITY Global Error Handler
Comprehensive error handling middleware for FastAPI with user-friendly responses
"""

import uuid
import traceback
from typing import Any, Dict, Optional
from datetime import datetime
import logging
import asyncio
from collections import deque

from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from pydantic import ValidationError

from app.utils.exceptions import (
    AIVONITYException,
    ErrorCategory,
    ErrorSeverity,
    AuthenticationError,
    AuthorizationError,
    ValidationError as AIVONITYValidationError,
    ExternalServiceError,
    DatabaseError,
    RateLimitError,
    SystemError
)

class GlobalErrorHandler:
    """Global error handler with comprehensive logging and user-friendly responses"""
    
    def __init__(self):
        self.logger = logging.getLogger("error_handler")
        self.error_metrics = {
            'total_errors': 0,
            'errors_by_category': {},
            'errors_by_severity': {},
            'recent_errors': deque(maxlen=100)
        }
    
    def _generate_correlation_id(self) -> str:
        """Generate unique correlation ID for error tracking"""
        return str(uuid.uuid4())
    
    def _log_error(
        self, 
        request: Request, 
        exception: Exception, 
        correlation_id: str,
        context: Optional[Dict[str, Any]] = None
    ):
        """Log error with comprehensive context"""
        context = context or {}
        
        error_context = {
            'correlation_id': correlation_id,
            'method': request.method,
            'url': str(request.url),
            'client_ip': request.client.host if request.client else None,
            'user_agent': request.headers.get('user-agent'),
            'error_type': type(exception).__name__,
            'error_message': str(exception),
            'timestamp': datetime.utcnow().isoformat(),
            **context
        }
        
        # Add user context if available
        if hasattr(request.state, 'user_id'):
            error_context['user_id'] = request.state.user_id
        
        # Update error metrics
        self._update_error_metrics(exception, error_context)
        
        # Log based on error severity
        if isinstance(exception, AIVONITYException):
            if exception.severity == ErrorSeverity.CRITICAL:
                self.logger.critical(
                    f"Critical error: {exception.message}",
                    extra=error_context,
                    exc_info=True
                )
            elif exception.severity == ErrorSeverity.HIGH:
                self.logger.error(
                    f"High severity error: {exception.message}",
                    extra=error_context,
                    exc_info=True
                )
            elif exception.severity == ErrorSeverity.MEDIUM:
                self.logger.warning(
                    f"Medium severity error: {exception.message}",
                    extra=error_context
                )
            else:  # LOW
                self.logger.info(
                    f"Low severity error: {exception.message}",
                    extra=error_context
                )
        else:
            # Unknown exception - log as error
            self.logger.error(
                f"Unhandled exception: {str(exception)}",
                extra=error_context,
                exc_info=True
            )
    
    def _update_error_metrics(self, exception: Exception, error_context: Dict[str, Any]):
        """Update error metrics for monitoring"""
        self.error_metrics['total_errors'] += 1
        
        # Track by category
        if isinstance(exception, AIVONITYException):
            category = exception.category.value
            severity = exception.severity.value
        else:
            category = 'unknown'
            severity = 'medium'
        
        self.error_metrics['errors_by_category'][category] = \
            self.error_metrics['errors_by_category'].get(category, 0) + 1
        self.error_metrics['errors_by_severity'][severity] = \
            self.error_metrics['errors_by_severity'].get(severity, 0) + 1
        
        # Store recent error for analysis
        self.error_metrics['recent_errors'].append({
            'timestamp': error_context.get('timestamp'),
            'error_type': error_context.get('error_type'),
            'category': category,
            'severity': severity,
            'correlation_id': error_context.get('correlation_id'),
            'url': error_context.get('url'),
            'method': error_context.get('method')
        })
    
    def get_error_metrics(self) -> Dict[str, Any]:
        """Get current error metrics"""
        return {
            'total_errors': self.error_metrics['total_errors'],
            'errors_by_category': dict(self.error_metrics['errors_by_category']),
            'errors_by_severity': dict(self.error_metrics['errors_by_severity']),
            'recent_errors_count': len(self.error_metrics['recent_errors']),
            'recent_errors': list(self.error_metrics['recent_errors'])
        }
    
    def reset_error_metrics(self):
        """Reset error metrics"""
        self.error_metrics = {
            'total_errors': 0,
            'errors_by_category': {},
            'errors_by_severity': {},
            'recent_errors': deque(maxlen=100)
        }
    
    def _create_error_response(
        self, 
        exception: Exception, 
        correlation_id: str,
        status_code: int = 500
    ) -> JSONResponse:
        """Create standardized error response"""
        
        if isinstance(exception, AIVONITYException):
            # Use AIVONITY exception details
            response_data = exception.to_dict()
            response_data['error']['correlation_id'] = correlation_id
            return JSONResponse(
                status_code=exception.status_code,
                content=response_data,
                headers=self._get_error_headers(exception)
            )
        
        # Handle standard HTTP exceptions
        elif isinstance(exception, HTTPException):
            return JSONResponse(
                status_code=exception.status_code,
                content={
                    "error": {
                        "code": f"HTTP_{exception.status_code}",
                        "message": exception.detail,
                        "user_message": self._get_user_friendly_message(exception.status_code),
                        "correlation_id": correlation_id,
                        "timestamp": datetime.utcnow().isoformat()
                    }
                }
            )
        
        # Handle validation errors
        elif isinstance(exception, (RequestValidationError, ValidationError)):
            return JSONResponse(
                status_code=422,
                content={
                    "error": {
                        "code": "VALIDATION_ERROR",
                        "message": "Request validation failed",
                        "user_message": "Please check your input and try again.",
                        "correlation_id": correlation_id,
                        "timestamp": datetime.utcnow().isoformat(),
                        "details": {
                            "validation_errors": self._format_validation_errors(exception)
                        }
                    }
                }
            )
        
        # Handle unknown exceptions
        else:
            return JSONResponse(
                status_code=500,
                content={
                    "error": {
                        "code": "INTERNAL_SERVER_ERROR",
                        "message": "An unexpected error occurred",
                        "user_message": "We're experiencing technical difficulties. Please try again later.",
                        "correlation_id": correlation_id,
                        "timestamp": datetime.utcnow().isoformat()
                    }
                }
            )
    
    def _get_error_headers(self, exception: AIVONITYException) -> Dict[str, str]:
        """Get appropriate headers for error response"""
        headers = {}
        
        if isinstance(exception, RateLimitError) and exception.retry_after:
            headers['Retry-After'] = str(exception.retry_after)
        
        return headers
    
    def _get_user_friendly_message(self, status_code: int) -> str:
        """Get user-friendly message for HTTP status codes"""
        messages = {
            400: "Invalid request. Please check your input and try again.",
            401: "Authentication required. Please log in and try again.",
            403: "You don't have permission to access this resource.",
            404: "The requested resource was not found.",
            405: "This operation is not allowed.",
            408: "Request timeout. Please try again.",
            409: "Conflict with current state. Please refresh and try again.",
            413: "Request too large. Please reduce the size and try again.",
            422: "Invalid input data. Please check your input and try again.",
            429: "Too many requests. Please wait a moment and try again.",
            500: "Internal server error. Please try again later.",
            502: "Service temporarily unavailable. Please try again later.",
            503: "Service temporarily unavailable. Please try again later.",
            504: "Request timeout. Please try again later."
        }
        return messages.get(status_code, "An error occurred. Please try again later.")
    
    def _format_validation_errors(self, exception) -> list:
        """Format validation errors for user-friendly display"""
        if isinstance(exception, RequestValidationError):
            errors = []
            for error in exception.errors():
                field = " -> ".join(str(loc) for loc in error["loc"])
                errors.append({
                    "field": field,
                    "message": error["msg"],
                    "type": error["type"]
                })
            return errors
        elif isinstance(exception, ValidationError):
            return [{"field": str(error["loc"]), "message": error["msg"]} for error in exception.errors()]
        return []


# Global error handler instance
global_error_handler = GlobalErrorHandler()


# Exception handlers for FastAPI
async def aivonity_exception_handler(request: Request, exc: AIVONITYException):
    """Handle AIVONITY custom exceptions"""
    correlation_id = exc.correlation_id or global_error_handler._generate_correlation_id()
    
    global_error_handler._log_error(
        request, 
        exc, 
        correlation_id,
        context={
            'error_category': exc.category.value,
            'error_severity': exc.severity.value,
            'error_code': exc.error_code
        }
    )
    
    return global_error_handler._create_error_response(exc, correlation_id)


async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle standard HTTP exceptions"""
    correlation_id = global_error_handler._generate_correlation_id()
    
    global_error_handler._log_error(request, exc, correlation_id)
    
    return global_error_handler._create_error_response(exc, correlation_id)


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle request validation exceptions"""
    correlation_id = global_error_handler._generate_correlation_id()
    
    global_error_handler._log_error(
        request, 
        exc, 
        correlation_id,
        context={'validation_errors': exc.errors()}
    )
    
    return global_error_handler._create_error_response(exc, correlation_id)


async def general_exception_handler(request: Request, exc: Exception):
    """Handle all other exceptions"""
    correlation_id = global_error_handler._generate_correlation_id()
    
    # Convert to appropriate AIVONITY exception if possible
    if isinstance(exc, asyncio.TimeoutError):
        aivonity_exc = SystemError(
            message="Operation timed out",
            correlation_id=correlation_id,
            severity=ErrorSeverity.HIGH
        )
    elif isinstance(exc, ConnectionError):
        aivonity_exc = ExternalServiceError(
            service_name="Unknown Service",
            message="Connection error",
            correlation_id=correlation_id
        )
    else:
        aivonity_exc = SystemError(
            message=f"Unexpected error: {str(exc)}",
            correlation_id=correlation_id,
            severity=ErrorSeverity.CRITICAL
        )
    
    global_error_handler._log_error(
        request, 
        aivonity_exc, 
        correlation_id,
        context={'original_exception': str(exc)}
    )
    
    return global_error_handler._create_error_response(aivonity_exc, correlation_id)


# Error handling middleware
class ErrorHandlingMiddleware:
    """Middleware for comprehensive error handling"""
    
    def __init__(self, app):
        self.app = app
        self.logger = logging.getLogger("error_middleware")
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                # Log response status for monitoring
                status_code = message["status"]
                if status_code >= 400:
                    self.logger.warning(
                        f"HTTP error response: {status_code}",
                        extra={
                            'status_code': status_code,
                            'path': scope.get('path'),
                            'method': scope.get('method')
                        }
                    )
            await send(message)
        
        try:
            await self.app(scope, receive, send_wrapper)
        except Exception as exc:
            # This should rarely be reached due to FastAPI's exception handling
            self.logger.critical(
                f"Unhandled exception in middleware: {str(exc)}",
                extra={
                    'path': scope.get('path'),
                    'method': scope.get('method'),
                    'exception_type': type(exc).__name__
                },
                exc_info=True
            )
            
            # Send error response
            response = JSONResponse(
                status_code=500,
                content={
                    "error": {
                        "code": "MIDDLEWARE_ERROR",
                        "message": "Critical system error",
                        "user_message": "We're experiencing technical difficulties. Please try again later.",
                        "correlation_id": str(uuid.uuid4()),
                        "timestamp": datetime.utcnow().isoformat()
                    }
                }
            )
            await response(scope, receive, send)


def setup_error_handlers(app):
    """Setup all error handlers for the FastAPI app"""
    
    # Add custom exception handlers
    app.add_exception_handler(AIVONITYException, aivonity_exception_handler)
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, general_exception_handler)
    
    # Add error handling middleware
    app.add_middleware(ErrorHandlingMiddleware)
    
    logging.getLogger("error_handler").info("Error handlers configured successfully")