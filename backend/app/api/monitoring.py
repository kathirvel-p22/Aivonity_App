"""
AIVONITY Monitoring API
API endpoints for system monitoring, metrics, and health checks
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from fastapi.responses import PlainTextResponse
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import logging

from app.utils.health_check import system_health_monitor, HealthStatus
from app.utils.metrics import metrics_collector, metrics_exporter, alert_manager
from app.utils.alerting import alert_manager_instance, AlertSeverity
from app.utils.auth import get_current_admin_user  # Assuming admin auth exists
from app.utils.exceptions import SystemError

router = APIRouter()
logger = logging.getLogger("monitoring_api")


@router.get("/health")
async def comprehensive_health_check():
    """
    Comprehensive health check endpoint
    Returns detailed health status of all system components
    """
    try:
        health_results = await system_health_monitor.check_all(timeout=10.0)
        return health_results
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail={
                "overall_status": "unknown",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e),
                "components": {}
            }
        )


@router.get("/health/quick")
async def quick_health_check():
    """
    Quick health check endpoint
    Returns cached health status for fast response
    """
    last_results = system_health_monitor.get_last_results()
    if last_results:
        return {
            "status": "healthy" if system_health_monitor.is_healthy() else "unhealthy",
            "last_check": last_results
        }
    else:
        return {
            "status": "unknown",
            "message": "No health check data available"
        }


@router.get("/health/component/{component_name}")
async def component_health_check(component_name: str):
    """
    Health check for a specific component
    """
    last_results = system_health_monitor.get_last_results()
    if not last_results or "components" not in last_results:
        raise HTTPException(
            status_code=404,
            detail=f"No health data available for component: {component_name}"
        )
    
    if component_name not in last_results["components"]:
        raise HTTPException(
            status_code=404,
            detail=f"Component not found: {component_name}"
        )
    
    return {
        "component": component_name,
        "status": last_results["components"][component_name],
        "timestamp": last_results["timestamp"]
    }


@router.get("/metrics")
async def get_all_metrics():
    """
    Get all current metrics
    Returns summary of all collected metrics
    """
    try:
        all_metrics = metrics_collector.get_all_metrics()
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_metrics": len(all_metrics),
            "metrics": {
                key: {
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
                for key, summary in all_metrics.items()
            }
        }
    except Exception as e:
        logger.error(f"Failed to get metrics: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve metrics: {str(e)}")


@router.get("/metrics/{metric_name}")
async def get_metric(metric_name: str, labels: Optional[str] = Query(None)):
    """
    Get specific metric by name
    Optional labels parameter for filtering (format: key1=value1,key2=value2)
    """
    try:
        # Parse labels if provided
        label_dict = {}
        if labels:
            for label_pair in labels.split(','):
                if '=' in label_pair:
                    key, value = label_pair.split('=', 1)
                    label_dict[key.strip()] = value.strip()
        
        summary = metrics_collector.get_metric_summary(metric_name, label_dict)
        if not summary:
            raise HTTPException(
                status_code=404,
                detail=f"Metric not found: {metric_name}"
            )
        
        return {
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
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get metric {metric_name}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve metric: {str(e)}")


@router.get("/metrics/export/prometheus", response_class=PlainTextResponse)
async def export_prometheus_metrics():
    """
    Export metrics in Prometheus format
    """
    try:
        prometheus_data = metrics_exporter.export_prometheus()
        return PlainTextResponse(content=prometheus_data, media_type="text/plain")
    except Exception as e:
        logger.error(f"Failed to export Prometheus metrics: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to export metrics: {str(e)}")


@router.get("/metrics/export/json")
async def export_json_metrics():
    """
    Export metrics in JSON format
    """
    try:
        json_data = metrics_exporter.export_json()
        return json_data
    except Exception as e:
        logger.error(f"Failed to export JSON metrics: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to export metrics: {str(e)}")


@router.get("/alerts")
async def get_active_alerts(
    severity: Optional[AlertSeverity] = Query(None),
    limit: int = Query(50, ge=1, le=1000)
):
    """
    Get active alerts
    Optional severity filter and limit
    """
    try:
        alerts = alert_manager_instance.get_active_alerts(severity)
        
        # Limit results
        alerts = alerts[:limit]
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_alerts": len(alerts),
            "alerts": [
                {
                    "id": alert.id,
                    "title": alert.title,
                    "description": alert.description,
                    "severity": alert.severity.value,
                    "category": alert.category.value,
                    "source": alert.source,
                    "timestamp": alert.timestamp.isoformat(),
                    "metadata": alert.metadata
                }
                for alert in alerts
            ]
        }
    except Exception as e:
        logger.error(f"Failed to get alerts: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve alerts: {str(e)}")


@router.get("/alerts/history")
async def get_alert_history(
    hours: int = Query(24, ge=1, le=168),  # Max 1 week
    limit: int = Query(100, ge=1, le=1000)
):
    """
    Get alert history for specified hours
    """
    try:
        alerts = alert_manager_instance.get_alert_history(hours)
        
        # Limit results
        alerts = alerts[:limit]
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "hours": hours,
            "total_alerts": len(alerts),
            "alerts": [
                {
                    "id": alert.id,
                    "title": alert.title,
                    "description": alert.description,
                    "severity": alert.severity.value,
                    "category": alert.category.value,
                    "source": alert.source,
                    "timestamp": alert.timestamp.isoformat(),
                    "resolved": alert.resolved,
                    "resolved_at": alert.resolved_at.isoformat() if alert.resolved_at else None,
                    "resolved_by": alert.resolved_by,
                    "metadata": alert.metadata
                }
                for alert in alerts
            ]
        }
    except Exception as e:
        logger.error(f"Failed to get alert history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve alert history: {str(e)}")


@router.post("/alerts/{alert_id}/resolve")
async def resolve_alert(
    alert_id: str,
    resolved_by: str = "api_user"
):
    """
    Resolve an active alert
    """
    try:
        await alert_manager_instance.resolve_alert(alert_id, resolved_by)
        return {
            "message": f"Alert {alert_id} resolved successfully",
            "resolved_by": resolved_by,
            "resolved_at": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Failed to resolve alert {alert_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to resolve alert: {str(e)}")


@router.get("/system/status")
async def get_system_status():
    """
    Get comprehensive system status
    Combines health, metrics, and alerts
    """
    try:
        # Get health status
        health_results = system_health_monitor.get_last_results()
        is_healthy = system_health_monitor.is_healthy()
        
        # Get key metrics
        key_metrics = {}
        metric_names = [
            "system_cpu_percent",
            "system_memory_percent", 
            "system_disk_percent",
            "api_response_time_ms",
            "database_query_time_ms"
        ]
        
        for metric_name in metric_names:
            summary = metrics_collector.get_metric_summary(metric_name)
            if summary:
                key_metrics[metric_name] = {
                    "current_value": summary.current_value,
                    "avg_value": summary.avg_value
                }
        
        # Get active alerts count by severity
        active_alerts = alert_manager_instance.get_active_alerts()
        alert_counts = {
            "critical": len([a for a in active_alerts if a.severity == AlertSeverity.CRITICAL]),
            "warning": len([a for a in active_alerts if a.severity == AlertSeverity.WARNING]),
            "info": len([a for a in active_alerts if a.severity == AlertSeverity.INFO])
        }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "overall_status": "healthy" if is_healthy else "unhealthy",
            "health": health_results,
            "key_metrics": key_metrics,
            "active_alerts": {
                "total": len(active_alerts),
                "by_severity": alert_counts
            },
            "uptime_info": {
                "status": "operational",
                "last_restart": "system_start_time"  # Would be actual start time
            }
        }
    except Exception as e:
        logger.error(f"Failed to get system status: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve system status: {str(e)}")


@router.get("/performance/summary")
async def get_performance_summary():
    """
    Get performance summary with key performance indicators
    """
    try:
        # Get performance-related metrics
        performance_metrics = {}
        perf_metric_names = [
            "api_response_time_ms",
            "database_query_time_ms", 
            "ml_inference_time_ms",
            "websocket_connections",
            "active_sessions",
            "request_rate_per_minute"
        ]
        
        for metric_name in perf_metric_names:
            summary = metrics_collector.get_metric_summary(metric_name)
            if summary:
                performance_metrics[metric_name] = {
                    "current": summary.current_value,
                    "average": summary.avg_value,
                    "min": summary.min_value,
                    "max": summary.max_value,
                    "samples": summary.count
                }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "performance_metrics": performance_metrics,
            "summary": {
                "avg_response_time": performance_metrics.get("api_response_time_ms", {}).get("average", 0),
                "avg_db_query_time": performance_metrics.get("database_query_time_ms", {}).get("average", 0),
                "active_connections": performance_metrics.get("websocket_connections", {}).get("current", 0),
                "request_rate": performance_metrics.get("request_rate_per_minute", {}).get("current", 0)
            }
        }
    except Exception as e:
        logger.error(f"Failed to get performance summary: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve performance summary: {str(e)}")


# Admin-only endpoints (would require proper authentication)
@router.post("/admin/metrics/clear")
async def clear_all_metrics():
    """
    Clear all metrics (admin only)
    """
    try:
        metrics_collector.clear_metrics()
        return {
            "message": "All metrics cleared successfully",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Failed to clear metrics: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to clear metrics: {str(e)}")


@router.get("/admin/system/info")
async def get_system_info():
    """
    Get detailed system information (admin only)
    """
    try:
        import psutil
        import platform
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "system": {
                "platform": platform.platform(),
                "python_version": platform.python_version(),
                "cpu_count": psutil.cpu_count(),
                "memory_total_gb": psutil.virtual_memory().total / 1024 / 1024 / 1024,
                "disk_total_gb": psutil.disk_usage('/').total / 1024 / 1024 / 1024
            },
            "process": {
                "pid": psutil.Process().pid,
                "memory_mb": psutil.Process().memory_info().rss / 1024 / 1024,
                "cpu_percent": psutil.Process().cpu_percent(),
                "threads": psutil.Process().num_threads(),
                "open_files": len(psutil.Process().open_files())
            }
        }
    except Exception as e:
        logger.error(f"Failed to get system info: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve system info: {str(e)}")