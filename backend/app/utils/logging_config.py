"""
AIVONITY Advanced Logging Configuration
Structured logging with comprehensive monitoring capabilities
"""

import logging
import logging.config
import sys
import json
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path
import structlog
from pythonjsonlogger import jsonlogger

from app.config import settings

class AIVONITYFormatter(logging.Formatter):
    """Custom formatter for AIVONITY logs with enhanced information"""
    
    def format(self, record):
        # Add custom fields
        record.service = "aivonity"
        record.environment = settings.ENVIRONMENT
        record.timestamp = datetime.utcnow().isoformat()
        
        # Add context information if available
        if hasattr(record, 'user_id'):
            record.user_context = record.user_id
        if hasattr(record, 'vehicle_id'):
            record.vehicle_context = record.vehicle_id
        if hasattr(record, 'agent_name'):
            record.agent_context = record.agent_name
        
        return super().format(record)

class StructuredFormatter(jsonlogger.JsonFormatter):
    """JSON formatter for structured logging"""
    
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        
        # Add standard fields
        log_record['timestamp'] = datetime.utcnow().isoformat()
        log_record['service'] = 'aivonity'
        log_record['environment'] = settings.ENVIRONMENT
        log_record['level'] = record.levelname
        log_record['logger'] = record.name
        
        # Add thread and process info
        log_record['thread_id'] = record.thread
        log_record['process_id'] = record.process
        
        # Add custom context if available
        if hasattr(record, 'user_id'):
            log_record['user_id'] = record.user_id
        if hasattr(record, 'vehicle_id'):
            log_record['vehicle_id'] = record.vehicle_id
        if hasattr(record, 'agent_name'):
            log_record['agent_name'] = record.agent_name
        if hasattr(record, 'correlation_id'):
            log_record['correlation_id'] = record.correlation_id

def setup_logging():
    """Setup comprehensive logging configuration"""
    
    # Ensure logs directory exists
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Logging configuration
    logging_config = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'standard': {
                'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s',
                'datefmt': '%Y-%m-%d %H:%M:%S'
            },
            'detailed': {
                'format': '%(asctime)s [%(levelname)s] %(name)s [%(filename)s:%(lineno)d] - %(message)s',
                'datefmt': '%Y-%m-%d %H:%M:%S'
            },
            'json': {
                '()': StructuredFormatter,
                'format': '%(timestamp)s %(level)s %(name)s %(message)s'
            },
            'aivonity': {
                '()': AIVONITYFormatter,
                'format': '%(timestamp)s [%(levelname)s] %(service)s.%(name)s: %(message)s'
            }
        },
        'handlers': {
            'console': {
                'level': 'INFO',
                'class': 'logging.StreamHandler',
                'formatter': 'aivonity',
                'stream': sys.stdout
            },
            'file': {
                'level': 'DEBUG',
                'class': 'logging.handlers.RotatingFileHandler',
                'formatter': 'detailed',
                'filename': 'logs/aivonity.log',
                'maxBytes': 10485760,  # 10MB
                'backupCount': 5
            },
            'json_file': {
                'level': 'INFO',
                'class': 'logging.handlers.RotatingFileHandler',
                'formatter': 'json',
                'filename': 'logs/aivonity.json',
                'maxBytes': 10485760,  # 10MB
                'backupCount': 5
            },
            'error_file': {
                'level': 'ERROR',
                'class': 'logging.handlers.RotatingFileHandler',
                'formatter': 'detailed',
                'filename': 'logs/errors.log',
                'maxBytes': 10485760,  # 10MB
                'backupCount': 10
            },
            'agent_file': {
                'level': 'DEBUG',
                'class': 'logging.handlers.RotatingFileHandler',
                'formatter': 'json',
                'filename': 'logs/agents.log',
                'maxBytes': 10485760,  # 10MB
                'backupCount': 5
            }
        },
        'loggers': {
            '': {  # Root logger
                'handlers': ['console', 'file', 'json_file', 'error_file'],
                'level': settings.LOG_LEVEL,
                'propagate': False
            },
            'app': {
                'handlers': ['console', 'file', 'json_file'],
                'level': 'DEBUG' if settings.DEBUG else 'INFO',
                'propagate': False
            },
            'agent': {
                'handlers': ['console', 'agent_file'],
                'level': 'DEBUG',
                'propagate': False
            },
            'uvicorn': {
                'handlers': ['console', 'file'],
                'level': 'INFO',
                'propagate': False
            },
            'sqlalchemy': {
                'handlers': ['file'],
                'level': 'WARNING',
                'propagate': False
            }
        }
    }
    
    # Apply configuration
    logging.config.dictConfig(logging_config)
    
    # Set up additional loggers for specific components
    setup_component_loggers()

def setup_component_loggers():
    """Setup specialized loggers for different components"""
    
    # Performance logger
    perf_logger = logging.getLogger('performance')
    perf_handler = logging.handlers.RotatingFileHandler(
        'logs/performance.log', maxBytes=10485760, backupCount=5
    )
    perf_handler.setFormatter(StructuredFormatter())
    perf_logger.addHandler(perf_handler)
    perf_logger.setLevel(logging.INFO)
    
    # Security logger
    security_logger = logging.getLogger('security')
    security_handler = logging.handlers.RotatingFileHandler(
        'logs/security.log', maxBytes=10485760, backupCount=10
    )
    security_handler.setFormatter(StructuredFormatter())
    security_logger.addHandler(security_handler)
    security_logger.setLevel(logging.INFO)
    
    # Audit logger
    audit_logger = logging.getLogger('audit')
    audit_handler = logging.handlers.RotatingFileHandler(
        'logs/audit.log', maxBytes=10485760, backupCount=20
    )
    audit_handler.setFormatter(StructuredFormatter())
    audit_logger.addHandler(audit_handler)
    audit_logger.setLevel(logging.INFO)

def get_logger(name: str, **kwargs) -> logging.Logger:
    """
    Get a configured logger with optional context
    
    Args:
        name: Logger name
        **kwargs: Additional context to add to log records
    
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    
    # Add context to logger if provided
    if kwargs:
        # Create a custom adapter to add context
        logger = ContextLogger(logger, kwargs)
    
    return logger

class ContextLogger(logging.LoggerAdapter):
    """Logger adapter that adds context to log records"""
    
    def __init__(self, logger, extra):
        super().__init__(logger, extra)
    
    def process(self, msg, kwargs):
        # Add extra context to kwargs
        if 'extra' not in kwargs:
            kwargs['extra'] = {}
        kwargs['extra'].update(self.extra)
        return msg, kwargs

class PerformanceLogger:
    """Specialized logger for performance monitoring"""
    
    def __init__(self):
        self.logger = logging.getLogger('performance')
    
    def log_api_performance(self, endpoint: str, method: str, duration: float, 
                          status_code: int, user_id: Optional[str] = None):
        """Log API performance metrics"""
        self.logger.info(
            "API Performance",
            extra={
                'metric_type': 'api_performance',
                'endpoint': endpoint,
                'method': method,
                'duration_ms': duration * 1000,
                'status_code': status_code,
                'user_id': user_id
            }
        )
    
    def log_agent_performance(self, agent_name: str, operation: str, 
                            duration: float, success: bool):
        """Log agent performance metrics"""
        self.logger.info(
            "Agent Performance",
            extra={
                'metric_type': 'agent_performance',
                'agent_name': agent_name,
                'operation': operation,
                'duration_ms': duration * 1000,
                'success': success
            }
        )
    
    def log_database_performance(self, query_type: str, duration: float, 
                               rows_affected: int = 0):
        """Log database performance metrics"""
        self.logger.info(
            "Database Performance",
            extra={
                'metric_type': 'database_performance',
                'query_type': query_type,
                'duration_ms': duration * 1000,
                'rows_affected': rows_affected
            }
        )

class SecurityLogger:
    """Specialized logger for security events"""
    
    def __init__(self):
        self.logger = logging.getLogger('security')
    
    def log_authentication_attempt(self, email: str, success: bool, 
                                 ip_address: str, user_agent: str):
        """Log authentication attempts"""
        self.logger.info(
            "Authentication Attempt",
            extra={
                'event_type': 'authentication',
                'email': email,
                'success': success,
                'ip_address': ip_address,
                'user_agent': user_agent
            }
        )
    
    def log_authorization_failure(self, user_id: str, resource: str, 
                                action: str, ip_address: str):
        """Log authorization failures"""
        self.logger.warning(
            "Authorization Failure",
            extra={
                'event_type': 'authorization_failure',
                'user_id': user_id,
                'resource': resource,
                'action': action,
                'ip_address': ip_address
            }
        )
    
    def log_suspicious_activity(self, user_id: str, activity_type: str, 
                              details: Dict[str, Any], risk_score: float):
        """Log suspicious activities"""
        self.logger.warning(
            "Suspicious Activity",
            extra={
                'event_type': 'suspicious_activity',
                'user_id': user_id,
                'activity_type': activity_type,
                'details': details,
                'risk_score': risk_score
            }
        )

class AuditLogger:
    """Specialized logger for audit trails"""
    
    def __init__(self):
        self.logger = logging.getLogger('audit')
    
    def log_data_access(self, user_id: str, resource_type: str, 
                       resource_id: str, action: str):
        """Log data access events"""
        self.logger.info(
            "Data Access",
            extra={
                'event_type': 'data_access',
                'user_id': user_id,
                'resource_type': resource_type,
                'resource_id': resource_id,
                'action': action
            }
        )
    
    def log_data_modification(self, user_id: str, resource_type: str, 
                            resource_id: str, changes: Dict[str, Any]):
        """Log data modification events"""
        self.logger.info(
            "Data Modification",
            extra={
                'event_type': 'data_modification',
                'user_id': user_id,
                'resource_type': resource_type,
                'resource_id': resource_id,
                'changes': changes
            }
        )
    
    def log_system_event(self, event_type: str, details: Dict[str, Any], 
                        severity: str = 'info'):
        """Log system events"""
        log_method = getattr(self.logger, severity.lower(), self.logger.info)
        log_method(
            "System Event",
            extra={
                'event_type': 'system_event',
                'system_event_type': event_type,
                'details': details
            }
        )

# Global logger instances
performance_logger = PerformanceLogger()
security_logger = SecurityLogger()
audit_logger = AuditLogger()