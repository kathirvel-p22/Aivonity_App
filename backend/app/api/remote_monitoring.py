"""
Remote Monitoring API endpoints for AIVONITY
Handles vehicle location tracking, geofencing, remote diagnostics, and theft detection
"""

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc, func
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from pydantic import BaseModel, Field
import json
import asyncio
import math

from app.db.database import get_async_session
from app.services.notification_service import NotificationService
from app.utils.logging_config import get_logger

router = APIRouter(prefix="/api/vehicles", tags=["remote-monitoring"])
logger = get_logger(__name__)

# Pydantic models for request/response
class LocationUpdateRequest(BaseModel):
    vehicleId: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: float
    speed: Optional[float] = None
    heading: Optional[float] = None
    timestamp: datetime
    distanceMoved: Optional[float] = None

class SecurityAlertRequest(BaseModel):
    vehicleId: str
    alertType: str
    severity: str
    message: str
    location: Optional[Dict[str, float]] = None
    timestamp: datetime
    threats: List[str]

class DiagnosticResultRequest(BaseModel):
    vehicleId: str
    timestamp: datetime
    batteryVoltage: float
    engineTemperature: int
    oilPressure: int
    fuelLevel: int
    diagnosticCodes: List[str]
    overallHealth: float

class GeofenceRequest(BaseModel):
    name: str
    centerLatitude: float = Field(..., ge=-90, le=90)
    centerLongitude: float = Field(..., ge=-180, le=180)
    radius: float = Field(..., gt=0)
    type: str = Field(..., regex="^(home|work|service|restricted)$")

class GeofenceAlertRequest(BaseModel):
    vehicleId: str
    geofenceId: str
    geofenceName: str
    alertType: str = Field(..., regex="^(entered|exited)$")
    location: Dict[str, float]
    timestamp: datetime

# Response models
class LocationResponse(BaseModel):
    id: str
    vehicleId: str
    latitude: float
    longitude: float
    accuracy: float
    speed: Optional[float]
    heading: Optional[float]
    timestamp: datetime
    distanceMoved: Optional[float]

class GeofenceResponse(BaseModel):
    id: str
    vehicleId: str
    name: str
    centerLatitude: float
    centerLongitude: float
    radius: float
    type: str
    isActive: bool
    createdAt: datetime

class SecurityAlertResponse(BaseModel):
    id: str
    vehicleId: str
    alertType: str
    severity: str
    message: str
    location: Optional[Dict[str, float]]
    timestamp: datetime
    threats: List[str]
    acknowledged: bool
    acknowledgedAt: Optional[datetime]

# Initialize services
notification_service = NotificationService()

# In-memory storage for demo (replace with proper database models in production)
vehicle_locations = {}
geofences = {}
security_alerts = []
diagnostic_results = []

@router.post("/{vehicle_id}/location")
async def update_vehicle_location(
    vehicle_id: str,
    location_data: LocationUpdateRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_session)
):
    """Update vehicle location and check for geofence violations"""
    try:
        # Store location update
        location_id = f"loc_{len(vehicle_locations) + 1}"
        vehicle_locations[location_id] = {
            "id": location_id,
            "vehicleId": vehicle_id,
            "latitude": location_data.latitude,
            "longitude": location_data.longitude,
            "accuracy": location_data.accuracy,
            "speed": location_data.speed,
            "heading": location_data.heading,
            "timestamp": location_data.timestamp,
            "distanceMoved": location_data.distanceMoved
        }

        # Check geofences in background
        background_tasks.add_task(
            check_geofence_violations,
            vehicle_id,
            location_data.latitude,
            location_data.longitude,
            location_data.timestamp
        )

        # Check for theft indicators
        if location_data.distanceMoved and location_data.distanceMoved > 100:
            background_tasks.add_task(
                check_theft_indicators,
                vehicle_id,
                location_data
            )

        logger.info(f"📍 Location updated for vehicle {vehicle_id} at ({location_data.latitude}, {location_data.longitude})")
        return {
            "status": "success", 
            "message": "Location updated successfully",
            "locationId": location_id
        }

    except Exception as e:
        logger.error(f"❌ Error updating vehicle location: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/location/current")
async def get_current_location(
    vehicle_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Get current vehicle location"""
    try:
        # Find most recent location for vehicle
        current_location = None
        latest_timestamp = None
        
        for location in vehicle_locations.values():
            if location["vehicleId"] == vehicle_id:
                if latest_timestamp is None or location["timestamp"] > latest_timestamp:
                    latest_timestamp = location["timestamp"]
                    current_location = location

        if not current_location:
            raise HTTPException(status_code=404, detail="No location data found for vehicle")

        return LocationResponse(**current_location)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting current location: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/location/history")
async def get_location_history(
    vehicle_id: str,
    hours: int = 24,
    db: AsyncSession = Depends(get_async_session)
):
    """Get vehicle location history"""
    try:
        cutoff_time = datetime.now() - timedelta(hours=hours)
        
        history = [
            location for location in vehicle_locations.values()
            if location["vehicleId"] == vehicle_id and location["timestamp"] >= cutoff_time
        ]
        
        # Sort by timestamp
        history.sort(key=lambda x: x["timestamp"], reverse=True)
        
        return {
            "vehicleId": vehicle_id,
            "locations": history,
            "count": len(history),
            "timeRange": f"Last {hours} hours"
        }

    except Exception as e:
        logger.error(f"❌ Error getting location history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{vehicle_id}/geofences")
async def create_geofence(
    vehicle_id: str,
    geofence_data: GeofenceRequest,
    db: AsyncSession = Depends(get_async_session)
):
    """Create a new geofence for vehicle"""
    try:
        geofence_id = f"geo_{len(geofences) + 1}"
        geofence = {
            "id": geofence_id,
            "vehicleId": vehicle_id,
            "name": geofence_data.name,
            "centerLatitude": geofence_data.centerLatitude,
            "centerLongitude": geofence_data.centerLongitude,
            "radius": geofence_data.radius,
            "type": geofence_data.type,
            "isActive": True,
            "createdAt": datetime.now()
        }
        
        geofences[geofence_id] = geofence
        
        logger.info(f"📍 Geofence created for vehicle {vehicle_id}: {geofence_data.name}")
        return GeofenceResponse(**geofence)

    except Exception as e:
        logger.error(f"❌ Error creating geofence: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/geofences")
async def get_geofences(
    vehicle_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Get all geofences for vehicle"""
    try:
        vehicle_geofences = [
            geofence for geofence in geofences.values()
            if geofence["vehicleId"] == vehicle_id and geofence["isActive"]
        ]
        
        return {
            "vehicleId": vehicle_id,
            "geofences": vehicle_geofences,
            "count": len(vehicle_geofences)
        }

    except Exception as e:
        logger.error(f"❌ Error getting geofences: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{vehicle_id}/geofences/{geofence_id}")
async def delete_geofence(
    vehicle_id: str,
    geofence_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Delete a geofence"""
    try:
        if geofence_id not in geofences:
            raise HTTPException(status_code=404, detail="Geofence not found")
        
        geofence = geofences[geofence_id]
        if geofence["vehicleId"] != vehicle_id:
            raise HTTPException(status_code=403, detail="Geofence does not belong to this vehicle")
        
        geofence["isActive"] = False
        
        logger.info(f"🗑️ Geofence deleted for vehicle {vehicle_id}: {geofence_id}")
        return {"status": "success", "message": "Geofence deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting geofence: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{vehicle_id}/geofence-alerts")
async def create_geofence_alert(
    vehicle_id: str,
    alert_data: GeofenceAlertRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_session)
):
    """Create a geofence alert"""
    try:
        alert_id = f"geoalert_{len(security_alerts) + 1}"
        alert = {
            "id": alert_id,
            "vehicleId": vehicle_id,
            "alertType": f"geofence_{alert_data.alertType}",
            "severity": "medium",
            "message": f"Vehicle {alert_data.alertType} geofence: {alert_data.geofenceName}",
            "location": alert_data.location,
            "timestamp": alert_data.timestamp,
            "threats": [f"Geofence {alert_data.alertType}"],
            "acknowledged": False,
            "acknowledgedAt": None
        }
        
        security_alerts.append(alert)
        
        # Send notification
        background_tasks.add_task(
            send_geofence_notification,
            vehicle_id,
            alert_data.geofenceName,
            alert_data.alertType
        )
        
        logger.warning(f"🚨 Geofence alert created for vehicle {vehicle_id}: {alert_data.alertType} {alert_data.geofenceName}")
        return {"status": "success", "alertId": alert_id}

    except Exception as e:
        logger.error(f"❌ Error creating geofence alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{vehicle_id}/security-alerts")
async def create_security_alert(
    vehicle_id: str,
    alert_data: SecurityAlertRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_session)
):
    """Create a security alert"""
    try:
        alert_id = f"alert_{len(security_alerts) + 1}"
        alert = {
            "id": alert_id,
            "vehicleId": vehicle_id,
            "alertType": alert_data.alertType,
            "severity": alert_data.severity,
            "message": alert_data.message,
            "location": alert_data.location,
            "timestamp": alert_data.timestamp,
            "threats": alert_data.threats,
            "acknowledged": False,
            "acknowledgedAt": None
        }
        
        security_alerts.append(alert)
        
        # Send immediate notification for high/critical alerts
        if alert_data.severity in ["high", "critical"]:
            background_tasks.add_task(
                send_security_notification,
                vehicle_id,
                alert_data.alertType,
                alert_data.severity,
                alert_data.message
            )
        
        logger.warning(f"🚨 Security alert created for vehicle {vehicle_id}: {alert_data.alertType} ({alert_data.severity})")
        return {"status": "success", "alertId": alert_id}

    except Exception as e:
        logger.error(f"❌ Error creating security alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/security-alerts")
async def get_security_alerts(
    vehicle_id: str,
    limit: int = 50,
    acknowledged: Optional[bool] = None,
    db: AsyncSession = Depends(get_async_session)
):
    """Get security alerts for vehicle"""
    try:
        vehicle_alerts = [
            alert for alert in security_alerts
            if alert["vehicleId"] == vehicle_id
        ]
        
        # Filter by acknowledged status if specified
        if acknowledged is not None:
            vehicle_alerts = [
                alert for alert in vehicle_alerts
                if alert["acknowledged"] == acknowledged
            ]
        
        # Sort by timestamp (most recent first)
        vehicle_alerts.sort(key=lambda x: x["timestamp"], reverse=True)
        
        # Limit results
        vehicle_alerts = vehicle_alerts[:limit]
        
        return {
            "vehicleId": vehicle_id,
            "alerts": vehicle_alerts,
            "count": len(vehicle_alerts)
        }

    except Exception as e:
        logger.error(f"❌ Error getting security alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{vehicle_id}/security-alerts/{alert_id}/acknowledge")
async def acknowledge_security_alert(
    vehicle_id: str,
    alert_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Acknowledge a security alert"""
    try:
        # Find the alert
        alert = None
        for a in security_alerts:
            if a["id"] == alert_id and a["vehicleId"] == vehicle_id:
                alert = a
                break
        
        if not alert:
            raise HTTPException(status_code=404, detail="Alert not found")
        
        alert["acknowledged"] = True
        alert["acknowledgedAt"] = datetime.now()
        
        logger.info(f"✅ Security alert acknowledged for vehicle {vehicle_id}: {alert_id}")
        return {"status": "success", "message": "Alert acknowledged successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error acknowledging security alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{vehicle_id}/diagnostics")
async def update_diagnostics(
    vehicle_id: str,
    diagnostic_data: DiagnosticResultRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_session)
):
    """Update vehicle diagnostic information"""
    try:
        diagnostic_id = f"diag_{len(diagnostic_results) + 1}"
        diagnostic = {
            "id": diagnostic_id,
            "vehicleId": vehicle_id,
            "timestamp": diagnostic_data.timestamp,
            "batteryVoltage": diagnostic_data.batteryVoltage,
            "engineTemperature": diagnostic_data.engineTemperature,
            "oilPressure": diagnostic_data.oilPressure,
            "fuelLevel": diagnostic_data.fuelLevel,
            "diagnosticCodes": diagnostic_data.diagnosticCodes,
            "overallHealth": diagnostic_data.overallHealth
        }
        
        diagnostic_results.append(diagnostic)
        
        # Check for critical issues
        background_tasks.add_task(
            check_critical_diagnostics,
            vehicle_id,
            diagnostic_data
        )
        
        logger.info(f"🔧 Diagnostics updated for vehicle {vehicle_id} - Health: {diagnostic_data.overallHealth}%")
        return {
            "status": "success", 
            "message": "Diagnostics updated successfully",
            "diagnosticId": diagnostic_id
        }

    except Exception as e:
        logger.error(f"❌ Error updating diagnostics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/diagnostics/latest")
async def get_latest_diagnostics(
    vehicle_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Get latest diagnostic information for vehicle"""
    try:
        # Find most recent diagnostic for vehicle
        latest_diagnostic = None
        latest_timestamp = None
        
        for diagnostic in diagnostic_results:
            if diagnostic["vehicleId"] == vehicle_id:
                if latest_timestamp is None or diagnostic["timestamp"] > latest_timestamp:
                    latest_timestamp = diagnostic["timestamp"]
                    latest_diagnostic = diagnostic

        if not latest_diagnostic:
            raise HTTPException(status_code=404, detail="No diagnostic data found for vehicle")

        return latest_diagnostic

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting latest diagnostics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/health-status")
async def get_vehicle_health_status(
    vehicle_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Get comprehensive vehicle health status"""
    try:
        # Get latest location
        current_location = None
        for location in vehicle_locations.values():
            if location["vehicleId"] == vehicle_id:
                if current_location is None or location["timestamp"] > current_location["timestamp"]:
                    current_location = location

        # Get latest diagnostics
        latest_diagnostic = None
        for diagnostic in diagnostic_results:
            if diagnostic["vehicleId"] == vehicle_id:
                if latest_diagnostic is None or diagnostic["timestamp"] > latest_diagnostic["timestamp"]:
                    latest_diagnostic = diagnostic

        # Get recent alerts
        recent_alerts = [
            alert for alert in security_alerts
            if alert["vehicleId"] == vehicle_id and 
               alert["timestamp"] >= datetime.now() - timedelta(hours=24)
        ]

        return {
            "vehicleId": vehicle_id,
            "lastUpdate": datetime.now(),
            "location": current_location,
            "diagnostics": latest_diagnostic,
            "recentAlerts": len(recent_alerts),
            "unacknowledgedAlerts": len([a for a in recent_alerts if not a["acknowledged"]]),
            "overallStatus": "healthy" if latest_diagnostic and latest_diagnostic["overallHealth"] > 80 else "attention_needed"
        }

    except Exception as e:
        logger.error(f"❌ Error getting vehicle health status: {e}")
        raise HTTPException(status_code=500, detail=str(e))
#
 Background task functions
async def check_geofence_violations(vehicle_id: str, latitude: float, longitude: float, timestamp: datetime):
    """Check if vehicle location violates any geofences"""
    try:
        vehicle_geofences = [
            geofence for geofence in geofences.values()
            if geofence["vehicleId"] == vehicle_id and geofence["isActive"]
        ]
        
        for geofence in vehicle_geofences:
            distance = calculate_distance(
                latitude, longitude,
                geofence["centerLatitude"], geofence["centerLongitude"]
            )
            
            is_inside = distance <= geofence["radius"]
            
            # For demo purposes, we'll assume the vehicle was previously outside
            # In production, you'd track the previous state
            if is_inside and geofence["type"] == "restricted":
                # Vehicle entered restricted area
                await create_geofence_alert_internal(
                    vehicle_id, geofence["id"], geofence["name"], 
                    "entered", {"latitude": latitude, "longitude": longitude}, timestamp
                )
            elif not is_inside and geofence["type"] in ["home", "work"]:
                # Vehicle left safe area
                await create_geofence_alert_internal(
                    vehicle_id, geofence["id"], geofence["name"], 
                    "exited", {"latitude": latitude, "longitude": longitude}, timestamp
                )
                
    except Exception as e:
        logger.error(f"❌ Error checking geofence violations: {e}")

async def check_theft_indicators(vehicle_id: str, location_data: LocationUpdateRequest):
    """Check for potential theft indicators"""
    try:
        suspicious_activities = []
        
        # Check for rapid movement
        if location_data.speed and location_data.speed > 15:  # > 15 m/s (54 km/h)
            suspicious_activities.append("High speed movement detected")
        
        # Check for movement during unusual hours (2 AM - 5 AM)
        hour = location_data.timestamp.hour
        if 2 <= hour <= 5 and location_data.distanceMoved and location_data.distanceMoved > 100:
            suspicious_activities.append("Vehicle movement during unusual hours")
        
        # Check for large distance moved without ignition (simulated)
        if location_data.distanceMoved and location_data.distanceMoved > 500:
            suspicious_activities.append("Large distance movement detected (possible towing)")
        
        if suspicious_activities:
            alert_data = SecurityAlertRequest(
                vehicleId=vehicle_id,
                alertType="theft_detection",
                severity="critical",
                message="Potential theft detected based on movement patterns",
                location={"latitude": location_data.latitude, "longitude": location_data.longitude},
                timestamp=location_data.timestamp,
                threats=suspicious_activities
            )
            
            # Create alert internally
            await create_security_alert_internal(alert_data)
            
    except Exception as e:
        logger.error(f"❌ Error checking theft indicators: {e}")

async def check_critical_diagnostics(vehicle_id: str, diagnostic_data: DiagnosticResultRequest):
    """Check for critical diagnostic issues"""
    try:
        critical_issues = []
        
        if diagnostic_data.batteryVoltage < 12.0:
            critical_issues.append(f"Low battery voltage: {diagnostic_data.batteryVoltage}V")
        
        if diagnostic_data.engineTemperature > 105:
            critical_issues.append(f"Engine overheating: {diagnostic_data.engineTemperature}°C")
        
        if diagnostic_data.oilPressure < 20:
            critical_issues.append(f"Low oil pressure: {diagnostic_data.oilPressure} PSI")
        
        if diagnostic_data.fuelLevel < 10:
            critical_issues.append(f"Low fuel level: {diagnostic_data.fuelLevel}%")
        
        if diagnostic_data.diagnosticCodes:
            critical_issues.append(f"Diagnostic codes: {', '.join(diagnostic_data.diagnosticCodes)}")
        
        if diagnostic_data.overallHealth < 50:
            critical_issues.append(f"Poor overall health: {diagnostic_data.overallHealth}%")
        
        if critical_issues:
            alert_data = SecurityAlertRequest(
                vehicleId=vehicle_id,
                alertType="critical_diagnostic",
                severity="high",
                message="Critical vehicle issues detected",
                location=None,
                timestamp=diagnostic_data.timestamp,
                threats=critical_issues
            )
            
            await create_security_alert_internal(alert_data)
            
    except Exception as e:
        logger.error(f"❌ Error checking critical diagnostics: {e}")

async def send_geofence_notification(vehicle_id: str, geofence_name: str, alert_type: str):
    """Send geofence notification"""
    try:
        message = f"Vehicle {alert_type} geofence: {geofence_name}"
        await notification_service.send_push_notification(
            user_id=f"user_{vehicle_id}",  # In production, get actual user ID
            title="Geofence Alert",
            message=message,
            data={"type": "geofence", "vehicleId": vehicle_id}
        )
        logger.info(f"📱 Geofence notification sent for vehicle {vehicle_id}")
    except Exception as e:
        logger.error(f"❌ Error sending geofence notification: {e}")

async def send_security_notification(vehicle_id: str, alert_type: str, severity: str, message: str):
    """Send security notification"""
    try:
        await notification_service.send_push_notification(
            user_id=f"user_{vehicle_id}",  # In production, get actual user ID
            title=f"Security Alert - {severity.upper()}",
            message=message,
            data={"type": "security", "vehicleId": vehicle_id, "severity": severity}
        )
        logger.info(f"📱 Security notification sent for vehicle {vehicle_id}")
    except Exception as e:
        logger.error(f"❌ Error sending security notification: {e}")

# Helper functions
def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points using Haversine formula"""
    R = 6371000  # Earth's radius in meters
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = (math.sin(delta_lat / 2) ** 2 + 
         math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c

async def create_geofence_alert_internal(vehicle_id: str, geofence_id: str, geofence_name: str, 
                                       alert_type: str, location: Dict[str, float], timestamp: datetime):
    """Create geofence alert internally"""
    alert_data = GeofenceAlertRequest(
        vehicleId=vehicle_id,
        geofenceId=geofence_id,
        geofenceName=geofence_name,
        alertType=alert_type,
        location=location,
        timestamp=timestamp
    )
    
    # This would normally call the endpoint, but we'll create the alert directly
    alert_id = f"geoalert_{len(security_alerts) + 1}"
    alert = {
        "id": alert_id,
        "vehicleId": vehicle_id,
        "alertType": f"geofence_{alert_type}",
        "severity": "medium",
        "message": f"Vehicle {alert_type} geofence: {geofence_name}",
        "location": location,
        "timestamp": timestamp,
        "threats": [f"Geofence {alert_type}"],
        "acknowledged": False,
        "acknowledgedAt": None
    }
    
    security_alerts.append(alert)
    await send_geofence_notification(vehicle_id, geofence_name, alert_type)

async def create_security_alert_internal(alert_data: SecurityAlertRequest):
    """Create security alert internally"""
    alert_id = f"alert_{len(security_alerts) + 1}"
    alert = {
        "id": alert_id,
        "vehicleId": alert_data.vehicleId,
        "alertType": alert_data.alertType,
        "severity": alert_data.severity,
        "message": alert_data.message,
        "location": alert_data.location,
        "timestamp": alert_data.timestamp,
        "threats": alert_data.threats,
        "acknowledged": False,
        "acknowledgedAt": None
    }
    
    security_alerts.append(alert)
    
    if alert_data.severity in ["high", "critical"]:
        await send_security_notification(
            alert_data.vehicleId, alert_data.alertType, 
            alert_data.severity, alert_data.message
        )