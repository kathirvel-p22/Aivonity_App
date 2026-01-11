"""
AIVONITY Alerting System
Automated alerting for system issues and performance problems
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
import json

from app.utils.exceptions import SystemError, ExternalServiceError
from app.utils.metrics import metrics_collector, alert_manager


class AlertSeverity(str, Enum):
    """Alert severity levels"""
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"
    EMERGENCY = "emergency"


class AlertCategory(str, Enum):
    """Alert categories"""
    SYSTEM = "system"
    PERFORMANCE = "performance"
    SECURITY = "security"
    APPLICATION = "application"
    EXTERNAL_SERVICE = "external_service"


@dataclass
class Alert:
    """Alert data structure"""
    id: str
    title: str
    description: str
    severity: AlertSeverity
    category: AlertCategory
    source: str
    timestamp: datetime
    metadata: Dict[str, Any]
    resolved: bool = False
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[str] = None


class AlertRule:
    """Alert rule definition"""
    
    def __init__(
        self,
        name: str,
        condition: Callable[[Dict[str, Any]], bool],
        severity: AlertSeverity,
        category: AlertCategory,
        title_template: str,
        description_template: str,
        cooldown_minutes: int = 5
    ):
        self.name = name
        self.condition = condition
        self.severity = severity
        self.category = category
        self.title_template = title_template
        self.description_template = description_template
        self.cooldown = timedelta(minutes=cooldown_minutes)
        self.last_triggered: Optional[datetime] = None
    
    def should_trigger(self, context: Dict[str, Any]) -> bool:
        """Check if alert should be triggered"""
        # Check cooldown
        if (self.last_triggered and 
            datetime.utcnow() - self.last_triggered < self.cooldown):
            return False
        
        # Check condition
        try:
            return self.condition(context)
        except Exception as e:
            logging.getLogger("alert_rule").error(
                f"Error evaluating alert rule {self.name}: {str(e)}"
            )
            return False
    
    def create_alert(self, context: Dict[str, Any]) -> Alert:
        """Create alert from rule and context"""
        alert_id = f"{self.name}_{int(datetime.utcnow().timestamp())}"
        
        return Alert(
            id=alert_id,
            title=self.title_template.format(**context),
            description=self.description_template.format(**context),
            severity=self.severity,
            category=self.category,
            source=self.name,
            timestamp=datetime.utcnow(),
            metadata=context
        )
    
    def mark_triggered(self):
        """Mark rule as triggered"""
        self.last_triggered = datetime.utcnow()


class AlertManager:
    """Manage alerts and alert rules"""
    
    def __init__(self):
        self.rules: List[AlertRule] = []
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.alert_handlers: List[Callable[[Alert], None]] = []
        self.logger = logging.getLogger("alert_manager")
        self._monitoring_task: Optional[asyncio.Task] = None
        self._running = False
    
    def add_rule(self, rule: AlertRule):
        """Add an alert rule"""
        self.rules.append(rule)
        self.logger.info(f"Added alert rule: {rule.name}")
    
    def add_handler(self, handler: Callable[[Alert], None]):
        """Add alert handler"""
        self.alert_handlers.append(handler)
    
    async def start_monitoring(self, check_interval_seconds: float = 60.0):
        """Start alert monitoring"""
        if self._running:
            return
        
        self._running = True
        self._monitoring_task = asyncio.create_task(
            self._monitoring_loop(check_interval_seconds)
        )
        self.logger.info(f"Started alert monitoring (interval: {check_interval_seconds}s)")
    
    async def stop_monitoring(self):
        """Stop alert monitoring"""
        self._running = False
        if self._monitoring_task:
            self._monitoring_task.cancel()
            try:
                await self._monitoring_task
            except asyncio.CancelledError:
                pass
        self.logger.info("Stopped alert monitoring")
    
    async def _monitoring_loop(self, interval_seconds: float):
        """Main alert monitoring loop"""
        while self._running:
            try:
                await self._check_all_rules()
                await asyncio.sleep(interval_seconds)
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error(f"Error in alert monitoring loop: {str(e)}")
                await asyncio.sleep(interval_seconds)
    
    async def _check_all_rules(self):
        """Check all alert rules"""
        # Gather system context
        context = await self._gather_context()
        
        for rule in self.rules:
            try:
                if rule.should_trigger(context):
                    alert = rule.create_alert(context)
                    await self._trigger_alert(alert)
                    rule.mark_triggered()
            except Exception as e:
                self.logger.error(f"Error checking rule {rule.name}: {str(e)}")
    
    async def _gather_context(self) -> Dict[str, Any]:
        """Gather system context for alert evaluation"""
        context = {
            "timestamp": datetime.utcnow(),
            "metrics": {},
            "system_status": {}
        }
        
        # Get current metrics
        try:
            all_metrics = metrics_collector.get_all_metrics()
            for key, summary in all_metrics.items():
                context["metrics"][key] = {
                    "current_value": summary.current_value,
                    "avg_value": summary.avg_value,
                    "max_value": summary.max_value,
                    "min_value": summary.min_value
                }
        except Exception as e:
            self.logger.error(f"Failed to gather metrics context: {str(e)}")
        
        return context
    
    async def _trigger_alert(self, alert: Alert):
        """Trigger an alert"""
        self.active_alerts[alert.id] = alert
        self.alert_history.append(alert)
        
        self.logger.warning(
            f"ALERT TRIGGERED: {alert.title}",
            extra={
                "alert_id": alert.id,
                "severity": alert.severity.value,
                "category": alert.category.value,
                "source": alert.source
            }
        )
        
        # Call all alert handlers
        for handler in self.alert_handlers:
            try:
                if asyncio.iscoroutinefunction(handler):
                    await handler(alert)
                else:
                    handler(alert)
            except Exception as e:
                self.logger.error(f"Alert handler failed: {str(e)}")
    
    async def resolve_alert(self, alert_id: str, resolved_by: str = "system"):
        """Resolve an active alert"""
        if alert_id in self.active_alerts:
            alert = self.active_alerts[alert_id]
            alert.resolved = True
            alert.resolved_at = datetime.utcnow()
            alert.resolved_by = resolved_by
            
            del self.active_alerts[alert_id]
            
            self.logger.info(
                f"Alert resolved: {alert.title}",
                extra={
                    "alert_id": alert_id,
                    "resolved_by": resolved_by
                }
            )
    
    def get_active_alerts(self, severity: Optional[AlertSeverity] = None) -> List[Alert]:
        """Get active alerts, optionally filtered by severity"""
        alerts = list(self.active_alerts.values())
        if severity:
            alerts = [a for a in alerts if a.severity == severity]
        return sorted(alerts, key=lambda x: x.timestamp, reverse=True)
    
    def get_alert_history(self, hours: int = 24) -> List[Alert]:
        """Get alert history for the specified number of hours"""
        cutoff = datetime.utcnow() - timedelta(hours=hours)
        return [a for a in self.alert_history if a.timestamp >= cutoff]


class SystemAlertHandler:
    """Handle system alerts with notifications"""
    
    def __init__(self):
        self.logger = logging.getLogger("system_alert_handler")
    
    async def handle_alert(self, alert: Alert):
        """Handle an alert by sending notifications"""
        try:
            # Log the alert
            self.logger.error(
                f"System Alert: {alert.title} - {alert.description}",
                extra={
                    "alert_id": alert.id,
                    "severity": alert.severity.value,
                    "category": alert.category.value,
                    "metadata": alert.metadata
                }
            )
            
            # Send notifications based on severity
            if alert.severity in [AlertSeverity.CRITICAL, AlertSeverity.EMERGENCY]:
                await self._send_critical_notifications(alert)
            elif alert.severity == AlertSeverity.WARNING:
                await self._send_warning_notifications(alert)
            
        except Exception as e:
            self.logger.error(f"Failed to handle alert {alert.id}: {str(e)}")
    
    async def _send_critical_notifications(self, alert: Alert):
        """Send notifications for critical alerts"""
        # In a real implementation, this would integrate with:
        # - Email notifications
        # - SMS alerts
        # - Slack/Teams notifications
        # - PagerDuty or similar
        
        self.logger.critical(
            f"CRITICAL ALERT: {alert.title}",
            extra={"alert_data": alert.__dict__}
        )
    
    async def _send_warning_notifications(self, alert: Alert):
        """Send notifications for warning alerts"""
        self.logger.warning(
            f"WARNING ALERT: {alert.title}",
            extra={"alert_data": alert.__dict__}
        )


def create_default_alert_rules() -> List[AlertRule]:
    """Create default alert rules for system monitoring"""
    
    rules = []
    
    # High CPU usage
    rules.append(AlertRule(
        name="high_cpu_usage",
        condition=lambda ctx: ctx.get("metrics", {}).get("system_cpu_percent", {}).get("current_value", 0) > 80,
        severity=AlertSeverity.WARNING,
        category=AlertCategory.PERFORMANCE,
        title_template="High CPU Usage Detected",
        description_template="CPU usage is {metrics[system_cpu_percent][current_value]:.1f}%, exceeding 80% threshold",
        cooldown_minutes=5
    ))
    
    # High memory usage
    rules.append(AlertRule(
        name="high_memory_usage",
        condition=lambda ctx: ctx.get("metrics", {}).get("system_memory_percent", {}).get("current_value", 0) > 85,
        severity=AlertSeverity.WARNING,
        category=AlertCategory.PERFORMANCE,
        title_template="High Memory Usage Detected",
        description_template="Memory usage is {metrics[system_memory_percent][current_value]:.1f}%, exceeding 85% threshold",
        cooldown_minutes=5
    ))
    
    # High disk usage
    rules.append(AlertRule(
        name="high_disk_usage",
        condition=lambda ctx: ctx.get("metrics", {}).get("system_disk_percent", {}).get("current_value", 0) > 90,
        severity=AlertSeverity.CRITICAL,
        category=AlertCategory.SYSTEM,
        title_template="High Disk Usage Detected",
        description_template="Disk usage is {metrics[system_disk_percent][current_value]:.1f}%, exceeding 90% threshold",
        cooldown_minutes=10
    ))
    
    # Slow API responses
    rules.append(AlertRule(
        name="slow_api_responses",
        condition=lambda ctx: ctx.get("metrics", {}).get("api_response_time_ms", {}).get("avg_value", 0) > 3000,
        severity=AlertSeverity.WARNING,
        category=AlertCategory.PERFORMANCE,
        title_template="Slow API Response Times",
        description_template="Average API response time is {metrics[api_response_time_ms][avg_value]:.0f}ms, exceeding 3000ms threshold",
        cooldown_minutes=3
    ))
    
    # Database connection issues
    rules.append(AlertRule(
        name="database_connection_errors",
        condition=lambda ctx: ctx.get("metrics", {}).get("database_connection_errors", {}).get("current_value", 0) > 5,
        severity=AlertSeverity.CRITICAL,
        category=AlertCategory.SYSTEM,
        title_template="Database Connection Errors",
        description_template="Database connection errors: {metrics[database_connection_errors][current_value]:.0f} in recent period",
        cooldown_minutes=2
    ))
    
    # Agent failures
    rules.append(AlertRule(
        name="agent_failures",
        condition=lambda ctx: ctx.get("metrics", {}).get("agent_failures", {}).get("current_value", 0) > 0,
        severity=AlertSeverity.CRITICAL,
        category=AlertCategory.APPLICATION,
        title_template="AI Agent Failures Detected",
        description_template="AI agent failures: {metrics[agent_failures][current_value]:.0f} agents are unhealthy",
        cooldown_minutes=1
    ))
    
    return rules


# Global alert manager instance
alert_manager_instance = AlertManager()
system_alert_handler = SystemAlertHandler()


async def setup_alerting():
    """Setup alerting system with default rules"""
    
    # Add default alert rules
    for rule in create_default_alert_rules():
        alert_manager_instance.add_rule(rule)
    
    # Add system alert handler
    alert_manager_instance.add_handler(system_alert_handler.handle_alert)
    
    # Start monitoring
    await alert_manager_instance.start_monitoring(check_interval_seconds=60.0)
    
    logging.getLogger("alerting").info("Alerting system setup complete")


async def shutdown_alerting():
    """Shutdown alerting system"""
    await alert_manager_instance.stop_monitoring()