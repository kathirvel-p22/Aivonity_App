"""
AIVONITY Offline Data Management Service
Handles offline data synchronization and conflict resolution
"""

import asyncio
import json
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from enum import Enum
import logging
from dataclasses import dataclass, asdict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, and_, or_
from sqlalchemy.orm import selectinload

from app.db.database import get_db_session
from app.db.models import User, Vehicle, TelemetryData, MaintenancePrediction
from app.utils.exceptions import (
    AIVONITYException,
    DatabaseError,
    ValidationError,
    ResourceNotFoundError,
    ResourceConflictError
)


class ConflictResolution(str, Enum):
    """Conflict resolution strategies"""
    CLIENT_WINS = "client_wins"
    SERVER_WINS = "server_wins"
    MERGE = "merge"
    MANUAL = "manual"


class SyncStatus(str, Enum):
    """Synchronization status"""
    PENDING = "pending"
    SYNCING = "syncing"
    SYNCED = "synced"
    CONFLICT = "conflict"
    ERROR = "error"


@dataclass
class SyncOperation:
    """Represents a synchronization operation"""
    id: str
    user_id: str
    resource_type: str
    resource_id: str
    operation_type: str  # create, update, delete
    data: Dict[str, Any]
    timestamp: datetime
    client_version: int
    server_version: Optional[int] = None
    status: SyncStatus = SyncStatus.PENDING
    conflict_resolution: ConflictResolution = ConflictResolution.CLIENT_WINS
    retry_count: int = 0
    error_message: Optional[str] = None


@dataclass
class SyncConflict:
    """Represents a synchronization conflict"""
    id: str
    resource_type: str
    resource_id: str
    client_data: Dict[str, Any]
    server_data: Dict[str, Any]
    client_version: int
    server_version: int
    conflict_type: str
    timestamp: datetime
    resolved: bool = False
    resolution_strategy: Optional[ConflictResolution] = None
    merged_data: Optional[Dict[str, Any]] = None


class OfflineDataService:
    """Service for handling offline data synchronization"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.sync_operations: Dict[str, SyncOperation] = {}
        self.sync_conflicts: Dict[str, SyncConflict] = {}
    
    async def queue_sync_operation(
        self,
        user_id: str,
        resource_type: str,
        resource_id: str,
        operation_type: str,
        data: Dict[str, Any],
        client_version: int = 1,
        conflict_resolution: ConflictResolution = ConflictResolution.CLIENT_WINS
    ) -> str:
        """Queue a synchronization operation"""
        
        operation_id = f"{user_id}_{resource_type}_{resource_id}_{operation_type}_{datetime.utcnow().timestamp()}"
        
        sync_op = SyncOperation(
            id=operation_id,
            user_id=user_id,
            resource_type=resource_type,
            resource_id=resource_id,
            operation_type=operation_type,
            data=data,
            timestamp=datetime.utcnow(),
            client_version=client_version,
            conflict_resolution=conflict_resolution
        )
        
        self.sync_operations[operation_id] = sync_op
        
        self.logger.info(
            f"Queued sync operation: {operation_type} {resource_type}/{resource_id}",
            extra={
                'operation_id': operation_id,
                'user_id': user_id,
                'resource_type': resource_type,
                'resource_id': resource_id,
                'operation_type': operation_type
            }
        )
        
        return operation_id
    
    async def process_sync_operations(self, user_id: str) -> Dict[str, Any]:
        """Process all pending sync operations for a user"""
        
        user_operations = [
            op for op in self.sync_operations.values()
            if op.user_id == user_id and op.status == SyncStatus.PENDING
        ]
        
        if not user_operations:
            return {
                'processed': 0,
                'successful': 0,
                'conflicts': 0,
                'errors': 0
            }
        
        self.logger.info(
            f"Processing {len(user_operations)} sync operations for user {user_id}"
        )
        
        results = {
            'processed': 0,
            'successful': 0,
            'conflicts': 0,
            'errors': 0,
            'operations': []
        }
        
        async with get_db_session() as session:
            for operation in user_operations:
                try:
                    operation.status = SyncStatus.SYNCING
                    result = await self._process_single_operation(session, operation)
                    results['operations'].append(result)
                    results['processed'] += 1
                    
                    if result['status'] == 'success':
                        results['successful'] += 1
                        operation.status = SyncStatus.SYNCED
                    elif result['status'] == 'conflict':
                        results['conflicts'] += 1
                        operation.status = SyncStatus.CONFLICT
                    else:
                        results['errors'] += 1
                        operation.status = SyncStatus.ERROR
                        operation.error_message = result.get('error')
                
                except Exception as e:
                    self.logger.error(
                        f"Error processing sync operation {operation.id}: {str(e)}",
                        exc_info=True
                    )
                    operation.status = SyncStatus.ERROR
                    operation.error_message = str(e)
                    operation.retry_count += 1
                    results['errors'] += 1
        
        return results
    
    async def _process_single_operation(
        self,
        session: AsyncSession,
        operation: SyncOperation
    ) -> Dict[str, Any]:
        """Process a single sync operation"""
        
        try:
            # Check if resource exists and get current version
            current_data, current_version = await self._get_current_resource_data(
                session, operation.resource_type, operation.resource_id
            )
            
            # Detect conflicts
            if current_data and current_version != operation.client_version:
                conflict = await self._handle_sync_conflict(
                    operation, current_data, current_version
                )
                return {
                    'operation_id': operation.id,
                    'status': 'conflict',
                    'conflict_id': conflict.id,
                    'message': 'Sync conflict detected'
                }
            
            # Apply the operation
            result = await self._apply_sync_operation(session, operation)
            
            return {
                'operation_id': operation.id,
                'status': 'success',
                'resource_id': operation.resource_id,
                'new_version': result.get('version', 1),
                'message': 'Operation applied successfully'
            }
        
        except Exception as e:
            return {
                'operation_id': operation.id,
                'status': 'error',
                'error': str(e),
                'message': 'Failed to process operation'
            }
    
    async def _get_current_resource_data(
        self,
        session: AsyncSession,
        resource_type: str,
        resource_id: str
    ) -> Tuple[Optional[Dict[str, Any]], int]:
        """Get current resource data and version"""
        
        if resource_type == 'vehicle':
            stmt = select(Vehicle).where(Vehicle.id == resource_id)
            result = await session.execute(stmt)
            vehicle = result.scalar_one_or_none()
            
            if vehicle:
                return {
                    'id': str(vehicle.id),
                    'user_id': str(vehicle.user_id),
                    'make': vehicle.make,
                    'model': vehicle.model,
                    'year': vehicle.year,
                    'vin': vehicle.vin,
                    'mileage': vehicle.mileage,
                    'health_score': vehicle.health_score,
                    'updated_at': vehicle.updated_at.isoformat()
                }, 1  # Version would be stored in a separate versioning table in production
            
        elif resource_type == 'telemetry':
            stmt = select(TelemetryData).where(TelemetryData.id == resource_id)
            result = await session.execute(stmt)
            telemetry = result.scalar_one_or_none()
            
            if telemetry:
                return {
                    'id': str(telemetry.id),
                    'vehicle_id': str(telemetry.vehicle_id),
                    'timestamp': telemetry.timestamp.isoformat(),
                    'sensor_data': telemetry.sensor_data,
                    'location': telemetry.location,
                    'anomaly_score': telemetry.anomaly_score
                }, 1
        
        return None, 0
    
    async def _apply_sync_operation(
        self,
        session: AsyncSession,
        operation: SyncOperation
    ) -> Dict[str, Any]:
        """Apply a sync operation to the database"""
        
        if operation.resource_type == 'vehicle':
            return await self._apply_vehicle_operation(session, operation)
        elif operation.resource_type == 'telemetry':
            return await self._apply_telemetry_operation(session, operation)
        elif operation.resource_type == 'prediction':
            return await self._apply_prediction_operation(session, operation)
        else:
            raise ValidationError(f"Unsupported resource type: {operation.resource_type}")
    
    async def _apply_vehicle_operation(
        self,
        session: AsyncSession,
        operation: SyncOperation
    ) -> Dict[str, Any]:
        """Apply vehicle-related sync operation"""
        
        if operation.operation_type == 'create':
            vehicle = Vehicle(
                id=operation.resource_id,
                user_id=operation.data['user_id'],
                make=operation.data['make'],
                model=operation.data['model'],
                year=operation.data['year'],
                vin=operation.data['vin'],
                mileage=operation.data.get('mileage', 0),
                health_score=operation.data.get('health_score', 1.0)
            )
            session.add(vehicle)
            
        elif operation.operation_type == 'update':
            stmt = select(Vehicle).where(Vehicle.id == operation.resource_id)
            result = await session.execute(stmt)
            vehicle = result.scalar_one_or_none()
            
            if not vehicle:
                raise ResourceNotFoundError('Vehicle', operation.resource_id)
            
            # Update fields
            for key, value in operation.data.items():
                if hasattr(vehicle, key) and key != 'id':
                    setattr(vehicle, key, value)
        
        elif operation.operation_type == 'delete':
            stmt = delete(Vehicle).where(Vehicle.id == operation.resource_id)
            await session.execute(stmt)
        
        await session.commit()
        return {'version': 1}  # In production, increment version
    
    async def _apply_telemetry_operation(
        self,
        session: AsyncSession,
        operation: SyncOperation
    ) -> Dict[str, Any]:
        """Apply telemetry-related sync operation"""
        
        if operation.operation_type == 'create':
            telemetry = TelemetryData(
                id=operation.resource_id,
                vehicle_id=operation.data['vehicle_id'],
                timestamp=datetime.fromisoformat(operation.data['timestamp']),
                sensor_data=operation.data['sensor_data'],
                location=operation.data.get('location'),
                anomaly_score=operation.data.get('anomaly_score')
            )
            session.add(telemetry)
        
        await session.commit()
        return {'version': 1}
    
    async def _apply_prediction_operation(
        self,
        session: AsyncSession,
        operation: SyncOperation
    ) -> Dict[str, Any]:
        """Apply prediction-related sync operation"""
        
        if operation.operation_type == 'create':
            prediction = MaintenancePrediction(
                id=operation.resource_id,
                vehicle_id=operation.data['vehicle_id'],
                component=operation.data['component'],
                failure_probability=operation.data['failure_probability'],
                confidence_score=operation.data['confidence_score'],
                recommended_action=operation.data['recommended_action'],
                timeframe_days=operation.data['timeframe_days'],
                status=operation.data.get('status', 'pending')
            )
            session.add(prediction)
        
        await session.commit()
        return {'version': 1}
    
    async def _handle_sync_conflict(
        self,
        operation: SyncOperation,
        server_data: Dict[str, Any],
        server_version: int
    ) -> SyncConflict:
        """Handle synchronization conflict"""
        
        conflict_id = f"conflict_{operation.resource_type}_{operation.resource_id}_{datetime.utcnow().timestamp()}"
        
        conflict = SyncConflict(
            id=conflict_id,
            resource_type=operation.resource_type,
            resource_id=operation.resource_id,
            client_data=operation.data,
            server_data=server_data,
            client_version=operation.client_version,
            server_version=server_version,
            conflict_type='version_mismatch',
            timestamp=datetime.utcnow()
        )
        
        self.sync_conflicts[conflict_id] = conflict
        
        self.logger.warning(
            f"Sync conflict detected: {operation.resource_type}/{operation.resource_id}",
            extra={
                'conflict_id': conflict_id,
                'client_version': operation.client_version,
                'server_version': server_version
            }
        )
        
        return conflict
    
    async def resolve_conflict(
        self,
        conflict_id: str,
        resolution: ConflictResolution,
        merged_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Resolve a synchronization conflict"""
        
        if conflict_id not in self.sync_conflicts:
            raise ResourceNotFoundError('SyncConflict', conflict_id)
        
        conflict = self.sync_conflicts[conflict_id]
        
        if conflict.resolved:
            raise ResourceConflictError('SyncConflict', 'Conflict already resolved')
        
        resolved_data = None
        
        if resolution == ConflictResolution.CLIENT_WINS:
            resolved_data = conflict.client_data
        elif resolution == ConflictResolution.SERVER_WINS:
            resolved_data = conflict.server_data
        elif resolution == ConflictResolution.MERGE:
            if merged_data:
                resolved_data = merged_data
            else:
                # Simple merge strategy - server wins for conflicts, client for new fields
                resolved_data = {**conflict.server_data, **conflict.client_data}
        
        # Apply the resolved data
        async with get_db_session() as session:
            operation = SyncOperation(
                id=f"resolve_{conflict_id}",
                user_id="system",  # System resolution
                resource_type=conflict.resource_type,
                resource_id=conflict.resource_id,
                operation_type='update',
                data=resolved_data,
                timestamp=datetime.utcnow(),
                client_version=conflict.server_version + 1
            )
            
            await self._apply_sync_operation(session, operation)
        
        # Mark conflict as resolved
        conflict.resolved = True
        conflict.resolution_strategy = resolution
        conflict.merged_data = resolved_data
        
        self.logger.info(
            f"Resolved sync conflict {conflict_id} with strategy {resolution.value}"
        )
        
        return {
            'conflict_id': conflict_id,
            'resolution': resolution.value,
            'resolved_data': resolved_data,
            'timestamp': datetime.utcnow().isoformat()
        }
    
    async def get_sync_status(self, user_id: str) -> Dict[str, Any]:
        """Get synchronization status for a user"""
        
        user_operations = [
            op for op in self.sync_operations.values()
            if op.user_id == user_id
        ]
        
        user_conflicts = [
            conflict for conflict in self.sync_conflicts.values()
            if any(op.user_id == user_id and op.resource_id == conflict.resource_id 
                   for op in user_operations)
        ]
        
        status_counts = {}
        for status in SyncStatus:
            status_counts[status.value] = sum(
                1 for op in user_operations if op.status == status
            )
        
        return {
            'user_id': user_id,
            'total_operations': len(user_operations),
            'status_breakdown': status_counts,
            'unresolved_conflicts': len([c for c in user_conflicts if not c.resolved]),
            'last_sync': max(
                (op.timestamp for op in user_operations if op.status == SyncStatus.SYNCED),
                default=None
            )
        }
    
    async def get_conflicts(self, user_id: str) -> List[Dict[str, Any]]:
        """Get unresolved conflicts for a user"""
        
        user_operations = [
            op for op in self.sync_operations.values()
            if op.user_id == user_id
        ]
        
        user_conflicts = [
            conflict for conflict in self.sync_conflicts.values()
            if not conflict.resolved and any(
                op.user_id == user_id and op.resource_id == conflict.resource_id 
                for op in user_operations
            )
        ]
        
        return [
            {
                'conflict_id': conflict.id,
                'resource_type': conflict.resource_type,
                'resource_id': conflict.resource_id,
                'conflict_type': conflict.conflict_type,
                'client_data': conflict.client_data,
                'server_data': conflict.server_data,
                'timestamp': conflict.timestamp.isoformat()
            }
            for conflict in user_conflicts
        ]
    
    async def cleanup_old_operations(self, days: int = 7) -> int:
        """Clean up old sync operations"""
        
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        old_operations = [
            op_id for op_id, op in self.sync_operations.items()
            if op.timestamp < cutoff_date and op.status in [SyncStatus.SYNCED, SyncStatus.ERROR]
        ]
        
        for op_id in old_operations:
            del self.sync_operations[op_id]
        
        self.logger.info(f"Cleaned up {len(old_operations)} old sync operations")
        
        return len(old_operations)


# Global service instance
offline_data_service = OfflineDataService()