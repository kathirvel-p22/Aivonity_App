"""
AIVONITY Monitoring Middleware
Automatic collection of API performance metrics and request tracking
"""

import time
import logging
from typing import Callable
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
import asyncio

from app.utils.metrics import metrics_collector, timer
from app.utils.exceptions import SystemError


class MetricsMiddleware(BaseHTTPMiddleware):
    """Middleware to collect API performance metrics"""
    
    def __init__(self, app: ASGIApp):
        super().__init__(app)
        self.logger = logging.getLogger("metrics_middleware")
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request and collect metrics"""
        start_time = time.time()
        
        # Extract request information
        method = request.method
        path = request.url.path
        
        # Normalize path for metrics (remove IDs and dynamic parts)
        normalized_path = self._normalize_path(path)
        
        # Labels for metrics
        labels = {
            "method": method,
            "endpoint": normalized_path
        }
        
        # Increment request counter
        metrics_collector.increment_counter("api_requests_total", 1.0, labels)
        
        try:
            # Process request
            response = await call_next(request)
            
            # Calculate response time
            response_time_ms = (time.time() - start_time) * 1000
            
            # Add status code to labels
            status_labels = {**labels, "status_code": str(response.status_code)}
            
            # Record metrics
            metrics_collector.record_timer("api_response_time_ms", response_time_ms, labels)
            metrics_collector.increment_counter("api_responses_total", 1.0, status_labels)
            
            # Record status code specific metrics
            if response.status_code >= 400:
                metrics_collector.increment_counter("api_errors_total", 1.0, status_labels)
                if response.status_code >= 500:
                    metrics_collector.increment_counter("api_server_errors_total", 1.0, status_labels)
            
            # Log slow requests
            if response_time_ms > 3000:  # Log requests slower than 3 seconds
                self.logger.warning(
                    f"Slow API request: {method} {path} took {response_time_ms:.0f}ms",
                    extra={
                        "method": method,
                        "path": path,
                        "response_time_ms": response_time_ms,
                        "status_code": response.status_code
                    }
                )
            
            return response
            
        except Exception as e:
            # Calculate response time for errors
            response_time_ms = (time.time() - start_time) * 1000
            
            # Record error metrics
            error_labels = {**labels, "error_type": type(e).__name__}
            metrics_collector.increment_counter("api_exceptions_total", 1.0, error_labels)
            metrics_collector.record_timer("api_response_time_ms", response_time_ms, labels)
            
            # Log the error
            self.logger.error(
                f"API request failed: {method} {path} - {str(e)}",
                extra={
                    "method": method,
                    "path": path,
                    "response_time_ms": response_time_ms,
                    "error": str(e),
                    "error_type": type(e).__name__
                },
                exc_info=True
            )
            
            # Re-raise the exception
            raise
    
    def _normalize_path(self, path: str) -> str:
        """Normalize API path for metrics grouping"""
        # Remove common dynamic parts
        parts = path.split('/')
        normalized_parts = []
        
        for part in parts:
            # Replace UUIDs and IDs with placeholders
            if self._is_uuid(part):
                normalized_parts.append('{id}')
            elif self._is_numeric_id(part):
                normalized_parts.append('{id}')
            else:
                normalized_parts.append(part)
        
        return '/'.join(normalized_parts)
    
    def _is_uuid(self, value: str) -> bool:
        """Check if string is a UUID"""
        try:
            import uuid
            uuid.UUID(value)
            return True
        except (ValueError, AttributeError):
            return False
    
    def _is_numeric_id(self, value: str) -> bool:
        """Check if string is a numeric ID"""
        return value.isdigit() and len(value) > 3  # Assume IDs are longer than 3 digits


class RequestTrackingMiddleware(BaseHTTPMiddleware):
    """Middleware to track active requests and connections"""
    
    def __init__(self, app: ASGIApp):
        super().__init__(app)
        self.active_requests = 0
        self.logger = logging.getLogger("request_tracking")
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Track active requests"""
        self.active_requests += 1
        metrics_collector.set_gauge("api_active_requests", self.active_requests)
        
        try:
            response = await call_next(request)
            return response
        finally:
            self.active_requests -= 1
            metrics_collector.set_gauge("api_active_requests", self.active_requests)


class DatabaseMetricsMiddleware:
    """Middleware to collect database operation metrics"""
    
    def __init__(self):
        self.logger = logging.getLogger("database_metrics")
    
    async def __call__(self, query: str, start_time: float):
        """Record database query metrics"""
        query_time_ms = (time.time() - start_time) * 1000
        
        # Determine query type
        query_type = self._get_query_type(query)
        
        labels = {"query_type": query_type}
        
        # Record metrics
        metrics_collector.record_timer("database_query_time_ms", query_time_ms, labels)
        metrics_collector.increment_counter("database_queries_total", 1.0, labels)
        
        # Log slow queries
        if query_time_ms > 1000:  # Log queries slower than 1 second
            self.logger.warning(
                f"Slow database query: {query_type} took {query_time_ms:.0f}ms",
                extra={
                    "query_type": query_type,
                    "query_time_ms": query_time_ms,
                    "query": query[:200] + "..." if len(query) > 200 else query
                }
            )
    
    def _get_query_type(self, query: str) -> str:
        """Extract query type from SQL query"""
        query_lower = query.strip().lower()
        
        if query_lower.startswith('select'):
            return 'SELECT'
        elif query_lower.startswith('insert'):
            return 'INSERT'
        elif query_lower.startswith('update'):
            return 'UPDATE'
        elif query_lower.startswith('delete'):
            return 'DELETE'
        elif query_lower.startswith('create'):
            return 'CREATE'
        elif query_lower.startswith('alter'):
            return 'ALTER'
        elif query_lower.startswith('drop'):
            return 'DROP'
        else:
            return 'OTHER'


class WebSocketMetricsMiddleware:
    """Middleware to collect WebSocket connection metrics"""
    
    def __init__(self):
        self.active_connections = 0
        self.total_connections = 0
        self.logger = logging.getLogger("websocket_metrics")
    
    def on_connect(self, websocket_type: str = "unknown"):
        """Called when WebSocket connection is established"""
        self.active_connections += 1
        self.total_connections += 1
        
        labels = {"websocket_type": websocket_type}
        
        metrics_collector.set_gauge("websocket_active_connections", self.active_connections)
        metrics_collector.increment_counter("websocket_connections_total", 1.0, labels)
        
        self.logger.info(
            f"WebSocket connected: {websocket_type} (active: {self.active_connections})",
            extra={"websocket_type": websocket_type, "active_connections": self.active_connections}
        )
    
    def on_disconnect(self, websocket_type: str = "unknown"):
        """Called when WebSocket connection is closed"""
        self.active_connections = max(0, self.active_connections - 1)
        
        labels = {"websocket_type": websocket_type}
        
        metrics_collector.set_gauge("websocket_active_connections", self.active_connections)
        metrics_collector.increment_counter("websocket_disconnections_total", 1.0, labels)
        
        self.logger.info(
            f"WebSocket disconnected: {websocket_type} (active: {self.active_connections})",
            extra={"websocket_type": websocket_type, "active_connections": self.active_connections}
        )
    
    def on_message(self, websocket_type: str = "unknown", message_size: int = 0):
        """Called when WebSocket message is received"""
        labels = {"websocket_type": websocket_type}
        
        metrics_collector.increment_counter("websocket_messages_total", 1.0, labels)
        if message_size > 0:
            metrics_collector.record_histogram("websocket_message_size_bytes", message_size, labels)


class AgentMetricsCollector:
    """Collect metrics for AI agent operations"""
    
    def __init__(self):
        self.logger = logging.getLogger("agent_metrics")
    
    @timer("agent_processing_time_ms")
    async def track_agent_processing(self, agent_name: str, operation: str, func: Callable):
        """Track agent processing time and results"""
        labels = {"agent": agent_name, "operation": operation}
        
        try:
            # Increment processing counter
            metrics_collector.increment_counter("agent_operations_total", 1.0, labels)
            
            # Execute the operation
            result = await func() if asyncio.iscoroutinefunction(func) else func()
            
            # Record success
            success_labels = {**labels, "status": "success"}
            metrics_collector.increment_counter("agent_operations_completed", 1.0, success_labels)
            
            return result
            
        except Exception as e:
            # Record failure
            error_labels = {**labels, "status": "error", "error_type": type(e).__name__}
            metrics_collector.increment_counter("agent_operations_failed", 1.0, error_labels)
            
            self.logger.error(
                f"Agent operation failed: {agent_name}.{operation} - {str(e)}",
                extra={
                    "agent": agent_name,
                    "operation": operation,
                    "error": str(e),
                    "error_type": type(e).__name__
                }
            )
            
            raise
    
    def record_agent_health(self, agent_name: str, is_healthy: bool):
        """Record agent health status"""
        labels = {"agent": agent_name}
        health_value = 1.0 if is_healthy else 0.0
        
        metrics_collector.set_gauge("agent_health_status", health_value, labels)
        
        if not is_healthy:
            metrics_collector.increment_counter("agent_health_failures", 1.0, labels)


# Global instances
database_metrics = DatabaseMetricsMiddleware()
websocket_metrics = WebSocketMetricsMiddleware()
agent_metrics = AgentMetricsCollector()


def setup_monitoring_middleware(app):
    """Setup all monitoring middleware"""
    # Add metrics collection middleware
    app.add_middleware(MetricsMiddleware)
    app.add_middleware(RequestTrackingMiddleware)
    
    logging.getLogger("monitoring_middleware").info("Monitoring middleware setup complete")