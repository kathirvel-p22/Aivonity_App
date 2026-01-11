"""
AIVONITY Vehicle Management API
Advanced vehicle registration and management endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, validator
import uuid

from app.db.database import get_db
from app.db.models import User, Vehicle, TelemetryData, MaintenancePrediction
from app.api.auth import get_current_user
from app.utils.logging_config import get_logger, audit_logger
from app.config import settings

logger = get_logger(__name__)
router = APIRouter()

# Pydantic models
class VehicleRegistration(BaseModel):
    make: str
    model: str
    year: int
    vin: str
    license_plate: Optional[str] = None
    color: Optional[str] = None
    engine_type: Optional[str] = None
    transmission: Optional[str] = None
    fuel_capacity: Optional[float] = None
    engine_displacement: Optional[float] = None
    mileage: int = 0
    registration_date: Optional[datetime] = None
    
    @validator('year')
    def validate_year(cls, v):
        current_year = datetime.now().year
        if v < 1900 or v > current_year + 1:
            raise ValueError(f'Year must be between 1900 and {current_year + 1}')
        return v
    
    @validator('vin')
    def validate_vin(cls, v):
        if len(v) != 17:
            raise ValueError('VIN must be exactly 17 characters')
        return v.upper()
    
    @validator('mileage')
    def validate_mileage(cls, v):
        if v < 0:
            raise ValueError('Mileage cannot be negative')
        return v

class VehicleUpdate(BaseModel):
    license_plate: Optional[str] = None
    color: Optional[str] = None
    mileage: Optional[int] = None
    last_service_date: Optional[datetime] = None
    insurance_info: Optional[Dict[str, Any]] = None
    warranty_info: Optional[Dict[str, Any]] = None
    
    @validator('mileage')
    def validate_mileage(cls, v):
        if v is not None and v < 0:
            raise ValueError('Mileage cannot be negative')
        return v

class VehicleResponse(BaseModel):
    id: str
    make: str
    model: str
    year: int
    vin: str
    license_plate: Optional[str]
    color: Optional[str]
    engine_type: Optional[str]
    transmission: Optional[str]
    mileage: int
    health_score: float
    last_service_date: Optional[datetime]
    next_service_due: Optional[datetime]
    registration_date: Optional[datetime]
    created_at: datetime
    updated_at: datetime

class VehicleHealthSummary(BaseModel):
    vehicle_id: str
    overall_score: float
    component_scores: Dict[str, float]
    active_alerts: int
    last_updated: datetime
    recommendations: List[str]

class VehicleStatistics(BaseModel):
    vehicle_id: str
    total_trips: int
    total_distance: float
    average_fuel_efficiency: float
    total_drive_time: int  # minutes
    monthly_mileage: Dict[str, int]
    alert_history: Dict[str, int]
    maintenance_due: List[Dict[str, Any]]

@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
async def register_vehicle(
    vehicle_data: VehicleRegistration,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Register a new vehicle"""
    try:
        # Check if VIN already exists
        result = await db.execute(select(Vehicle).where(Vehicle.vin == vehicle_data.vin))
        existing_vehicle = result.scalar_one_or_none()
        
        if existing_vehicle:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Vehicle with this VIN is already registered"
            )
        
        # Create new vehicle
        new_vehicle = Vehicle(
            user_id=current_user.id,
            make=vehicle_data.make,
            model=vehicle_data.model,
            year=vehicle_data.year,
            vin=vehicle_data.vin,
            license_plate=vehicle_data.license_plate,
            color=vehicle_data.color,
            engine_type=vehicle_data.engine_type,
            transmission=vehicle_data.transmission,
            fuel_capacity=vehicle_data.fuel_capacity,
            engine_displacement=vehicle_data.engine_displacement,
            mileage=vehicle_data.mileage,
            registration_date=vehicle_data.registration_date or datetime.utcnow(),
            health_score=1.0,  # Start with perfect health
            performance_metrics={
                "fuel_efficiency": 0.0,
                "average_speed": 0.0,
                "total_trips": 0,
                "total_distance": 0.0
            }
        )
        
        db.add(new_vehicle)
        await db.commit()
        await db.refresh(new_vehicle)
        
        # Log vehicle registration
        audit_logger.log_data_modification(
            user_id=str(current_user.id),
            resource_type="vehicle",
            resource_id=str(new_vehicle.id),
            changes={"action": "registered", "vin": vehicle_data.vin}
        )
        
        logger.info(f"🚗 Vehicle registered: {vehicle_data.make} {vehicle_data.model} for user {current_user.email}")
        
        return VehicleResponse(
            id=str(new_vehicle.id),
            make=new_vehicle.make,
            model=new_vehicle.model,
            year=new_vehicle.year,
            vin=new_vehicle.vin,
            license_plate=new_vehicle.license_plate,
            color=new_vehicle.color,
            engine_type=new_vehicle.engine_type,
            transmission=new_vehicle.transmission,
            mileage=new_vehicle.mileage,
            health_score=new_vehicle.health_score,
            last_service_date=new_vehicle.last_service_date,
            next_service_due=new_vehicle.next_service_due,
            registration_date=new_vehicle.registration_date,
            created_at=new_vehicle.created_at,
            updated_at=new_vehicle.updated_at
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error registering vehicle: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to register vehicle"
        )

@router.get("/", response_model=List[VehicleResponse])
async def get_user_vehicles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all vehicles for the current user"""
    try:
        result = await db.execute(
            select(Vehicle).where(Vehicle.user_id == current_user.id)
            .order_by(Vehicle.created_at.desc())
        )
        vehicles = result.scalars().all()
        
        # Log data access
        audit_logger.log_data_access(
            user_id=str(current_user.id),
            resource_type="vehicles",
            resource_id="list",
            action="read"
        )
        
        return [
            VehicleResponse(
                id=str(vehicle.id),
                make=vehicle.make,
                model=vehicle.model,
                year=vehicle.year,
                vin=vehicle.vin,
                license_plate=vehicle.license_plate,
                color=vehicle.color,
                engine_type=vehicle.engine_type,
                transmission=vehicle.transmission,
                mileage=vehicle.mileage,
                health_score=vehicle.health_score,
                last_service_date=vehicle.last_service_date,
                next_service_due=vehicle.next_service_due,
                registration_date=vehicle.registration_date,
                created_at=vehicle.created_at,
                updated_at=vehicle.updated_at
            )
            for vehicle in vehicles
        ]
        
    except Exception as e:
        logger.error(f"Error retrieving vehicles: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve vehicles"
        )

@router.get("/{vehicle_id}", response_model=VehicleResponse)
async def get_vehicle_details(
    vehicle_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information for a specific vehicle"""
    try:
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )
        
        # Log data access
        audit_logger.log_data_access(
            user_id=str(current_user.id),
            resource_type="vehicle",
            resource_id=vehicle_id,
            action="read"
        )
        
        return VehicleResponse(
            id=str(vehicle.id),
            make=vehicle.make,
            model=vehicle.model,
            year=vehicle.year,
            vin=vehicle.vin,
            license_plate=vehicle.license_plate,
            color=vehicle.color,
            engine_type=vehicle.engine_type,
            transmission=vehicle.transmission,
            mileage=vehicle.mileage,
            health_score=vehicle.health_score,
            last_service_date=vehicle.last_service_date,
            next_service_due=vehicle.next_service_due,
            registration_date=vehicle.registration_date,
            created_at=vehicle.created_at,
            updated_at=vehicle.updated_at
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving vehicle details: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve vehicle details"
        )

@router.put("/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(
    vehicle_id: str,
    vehicle_updates: VehicleUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update vehicle information"""
    try:
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )
        
        # Track changes for audit log
        changes = {}
        
        # Update fields
        update_data = vehicle_updates.dict(exclude_unset=True)
        for field, value in update_data.items():
            if hasattr(vehicle, field) and getattr(vehicle, field) != value:
                changes[field] = {"old": getattr(vehicle, field), "new": value}
                setattr(vehicle, field, value)
        
        vehicle.updated_at = datetime.utcnow()
        
        await db.commit()
        await db.refresh(vehicle)
        
        # Log changes
        if changes:
            audit_logger.log_data_modification(
                user_id=str(current_user.id),
                resource_type="vehicle",
                resource_id=vehicle_id,
                changes=changes
            )
        
        logger.info(f"🚗 Vehicle updated: {vehicle_id}")
        
        return VehicleResponse(
            id=str(vehicle.id),
            make=vehicle.make,
            model=vehicle.model,
            year=vehicle.year,
            vin=vehicle.vin,
            license_plate=vehicle.license_plate,
            color=vehicle.color,
            engine_type=vehicle.engine_type,
            transmission=vehicle.transmission,
            mileage=vehicle.mileage,
            health_score=vehicle.health_score,
            last_service_date=vehicle.last_service_date,
            next_service_due=vehicle.next_service_due,
            registration_date=vehicle.registration_date,
            created_at=vehicle.created_at,
            updated_at=vehicle.updated_at
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating vehicle: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update vehicle"
        )

@router.delete("/{vehicle_id}")
async def delete_vehicle(
    vehicle_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a vehicle (soft delete)"""
    try:
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )
        
        # Soft delete by marking as inactive (you could add an is_active field)
        # For now, we'll actually delete the record
        await db.delete(vehicle)
        await db.commit()
        
        # Log deletion
        audit_logger.log_data_modification(
            user_id=str(current_user.id),
            resource_type="vehicle",
            resource_id=vehicle_id,
            changes={"action": "deleted", "vin": vehicle.vin}
        )
        
        logger.info(f"🗑️ Vehicle deleted: {vehicle_id}")
        
        return {"message": "Vehicle deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting vehicle: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete vehicle"
        )

@router.get("/{vehicle_id}/health", response_model=VehicleHealthSummary)
async def get_vehicle_health(
    vehicle_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get comprehensive vehicle health summary"""
    try:
        # Verify vehicle ownership
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )
        
        # Get recent telemetry for health calculation
        recent_telemetry = await db.execute(
            select(TelemetryData).where(
                and_(
                    TelemetryData.vehicle_id == vehicle_id,
                    TelemetryData.timestamp >= datetime.utcnow() - timedelta(days=7)
                )
            ).order_by(TelemetryData.timestamp.desc()).limit(100)
        )
        telemetry_records = recent_telemetry.scalars().all()
        
        # Calculate component health scores
        component_scores = await calculate_component_health(telemetry_records)
        
        # Get active alerts count
        active_alerts = await db.execute(
            select(func.count(TelemetryData.id)).where(
                and_(
                    TelemetryData.vehicle_id == vehicle_id,
                    TelemetryData.anomaly_score > settings.ANOMALY_THRESHOLD,
                    TelemetryData.timestamp >= datetime.utcnow() - timedelta(days=1)
                )
            )
        )
        alert_count = active_alerts.scalar() or 0
        
        # Generate recommendations
        recommendations = generate_health_recommendations(vehicle, component_scores, alert_count)
        
        return VehicleHealthSummary(
            vehicle_id=vehicle_id,
            overall_score=vehicle.health_score,
            component_scores=component_scores,
            active_alerts=alert_count,
            last_updated=datetime.utcnow(),
            recommendations=recommendations
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving vehicle health: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve vehicle health"
        )

@router.get("/{vehicle_id}/statistics", response_model=VehicleStatistics)
async def get_vehicle_statistics(
    vehicle_id: str,
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get vehicle usage statistics"""
    try:
        # Verify vehicle ownership
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )
        
        # Calculate statistics (simplified for now)
        statistics = await calculate_vehicle_statistics(vehicle_id, days, db)
        
        return VehicleStatistics(
            vehicle_id=vehicle_id,
            total_trips=statistics.get("total_trips", 0),
            total_distance=statistics.get("total_distance", 0.0),
            average_fuel_efficiency=statistics.get("fuel_efficiency", 0.0),
            total_drive_time=statistics.get("drive_time", 0),
            monthly_mileage=statistics.get("monthly_mileage", {}),
            alert_history=statistics.get("alert_history", {}),
            maintenance_due=statistics.get("maintenance_due", [])
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving vehicle statistics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve vehicle statistics"
        )

# Utility functions
async def calculate_component_health(telemetry_records: List[TelemetryData]) -> Dict[str, float]:
    """Calculate health scores for different vehicle components"""
    try:
        if not telemetry_records:
            return {
                "engine": 1.0,
                "transmission": 1.0,
                "battery": 1.0,
                "cooling_system": 1.0,
                "fuel_system": 1.0
            }
        
        # Simplified health calculation based on sensor data
        component_scores = {
            "engine": 0.9,
            "transmission": 0.95,
            "battery": 0.88,
            "cooling_system": 0.92,
            "fuel_system": 0.85
        }
        
        # In a real implementation, this would analyze actual sensor data
        # to calculate component-specific health scores
        
        return component_scores
        
    except Exception as e:
        logger.error(f"Error calculating component health: {e}")
        return {}

def generate_health_recommendations(vehicle: Vehicle, component_scores: Dict[str, float], 
                                  alert_count: int) -> List[str]:
    """Generate health-based recommendations"""
    recommendations = []
    
    try:
        # Check overall health
        if vehicle.health_score < 0.7:
            recommendations.append("Schedule comprehensive diagnostic check")
        
        # Check component scores
        for component, score in component_scores.items():
            if score < 0.8:
                recommendations.append(f"Inspect {component.replace('_', ' ')} system")
        
        # Check alerts
        if alert_count > 5:
            recommendations.append("Multiple alerts detected - immediate attention required")
        elif alert_count > 0:
            recommendations.append("Review recent alerts and take corrective action")
        
        # Check service due date
        if vehicle.next_service_due and vehicle.next_service_due <= datetime.utcnow():
            recommendations.append("Scheduled maintenance is overdue")
        elif (vehicle.next_service_due and 
              vehicle.next_service_due <= datetime.utcnow() + timedelta(days=7)):
            recommendations.append("Scheduled maintenance due soon")
        
        # Default recommendation
        if not recommendations:
            recommendations.append("Vehicle is in good condition - continue regular maintenance")
        
        return recommendations[:5]  # Limit to 5 recommendations
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        return ["Consult with a qualified mechanic for vehicle assessment"]

async def calculate_vehicle_statistics(vehicle_id: str, days: int, 
                                     db: AsyncSession) -> Dict[str, Any]:
    """Calculate comprehensive vehicle statistics"""
    try:
        # This is a simplified implementation
        # In a real system, you would calculate actual statistics from telemetry data
        
        statistics = {
            "total_trips": 45,
            "total_distance": 1250.5,
            "fuel_efficiency": 8.5,  # L/100km
            "drive_time": 2400,  # minutes
            "monthly_mileage": {
                "January": 420,
                "February": 380,
                "March": 450
            },
            "alert_history": {
                "critical": 0,
                "high": 2,
                "medium": 5,
                "low": 8
            },
            "maintenance_due": [
                {
                    "type": "Oil Change",
                    "due_date": "2024-02-15",
                    "urgency": "medium"
                }
            ]
        }
        
        return statistics
        
    except Exception as e:
        logger.error(f"Error calculating vehicle statistics: {e}")
        return {}