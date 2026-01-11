"""
AIVONITY Custom Exceptions and Error Handling
Comprehensive error handling with user-friendly messages and proper categorization
"""

from typing import Any, Dict, Optional, List
from enum import Enum
import traceback
from datetime import datetime


class ErrorCategory(str, Enum):
    """Error categories for better classification and handling"""
    AUTHENTICATION = "authentication"
    AUTHORIZATION = "authorization"
    VALIDATION = "validation"
    BUSINESS_LOGIC = "business_logic"
    EXTERNAL_SERVICE = "external_service"
    DATABASE = "database"
    NETWORK = "network"
    SYSTEM = "system"
    AI_MODEL = "ai_model"
    RATE_LIMIT = "rate_limit"


class ErrorSeverity(str, Enum):
    """Error severity levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AIVONITYException(Exception):
    """Base exception class for AIVONITY with enhanced error information"""
    
    def __init__(
        self,
        message: str,
        error_code: str,
        category: ErrorCategory = ErrorCategory.SYSTEM,
        severity: ErrorSeverity = ErrorSeverity.MEDIUM,
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None,
        user_message: Optional[str] = None,
        correlation_id: Optional[str] = None,
        retry_after: Optional[int] = None
    ):
        self.message = message
        self.error_code = error_code
        self.category = category
        self.severity = severity
        self.status_code = status_code
        self.details = details or {}
        self.user_message = user_message or self._generate_user_message()
        self.correlation_id = correlation_id
        self.retry_after = retry_after
        self.timestamp = datetime.utcnow()
        self.traceback = traceback.format_exc()
        
        super().__init__(self.message)
    
    def _generate_user_message(self) -> str:
        """Generate user-friendly error message based on category"""
        user_messages = {
            ErrorCategory.AUTHENTICATION: "Please check your login credentials and try again.",
            ErrorCategory.AUTHORIZATION: "You don't have permission to access this resource.",
            ErrorCategory.VALIDATION: "Please check your input and try again.",
            ErrorCategory.BUSINESS_LOGIC: "Unable to complete the requested operation.",
            ErrorCategory.EXTERNAL_SERVICE: "External service is temporarily unavailable. Please try again later.",
            ErrorCategory.DATABASE: "Data service is temporarily unavailable. Please try again later.",
            ErrorCategory.NETWORK: "Network connection issue. Please check your connection and try again.",
            ErrorCategory.SYSTEM: "System is temporarily unavailable. Please try again later.",
            ErrorCategory.AI_MODEL: "AI service is temporarily unavailable. Please try again later.",
            ErrorCategory.RATE_LIMIT: "Too many requests. Please wait a moment and try again."
        }
        return user_messages.get(self.category, "An unexpected error occurred. Please try again later.")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert exception to dictionary for API responses"""
        return {
            "error": {
                "code": self.error_code,
                "message": self.message,
                "user_message": self.user_message,
                "category": self.category.value,
                "severity": self.severity.value,
                "timestamp": self.timestamp.isoformat(),
                "correlation_id": self.correlation_id,
                "details": self.details,
                "retry_after": self.retry_after
            }
        }


# Authentication and Authorization Exceptions
class AuthenticationError(AIVONITYException):
    """Authentication related errors"""
    
    def __init__(self, message: str = "Authentication failed", **kwargs):
        super().__init__(
            message=message,
            error_code="AUTH_001",
            category=ErrorCategory.AUTHENTICATION,
            status_code=401,
            **kwargs
        )


class TokenExpiredError(AuthenticationError):
    """Token expired error"""
    
    def __init__(self, **kwargs):
        super().__init__(
            message="Authentication token has expired",
            error_code="AUTH_002",
            user_message="Your session has expired. Please log in again.",
            **kwargs
        )


class InvalidTokenError(AuthenticationError):
    """Invalid token error"""
    
    def __init__(self, **kwargs):
        super().__init__(
            message="Invalid authentication token",
            error_code="AUTH_003",
            user_message="Invalid authentication. Please log in again.",
            **kwargs
        )


class AuthorizationError(AIVONITYException):
    """Authorization related errors"""
    
    def __init__(self, message: str = "Access denied", **kwargs):
        super().__init__(
            message=message,
            error_code="AUTHZ_001",
            category=ErrorCategory.AUTHORIZATION,
            status_code=403,
            **kwargs
        )


# Validation Exceptions
class ValidationError(AIVONITYException):
    """Data validation errors"""
    
    def __init__(self, message: str, field_errors: Optional[List[Dict[str, str]]] = None, **kwargs):
        details = kwargs.get('details', {})
        if field_errors:
            details['field_errors'] = field_errors
        
        super().__init__(
            message=message,
            error_code="VAL_001",
            category=ErrorCategory.VALIDATION,
            status_code=422,
            details=details,
            **kwargs
        )
cl
ass BusinessLogicError(AIVONITYException):
    """Business logic related errors"""
    
    def __init__(self, message: str, **kwargs):
        super().__init__(
            message=message,
            error_code="BIZ_001",
            category=ErrorCategory.BUSINESS_LOGIC,
            status_code=400,
            **kwargs
        )


# External Service Exceptions
class ExternalServiceError(AIVONITYException):
    """External service integration errors"""
    
    def __init__(self, service_name: str, message: str = "External service error", **kwargs):
        details = kwargs.get('details', {})
        details['service_name'] = service_name
        
        super().__init__(
            message=f"{service_name}: {message}",
            error_code="EXT_001",
            category=ErrorCategory.EXTERNAL_SERVICE,
            status_code=502,
            details=details,
            **kwargs
        )


class AIServiceError(ExternalServiceError):
    """AI service specific errors"""
    
    def __init__(self, provider: str, message: str = "AI service error", **kwargs):
        super().__init__(
            service_name=f"AI Provider ({provider})",
            message=message,
            error_code="AI_001",
            category=ErrorCategory.AI_MODEL,
            **kwargs
        )


class NotificationServiceError(ExternalServiceError):
    """Notification service errors"""
    
    def __init__(self, service: str, message: str = "Notification service error", **kwargs):
        super().__init__(
            service_name=f"Notification Service ({service})",
            message=message,
            error_code="NOTIF_001",
            **kwargs
        )


# Database Exceptions
class DatabaseError(AIVONITYException):
    """Database related errors"""
    
    def __init__(self, message: str = "Database error", **kwargs):
        super().__init__(
            message=message,
            error_code="DB_001",
            category=ErrorCategory.DATABASE,
            status_code=500,
            **kwargs
        )


class ResourceNotFoundError(AIVONITYException):
    """Resource not found errors"""
    
    def __init__(self, resource_type: str, resource_id: str = None, **kwargs):
        message = f"{resource_type} not found"
        if resource_id:
            message += f" (ID: {resource_id})"
        
        details = kwargs.get('details', {})
        details.update({
            'resource_type': resource_type,
            'resource_id': resource_id
        })
        
        super().__init__(
            message=message,
            error_code="RES_001",
            category=ErrorCategory.BUSINESS_LOGIC,
            status_code=404,
            details=details,
            user_message=f"The requested {resource_type.lower()} was not found.",
            **kwargs
        )


class ResourceConflictError(AIVONITYException):
    """Resource conflict errors"""
    
    def __init__(self, resource_type: str, conflict_reason: str, **kwargs):
        super().__init__(
            message=f"{resource_type} conflict: {conflict_reason}",
            error_code="RES_002",
            category=ErrorCategory.BUSINESS_LOGIC,
            status_code=409,
            details={
                'resource_type': resource_type,
                'conflict_reason': conflict_reason
            },
            **kwargs
        )


# Rate Limiting Exceptions
class RateLimitError(AIVONITYException):
    """Rate limiting errors"""
    
    def __init__(self, limit: int, window: int, retry_after: int = None, **kwargs):
        super().__init__(
            message=f"Rate limit exceeded: {limit} requests per {window} seconds",
            error_code="RATE_001",
            category=ErrorCategory.RATE_LIMIT,
            status_code=429,
            retry_after=retry_after,
            details={
                'limit': limit,
                'window': window
            },
            user_message=f"Too many requests. Please wait {retry_after or window} seconds before trying again.",
            **kwargs
        )


# Network and System Exceptions
class NetworkError(AIVONITYException):
    """Network related errors"""
    
    def __init__(self, message: str = "Network error", **kwargs):
        super().__init__(
            message=message,
            error_code="NET_001",
            category=ErrorCategory.NETWORK,
            status_code=503,
            **kwargs
        )


class SystemError(AIVONITYException):
    """System level errors"""
    
    def __init__(self, message: str = "System error", **kwargs):
        super().__init__(
            message=message,
            error_code="SYS_001",
            category=ErrorCategory.SYSTEM,
            status_code=500,
            severity=ErrorSeverity.HIGH,
            **kwargs
        )


# Agent-specific Exceptions
class AgentError(AIVONITYException):
    """AI Agent related errors"""
    
    def __init__(self, agent_name: str, message: str, **kwargs):
        details = kwargs.get('details', {})
        details['agent_name'] = agent_name
        
        super().__init__(
            message=f"Agent {agent_name}: {message}",
            error_code="AGENT_001",
            category=ErrorCategory.AI_MODEL,
            details=details,
            **kwargs
        )


class AgentTimeoutError(AgentError):
    """Agent timeout errors"""
    
    def __init__(self, agent_name: str, timeout_seconds: int, **kwargs):
        super().__init__(
            agent_name=agent_name,
            message=f"Operation timed out after {timeout_seconds} seconds",
            error_code="AGENT_002",
            details={'timeout_seconds': timeout_seconds},
            **kwargs
        )


class AgentUnavailableError(AgentError):
    """Agent unavailable errors"""
    
    def __init__(self, agent_name: str, **kwargs):
        super().__init__(
            agent_name=agent_name,
            message="Agent is currently unavailable",
            error_code="AGENT_003",
            user_message="The AI service is temporarily unavailable. Please try again in a few moments.",
            **kwargs
        )


# Telemetry-specific Exceptions
class TelemetryError(AIVONITYException):
    """Telemetry processing errors"""
    
    def __init__(self, message: str, vehicle_id: str = None, **kwargs):
        details = kwargs.get('details', {})
        if vehicle_id:
            details['vehicle_id'] = vehicle_id
        
        super().__init__(
            message=message,
            error_code="TEL_001",
            category=ErrorCategory.BUSINESS_LOGIC,
            details=details,
            **kwargs
        )


class InvalidTelemetryDataError(TelemetryError):
    """Invalid telemetry data errors"""
    
    def __init__(self, validation_errors: List[str], vehicle_id: str = None, **kwargs):
        super().__init__(
            message="Invalid telemetry data format",
            error_code="TEL_002",
            vehicle_id=vehicle_id,
            details={'validation_errors': validation_errors},
            user_message="Invalid vehicle data format. Please check your device connection.",
            **kwargs
        )


# Prediction-specific Exceptions
class PredictionError(AIVONITYException):
    """Prediction service errors"""
    
    def __init__(self, message: str, model_name: str = None, **kwargs):
        details = kwargs.get('details', {})
        if model_name:
            details['model_name'] = model_name
        
        super().__init__(
            message=message,
            error_code="PRED_001",
            category=ErrorCategory.AI_MODEL,
            details=details,
            **kwargs
        )


class ModelNotAvailableError(PredictionError):
    """ML model not available errors"""
    
    def __init__(self, model_name: str, **kwargs):
        super().__init__(
            message=f"Model {model_name} is not available",
            error_code="PRED_002",
            model_name=model_name,
            user_message="Prediction service is temporarily unavailable. Please try again later.",
            **kwargs
        )


class InsufficientDataError(PredictionError):
    """Insufficient data for prediction errors"""
    
    def __init__(self, required_data_points: int, available_data_points: int, **kwargs):
        super().__init__(
            message=f"Insufficient data for prediction: need {required_data_points}, have {available_data_points}",
            error_code="PRED_003",
            details={
                'required_data_points': required_data_points,
                'available_data_points': available_data_points
            },
            user_message="Not enough vehicle data available for accurate predictions. Please drive more to collect sufficient data.",
            **kwargs
        )