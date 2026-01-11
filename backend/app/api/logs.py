"""
AIVONITY Logs and Audit API
API endpoints for log analysis, audit trails, and system logging
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import logging

from app.utils.log_aggregation import log_aggregator, LogLevel
from app.utils.audit_trail import (
    audit_trail_manager, 
    AuditEventType, 
    AuditSeverity,
    data_access_auditor
)
from app.utils.logging_config import get_logger
from app.utils.exceptions import SystemError

router = APIRouter()
logger = logging.getLogger("logs_api")


@router.get("/logs")
async def get_logs(
    level: Optional[LogLevel] = Query(None, description="Filter by log level"),
    logger_name: Optional[str] = Query(None, description="Filter by logger name"),
    start_time: Optional[datetime] = Query(None, description="Start time for log entries"),
    end_time: Optional[datetime] = Query(None, description="End time for log entries"),
    limit: int = Query(100, ge=1, le=10000, description="Maximum number of entries to return"),
    search: Optional[str] = Query(None, description="Search term in log messages")
):
    """
    Get system logs with filtering options
    """
    try:
        # Get filtered log entries
        entries = log_aggregator.get_entries(
            level=level,
            logger_name=logger_name,
            start_time=start_time,
            end_time=end_time,
            limit=limit
        )
        
        # Apply search filter if provided
        if search:
            search_lower = search.lower()
            entries = [
                entry for entry in entries 
                if search_lower in entry.message.lower()
            ]
        
        # Convert to response format
        log_entries = []
        for entry in entries:
            log_entries.append({
                "timestamp": entry.timestamp.isoformat(),
                "level": entry.level.value,
                "logger_name": entry.logger_name,
                "message": entry.message,
                "module": entry.module,
                "function": entry.function,
                "line_number": entry.line_number,
                "thread_id": entry.thread_id,
                "process_id": entry.process_id,
                "user_id": entry.user_id,
                "correlation_id": entry.correlation_id,
                "extra_data": entry.extra_data
            })
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_entries": len(log_entries),
            "filters": {
                "level": level.value if level else None,
                "logger_name": logger_name,
                "start_time": start_time.isoformat() if start_time else None,
                "end_time": end_time.isoformat() if end_time else None,
                "search": search
            },
            "entries": log_entries
        }
        
    except Exception as e:
        logger.error(f"Failed to get logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve logs: {str(e)}")


@router.get("/logs/statistics")
async def get_log_statistics():
    """
    Get log aggregation statistics
    """
    try:
        stats = log_aggregator.get_statistics()
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "statistics": stats
        }
    except Exception as e:
        logger.error(f"Failed to get log statistics: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve statistics: {str(e)}")


@router.get("/logs/analysis")
async def analyze_logs(
    time_window_hours: int = Query(24, ge=1, le=168, description="Time window in hours for analysis")
):
    """
    Analyze logs for patterns and anomalies
    """
    try:
        analysis_results = log_aggregator.analyze_patterns(time_window_hours)
        
        # Convert results to response format
        results = {}
        for pattern_name, result in analysis_results.items():
            results[pattern_name] = {
                "pattern_name": result.pattern_name,
                "count": result.count,
                "time_range": {
                    "start": result.time_range[0].isoformat(),
                    "end": result.time_range[1].isoformat()
                },
                "severity": result.severity,
                "summary": result.summary,
                "recommendations": result.recommendations,
                "sample_matches": [
                    {
                        "timestamp": match.timestamp.isoformat(),
                        "level": match.level.value,
                        "message": match.message,
                        "logger_name": match.logger_name
                    }
                    for match in result.matches[:5]  # Show first 5 matches
                ]
            }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "time_window_hours": time_window_hours,
            "total_patterns": len(results),
            "analysis_results": results
        }
        
    except Exception as e:
        logger.error(f"Failed to analyze logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to analyze logs: {str(e)}")


@router.get("/logs/errors")
async def get_error_logs(
    hours: int = Query(24, ge=1, le=168, description="Hours to look back for errors"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of errors to return")
):
    """
    Get recent error logs
    """
    try:
        start_time = datetime.utcnow() - timedelta(hours=hours)
        
        # Get error and critical level logs
        error_entries = log_aggregator.get_entries(
            level=LogLevel.ERROR,
            start_time=start_time,
            limit=limit
        )
        
        critical_entries = log_aggregator.get_entries(
            level=LogLevel.CRITICAL,
            start_time=start_time,
            limit=limit
        )
        
        # Combine and sort
        all_errors = error_entries + critical_entries
        all_errors.sort(key=lambda x: x.timestamp, reverse=True)
        all_errors = all_errors[:limit]
        
        # Convert to response format
        error_logs = []
        for entry in all_errors:
            error_logs.append({
                "timestamp": entry.timestamp.isoformat(),
                "level": entry.level.value,
                "logger_name": entry.logger_name,
                "message": entry.message,
                "module": entry.module,
                "function": entry.function,
                "line_number": entry.line_number,
                "extra_data": entry.extra_data
            })
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "time_window_hours": hours,
            "total_errors": len(error_logs),
            "errors": error_logs
        }
        
    except Exception as e:
        logger.error(f"Failed to get error logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve error logs: {str(e)}")


@router.get("/audit/events")
async def get_audit_events(
    event_type: Optional[AuditEventType] = Query(None, description="Filter by event type"),
    user_id: Optional[str] = Query(None, description="Filter by user ID"),
    start_time: Optional[datetime] = Query(None, description="Start time for events"),
    end_time: Optional[datetime] = Query(None, description="End time for events"),
    severity: Optional[AuditSeverity] = Query(None, description="Filter by severity"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of events to return")
):
    """
    Get audit trail events with filtering
    Note: This is a placeholder - in a real implementation, 
    audit events would be stored in a database
    """
    try:
        # This would typically query a database of audit events
        # For now, we'll return a placeholder response
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "filters": {
                "event_type": event_type.value if event_type else None,
                "user_id": user_id,
                "start_time": start_time.isoformat() if start_time else None,
                "end_time": end_time.isoformat() if end_time else None,
                "severity": severity.value if severity else None
            },
            "total_events": 0,
            "events": [],
            "note": "Audit events are logged to files and would be stored in database in production"
        }
        
    except Exception as e:
        logger.error(f"Failed to get audit events: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve audit events: {str(e)}")


@router.get("/audit/summary")
async def get_audit_summary(
    hours: int = Query(24, ge=1, le=168, description="Hours to summarize")
):
    """
    Get audit trail summary for specified time period
    """
    try:
        # This would typically aggregate audit data from database
        # For now, return a placeholder summary
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "time_window_hours": hours,
            "summary": {
                "total_events": 0,
                "events_by_type": {},
                "events_by_severity": {},
                "unique_users": 0,
                "failed_operations": 0,
                "security_events": 0
            },
            "note": "Audit summary would be generated from database in production"
        }
        
    except Exception as e:
        logger.error(f"Failed to get audit summary: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve audit summary: {str(e)}")


@router.post("/audit/data-access")
async def log_data_access(
    user_id: str,
    resource_type: str,
    resource_id: str,
    fields_accessed: List[str],
    query_params: Optional[Dict[str, Any]] = None
):
    """
    Log a data access event for audit trail
    """
    try:
        await data_access_auditor.audit_data_read(
            user_id=user_id,
            resource_type=resource_type,
            resource_id=resource_id,
            fields_accessed=fields_accessed,
            query_params=query_params
        )
        
        return {
            "message": "Data access logged successfully",
            "timestamp": datetime.utcnow().isoformat(),
            "event_details": {
                "user_id": user_id,
                "resource_type": resource_type,
                "resource_id": resource_id,
                "fields_accessed": fields_accessed
            }
        }
        
    except Exception as e:
        logger.error(f"Failed to log data access: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to log data access: {str(e)}")


@router.get("/logs/export")
async def export_logs(
    format: str = Query("json", regex="^(json|csv)$", description="Export format"),
    level: Optional[LogLevel] = Query(None, description="Filter by log level"),
    start_time: Optional[datetime] = Query(None, description="Start time for export"),
    end_time: Optional[datetime] = Query(None, description="End time for export"),
    limit: int = Query(1000, ge=1, le=50000, description="Maximum entries to export")
):
    """
    Export logs in specified format
    """
    try:
        # Get filtered entries
        entries = log_aggregator.get_entries(
            level=level,
            start_time=start_time,
            end_time=end_time,
            limit=limit
        )
        
        if format == "json":
            export_data = {
                "export_timestamp": datetime.utcnow().isoformat(),
                "total_entries": len(entries),
                "filters": {
                    "level": level.value if level else None,
                    "start_time": start_time.isoformat() if start_time else None,
                    "end_time": end_time.isoformat() if end_time else None
                },
                "entries": [
                    {
                        "timestamp": entry.timestamp.isoformat(),
                        "level": entry.level.value,
                        "logger_name": entry.logger_name,
                        "message": entry.message,
                        "module": entry.module,
                        "function": entry.function,
                        "line_number": entry.line_number,
                        "user_id": entry.user_id,
                        "correlation_id": entry.correlation_id,
                        "extra_data": entry.extra_data
                    }
                    for entry in entries
                ]
            }
            return export_data
            
        elif format == "csv":
            # For CSV, we'd return a CSV response
            # This is a simplified implementation
            csv_lines = ["timestamp,level,logger_name,message"]
            for entry in entries:
                csv_lines.append(
                    f"{entry.timestamp.isoformat()},{entry.level.value},"
                    f"{entry.logger_name},\"{entry.message.replace('\"', '\"\"')}\""
                )
            
            return {
                "format": "csv",
                "data": "\n".join(csv_lines),
                "total_entries": len(entries)
            }
        
    except Exception as e:
        logger.error(f"Failed to export logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to export logs: {str(e)}")


@router.get("/logs/search")
async def search_logs(
    query: str = Query(..., description="Search query"),
    level: Optional[LogLevel] = Query(None, description="Filter by log level"),
    logger_name: Optional[str] = Query(None, description="Filter by logger name"),
    hours: int = Query(24, ge=1, le=168, description="Hours to search back"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum results to return")
):
    """
    Search logs with text query
    """
    try:
        start_time = datetime.utcnow() - timedelta(hours=hours)
        
        # Get entries within time range
        entries = log_aggregator.get_entries(
            level=level,
            logger_name=logger_name,
            start_time=start_time,
            limit=limit * 2  # Get more to filter
        )
        
        # Search in messages
        query_lower = query.lower()
        matching_entries = []
        
        for entry in entries:
            if (query_lower in entry.message.lower() or 
                (entry.extra_data and 
                 any(query_lower in str(v).lower() for v in entry.extra_data.values()))):
                matching_entries.append(entry)
                
                if len(matching_entries) >= limit:
                    break
        
        # Convert to response format
        search_results = []
        for entry in matching_entries:
            search_results.append({
                "timestamp": entry.timestamp.isoformat(),
                "level": entry.level.value,
                "logger_name": entry.logger_name,
                "message": entry.message,
                "module": entry.module,
                "function": entry.function,
                "user_id": entry.user_id,
                "correlation_id": entry.correlation_id,
                "extra_data": entry.extra_data
            })
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "query": query,
            "time_window_hours": hours,
            "total_results": len(search_results),
            "results": search_results
        }
        
    except Exception as e:
        logger.error(f"Failed to search logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to search logs: {str(e)}")


# Admin endpoints for log management
@router.delete("/admin/logs/clear")
async def clear_logs():
    """
    Clear log aggregator buffer (admin only)
    """
    try:
        # Clear the log aggregator
        log_aggregator.log_entries.clear()
        log_aggregator.stats = {
            "total_entries": 0,
            "entries_by_level": {},
            "entries_by_logger": {},
            "pattern_matches": {}
        }
        
        return {
            "message": "Log buffer cleared successfully",
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to clear logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to clear logs: {str(e)}")


@router.get("/admin/logs/config")
async def get_log_config():
    """
    Get current logging configuration (admin only)
    """
    try:
        # Get current logging configuration
        root_logger = logging.getLogger()
        
        config_info = {
            "root_level": root_logger.level,
            "handlers": [
                {
                    "name": handler.__class__.__name__,
                    "level": handler.level,
                    "formatter": handler.formatter.__class__.__name__ if handler.formatter else None
                }
                for handler in root_logger.handlers
            ],
            "loggers": {}
        }
        
        # Get info for specific loggers
        for logger_name in ["app", "agent", "security", "audit", "performance"]:
            logger_obj = logging.getLogger(logger_name)
            config_info["loggers"][logger_name] = {
                "level": logger_obj.level,
                "handlers_count": len(logger_obj.handlers),
                "propagate": logger_obj.propagate
            }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "logging_config": config_info
        }
        
    except Exception as e:
        logger.error(f"Failed to get log config: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get log config: {str(e)}")