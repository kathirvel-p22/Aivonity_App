"""
AIVONITY Feedback API
Root cause analysis and maintenance insights endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import uuid

from app.db.database import get_db
from app.db.models import MaintenanceEvent, FailurePattern, RCAReport, CAPAAction, FleetInsight
from app.agents.feedback_agent import FeedbackAgent
from app.agents.base_agent import AgentMessage
from app.utils.auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/feedback", tags=["feedback"])

# Pydantic models for request/response
class MaintenanceEventCreate(BaseModel):
    vehicle_id: str
    event_type: str
    component: str
    description: str
    cost: Optional[float] = None
    duration_hours: Optional[float] = None
    service_center_id: Optional[str] = None
    technician_notes: Optional[str] = None
    parts_replaced: Optional[List[str]] = None
    root_cause: Optional[str] = None
    severity: str = "medium"

class MaintenanceEventResponse(BaseModel):
    id: str
    vehicle_id: str
    event_type: str
    component: str
    description: str
    cost: Optional[float]
    duration_hours: Optional[float]
    service_center_id: Optional[str]
    technician_notes: Optional[str]
    parts_replaced: List[str]
    root_cause: Optional[str]
    severity: str
    created_at: datetime
    updated_at: datetime

class PatternAnalysisRequest(BaseModel):
    component: Optional[str] = None
    time_window_days: int = 365
    min_frequency: int = 3

class RCAGenerationRequest(BaseModel):
    pattern_id: Optional[str] = None
    component: Optional[str] = None
    failure_mode: Optional[str] = None

class FleetInsightsRequest(BaseModel):
    oem_id: Optional[str] = None
    time_period: str = "last_quarter"
    vehicle_makes: Optional[List[str]] = None
    vehicle_models: Optional[List[str]] = None

# Global feedback agent instance
feedback_agent = None

async def get_feedback_agent() -> FeedbackAgent:
    """Get or create feedback agent instance"""
    global feedback_agent
    if feedback_agent is None:
        config = {
            "min_pattern_frequency": 3,
            "confidence_threshold": 0.7,
            "analysis_window_days": 365
        }
        feedback_agent = FeedbackAgent(config)
        await feedback_agent.start()
    return feedback_agent

@router.post("/maintenance-events", response_model=Dict[str, Any])
async def create_maintenance_event(
    event_data: MaintenanceEventCreate,
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Create a new maintenance event for analysis"""
    try:
        # Create message for feedback agent
        message = AgentMessage(
            sender="api",
            recipient="feedback_agent",
            message_type="maintenance_event",
            payload={
                "vehicle_id": event_data.vehicle_id,
                "event_type": event_data.event_type,
                "component": event_data.component,
                "description": event_data.description,
                "timestamp": datetime.utcnow().isoformat(),
                "cost": event_data.cost,
                "duration_hours": event_data.duration_hours,
                "service_center_id": event_data.service_center_id,
                "technician_notes": event_data.technician_notes,
                "parts_replaced": event_data.parts_replaced or [],
                "root_cause": event_data.root_cause,
                "severity": event_data.severity
            }
        )
        
        # Send to feedback agent
        response = await agent.process_message(message)
        
        if response and response.message_type == "maintenance_event_recorded":
            return {
                "status": "success",
                "event_id": response.payload["event_id"],
                "message": "Maintenance event recorded successfully",
                "analysis_triggered": response.payload.get("analysis_triggered", False)
            }
        else:
            raise HTTPException(status_code=500, detail="Failed to record maintenance event")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating maintenance event: {str(e)}")

@router.get("/maintenance-events", response_model=List[Dict[str, Any]])
async def get_maintenance_events(
    vehicle_id: Optional[str] = Query(None),
    component: Optional[str] = Query(None),
    event_type: Optional[str] = Query(None),
    limit: int = Query(100, le=1000),
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Get maintenance events with optional filtering"""
    try:
        events = await agent.get_maintenance_events(vehicle_id, component)
        
        # Apply additional filters
        if event_type:
            events = [e for e in events if e.get("event_type") == event_type]
        
        # Apply limit
        events = events[:limit]
        
        return events
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving maintenance events: {str(e)}")

@router.post("/analyze-patterns", response_model=Dict[str, Any])
async def analyze_failure_patterns(
    request: PatternAnalysisRequest,
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Trigger failure pattern analysis"""
    try:
        # Create message for pattern analysis
        message = AgentMessage(
            sender="api",
            recipient="feedback_agent",
            message_type="analyze_patterns",
            payload={
                "component": request.component,
                "time_window_days": request.time_window_days,
                "min_frequency": request.min_frequency
            }
        )
        
        # Send to feedback agent
        response = await agent.process_message(message)
        
        if response and response.message_type == "pattern_analysis_complete":
            return {
                "status": "success",
                "patterns_found": response.payload["patterns_found"],
                "patterns": response.payload["patterns"],
                "analysis_timestamp": response.payload["analysis_timestamp"]
            }
        else:
            raise HTTPException(status_code=500, detail="Pattern analysis failed")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing patterns: {str(e)}")

@router.get("/failure-patterns", response_model=List[Dict[str, Any]])
async def get_failure_patterns(
    component: Optional[str] = Query(None),
    min_frequency: int = Query(1),
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Get identified failure patterns"""
    try:
        patterns = await agent.get_failure_patterns(component)
        
        # Filter by minimum frequency
        patterns = [p for p in patterns if p.get("frequency", 0) >= min_frequency]
        
        # Sort by frequency and confidence
        patterns.sort(key=lambda p: (p.get("frequency", 0), p.get("confidence_score", 0)), reverse=True)
        
        return patterns
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving failure patterns: {str(e)}")

@router.post("/generate-rca", response_model=Dict[str, Any])
async def generate_rca_report(
    request: RCAGenerationRequest,
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Generate Root Cause Analysis report"""
    try:
        # Create message for RCA generation
        message = AgentMessage(
            sender="api",
            recipient="feedback_agent",
            message_type="generate_rca",
            payload={
                "pattern_id": request.pattern_id,
                "component": request.component,
                "failure_mode": request.failure_mode
            }
        )
        
        # Send to feedback agent
        response = await agent.process_message(message)
        
        if response and response.message_type == "rca_report_generated":
            return {
                "status": "success",
                "report_id": response.payload["report_id"],
                "report": response.payload["report"]
            }
        else:
            raise HTTPException(status_code=500, detail="RCA report generation failed")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating RCA report: {str(e)}")

@router.get("/rca-reports", response_model=List[Dict[str, Any]])
async def get_rca_reports(
    component: Optional[str] = Query(None),
    severity_level: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Get RCA reports with optional filtering"""
    try:
        reports = await agent.get_rca_reports(component)
        
        # Apply additional filters
        if severity_level:
            reports = [r for r in reports if r.get("severity_level") == severity_level]
        
        if status:
            reports = [r for r in reports if r.get("status") == status]
        
        # Sort by generation date (most recent first)
        reports.sort(key=lambda r: r.get("generated_at", ""), reverse=True)
        
        return reports
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving RCA reports: {str(e)}")

@router.get("/rca-reports/{report_id}", response_model=Dict[str, Any])
async def get_rca_report(
    report_id: str,
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Get specific RCA report by ID"""
    try:
        reports = await agent.get_rca_reports()
        report = next((r for r in reports if r.get("report_id") == report_id), None)
        
        if not report:
            raise HTTPException(status_code=404, detail="RCA report not found")
        
        return report
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving RCA report: {str(e)}")

@router.post("/fleet-insights", response_model=Dict[str, Any])
async def generate_fleet_insights(
    request: FleetInsightsRequest,
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Generate fleet-wide insights for OEM dashboard"""
    try:
        # Create message for fleet insights
        message = AgentMessage(
            sender="api",
            recipient="feedback_agent",
            message_type="fleet_insights",
            payload={
                "oem_id": request.oem_id,
                "time_period": request.time_period,
                "vehicle_makes": request.vehicle_makes or [],
                "vehicle_models": request.vehicle_models or []
            }
        )
        
        # Send to feedback agent
        response = await agent.process_message(message)
        
        if response and response.message_type == "fleet_insights_generated":
            return {
                "status": "success",
                "insights": response.payload["insights"],
                "generated_at": response.payload["generated_at"]
            }
        else:
            raise HTTPException(status_code=500, detail="Fleet insights generation failed")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating fleet insights: {str(e)}")

@router.post("/trend-analysis", response_model=Dict[str, Any])
async def analyze_trends(
    component: Optional[str] = Query(None),
    time_window: str = Query("6_months"),
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Analyze failure trends over time"""
    try:
        # Create message for trend analysis
        message = AgentMessage(
            sender="api",
            recipient="feedback_agent",
            message_type="trend_analysis",
            payload={
                "component": component,
                "time_window": time_window
            }
        )
        
        # Send to feedback agent
        response = await agent.process_message(message)
        
        if response and response.message_type == "trend_analysis_complete":
            return {
                "status": "success",
                "trends": response.payload["trends"],
                "component": response.payload["component"],
                "time_window": response.payload["time_window"]
            }
        else:
            raise HTTPException(status_code=500, detail="Trend analysis failed")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing trends: {str(e)}")

@router.get("/statistics", response_model=Dict[str, Any])
async def get_feedback_statistics(
    current_user = Depends(get_current_user),
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Get feedback system statistics"""
    try:
        # Get agent status
        status = agent.get_status()
        
        # Get health check
        health = await agent.health_check()
        
        return {
            "status": "success",
            "agent_status": status,
            "health_check": health,
            "statistics": {
                "maintenance_events_count": health.get("maintenance_events_count", 0),
                "failure_patterns_count": health.get("failure_patterns_count", 0),
                "rca_reports_count": health.get("rca_reports_count", 0)
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving statistics: {str(e)}")

@router.get("/health", response_model=Dict[str, Any])
async def health_check(
    agent: FeedbackAgent = Depends(get_feedback_agent)
):
    """Health check endpoint for feedback system"""
    try:
        health = await agent.health_check()
        
        return {
            "status": "healthy" if health.get("healthy", False) else "unhealthy",
            "details": health
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }