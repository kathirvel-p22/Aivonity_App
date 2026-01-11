"""
AIVONITY Audit Trail System
Comprehensive audit logging for security-sensitive operations
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional, Union
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import json
import uuid
from contextlib import asynccontextmanager

from app.utils.logging_config import audit_logger, security_logger
from app.utils.exceptions import SystemError


class AuditEventType(str, Enum):
    """Types of audit events"""
    USER_LOGIN = "user_login"
    USER_LOGOUT = "user_logout"
    USER_REGISTRATION = "user_registration"
    PASSWORD_CHANGE = "password_change"
    DATA_ACCESS = "data_access"
    DATA_CREATE = "data_create"
    DATA_UPDATE = "data_update"
    DATA_DELETE = "data_delete"
    PERMISSION_GRANT = "permission_grant"
    PERMISSION_REVOKE = "permission_revoke"
    SYSTEM_CONFIG_CHANGE = "system_config_change"
    AGENT_ACTION = "agent_action"
    API_CALL = "api_call"
    FILE_ACCESS = "file_access"
    EXPORT_DATA = "export_data"
    IMPORT_DATA = "import_data"
    SECURITY_VIOLATION = "security_violation"
    ADMIN_ACTION = "admin_action"


class AuditSeverity(str, Enum):
    """Severity levels for audit events"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class AuditEvent:
    """Audit event data structure"""
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    event_type: AuditEventType = AuditEventType.API_CALL
    timestamp: datetime = field(default_factory=datetime.utcnow)
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    action: Optional[str] = None
    details: Dict[str, Any] = field(default_factory=dict)
    before_state: Optional[Dict[str, Any]] = None
    after_state: Optional[Dict[str, Any]] = None
    severity: AuditSeverity = AuditSeverity.LOW
    success: bool = True
    error_message: Optional[str] = None
    correlation_id: Optional[str] = None
    tags: List[str] = field(default_factory=list)


class AuditTrailManager:
    """Manage audit trail logging and storage"""
    
    def __init__(self):
        self.logger = logging.getLogger("audit_trail")
        self._event_queue: asyncio.Queue = asyncio.Queue()
        self._processing_task: Optional[asyncio.Task] = None
        self._running = False
        self._event_handlers: List[callable] = []
    
    async def start(self):
        """Start audit trail processing"""
        if self._running:
            return
        
        self._running = True
        self._processing_task = asyncio.create_task(self._process_events())
        self.logger.info("Audit trail manager started")
    
    async def stop(self):
        """Stop audit trail processing"""
        self._running = False
        if self._processing_task:
            self._processing_task.cancel()
            try:
                await self._processing_task
            except asyncio.CancelledError:
                pass
        self.logger.info("Audit trail manager stopped")
    
    def add_event_handler(self, handler: callable):
        """Add custom event handler"""
        self._event_handlers.append(handler)
    
    async def log_event(self, event: AuditEvent):
        """Log an audit event"""
        try:
            await self._event_queue.put(event)
        except Exception as e:
            self.logger.error(f"Failed to queue audit event: {str(e)}")
    
    async def _process_events(self):
        """Process audit events from queue"""
        while self._running:
            try:
                # Get event from queue with timeout
                event = await asyncio.wait_for(
                    self._event_queue.get(), 
                    timeout=1.0
                )
                
                await self._handle_event(event)
                
            except asyncio.TimeoutError:
                continue
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error(f"Error processing audit event: {str(e)}")
    
    async def _handle_event(self, event: AuditEvent):
        """Handle individual audit event"""
        try:
            # Log to audit logger
            audit_logger.log_system_event(
                event_type=event.event_type.value,
                details={
                    "event_id": event.event_id,
                    "user_id": event.user_id,
                    "session_id": event.session_id,
                    "ip_address": event.ip_address,
                    "user_agent": event.user_agent,
                    "resource_type": event.resource_type,
                    "resource_id": event.resource_id,
                    "action": event.action,
                    "details": event.details,
                    "before_state": event.before_state,
                    "after_state": event.after_state,
                    "severity": event.severity.value,
                    "success": event.success,
                    "error_message": event.error_message,
                    "correlation_id": event.correlation_id,
                    "tags": event.tags
                },
                severity=event.severity.value
            )
            
            # Log security events separately if high severity
            if event.severity in [AuditSeverity.HIGH, AuditSeverity.CRITICAL]:
                security_logger.log_suspicious_activity(
                    user_id=event.user_id or "unknown",
                    activity_type=event.event_type.value,
                    details=event.details,
                    risk_score=self._calculate_risk_score(event)
                )
            
            # Call custom event handlers
            for handler in self._event_handlers:
                try:
                    if asyncio.iscoroutinefunction(handler):
                        await handler(event)
                    else:
                        handler(event)
                except Exception as e:
                    self.logger.error(f"Event handler failed: {str(e)}")
                    
        except Exception as e:
            self.logger.error(f"Failed to handle audit event: {str(e)}")
    
    def _calculate_risk_score(self, event: AuditEvent) -> float:
        """Calculate risk score for security events"""
        base_score = 0.0
        
        # Base score by event type
        risk_scores = {
            AuditEventType.USER_LOGIN: 0.1,
            AuditEventType.PASSWORD_CHANGE: 0.3,
            AuditEventType.DATA_DELETE: 0.5,
            AuditEventType.PERMISSION_GRANT: 0.4,
            AuditEventType.SYSTEM_CONFIG_CHANGE: 0.7,
            AuditEventType.SECURITY_VIOLATION: 0.9,
            AuditEventType.ADMIN_ACTION: 0.6
        }
        
        base_score = risk_scores.get(event.event_type, 0.2)
        
        # Increase score for failures
        if not event.success:
            base_score += 0.3
        
        # Increase score for critical severity
        if event.severity == AuditSeverity.CRITICAL:
            base_score += 0.4
        elif event.severity == AuditSeverity.HIGH:
            base_score += 0.2
        
        return min(1.0, base_score)


class AuditContext:
    """Context manager for audit trail operations"""
    
    def __init__(self, audit_manager: AuditTrailManager):
        self.audit_manager = audit_manager
        self.context_data: Dict[str, Any] = {}
    
    def set_user(self, user_id: str, session_id: Optional[str] = None):
        """Set user context"""
        self.context_data["user_id"] = user_id
        if session_id:
            self.context_data["session_id"] = session_id
        return self
    
    def set_request_info(self, ip_address: str, user_agent: str):
        """Set request information"""
        self.context_data["ip_address"] = ip_address
        self.context_data["user_agent"] = user_agent
        return self
    
    def set_correlation_id(self, correlation_id: str):
        """Set correlation ID for tracking related events"""
        self.context_data["correlation_id"] = correlation_id
        return self
    
    async def log_event(
        self,
        event_type: AuditEventType,
        action: str,
        resource_type: Optional[str] = None,
        resource_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        severity: AuditSeverity = AuditSeverity.LOW,
        success: bool = True,
        error_message: Optional[str] = None,
        before_state: Optional[Dict[str, Any]] = None,
        after_state: Optional[Dict[str, Any]] = None,
        tags: Optional[List[str]] = None
    ):
        """Log audit event with context"""
        event = AuditEvent(
            event_type=event_type,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details or {},
            severity=severity,
            success=success,
            error_message=error_message,
            before_state=before_state,
            after_state=after_state,
            tags=tags or [],
            **self.context_data
        )
        
        await self.audit_manager.log_event(event)


@asynccontextmanager
async def audit_operation(
    audit_manager: AuditTrailManager,
    event_type: AuditEventType,
    action: str,
    resource_type: Optional[str] = None,
    resource_id: Optional[str] = None,
    user_id: Optional[str] = None,
    severity: AuditSeverity = AuditSeverity.LOW
):
    """Context manager for auditing operations"""
    context = AuditContext(audit_manager)
    if user_id:
        context.set_user(user_id)
    
    start_time = datetime.utcnow()
    success = True
    error_message = None
    
    try:
        yield context
    except Exception as e:
        success = False
        error_message = str(e)
        raise
    finally:
        duration = (datetime.utcnow() - start_time).total_seconds()
        
        await context.log_event(
            event_type=event_type,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details={"duration_seconds": duration},
            severity=severity,
            success=success,
            error_message=error_message
        )


class DataAccessAuditor:
    """Specialized auditor for data access operations"""
    
    def __init__(self, audit_manager: AuditTrailManager):
        self.audit_manager = audit_manager
    
    async def audit_data_read(
        self,
        user_id: str,
        resource_type: str,
        resource_id: str,
        fields_accessed: List[str],
        query_params: Optional[Dict[str, Any]] = None
    ):
        """Audit data read operations"""
        context = AuditContext(self.audit_manager).set_user(user_id)
        
        await context.log_event(
            event_type=AuditEventType.DATA_ACCESS,
            action="read",
            resource_type=resource_type,
            resource_id=resource_id,
            details={
                "fields_accessed": fields_accessed,
                "query_params": query_params or {}
            },
            severity=AuditSeverity.LOW
        )
    
    async def audit_data_create(
        self,
        user_id: str,
        resource_type: str,
        resource_id: str,
        data: Dict[str, Any]
    ):
        """Audit data creation operations"""
        context = AuditContext(self.audit_manager).set_user(user_id)
        
        # Remove sensitive data from audit log
        sanitized_data = self._sanitize_data(data)
        
        await context.log_event(
            event_type=AuditEventType.DATA_CREATE,
            action="create",
            resource_type=resource_type,
            resource_id=resource_id,
            after_state=sanitized_data,
            severity=AuditSeverity.MEDIUM
        )
    
    async def audit_data_update(
        self,
        user_id: str,
        resource_type: str,
        resource_id: str,
        before_data: Dict[str, Any],
        after_data: Dict[str, Any],
        changed_fields: List[str]
    ):
        """Audit data update operations"""
        context = AuditContext(self.audit_manager).set_user(user_id)
        
        # Remove sensitive data from audit log
        sanitized_before = self._sanitize_data(before_data)
        sanitized_after = self._sanitize_data(after_data)
        
        await context.log_event(
            event_type=AuditEventType.DATA_UPDATE,
            action="update",
            resource_type=resource_type,
            resource_id=resource_id,
            before_state=sanitized_before,
            after_state=sanitized_after,
            details={"changed_fields": changed_fields},
            severity=AuditSeverity.MEDIUM
        )
    
    async def audit_data_delete(
        self,
        user_id: str,
        resource_type: str,
        resource_id: str,
        deleted_data: Dict[str, Any]
    ):
        """Audit data deletion operations"""
        context = AuditContext(self.audit_manager).set_user(user_id)
        
        # Remove sensitive data from audit log
        sanitized_data = self._sanitize_data(deleted_data)
        
        await context.log_event(
            event_type=AuditEventType.DATA_DELETE,
            action="delete",
            resource_type=resource_type,
            resource_id=resource_id,
            before_state=sanitized_data,
            severity=AuditSeverity.HIGH
        )
    
    def _sanitize_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Remove sensitive fields from audit data"""
        sensitive_fields = {
            "password", "token", "secret", "key", "credential",
            "ssn", "credit_card", "bank_account"
        }
        
        sanitized = {}
        for key, value in data.items():
            if any(sensitive in key.lower() for sensitive in sensitive_fields):
                sanitized[key] = "[REDACTED]"
            elif isinstance(value, dict):
                sanitized[key] = self._sanitize_data(value)
            else:
                sanitized[key] = value
        
        return sanitized


class SecurityEventAuditor:
    """Specialized auditor for security events"""
    
    def __init__(self, audit_manager: AuditTrailManager):
        self.audit_manager = audit_manager
    
    async def audit_login_attempt(
        self,
        email: str,
        success: bool,
        ip_address: str,
        user_agent: str,
        failure_reason: Optional[str] = None
    ):
        """Audit login attempts"""
        context = AuditContext(self.audit_manager)
        context.set_request_info(ip_address, user_agent)
        
        await context.log_event(
            event_type=AuditEventType.USER_LOGIN,
            action="login_attempt",
            details={
                "email": email,
                "failure_reason": failure_reason
            },
            severity=AuditSeverity.MEDIUM if not success else AuditSeverity.LOW,
            success=success,
            error_message=failure_reason
        )
    
    async def audit_permission_change(
        self,
        admin_user_id: str,
        target_user_id: str,
        permission: str,
        action: str,  # grant or revoke
        resource: Optional[str] = None
    ):
        """Audit permission changes"""
        context = AuditContext(self.audit_manager).set_user(admin_user_id)
        
        event_type = (AuditEventType.PERMISSION_GRANT 
                     if action == "grant" 
                     else AuditEventType.PERMISSION_REVOKE)
        
        await context.log_event(
            event_type=event_type,
            action=action,
            resource_type="permission",
            resource_id=permission,
            details={
                "target_user_id": target_user_id,
                "permission": permission,
                "resource": resource
            },
            severity=AuditSeverity.HIGH
        )
    
    async def audit_security_violation(
        self,
        user_id: Optional[str],
        violation_type: str,
        details: Dict[str, Any],
        ip_address: Optional[str] = None
    ):
        """Audit security violations"""
        context = AuditContext(self.audit_manager)
        if user_id:
            context.set_user(user_id)
        if ip_address:
            context.set_request_info(ip_address, "")
        
        await context.log_event(
            event_type=AuditEventType.SECURITY_VIOLATION,
            action=violation_type,
            details=details,
            severity=AuditSeverity.CRITICAL,
            success=False
        )


# Global audit trail manager
audit_trail_manager = AuditTrailManager()
data_access_auditor = DataAccessAuditor(audit_trail_manager)
security_event_auditor = SecurityEventAuditor(audit_trail_manager)


async def setup_audit_trail():
    """Setup audit trail system"""
    await audit_trail_manager.start()
    logging.getLogger("audit_trail").info("Audit trail system initialized")


async def shutdown_audit_trail():
    """Shutdown audit trail system"""
    await audit_trail_manager.stop()