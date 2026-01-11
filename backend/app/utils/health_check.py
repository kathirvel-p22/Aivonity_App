"""
AIVONITY Health Check System
Comprehensive health monitoring for all system components
"""

import asyncio
import time
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from enum import Enum
import logging
from datetime import datetime, timedelta

from app.utils.exceptions import SystemError, DatabaseError, ExternalServiceError
from app.utils.circuit_breaker import circuit_breaker_manager
from app.utils.api_client import api_client_manager


class HealthStatus(str, Enum):
    """Health status levels"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"


@dataclass
class HealthCheckResult:
    """Result of a health check"""
    component: str
    status: HealthStatus
    message: str
    details: Dict[str, Any]
    response_time_ms: float
    timestamp: datetime
    error: Optional[str] = None


class HealthChecker:
    """Base health checker class"""
    
    def __init__(self, component_name: str):
        self.component_name = component_name
        self.logger = logging.getLogger(f"health_check.{component_name}")
    
    async def check(self) -> HealthCheckResult:
        """Perform health check"""
        start_time = time.time()
        
        try:
            details = await self._perform_check()
            response_time = (time.time() - start_time) * 1000
            
            return HealthCheckResult(
                component=self.component_name,
                status=HealthStatus.HEALTHY,
                message="Component is healthy",
                details=details,
                response_time_ms=response_time,
                timestamp=datetime.utcnow()
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            
            self.logger.error(
                f"Health check failed for {self.component_name}: {str(e)}",
                extra={'component': self.component_name, 'error': str(e)}
            )
            
            return HealthCheckResult(
                component=self.component_name,
                status=HealthStatus.UNHEALTHY,
                message=f"Health check failed: {str(e)}",
                details={},
                response_time_ms=response_time,
                timestamp=datetime.utcnow(),
                error=str(e)
            )
    
    async def _perform_check(self) -> Dict[str, Any]:
        """Override this method to implement specific health check logic"""
        raise NotImplementedError


class DatabaseHealthChecker(HealthChecker):
    """Health checker for database connections"""
    
    def __init__(self, db_session_factory):
        super().__init__("database")
        self.db_session_factory = db_session_factory
    
    async def _perform_check(self) -> Dict[str, Any]:
        """Check database connectivity"""
        try:
            # Test database connection with a simple query
            async with self.db_session_factory() as session:
                result = await session.execute("SELECT 1")
                await result.fetchone()
            
            return {
                "connection": "active",
                "query_test": "passed"
            }
            
        except Exception as e:
            raise DatabaseError(f"Database health check failed: {str(e)}")


class RedisHealthChecker(HealthChecker):
    """Health checker for Redis connections"""
    
    def __init__(self, redis_client):
        super().__init__("redis")
        self.redis_client = redis_client
    
    async def _perform_check(self) -> Dict[str, Any]:
        """Check Redis connectivity"""
        try:
            # Test Redis connection with ping
            await self.redis_client.ping()
            
            # Test basic operations
            test_key = "health_check_test"
            await self.redis_client.set(test_key, "test_value", ex=10)
            value = await self.redis_client.get(test_key)
            await self.redis_client.delete(test_key)
            
            if value != "test_value":
                raise Exception("Redis read/write test failed")
            
            return {
                "connection": "active",
                "ping": "success",
                "read_write_test": "passed"
            }
            
        except Exception as e:
            raise ExternalServiceError(
                service_name="Redis",
                message=f"Redis health check failed: {str(e)}"
            )


class AgentHealthChecker(HealthChecker):
    """Health checker for AI agents"""
    
    def __init__(self, agent_manager):
        super().__init__("agents")
        self.agent_manager = agent_manager
    
    async def _perform_check(self) -> Dict[str, Any]:
        """Check AI agents health"""
        try:
            agents_status = await self.agent_manager.health_check_all()
            
            healthy_agents = sum(1 for status in agents_status.values() if status)
            total_agents = len(agents_status)
            
            if healthy_agents == 0:
                raise SystemError("All AI agents are unhealthy")
            elif healthy_agents < total_agents:
                # Some agents are unhealthy but system can still function
                return {
                    "status": "degraded",
                    "healthy_agents": healthy_agents,
                    "total_agents": total_agents,
                    "agents_status": agents_status
                }
            
            return {
                "status": "healthy",
                "healthy_agents": healthy_agents,
                "total_agents": total_agents,
                "agents_status": agents_status
            }
            
        except Exception as e:
            raise SystemError(f"Agent health check failed: {str(e)}")


class ExternalServiceHealthChecker(HealthChecker):
    """Health checker for external services"""
    
    def __init__(self, service_name: str, health_endpoint: str):
        super().__init__(f"external_service_{service_name}")
        self.service_name = service_name
        self.health_endpoint = health_endpoint
    
    async def _perform_check(self) -> Dict[str, Any]:
        """Check external service health"""
        try:
            client = api_client_manager.get_client(self.service_name)
            if not client:
                raise ExternalServiceError(
                    service_name=self.service_name,
                    message="API client not configured"
                )
            
            response = await client.get(self.health_endpoint)
            
            return {
                "service": self.service_name,
                "endpoint": self.health_endpoint,
                "status_code": response.status_code,
                "response_data": response.data
            }
            
        except Exception as e:
            raise ExternalServiceError(
                service_name=self.service_name,
                message=f"External service health check failed: {str(e)}"
            )


class CircuitBreakerHealthChecker(HealthChecker):
    """Health checker for circuit breakers"""
    
    def __init__(self):
        super().__init__("circuit_breakers")
    
    async def _perform_check(self) -> Dict[str, Any]:
        """Check circuit breaker status"""
        try:
            all_stats = circuit_breaker_manager.get_all_stats()
            
            open_circuits = [
                name for name, stats in all_stats.items() 
                if stats['state'] == 'open'
            ]
            
            half_open_circuits = [
                name for name, stats in all_stats.items() 
                if stats['state'] == 'half_open'
            ]
            
            total_circuits = len(all_stats)
            healthy_circuits = total_circuits - len(open_circuits)
            
            status = "healthy"
            if len(open_circuits) > 0:
                status = "degraded" if healthy_circuits > 0 else "unhealthy"
            
            return {
                "status": status,
                "total_circuits": total_circuits,
                "healthy_circuits": healthy_circuits,
                "open_circuits": open_circuits,
                "half_open_circuits": half_open_circuits,
                "circuit_stats": all_stats
            }
            
        except Exception as e:
            raise SystemError(f"Circuit breaker health check failed: {str(e)}")


class SystemHealthMonitor:
    """Comprehensive system health monitoring"""
    
    def __init__(self):
        self.health_checkers: List[HealthChecker] = []
        self.logger = logging.getLogger("system_health_monitor")
        self._last_check_time: Optional[datetime] = None
        self._last_results: List[HealthCheckResult] = []
    
    def register_checker(self, checker: HealthChecker):
        """Register a health checker"""
        self.health_checkers.append(checker)
        self.logger.info(f"Registered health checker: {checker.component_name}")
    
    async def check_all(self, timeout: float = 30.0) -> Dict[str, Any]:
        """Perform health check on all registered components"""
        start_time = time.time()
        
        try:
            # Run all health checks concurrently with timeout
            tasks = [checker.check() for checker in self.health_checkers]
            results = await asyncio.wait_for(
                asyncio.gather(*tasks, return_exceptions=True),
                timeout=timeout
            )
            
            # Process results
            health_results = []
            for i, result in enumerate(results):
                if isinstance(result, Exception):
                    # Health check raised an exception
                    health_results.append(HealthCheckResult(
                        component=self.health_checkers[i].component_name,
                        status=HealthStatus.UNHEALTHY,
                        message=f"Health check exception: {str(result)}",
                        details={},
                        response_time_ms=0,
                        timestamp=datetime.utcnow(),
                        error=str(result)
                    ))
                else:
                    health_results.append(result)
            
            # Calculate overall system health
            overall_status = self._calculate_overall_status(health_results)
            total_time = (time.time() - start_time) * 1000
            
            self._last_check_time = datetime.utcnow()
            self._last_results = health_results
            
            return {
                "overall_status": overall_status.value,
                "timestamp": self._last_check_time.isoformat(),
                "total_check_time_ms": total_time,
                "components": {
                    result.component: {
                        "status": result.status.value,
                        "message": result.message,
                        "response_time_ms": result.response_time_ms,
                        "details": result.details,
                        "error": result.error
                    }
                    for result in health_results
                }
            }
            
        except asyncio.TimeoutError:
            self.logger.error(f"Health check timeout after {timeout}s")
            return {
                "overall_status": HealthStatus.UNKNOWN.value,
                "timestamp": datetime.utcnow().isoformat(),
                "error": f"Health check timeout after {timeout}s",
                "components": {}
            }
        except Exception as e:
            self.logger.error(f"Health check failed: {str(e)}", exc_info=True)
            return {
                "overall_status": HealthStatus.UNKNOWN.value,
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e),
                "components": {}
            }
    
    def _calculate_overall_status(self, results: List[HealthCheckResult]) -> HealthStatus:
        """Calculate overall system health status"""
        if not results:
            return HealthStatus.UNKNOWN
        
        unhealthy_count = sum(1 for r in results if r.status == HealthStatus.UNHEALTHY)
        degraded_count = sum(1 for r in results if r.status == HealthStatus.DEGRADED)
        
        if unhealthy_count > 0:
            # If any critical component is unhealthy, system is unhealthy
            critical_components = ["database", "agents"]
            for result in results:
                if (result.component in critical_components and 
                    result.status == HealthStatus.UNHEALTHY):
                    return HealthStatus.UNHEALTHY
            
            # Non-critical components unhealthy
            return HealthStatus.DEGRADED
        
        if degraded_count > 0:
            return HealthStatus.DEGRADED
        
        return HealthStatus.HEALTHY
    
    def get_last_results(self) -> Optional[Dict[str, Any]]:
        """Get last health check results"""
        if not self._last_results or not self._last_check_time:
            return None
        
        return {
            "timestamp": self._last_check_time.isoformat(),
            "components": {
                result.component: {
                    "status": result.status.value,
                    "message": result.message,
                    "response_time_ms": result.response_time_ms,
                    "details": result.details,
                    "error": result.error
                }
                for result in self._last_results
            }
        }
    
    def is_healthy(self) -> bool:
        """Check if system is currently healthy"""
        if not self._last_results:
            return False
        
        overall_status = self._calculate_overall_status(self._last_results)
        return overall_status == HealthStatus.HEALTHY


# Global health monitor instance
system_health_monitor = SystemHealthMonitor()


async def setup_health_monitoring(
    db_session_factory=None,
    redis_client=None,
    agent_manager=None
):
    """Setup health monitoring for all system components"""
    
    # Register database health checker
    if db_session_factory:
        system_health_monitor.register_checker(
            DatabaseHealthChecker(db_session_factory)
        )
    
    # Register Redis health checker
    if redis_client:
        system_health_monitor.register_checker(
            RedisHealthChecker(redis_client)
        )
    
    # Register agent health checker
    if agent_manager:
        system_health_monitor.register_checker(
            AgentHealthChecker(agent_manager)
        )
    
    # Register circuit breaker health checker
    system_health_monitor.register_checker(CircuitBreakerHealthChecker())
    
    logging.getLogger("health_monitor").info("Health monitoring setup complete")