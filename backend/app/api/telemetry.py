"""
AIVONITY Telemetry API
Advanced telemetry data ingestion and retrieval
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, and_, func
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, validator
import uuid

from app.db.database import get_db
from app.db.models import User, Vehicle, TelemetryData
from app.api.auth import get_current_user
from app.agents.agent_manager import AgentManager
from app.utils.logging_config import get_logger, performance_logger
from app.utils.websocket_manager import WebSocketManager, WebSocketMessage
from app.config import settings

logger = get_logger(__name__)
router = APIRouter()

# Pydantic models
class TelemetryIngestion(BaseModel):
    vehicle_id: str
    sensor_data: Dict[str, Any]
    timestamp: Optional[datetime] = None
    location: Optional[Dict[str, float]] = None
    
    @validator('sensor_data')
    def validate_sensor_data(cls, v):
        if not v:
            raise ValueError('Sensor data cannot be empty')
        
        # Validate required sensors
        required_sensors = ['engine_temp', 'oil_pressure', 'battery_voltage', 'rpm']
        missing_sensors = [sensor for sensor in required_sensors if sensor not in v]
        
        if missing_sensors:
            logger.warning(f"Missing sensors: {missing_sensors}")
        
        return v
    
    @validator('timestamp', pre=True, always=True)
    def set_timestamp(cls, v):
        return v or datetime.utcnow()

class TelemetryResponse(BaseModel):
    id: str
    vehicle_id: str
    timestamp: datetime
    sensor_data: Dict[str, Any]
    anomaly_score: Optional[float]
    quality_score: Optional[float]
    processed: bool

class TelemetryBatch(BaseModel):
    vehicle_id: str
    telemetry_data: List[Dict[str, Any]]
    
    @validator('telemetry_data')
    def validate_batch_size(cls, v):
        if len(v) > settings.MAX_TELEMETRY_BATCH_SIZE:
            raise ValueError(f'Batch size cannot exceed {settings.MAX_TELEMETRY_BATCH_SIZE}')
        return v

class AnomalyAlert(BaseModel):
    id: str
    vehicle_id: str
    timestamp: datetime
    anomaly_score: float
    affected_sensors: List[str]
    severity: str
    description: str
    recommendations: List[str]

class TelemetryStats(BaseModel):
    vehicle_id: str
    total_records: int
    date_range: Dict[str, datetime]
    anomaly_count: int
    average_quality_score: float
    sensor_health: Dict[str, float]

# Dependency to get agent manager
async def get_agent_manager() -> AgentManager:
    """Get agent manager instance"""
    # In a real application, this would be injected or retrieved from app state
    # For now, we'll create a simple instance
    return AgentManager()

# Dependency to get websocket manager
async def get_websocket_manager() -> WebSocketManager:
    """Get websocket manager instance"""
    # In a real application, this would be injected from app state
    # For now, we'll create a simple instance
    return WebSocketManager()

@router.post("/ingest", status_code=status.HTTP_201_CREATED)
async def ingest_telemetry(
    telemetry: TelemetryIngestion,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    agent_manager: AgentManager = Depends(get_agent_manager),
    websocket_manager: WebSocketManager = Depends(get_websocket_manager)
):
    """Ingest single telemetry data point"""
    try:
        start_time = datetime.utcnow()
        
        # Verify vehicle ownership
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == telemetry.vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found or access denied"
            )
        
        # Create telemetry record
        telemetry_record = TelemetryData(
            vehicle_id=telemetry.vehicle_id,
            timestamp=telemetry.timestamp,
            sensor_data=telemetry.sensor_data,
            location=telemetry.location,
            source="api",
            validation_status="pending"
        )
        
        db.add(telemetry_record)
        await db.commit()
        await db.refresh(telemetry_record)
        
        # Send to Data Agent for processing
        background_tasks.add_task(
            process_telemetry_async,
            agent_manager,
            {
                "vehicle_id": telemetry.vehicle_id,
                "sensor_data": telemetry.sensor_data,
                "timestamp": telemetry.timestamp.isoformat(),
                "telemetry_id": str(telemetry_record.id)
            }
        )
        
        # Broadcast real-time telemetry update via WebSocket
        background_tasks.add_task(
            broadcast_telemetry_update,
            websocket_manager,
            {
                "vehicle_id": telemetry.vehicle_id,
                "timestamp": telemetry.timestamp.isoformat(),
                "sensor_data": telemetry.sensor_data,
                "location": telemetry.location,
                "speed": telemetry.sensor_data.get("speed", 0),
                "engine_metrics": {
                    "temperature": telemetry.sensor_data.get("engine_temp", 0),
                    "rpm": telemetry.sensor_data.get("rpm", 0),
                    "oil_pressure": telemetry.sensor_data.get("oil_pressure", 0)
                },
                "battery_metrics": {
                    "voltage": telemetry.sensor_data.get("battery_voltage", 0),
                    "level": telemetry.sensor_data.get("battery_level", 0)
                },
                "fuel_metrics": {
                    "level": telemetry.sensor_data.get("fuel_level", 0),
                    "consumption": telemetry.sensor_data.get("fuel_consumption", 0)
                },
                "diagnostic_codes": telemetry.sensor_data.get("diagnostic_codes", []),
                "environmental_data": {
                    "ambient_temp": telemetry.sensor_data.get("ambient_temp", 0),
                    "humidity": telemetry.sensor_data.get("humidity", 0)
                }
            }
        )
        
        # Check for alerts and broadcast them
        background_tasks.add_task(
            check_and_broadcast_alerts,
            websocket_manager,
            current_user.id,
            telemetry.vehicle_id,
            telemetry.sensor_data
        )
        
        # Log performance
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        performance_logger.log_api_performance(
            endpoint="/telemetry/ingest",
            method="POST",
            duration=processing_time,
            status_code=201,
            user_id=str(current_user.id)
        )
        
        logger.info(f"📊 Telemetry ingested for vehicle {telemetry.vehicle_id}")
        
        return {
            "message": "Telemetry data ingested successfully",
            "telemetry_id": str(telemetry_record.id),
            "processing_status": "queued"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error ingesting telemetry: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to ingest telemetry data"
        )

@router.post("/batch-ingest", status_code=status.HTTP_201_CREATED)
async def batch_ingest_telemetry(
    batch: TelemetryBatch,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    agent_manager: AgentManager = Depends(get_agent_manager)
):
    """Ingest batch of telemetry data"""
    try:
        start_time = datetime.utcnow()
        
        # Verify vehicle ownership
        result = await db.execute(
            select(Vehicle).where(
                and_(Vehicle.id == batch.vehicle_id, Vehicle.user_id == current_user.id)
            )
        )
        vehicle = result.scalar_one_or_none()
        
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found or access denied"
            )
        
        # Create telemetry records
        telemetry_records = []
        for data_point in batch.telemetry_data:
            telemetry_record = TelemetryData(
                vehicle_id=batch.vehicle_id,
                timestamp=data_point.get("timestamp", datetime.utcnow()),
                sensor_data=data_point.get("sensor_data", {}),
                location=data_point.get("location"),
                source="api_batch",
                validation_status="pending"
            )
            telemetry_records.append(telemetry_record)
        
        db.add_all(telemetry_records)
        await db.commit()
        
        # Send batch to Data Agent for processing
        background_tasks.add_task(
            process_batch_telemetry_async,
            agent_manager,
            {
                "vehicle_id": batch.vehicle_id,
                "batch_data": batch.telemetry_data,
                "batch_size": len(batch.telemetry_data)
            }
        )
        
        # Log performance
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        performance_logger.log_api_performance(
            endpoint="/telemetry/batch-ingest",
            method="POST",
            duration=processing_time,
            status_code=201,
            user_id=str(current_user.id)
        )
        
        logger.info(f"📊 Batch telemetry ingested: {len(batch.telemetry_data)} records for vehicle {batch.vehicle_id}")
        
        return {
            "message": "Batch telemetry data ingested successfully",
            "records_processed": len(batch.telemetry_data),
            "processing_status": "queued"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error batch ingesting telemetry: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to ingest batch telemetry data"
        )

@router.get("/vehicle/{vehicle_id}", response_model=List[TelemetryResponse])
async def get_vehicle_telemetry(
    vehicle_id: str,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get telemetry data for a specific vehicle"""
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
        query = select(TelemetryData).where(TelemetryData.vehicle_id == vehicle_id)
        
        # Add date filters
        if start_date:
            query = query.where(TelemetryData.timestamp >= start_date)
        if end_date:
            query = query.where(TelemetryData.timestamp <= end_date)
        
        # Add ordering and pagination
        query = query.order_by(desc(TelemetryData.timestamp)).offset(offset).limit(limit)
        
        # Execute query
        result = await db.execute(query)
        telemetry_records = result.scalars().all()
        
        # Convert to response model
        response_data = [
            TelemetryResponse(
                id=str(record.id),
                vehicle_id=str(record.vehicle_id),
                timestamp=record.timestamp,
                sensor_data=record.sensor_data,
                anomaly_score=record.anomaly_score,
                quality_score=record.quality_score,
                processed=record.processed
            )
            for record in telemetry_records
        ]
        
        logger.info(f"📊 Retrieved {len(response_data)} telemetry records for vehicle {vehicle_id}")
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving telemetry: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve telemetry data"
        )

@router.get("/vehicle/{vehicle_id}/alerts", response_model=List[AnomalyAlert])
async def get_vehicle_alerts(
    vehicle_id: str,
    limit: int = Query(50, ge=1, le=200),
    severity: Optional[str] = Query(None, regex="^(low|medium|high|critical)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get anomaly alerts for a specific vehicle"""
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
        
        # Query for anomalous telemetry data
        query = select(TelemetryData).where(
            and_(
                TelemetryData.vehicle_id == vehicle_id,
                TelemetryData.anomaly_score > settings.ANOMALY_THRESHOLD
            )
        ).order_by(desc(TelemetryData.timestamp)).limit(limit)
        
        result = await db.execute(query)
        anomalous_records = result.scalars().all()
        
        # Convert to alert format
        alerts = []
        for record in anomalous_records:
            # Determine severity based on anomaly score
            if record.anomaly_score >= 0.9:
                alert_severity = "critical"
            elif record.anomaly_score >= 0.8:
                alert_severity = "high"
            elif record.anomaly_score >= 0.7:
                alert_severity = "medium"
            else:
                alert_severity = "low"
            
            # Skip if severity filter doesn't match
            if severity and alert_severity != severity:
                continue
            
            # Identify affected sensors (simplified logic)
            affected_sensors = list(record.sensor_data.keys())
            
            # Generate description and recommendations
            description = f"Anomaly detected with score {record.anomaly_score:.2f}"
            recommendations = generate_recommendations(record.sensor_data, record.anomaly_score)
            
            alert = AnomalyAlert(
                id=str(record.id),
                vehicle_id=str(record.vehicle_id),
                timestamp=record.timestamp,
                anomaly_score=record.anomaly_score,
                affected_sensors=affected_sensors,
                severity=alert_severity,
                description=description,
                recommendations=recommendations
            )
            alerts.append(alert)
        
        logger.info(f"🚨 Retrieved {len(alerts)} alerts for vehicle {vehicle_id}")
        
        return alerts
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving alerts: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve alerts"
        )

@router.get("/vehicle/{vehicle_id}/stats", response_model=TelemetryStats)
async def get_vehicle_telemetry_stats(
    vehicle_id: str,
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get telemetry statistics for a vehicle"""
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
        
        # Calculate date range
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Get basic statistics
        stats_query = select(
            func.count(TelemetryData.id).label("total_records"),
            func.min(TelemetryData.timestamp).label("min_date"),
            func.max(TelemetryData.timestamp).label("max_date"),
            func.count(TelemetryData.id).filter(TelemetryData.anomaly_score > settings.ANOMALY_THRESHOLD).label("anomaly_count"),
            func.avg(TelemetryData.quality_score).label("avg_quality")
        ).where(
            and_(
                TelemetryData.vehicle_id == vehicle_id,
                TelemetryData.timestamp >= start_date,
                TelemetryData.timestamp <= end_date
            )
        )
        
        result = await db.execute(stats_query)
        stats = result.first()
        
        # Calculate sensor health (simplified)
        sensor_health = await calculate_sensor_health(db, vehicle_id, start_date, end_date)
        
        telemetry_stats = TelemetryStats(
            vehicle_id=vehicle_id,
            total_records=stats.total_records or 0,
            date_range={
                "start": stats.min_date or start_date,
                "end": stats.max_date or end_date
            },
            anomaly_count=stats.anomaly_count or 0,
            average_quality_score=float(stats.avg_quality or 0),
            sensor_health=sensor_health
        )
        
        logger.info(f"📊 Retrieved telemetry stats for vehicle {vehicle_id}")
        
        return telemetry_stats
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving telemetry stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve telemetry statistics"
        )

@router.get("/vehicle/{vehicle_id}/status")
async def get_current_vehicle_status(
    vehicle_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current real-time status of a vehicle"""
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
        
        # Get latest telemetry data
        latest_query = select(TelemetryData).where(
            TelemetryData.vehicle_id == vehicle_id
        ).order_by(desc(TelemetryData.timestamp)).limit(1)
        
        result = await db.execute(latest_query)
        latest_telemetry = result.scalar_one_or_none()
        
        if not latest_telemetry:
            # Return default status if no telemetry data
            return {
                "is_online": False,
                "last_update": None,
                "engine_status": {},
                "battery_level": 0.0,
                "fuel_level": 0.0,
                "location": {},
                "alerts": []
            }
        
        # Check if vehicle is online (last update within 5 minutes)
        is_online = (datetime.utcnow() - latest_telemetry.timestamp).total_seconds() < 300
        
        # Get recent alerts
        alerts_query = select(TelemetryData).where(
            and_(
                TelemetryData.vehicle_id == vehicle_id,
                TelemetryData.anomaly_score > settings.ANOMALY_THRESHOLD,
                TelemetryData.timestamp >= datetime.utcnow() - timedelta(hours=24)
            )
        ).order_by(desc(TelemetryData.timestamp)).limit(10)
        
        result = await db.execute(alerts_query)
        alert_records = result.scalars().all()
        
        # Format alerts
        alerts = []
        for record in alert_records:
            severity = "critical" if record.anomaly_score >= 0.9 else "high" if record.anomaly_score >= 0.8 else "medium"
            alerts.append({
                "id": str(record.id),
                "type": "anomaly",
                "severity": severity,
                "message": f"Anomaly detected (score: {record.anomaly_score:.2f})",
                "timestamp": record.timestamp.isoformat(),
                "acknowledged": False
            })
        
        # Build status response
        status_response = {
            "is_online": is_online,
            "last_update": latest_telemetry.timestamp.isoformat(),
            "engine_status": {
                "temperature": latest_telemetry.sensor_data.get("engine_temp", 0),
                "rpm": latest_telemetry.sensor_data.get("rpm", 0),
                "oil_pressure": latest_telemetry.sensor_data.get("oil_pressure", 0),
                "running": latest_telemetry.sensor_data.get("engine_running", False)
            },
            "battery_level": latest_telemetry.sensor_data.get("battery_level", 0.0),
            "fuel_level": latest_telemetry.sensor_data.get("fuel_level", 0.0),
            "location": latest_telemetry.location or {},
            "alerts": alerts
        }
        
        logger.info(f"📊 Retrieved current status for vehicle {vehicle_id}")
        
        return status_response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving vehicle status: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve vehicle status"
        )

# Background task functions
async def process_telemetry_async(agent_manager: AgentManager, telemetry_data: Dict[str, Any]):
    """Process telemetry data asynchronously through Data Agent"""
    try:
        await agent_manager.send_message_to_agent(
            recipient="data_agent",
            message_type="telemetry_data",
            payload=telemetry_data,
            sender="telemetry_api"
        )
        logger.debug(f"📤 Telemetry sent to Data Agent for processing")
        
    except Exception as e:
        logger.error(f"Error processing telemetry async: {e}")

async def broadcast_telemetry_update(websocket_manager: WebSocketManager, telemetry_data: Dict[str, Any]):
    """Broadcast real-time telemetry update via WebSocket"""
    try:
        vehicle_id = telemetry_data["vehicle_id"]
        
        # Create WebSocket message
        message = WebSocketMessage(
            message_type="telemetry_update",
            data=telemetry_data
        )
        
        # Broadcast to vehicle-specific group
        await websocket_manager.broadcast_to_group(f"telemetry_{vehicle_id}", message)
        
        logger.debug(f"📡 Telemetry update broadcasted for vehicle {vehicle_id}")
        
    except Exception as e:
        logger.error(f"Error broadcasting telemetry update: {e}")

async def check_and_broadcast_alerts(websocket_manager: WebSocketManager, user_id: str, 
                                   vehicle_id: str, sensor_data: Dict[str, Any]):
    """Check sensor data for alerts and broadcast them"""
    try:
        alerts = []
        
        # Engine temperature alerts
        engine_temp = sensor_data.get("engine_temp", 0)
        if engine_temp > 115:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}",
                "title": "Critical Engine Temperature",
                "message": f"Engine temperature is critically high at {engine_temp}°C",
                "severity": "critical",
                "category": "engine",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"temperature": engine_temp, "threshold": 115},
                "recommended_actions": [
                    "Stop the vehicle immediately",
                    "Turn off the engine",
                    "Check coolant level",
                    "Contact emergency service"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        elif engine_temp > 105:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}",
                "title": "High Engine Temperature",
                "message": f"Engine temperature is high at {engine_temp}°C",
                "severity": "high",
                "category": "engine",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"temperature": engine_temp, "threshold": 105},
                "recommended_actions": [
                    "Reduce driving speed",
                    "Turn on heater to help cooling",
                    "Check coolant level when safe"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        
        # Oil pressure alerts
        oil_pressure = sensor_data.get("oil_pressure", 0)
        if oil_pressure < 15:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}_oil",
                "title": "Critical Oil Pressure",
                "message": f"Oil pressure is critically low at {oil_pressure} PSI",
                "severity": "critical",
                "category": "pressure",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"pressure": oil_pressure, "threshold": 15},
                "recommended_actions": [
                    "Stop the vehicle immediately",
                    "Turn off the engine",
                    "Check oil level",
                    "Do not drive until repaired"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        elif oil_pressure < 25:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}_oil",
                "title": "Low Oil Pressure",
                "message": f"Oil pressure is low at {oil_pressure} PSI",
                "severity": "high",
                "category": "pressure",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"pressure": oil_pressure, "threshold": 25},
                "recommended_actions": [
                    "Check oil level as soon as possible",
                    "Avoid high RPM driving",
                    "Schedule maintenance check"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        
        # Battery alerts
        battery_level = sensor_data.get("battery_level", 100)
        if battery_level < 10:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}_battery",
                "title": "Critical Battery Level",
                "message": f"Battery level is critically low at {battery_level}%",
                "severity": "critical",
                "category": "battery",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"level": battery_level, "threshold": 10},
                "recommended_actions": [
                    "Find charging station immediately",
                    "Reduce power consumption",
                    "Avoid using accessories"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        elif battery_level < 20:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}_battery",
                "title": "Low Battery Level",
                "message": f"Battery level is low at {battery_level}%",
                "severity": "medium",
                "category": "battery",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"level": battery_level, "threshold": 20},
                "recommended_actions": [
                    "Plan to charge soon",
                    "Locate nearby charging stations"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        
        # Fuel alerts
        fuel_level = sensor_data.get("fuel_level", 100)
        if fuel_level < 5:
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}_fuel",
                "title": "Critical Fuel Level",
                "message": f"Fuel level is critically low at {fuel_level}%",
                "severity": "high",
                "category": "fuel",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"level": fuel_level, "threshold": 5},
                "recommended_actions": [
                    "Find gas station immediately",
                    "Drive conservatively to save fuel"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        
        # Diagnostic code alerts
        diagnostic_codes = sensor_data.get("diagnostic_codes", [])
        if diagnostic_codes:
            severity = "critical" if any(code.startswith("P0") for code in diagnostic_codes) else "medium"
            alerts.append({
                "id": f"alert_{vehicle_id}_{int(datetime.utcnow().timestamp())}_diagnostic",
                "title": "Diagnostic Codes Detected",
                "message": f"Vehicle has {len(diagnostic_codes)} diagnostic code(s): {', '.join(diagnostic_codes)}",
                "severity": severity,
                "category": "diagnostic",
                "timestamp": datetime.utcnow().isoformat(),
                "data": {"codes": diagnostic_codes},
                "recommended_actions": [
                    "Schedule diagnostic scan",
                    "Check vehicle manual for code meanings",
                    "Contact service center if critical"
                ],
                "vehicle_id": vehicle_id,
                "user_id": user_id
            })
        
        # Broadcast alerts
        for alert in alerts:
            message = WebSocketMessage(
                message_type="alert",
                data=alert
            )
            
            # Broadcast to user-specific alerts group
            await websocket_manager.broadcast_to_group(f"alerts_{user_id}", message)
            
            logger.info(f"🚨 Alert broadcasted: {alert['severity']} - {alert['title']}")
        
    except Exception as e:
        logger.error(f"Error checking and broadcasting alerts: {e}")

async def process_batch_telemetry_async(agent_manager: AgentManager, batch_data: Dict[str, Any]):
    """Process batch telemetry data asynchronously"""
    try:
        await agent_manager.send_message_to_agent(
            recipient="data_agent",
            message_type="batch_process",
            payload=batch_data,
            sender="telemetry_api"
        )
        logger.debug(f"📤 Batch telemetry sent to Data Agent for processing")
        
    except Exception as e:
        logger.error(f"Error processing batch telemetry async: {e}")

# Utility functions
def generate_recommendations(sensor_data: Dict[str, Any], anomaly_score: float) -> List[str]:
    """Generate recommendations based on sensor data and anomaly score"""
    recommendations = []
    
    try:
        # Engine temperature recommendations
        if "engine_temp" in sensor_data:
            temp = sensor_data["engine_temp"]
            if temp > 110:
                recommendations.append("Check coolant level and radiator condition")
                recommendations.append("Inspect thermostat and water pump")
            elif temp < 60:
                recommendations.append("Allow engine to warm up properly")
        
        # Oil pressure recommendations
        if "oil_pressure" in sensor_data:
            pressure = sensor_data["oil_pressure"]
            if pressure < 20:
                recommendations.append("Check oil level immediately")
                recommendations.append("Inspect for oil leaks")
            elif pressure > 70:
                recommendations.append("Check oil viscosity and filter condition")
        
        # Battery voltage recommendations
        if "battery_voltage" in sensor_data:
            voltage = sensor_data["battery_voltage"]
            if voltage < 12.0:
                recommendations.append("Test battery and charging system")
                recommendations.append("Check alternator belt tension")
            elif voltage > 14.5:
                recommendations.append("Check voltage regulator")
        
        # General high anomaly score recommendations
        if anomaly_score > 0.9:
            recommendations.append("Schedule immediate diagnostic inspection")
            recommendations.append("Avoid heavy driving until issue is resolved")
        elif anomaly_score > 0.8:
            recommendations.append("Schedule maintenance check within 1 week")
        
        # Default recommendation if none specific
        if not recommendations:
            recommendations.append("Monitor vehicle performance closely")
            recommendations.append("Consider scheduling routine maintenance")
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        recommendations = ["Consult with a qualified mechanic"]
    
    return recommendations

async def calculate_sensor_health(db: AsyncSession, vehicle_id: str, 
                                start_date: datetime, end_date: datetime) -> Dict[str, float]:
    """Calculate health scores for different sensors"""
    try:
        # This is a simplified calculation
        # In a real implementation, this would be more sophisticated
        
        sensor_health = {
            "engine_temp": 0.85,
            "oil_pressure": 0.90,
            "battery_voltage": 0.88,
            "rpm": 0.92,
            "speed": 0.95
        }
        
        # You could implement actual calculations based on historical data
        # For now, returning mock data
        
        return sensor_health
        
    except Exception as e:
        logger.error(f"Error calculating sensor health: {e}")
        return {}