"""
AIVONITY Security API Endpoints
Advanced security monitoring and alerting endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Body
from fastapi.security import HTTPBearer
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import json

from app.agents.ueba_agent import UEBAAgent
from app.services.security_service import security_service
from app.db.database import get_async_session
from app.utils.logging_config import get_logger, security_logger, audit_logger
from app.config import settings

router = APIRouter(prefix="/security", tags=["security"])
security = HTTPBearer()
logger = get_logger(__name__)

# Global UEBA agent instance (would be managed by agent manager in production)
ueba_agent = None

async def get_ueba_agent():
    """Get UEBA agent instance"""
    global ueba_agent
    if not ueba_agent:
        config = {
            "monitoring_interval": 300,
            "anomaly_threshold": 0.8,
            "alert_threshold": 0.9
        }
        ueba_agent = UEBAAgent(config)
        await ueba_agent._initialize_resources()
    return ueba_agent

@router.get("/status")
async def get_security_status():
    """Get overall security status"""
    try:
        agent = await get_ueba_agent()
        
        # Get UEBA agent status
        ueba_status = await agent.health_check()
        
        # Get security service metrics
        security_metrics = await security_service.get_security_metrics()
        
        # Get dashboard data
        dashboard_data = await agent.get_security_dashboard_data()
        
        status = {
            "ueba_agent": ueba_status,
            "security_service": security_metrics,
            "dashboard": dashboard_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        return status
        
    except Exception as e:
        logger.error(f"❌ Error getting security status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/alerts")
async def get_security_alerts(
    limit: int = Query(50, ge=1, le=100),
    severity: Optional[str] = Query(None, regex="^(low|medium|high|critical)$"),
    status: Optional[str] = Query(None, regex="^(new|investigating|resolved|false_positive)$")
):
    """Get security alerts with filtering"""
    try:
        agent = await get_ueba_agent()
        
        # Get active alerts
        active_alerts = []
        for alert in agent.active_alerts.values():
            if severity and alert.severity != severity:
                continue
            if status and alert.status != status:
                continue
            
            alert_data = {
                "alert_id": alert.alert_id,
                "entity_id": alert.entity_id,
                "entity_type": alert.entity_type,
                "alert_type": alert.alert_type,
                "severity": alert.severity,
                "title": alert.title,
                "description": alert.description,
                "anomaly_score": alert.anomaly_score,
                "confidence": alert.confidence,
                "indicators": alert.indicators,
                "detected_at": alert.detected_at.isoformat(),
                "status": alert.status
            }
            active_alerts.append(alert_data)
        
        # Sort by detection time (newest first)
        active_alerts.sort(key=lambda x: x["detected_at"], reverse=True)
        
        # Apply limit
        active_alerts = active_alerts[:limit]
        
        return {
            "alerts": active_alerts,
            "total_count": len(agent.active_alerts),
            "filtered_count": len(active_alerts)
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting security alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/alerts/{alert_id}/resolve")
async def resolve_security_alert(
    alert_id: str,
    resolution_data: Dict[str, Any] = Body(...)
):
    """Resolve a security alert"""
    try:
        agent = await get_ueba_agent()
        
        resolution_notes = resolution_data.get("notes", "")
        
        success = await agent.resolve_alert(alert_id, resolution_notes)
        
        if not success:
            raise HTTPException(status_code=404, detail="Alert not found")
        
        # Log the resolution
        audit_logger.log_system_event(
            event_type="alert_resolved",
            details={
                "alert_id": alert_id,
                "resolution_notes": resolution_notes,
                "resolved_by": "api_user"  # Would be actual user in production
            }
        )
        
        return {"message": "Alert resolved successfully", "alert_id": alert_id}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error resolving security alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze/user-behavior")
async def analyze_user_behavior(
    behavior_data: Dict[str, Any] = Body(...)
):
    """Analyze user behavior for anomalies"""
    try:
        user_id = behavior_data.get("user_id")
        if not user_id:
            raise HTTPException(status_code=400, detail="user_id is required")
        
        # Detect anomalies using security service
        is_anomaly, anomaly_score, reasons = await security_service.detect_user_behavior_anomaly(
            user_id, behavior_data
        )
        
        # If anomaly detected, generate alert
        if is_anomaly and anomaly_score > 0.7:
            agent = await get_ueba_agent()
            await agent._generate_security_alert(
                entity_id=user_id,
                entity_type="user",
                alert_type="user_behavior_anomaly",
                anomalies=reasons
            )
        
        return {
            "user_id": user_id,
            "is_anomaly": is_anomaly,
            "anomaly_score": anomaly_score,
            "reasons": reasons,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error analyzing user behavior: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze/api-usage")
async def analyze_api_usage(
    api_data: Dict[str, Any] = Body(...)
):
    """Analyze API usage for anomalies"""
    try:
        user_id = api_data.get("user_id")
        if not user_id:
            raise HTTPException(status_code=400, detail="user_id is required")
        
        # Detect anomalies using security service
        is_anomaly, anomaly_score, reasons = await security_service.detect_api_usage_anomaly(
            user_id, api_data
        )
        
        # If anomaly detected, generate alert
        if is_anomaly and anomaly_score > 0.6:
            agent = await get_ueba_agent()
            await agent._generate_security_alert(
                entity_id=user_id,
                entity_type="user",
                alert_type="api_usage_anomaly",
                anomalies=reasons
            )
        
        return {
            "user_id": user_id,
            "is_anomaly": is_anomaly,
            "anomaly_score": anomaly_score,
            "reasons": reasons,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error analyzing API usage: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze/system")
async def analyze_system_metrics(
    system_data: Dict[str, Any] = Body(...)
):
    """Analyze system metrics for anomalies"""
    try:
        # Detect anomalies using security service
        is_anomaly, anomaly_score, reasons = await security_service.detect_system_anomaly(
            system_data
        )
        
        # If anomaly detected, generate alert
        if is_anomaly and anomaly_score > 0.8:
            agent = await get_ueba_agent()
            await agent._generate_security_alert(
                entity_id="system",
                entity_type="system",
                alert_type="system_anomaly",
                anomalies=reasons
            )
        
        return {
            "is_anomaly": is_anomaly,
            "anomaly_score": anomaly_score,
            "reasons": reasons,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Error analyzing system metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/incident-response")
async def execute_incident_response(
    response_data: Dict[str, Any] = Body(...)
):
    """Execute incident response actions"""
    try:
        alert_id = response_data.get("alert_id")
        actions = response_data.get("actions", [])
        
        if not alert_id or not actions:
            raise HTTPException(status_code=400, detail="alert_id and actions are required")
        
        # Execute incident response
        responses = await security_service.execute_incident_response(alert_id, actions)
        
        # Format response data
        response_data = []
        for response in responses:
            response_data.append({
                "action_type": response.action_type,
                "target": response.target,
                "success": response.success,
                "executed_at": response.executed_at.isoformat() if response.executed_at else None,
                "error_message": response.error_message
            })
        
        return {
            "alert_id": alert_id,
            "responses": response_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error executing incident response: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/threat-intelligence")
async def get_threat_intelligence():
    """Get current threat intelligence"""
    try:
        # Get threat indicators from security service
        indicators = []
        for key, indicator in security_service.threat_indicators.items():
            indicator_data = {
                "type": indicator.indicator_type,
                "value": indicator.value,
                "severity": indicator.severity,
                "confidence": indicator.confidence,
                "first_seen": indicator.first_seen.isoformat(),
                "last_seen": indicator.last_seen.isoformat(),
                "occurrence_count": indicator.occurrence_count,
                "context": indicator.context
            }
            indicators.append(indicator_data)
        
        # Sort by severity and confidence
        severity_order = {"critical": 4, "high": 3, "medium": 2, "low": 1}
        indicators.sort(
            key=lambda x: (severity_order.get(x["severity"], 0), x["confidence"]),
            reverse=True
        )
        
        return {
            "indicators": indicators,
            "total_count": len(indicators),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting threat intelligence: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/threat-intelligence")
async def update_threat_intelligence(
    indicators: List[Dict[str, Any]] = Body(...)
):
    """Update threat intelligence with new indicators"""
    try:
        # Validate indicators
        for indicator in indicators:
            required_fields = ["type", "value"]
            for field in required_fields:
                if field not in indicator:
                    raise HTTPException(status_code=400, detail=f"Missing required field: {field}")
        
        # Update threat intelligence
        await security_service.update_threat_intelligence(indicators)
        
        # Log the update
        audit_logger.log_system_event(
            event_type="threat_intelligence_updated",
            details={
                "indicators_count": len(indicators),
                "updated_by": "api_user"  # Would be actual user in production
            }
        )
        
        return {
            "message": "Threat intelligence updated successfully",
            "indicators_count": len(indicators),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating threat intelligence: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/blocked-entities")
async def get_blocked_entities():
    """Get list of blocked entities"""
    try:
        blocked_entities = []
        current_time = datetime.utcnow()
        
        for entity_id, block_until in security_service.blocked_entities.items():
            if current_time < block_until:  # Still blocked
                blocked_entities.append({
                    "entity_id": entity_id,
                    "blocked_until": block_until.isoformat(),
                    "remaining_minutes": int((block_until - current_time).total_seconds() / 60)
                })
        
        return {
            "blocked_entities": blocked_entities,
            "total_count": len(blocked_entities),
            "timestamp": current_time.isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting blocked entities: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/blocked-entities/{entity_id}")
async def unblock_entity(entity_id: str):
    """Unblock a specific entity"""
    try:
        if entity_id in security_service.blocked_entities:
            del security_service.blocked_entities[entity_id]
            
            # Remove from Redis
            await security_service.redis_client.delete(f"blocked_entity:{entity_id}")
            
            # Log the unblock action
            audit_logger.log_system_event(
                event_type="entity_unblocked",
                details={
                    "entity_id": entity_id,
                    "unblocked_by": "api_user"  # Would be actual user in production
                }
            )
            
            return {"message": f"Entity {entity_id} unblocked successfully"}
        else:
            raise HTTPException(status_code=404, detail="Entity not found in blocked list")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error unblocking entity: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dashboard")
async def get_security_dashboard():
    """Get security dashboard data"""
    try:
        agent = await get_ueba_agent()
        
        # Get comprehensive dashboard data
        dashboard_data = await agent.get_security_dashboard_data()
        
        # Add additional security service data
        security_metrics = await security_service.get_security_metrics()
        dashboard_data["security_service"] = security_metrics
        
        # Get recent notifications
        notifications = await security_service.redis_client.lrange("security_notifications", 0, 9)
        dashboard_data["recent_notifications"] = [
            json.loads(notification) for notification in notifications
        ]
        
        return dashboard_data
        
    except Exception as e:
        logger.error(f"❌ Error getting security dashboard: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/report-security-event")
async def report_security_event(
    event_data: Dict[str, Any] = Body(...)
):
    """Report a security event for analysis"""
    try:
        event_type = event_data.get("event_type")
        entity_id = event_data.get("entity_id")
        details = event_data.get("details", {})
        
        if not event_type or not entity_id:
            raise HTTPException(status_code=400, detail="event_type and entity_id are required")
        
        agent = await get_ueba_agent()
        
        # Send security event to UEBA agent
        await agent.receive_message({
            "sender": "security_api",
            "recipient": "ueba_agent",
            "message_type": "security_event",
            "payload": {
                "event_type": event_type,
                "entity_id": entity_id,
                "details": details
            }
        })
        
        # Log the security event
        security_logger.log_suspicious_activity(
            user_id=entity_id,
            activity_type=event_type,
            details=details,
            risk_score=details.get("risk_score", 0.5)
        )
        
        return {
            "message": "Security event reported successfully",
            "event_type": event_type,
            "entity_id": entity_id,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error reporting security event: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/metrics")
async def get_security_metrics():
    """Get detailed security metrics"""
    try:
        agent = await get_ueba_agent()
        
        # Get UEBA agent metrics
        ueba_health = await agent.health_check()
        
        # Get security service metrics
        security_metrics = await security_service.get_security_metrics()
        
        # Combine metrics
        combined_metrics = {
            "ueba_agent": {
                "entities_monitored": ueba_health.get("entities_monitored", 0),
                "active_alerts": ueba_health.get("active_alerts", 0),
                "monitoring_stats": ueba_health.get("monitoring_stats", {})
            },
            "security_service": security_metrics,
            "system_health": {
                "redis_connection": ueba_health.get("redis_connection", False),
                "database_connection": ueba_health.get("database_connection", False)
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
        return combined_metrics
        
    except Exception as e:
        logger.error(f"❌ Error getting security metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))