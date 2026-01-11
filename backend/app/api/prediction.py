"""
AIVONITY Prediction API
ML-based predictive maintenance endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
import uuid

from app.db.database import get_db
from app.db.models import User, Vehicle, MaintenancePrediction, TelemetryData
from app.api.auth import get_current_user
from app.utils.logging_config import get_logger
from app.config import settings

logger = get_logger(__name__)
router = APIRouter()

# Pydantic models
class PredictionResponse(BaseModel):
    id: str
    vehicle_id: str
    component: str
    failure_probability: float
    confidence_score: float
    recommended_action: str
    timeframe_days: int
    urgency_level: str
    estimated_cost: Optional[float]
    created_at: datetime
    status: str

class PredictionRequest(BaseModel):
    vehicle_id: str
    components: Optional[List[str]] = None  # Specific components to analyze

class PredictionSummary(BaseModel):
    vehicle_id: str
    total_predictions: int
    high_risk_count: int
    medium_risk_count: int
    low_risk_count: int
    next_maintenance_due: Optional[datetime]
    estimated_total_cost: float
    last_updated: datetime

@router.get("/vehicle/{vehicle_id}", response_model=List[PredictionResponse])
async def get_vehicle_predictions(
    vehicle_id: str,
    status_filter: Optional[str] = Query(None, regex="^(pending|acknowledged|scheduled|completed)$"),
    urgency_filter: Optional[str] = Query(None, regex="^(low|medium|high|critical)$"),
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get predictive maintenance recommendations for a vehicle"""
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
                detail="Vehicle not found or access denied"
            )
        
        # Build query
        query = select(MaintenancePrediction).where(
            MaintenancePrediction.vehicle_id == vehicle_id
        )
        
        # Apply filters
        if status_filter:
            query = query.where(MaintenancePrediction.status == status_filter)
        
        if urgency_filter:
            query = query.where(MaintenancePrediction.urgency_level == urgency_filter)
        
        # Order by urgency and creation date
        query = query.order_by(
            MaintenancePrediction.urgency_level.desc(),
            MaintenancePrediction.created_at.desc()
        ).limit(limit)
        
        result = await db.execute(query)
        predictions = result.scalars().all()
        
        # Convert to response format
        response_data = [
            PredictionResponse(
                id=str(prediction.id),
                vehicle_id=str(prediction.vehicle_id),
                component=prediction.component,
                failure_probability=prediction.failure_probability,
                confidence_score=prediction.confidence_score,
                recommended_action=prediction.recommended_action,
                timeframe_days=prediction.timeframe_days,
                urgency_level=prediction.urgency_level,
                estimated_cost=prediction.estimated_cost,
                created_at=prediction.created_at,
                status=prediction.status
            )
            for prediction in predictions
        ]
        
        logger.info(f"📊 Retrieved {len(response_data)} predictions for vehicle {vehicle_id}")
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving predictions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve predictions"
        )

@router.post("/request", status_code=status.HTTP_202_ACCEPTED)
async def request_prediction_analysis(
    prediction_request: PredictionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Request new prediction analysis for a vehicle"""
    try:
        # Verify vehicle ownership
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == prediction_request.vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found or access denied"
            )
        
        # Check if recent analysis exists (within last 24 hours)
        recent_analysis = await db.execute(
            select(MaintenancePrediction).where(
                and_(
                    MaintenancePrediction.vehicle_id == prediction_request.vehicle_id,
                    MaintenancePrediction.created_at >= datetime.utcnow() - timedelta(hours=24)
                )
            )
        )
        
        if recent_analysis.scalar_one_or_none():
            return {
                "message": "Recent analysis available",
                "status": "existing_analysis",
                "note": "Analysis was performed within the last 24 hours"
            }
        
        # For now, create mock predictions since Diagnosis Agent is not implemented
        mock_predictions = await create_mock_predictions(prediction_request.vehicle_id, db)
        
        logger.info(f"📊 Prediction analysis requested for vehicle {prediction_request.vehicle_id}")
        
        return {
            "message": "Prediction analysis initiated",
            "vehicle_id": prediction_request.vehicle_id,
            "status": "processing",
            "estimated_completion": datetime.utcnow() + timedelta(minutes=5),
            "predictions_generated": len(mock_predictions)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error requesting prediction analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to request prediction analysis"
        )

@router.get("/vehicle/{vehicle_id}/summary", response_model=PredictionSummary)
async def get_prediction_summary(
    vehicle_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get prediction summary for a vehicle"""
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
                detail="Vehicle not found or access denied"
            )
        
        # Get all predictions for the vehicle
        predictions_result = await db.execute(
            select(MaintenancePrediction).where(
                MaintenancePrediction.vehicle_id == vehicle_id
            )
        )
        predictions = predictions_result.scalars().all()
        
        # Calculate summary statistics
        total_predictions = len(predictions)
        high_risk_count = len([p for p in predictions if p.urgency_level in ['high', 'critical']])
        medium_risk_count = len([p for p in predictions if p.urgency_level == 'medium'])
        low_risk_count = len([p for p in predictions if p.urgency_level == 'low'])
        
        # Calculate estimated total cost
        estimated_total_cost = sum(p.estimated_cost or 0 for p in predictions if p.status == 'pending')
        
        # Find next maintenance due
        next_maintenance = None
        if predictions:
            urgent_predictions = [p for p in predictions if p.urgency_level in ['high', 'critical']]
            if urgent_predictions:
                earliest = min(urgent_predictions, key=lambda x: x.timeframe_days)
                next_maintenance = datetime.utcnow() + timedelta(days=earliest.timeframe_days)
        
        return PredictionSummary(
            vehicle_id=vehicle_id,
            total_predictions=total_predictions,
            high_risk_count=high_risk_count,
            medium_risk_count=medium_risk_count,
            low_risk_count=low_risk_count,
            next_maintenance_due=next_maintenance,
            estimated_total_cost=estimated_total_cost,
            last_updated=datetime.utcnow()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving prediction summary: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve prediction summary"
        )

@router.put("/{prediction_id}/acknowledge")
async def acknowledge_prediction(
    prediction_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Acknowledge a maintenance prediction"""
    try:
        # Get prediction and verify ownership
        result = await db.execute(
            select(MaintenancePrediction).join(Vehicle).where(
                and_(
                    MaintenancePrediction.id == prediction_id,
                    Vehicle.user_id == current_user.id
                )
            )
        )
        prediction = result.scalar_one_or_none()
        
        if not prediction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Prediction not found or access denied"
            )
        
        # Update prediction status
        prediction.status = "acknowledged"
        prediction.acknowledged_at = datetime.utcnow()
        
        await db.commit()
        
        logger.info(f"✅ Prediction acknowledged: {prediction_id}")
        
        return {
            "message": "Prediction acknowledged successfully",
            "prediction_id": prediction_id,
            "acknowledged_at": prediction.acknowledged_at.isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error acknowledging prediction: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to acknowledge prediction"
        )

@router.delete("/{prediction_id}")
async def dismiss_prediction(
    prediction_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Dismiss a maintenance prediction"""
    try:
        # Get prediction and verify ownership
        result = await db.execute(
            select(MaintenancePrediction).join(Vehicle).where(
                and_(
                    MaintenancePrediction.id == prediction_id,
                    Vehicle.user_id == current_user.id
                )
            )
        )
        prediction = result.scalar_one_or_none()
        
        if not prediction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Prediction not found or access denied"
            )
        
        # Delete prediction
        await db.delete(prediction)
        await db.commit()
        
        logger.info(f"🗑️ Prediction dismissed: {prediction_id}")
        
        return {"message": "Prediction dismissed successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error dismissing prediction: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to dismiss prediction"
        )

# Utility functions
async def create_mock_predictions(vehicle_id: str, db: AsyncSession) -> List[MaintenancePrediction]:
    """Create mock predictions for demonstration (until Diagnosis Agent is implemented)"""
    try:
        mock_predictions_data = [
            {
                "component": "brake_pads",
                "failure_probability": 0.75,
                "confidence_score": 0.85,
                "recommended_action": "Replace brake pads within 2 weeks",
                "timeframe_days": 14,
                "urgency_level": "high",
                "estimated_cost": 250.0
            },
            {
                "component": "oil_filter",
                "failure_probability": 0.45,
                "confidence_score": 0.70,
                "recommended_action": "Schedule oil change service",
                "timeframe_days": 30,
                "urgency_level": "medium",
                "estimated_cost": 80.0
            },
            {
                "component": "air_filter",
                "failure_probability": 0.30,
                "confidence_score": 0.60,
                "recommended_action": "Inspect and replace if necessary",
                "timeframe_days": 60,
                "urgency_level": "low",
                "estimated_cost": 45.0
            }
        ]
        
        predictions = []
        for data in mock_predictions_data:
            prediction = MaintenancePrediction(
                vehicle_id=vehicle_id,
                component=data["component"],
                failure_probability=data["failure_probability"],
                confidence_score=data["confidence_score"],
                recommended_action=data["recommended_action"],
                timeframe_days=data["timeframe_days"],
                urgency_level=data["urgency_level"],
                estimated_cost=data["estimated_cost"],
                model_version="mock_v1.0",
                status="pending"
            )
            
            db.add(prediction)
            predictions.append(prediction)
        
        await db.commit()
        
        logger.info(f"📊 Created {len(predictions)} mock predictions for vehicle {vehicle_id}")
        return predictions
        
    except Exception as e:
        logger.error(f"Error creating mock predictions: {e}")
        return []