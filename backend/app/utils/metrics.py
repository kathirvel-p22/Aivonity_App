"""
AIVONITY Performance Monitoring and Metrics Collection
Comprehensive metrics collection for system performance monitoring
"""

import time
import asyncio
import psutil
import logging
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from enum import Enum
import threading
import json

from app.utils.exceptions import SystemError


class MetricType(str, Enum):
    """Types of metrics"""
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    TIMER = "timer"


@dataclass
class MetricValue:
    """Individual metric value"""
    value: float
    timestamp: datetime
    labels: Dict[str, str] = field(default_factory=dict)


@dataclass
class MetricSummary:
    """Summary statistics for a metric"""
    name: str
    metric_type: MetricType
    current_value: float
    min_value: float
    max_value: float
    avg_value: float
    count: int
    last_updated: datetime
    labels: Dict[str, str] = field(default_factory=dict)


class MetricsCollector:
    """Thread-safe metrics collector"""
    
    def __init__(self, max_history: int = 1000):
        self.max_history = max_history
        self._metrics: Dict[str, deque] = defaultdict(lambda: deque(maxlen=max_history))
        self._counters: Dict[str, float] = defaultdict(float)
        self._gauges: Dict[str, float] = defaultdict(float)
        self._lock = threading.RLock()
        self.logger = logging.getLogger("metrics_collector")
    
    def increment_counter(self, name: str, value: float = 1.0, labels: Dict[str, str] = None):
        """Increment a counter metric"""
        with self._lock:
            key = self._make_key(name, labels or {})
            self._counters[key] += value
            self._add_metric_value(name, value, MetricType.COUNTER, labels or {})
    
    def set_gauge(self, name: str, value: float, labels: Dict[str, str] = None):
        """Set a gauge metric value"""
        with self._lock:
            key = self._make_key(name, labels or {})
            self._gauges[key] = value
            self._add_metric_value(name, value, MetricType.GAUGE, labels or {})
    
    def record_histogram(self, name: str, value: float, labels: Dict[str, str] = None):
        """Record a histogram value"""
        with self._lock:
            self._add_metric_value(name, value, MetricType.HISTOGRAM, labels or {})
    
    def record_timer(self, name: str, duration_ms: float, labels: Dict[str, str] = None):
        """Record a timer value in milliseconds"""
        with self._lock:
            self._add_metric_value(name, duration_ms, MetricType.TIMER, labels or {})
    
    def _add_metric_value(self, name: str, value: float, metric_type: MetricType, labels: Dict[str, str]):
        """Add a metric value to history"""
        key = self._make_key(name, labels)
        metric_value = MetricValue(
            value=value,
            timestamp=datetime.utcnow(),
            labels=labels
        )
        self._metrics[key].append((metric_type, metric_value))
    
    def _make_key(self, name: str, labels: Dict[str, str]) -> str:
        """Create a unique key for metric with labels"""
        if not labels:
            return name
        label_str = ",".join(f"{k}={v}" for k, v in sorted(labels.items()))
        return f"{name}[{label_str}]"
    
    def get_metric_summary(self, name: str, labels: Dict[str, str] = None) -> Optional[MetricSummary]:
        """Get summary statistics for a metric"""
        with self._lock:
            key = self._make_key(name, labels or {})
            if key not in self._metrics:
                return None
            
            values = [mv.value for _, mv in self._metrics[key]]
            if not values:
                return None
            
            # Get the metric type from the first entry
            metric_type = self._metrics[key][0][0]
            
            return MetricSummary(
                name=name,
                metric_type=metric_type,
                current_value=values[-1],
                min_value=min(values),
                max_value=max(values),
                avg_value=sum(values) / len(values),
                count=len(values),
                last_updated=self._metrics[key][-1][1].timestamp,
                labels=labels or {}
            )
    
    def get_all_metrics(self) -> Dict[str, MetricSummary]:
        """Get all metric summaries"""
        with self._lock:
            summaries = {}
            for key in self._metrics.keys():
                # Parse key to extract name and labels
                if '[' in key:
                    name = key.split('[')[0]
                    label_str = key.split('[')[1].rstrip(']')
                    labels = dict(item.split('=') for item in label_str.split(','))
                else:
                    name = key
                    labels = {}
                
                summary = self.get_metric_summary(name, labels)
                if summary:
                    summaries[key] = summary
            
            return summaries
    
    def clear_metrics(self):
        """Clear all metrics"""
        with self._lock:
            self._metrics.clear()
            self._counters.clear()
            self._gauges.clear()


class SystemMetricsCollector:
    """Collect system-level metrics"""
    
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
        self.logger = logging.getLogger("system_metrics")
        self._collection_task: Optional[asyncio.Task] = None
        self._running = False
    
    async def start_collection(self, interval_seconds: float = 30.0):
        """Start collecting system metrics"""
        if self._running:
            return
        
        self._running = True
        self._collection_task = asyncio.create_task(
            self._collect_metrics_loop(interval_seconds)
        )
        self.logger.info(f"Started system metrics collection (interval: {interval_seconds}s)")
    
    async def stop_collection(self):
        """Stop collecting system metrics"""
        self._running = False
        if self._collection_task:
            self._collection_task.cancel()
            try:
                await self._collection_task
            except asyncio.CancelledError:
                pass
        self.logger.info("Stopped system metrics collection")
    
    async def _collect_metrics_loop(self, interval_seconds: float):
        """Main metrics collection loop"""
        while self._running:
            try:
                await self._collect_system_metrics()
                await asyncio.sleep(interval_seconds)
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error(f"Error collecting system metrics: {str(e)}")
                await asyncio.sleep(interval_seconds)
    
    async def _collect_system_metrics(self):
        """Collect current system metrics"""
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            self.metrics_collector.set_gauge("system_cpu_percent", cpu_percent)
            
            # Memory metrics
            memory = psutil.virtual_memory()
            self.metrics_collector.set_gauge("system_memory_percent", memory.percent)
            self.metrics_collector.set_gauge("system_memory_available_mb", memory.available / 1024 / 1024)
            self.metrics_collector.set_gauge("system_memory_used_mb", memory.used / 1024 / 1024)
            
            # Disk metrics
            disk = psutil.disk_usage('/')
            self.metrics_collector.set_gauge("system_disk_percent", disk.percent)
            self.metrics_collector.set_gauge("system_disk_free_gb", disk.free / 1024 / 1024 / 1024)
            
            # Network metrics
            network = psutil.net_io_counters()
            self.metrics_collector.set_gauge("system_network_bytes_sent", network.bytes_sent)
            self.metrics_collector.set_gauge("system_network_bytes_recv", network.bytes_recv)
            
            # Process metrics
            process = psutil.Process()
            self.metrics_collector.set_gauge("process_cpu_percent", process.cpu_percent())
            self.metrics_collector.set_gauge("process_memory_mb", process.memory_info().rss / 1024 / 1024)
            self.metrics_collector.set_gauge("process_threads", process.num_threads())
            
        except Exception as e:
            self.logger.error(f"Failed to collect system metrics: {str(e)}")


class PerformanceTimer:
    """Context manager for timing operations"""
    
    def __init__(self, metrics_collector: MetricsCollector, metric_name: str, labels: Dict[str, str] = None):
        self.metrics_collector = metrics_collector
        self.metric_name = metric_name
        self.labels = labels or {}
        self.start_time = None
    
    def __enter__(self):
        self.start_time = time.time()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.start_time:
            duration_ms = (time.time() - self.start_time) * 1000
            self.metrics_collector.record_timer(self.metric_name, duration_ms, self.labels)


@asynccontextmanager
async def async_timer(metrics_collector: MetricsCollector, metric_name: str, labels: Dict[str, str] = None):
    """Async context manager for timing operations"""
    start_time = time.time()
    try:
        yield
    finally:
        duration_ms = (time.time() - start_time) * 1000
        metrics_collector.record_timer(metric_name, duration_ms, labels or {})


class AlertManager:
    """Manage performance alerts and thresholds"""
    
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
        self.thresholds: Dict[str, Dict[str, float]] = {}
        self.alert_callbacks: List[Callable] = []
        self.logger = logging.getLogger("alert_manager")
        self._last_alerts: Dict[str, datetime] = {}
        self._alert_cooldown = timedelta(minutes=5)  # Prevent alert spam
    
    def set_threshold(self, metric_name: str, threshold_type: str, value: float):
        """Set alert threshold for a metric"""
        if metric_name not in self.thresholds:
            self.thresholds[metric_name] = {}
        self.thresholds[metric_name][threshold_type] = value
        self.logger.info(f"Set {threshold_type} threshold for {metric_name}: {value}")
    
    def add_alert_callback(self, callback: Callable):
        """Add callback function for alerts"""
        self.alert_callbacks.append(callback)
    
    async def check_thresholds(self):
        """Check all metrics against thresholds and trigger alerts"""
        current_time = datetime.utcnow()
        
        for metric_name, thresholds in self.thresholds.items():
            summary = self.metrics_collector.get_metric_summary(metric_name)
            if not summary:
                continue
            
            for threshold_type, threshold_value in thresholds.items():
                alert_key = f"{metric_name}_{threshold_type}"
                
                # Check cooldown
                if (alert_key in self._last_alerts and 
                    current_time - self._last_alerts[alert_key] < self._alert_cooldown):
                    continue
                
                should_alert = False
                
                if threshold_type == "max" and summary.current_value > threshold_value:
                    should_alert = True
                elif threshold_type == "min" and summary.current_value < threshold_value:
                    should_alert = True
                elif threshold_type == "avg_max" and summary.avg_value > threshold_value:
                    should_alert = True
                
                if should_alert:
                    await self._trigger_alert(metric_name, threshold_type, summary.current_value, threshold_value)
                    self._last_alerts[alert_key] = current_time
    
    async def _trigger_alert(self, metric_name: str, threshold_type: str, current_value: float, threshold_value: float):
        """Trigger alert for threshold violation"""
        alert_data = {
            "metric_name": metric_name,
            "threshold_type": threshold_type,
            "current_value": current_value,
            "threshold_value": threshold_value,
            "timestamp": datetime.utcnow().isoformat(),
            "severity": "warning" if threshold_type.startswith("avg") else "critical"
        }
        
        self.logger.warning(
            f"ALERT: {metric_name} {threshold_type} threshold exceeded: "
            f"{current_value} > {threshold_value}",
            extra=alert_data
        )
        
        # Call all registered alert callbacks
        for callback in self.alert_callbacks:
            try:
                if asyncio.iscoroutinefunction(callback):
                    await callback(alert_data)
                else:
                    callback(alert_data)
            except Exception as e:
                self.logger.error(f"Alert callback failed: {str(e)}")


class MetricsExporter:
    """Export metrics in various formats"""
    
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
    
    def export_prometheus(self) -> str:
        """Export metrics in Prometheus format"""
        lines = []
        summaries = self.metrics_collector.get_all_metrics()
        
        for key, summary in summaries.items():
            # Convert metric name to Prometheus format
            prom_name = summary.name.replace("-", "_").replace(".", "_")
            
            # Add help and type comments
            lines.append(f"# HELP {prom_name} {summary.name} metric")
            lines.append(f"# TYPE {prom_name} {summary.metric_type.value}")
            
            # Add labels if present
            label_str = ""
            if summary.labels:
                label_pairs = [f'{k}="{v}"' for k, v in summary.labels.items()]
                label_str = "{" + ",".join(label_pairs) + "}"
            
            lines.append(f"{prom_name}{label_str} {summary.current_value}")
        
        return "\n".join(lines)
    
    def export_json(self) -> str:
        """Export metrics in JSON format"""
        summaries = self.metrics_collector.get_all_metrics()
        
        export_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "metrics": {}
        }
        
        for key, summary in summaries.items():
            export_data["metrics"][key] = {
                "name": summary.name,
                "type": summary.metric_type.value,
                "current_value": summary.current_value,
                "min_value": summary.min_value,
                "max_value": summary.max_value,
                "avg_value": summary.avg_value,
                "count": summary.count,
                "last_updated": summary.last_updated.isoformat(),
                "labels": summary.labels
            }
        
        return json.dumps(export_data, indent=2)


# Global metrics collector instance
metrics_collector = MetricsCollector()
system_metrics_collector = SystemMetricsCollector(metrics_collector)
alert_manager = AlertManager(metrics_collector)
metrics_exporter = MetricsExporter(metrics_collector)


async def setup_performance_monitoring():
    """Setup performance monitoring with default thresholds"""
    
    # Set default alert thresholds
    alert_manager.set_threshold("system_cpu_percent", "max", 80.0)
    alert_manager.set_threshold("system_memory_percent", "max", 85.0)
    alert_manager.set_threshold("system_disk_percent", "max", 90.0)
    alert_manager.set_threshold("api_response_time_ms", "avg_max", 3000.0)
    alert_manager.set_threshold("database_query_time_ms", "avg_max", 1000.0)
    
    # Start system metrics collection
    await system_metrics_collector.start_collection(interval_seconds=30.0)
    
    # Start periodic threshold checking
    asyncio.create_task(_periodic_threshold_check())
    
    logging.getLogger("performance_monitoring").info("Performance monitoring setup complete")


async def _periodic_threshold_check():
    """Periodically check thresholds for alerts"""
    while True:
        try:
            await alert_manager.check_thresholds()
            await asyncio.sleep(60)  # Check every minute
        except asyncio.CancelledError:
            break
        except Exception as e:
            logging.getLogger("alert_manager").error(f"Threshold check failed: {str(e)}")
            await asyncio.sleep(60)


def timer(metric_name: str, labels: Dict[str, str] = None):
    """Decorator for timing function execution"""
    def decorator(func):
        if asyncio.iscoroutinefunction(func):
            async def async_wrapper(*args, **kwargs):
                async with async_timer(metrics_collector, metric_name, labels):
                    return await func(*args, **kwargs)
            return async_wrapper
        else:
            def sync_wrapper(*args, **kwargs):
                with PerformanceTimer(metrics_collector, metric_name, labels):
                    return func(*args, **kwargs)
            return sync_wrapper
    return decorator