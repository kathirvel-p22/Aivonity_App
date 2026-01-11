"""
AIVONITY Offline Synchronization API
Endpoints for handling offline data synchronization and conflict resolution
"""

from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from datetime import datetime

from app.services.offline_data_service import (
    offline_data_service,
    ConflictResolution,
    SyncStatus
)
from app.api.auth import get_current_user
from app.db.models import User
from app.utils.exceptions import AIVONITYException
from app.utils.retry_handler import retry_async, RetryConfigs

router = APIRouter()


class SyncOperationRequest(BaseModel):
    """Request model for sync operations"""
    resource_type: str = Field(..., description="Type of resource (vehicle, telemetry, etc.)")
    resource_id: str = Field(..., description="Unique identifier of the resource")
    operation_type: str = Field(..., description="Type of operation (create, update, delete)")
    data: Dict[str, Any] = Field(..., description="Resource data")
    client_version: int = Field(default=1, description="Client version of the resource")
    conflict_resolution: ConflictResolution = Field(
        default=ConflictResolution.CLIENT_WINS,
        description="Conflict resolution strategy"
    )


class BatchSyncRequest(BaseModel):
    """Request model for batch sync operations"""
    operations: List[SyncOperationRequest] = Field(..., description="List of sync operations")


class ConflictResolutionRequest(BaseModel):
    """Request model for conflict resolution"""
    resolution: ConflictResolution = Field(..., description="Resolution strategy")
    merged_data: Optional[Dict[str, Any]] = Field(None, description="Merged data for manual resolution")


class SyncStatusResponse(BaseModel):
    """Response model for sync status"""
    user_id: str
    total_operations: int
    status_breakdown: Dict[str, int]
    unresolved_conflicts: int
    last_sync: Optional[datetime]


class ConflictResponse(BaseModel):
    """Response model for sync conflicts"""
    conflict_id: str
    resource_type: str
    resource_id: str
    conflict_type: str
    client_data: Dict[str, Any]
    server_data: Dict[str, Any]
    timestamp: datetime


@router.post("/sync/queue", response_model=Dict[str, str])
@retry_async(RetryConfigs.STANDARD)
async def queue_sync_operation(
    request: SyncOperationRequest,
    current_user: User = Depends(get_current_user)
):
    """Queue a single synchronization operation"""
    try:
        operation_id = await offline_data_service.queue_sync_operation(
            user_id=str(current_user.id),
            resource_type=request.resource_type,
            resource_id=request.resource_id,
            operation_type=request.operation_type,
            data=request.data,
            client_version=request.client_version,
            conflict_resolution=request.conflict_resolution
        )
        
        return {
            "operation_id": operation_id,
            "status": "queued",
            "message": "Sync operation queued successfully"
        }
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to queue sync operation: {str(e)}"
        )


@router.post("/sync/batch", response_model=Dict[str, Any])
@retry_async(RetryConfigs.STANDARD)
async def queue_batch_sync_operations(
    request: BatchSyncRequest,
    current_user: User = Depends(get_current_user)
):
    """Queue multiple synchronization operations"""
    try:
        operation_ids = []
        
        for operation in request.operations:
            operation_id = await offline_data_service.queue_sync_operation(
                user_id=str(current_user.id),
                resource_type=operation.resource_type,
                resource_id=operation.resource_id,
                operation_type=operation.operation_type,
                data=operation.data,
                client_version=operation.client_version,
                conflict_resolution=operation.conflict_resolution
            )
            operation_ids.append(operation_id)
        
        return {
            "operation_ids": operation_ids,
            "total_queued": len(operation_ids),
            "status": "queued",
            "message": f"Queued {len(operation_ids)} sync operations successfully"
        }
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to queue batch sync operations: {str(e)}"
        )


@router.post("/sync/process", response_model=Dict[str, Any])
@retry_async(RetryConfigs.AGGRESSIVE)
async def process_sync_operations(
    current_user: User = Depends(get_current_user)
):
    """Process all pending synchronization operations for the current user"""
    try:
        results = await offline_data_service.process_sync_operations(str(current_user.id))
        
        return {
            "user_id": str(current_user.id),
            "results": results,
            "message": f"Processed {results['processed']} operations"
        }
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process sync operations: {str(e)}"
        )


@router.get("/sync/status", response_model=SyncStatusResponse)
async def get_sync_status(
    current_user: User = Depends(get_current_user)
):
    """Get synchronization status for the current user"""
    try:
        status_data = await offline_data_service.get_sync_status(str(current_user.id))
        
        return SyncStatusResponse(
            user_id=status_data['user_id'],
            total_operations=status_data['total_operations'],
            status_breakdown=status_data['status_breakdown'],
            unresolved_conflicts=status_data['unresolved_conflicts'],
            last_sync=status_data['last_sync']
        )
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get sync status: {str(e)}"
        )


@router.get("/sync/conflicts", response_model=List[ConflictResponse])
async def get_sync_conflicts(
    current_user: User = Depends(get_current_user)
):
    """Get unresolved synchronization conflicts for the current user"""
    try:
        conflicts = await offline_data_service.get_conflicts(str(current_user.id))
        
        return [
            ConflictResponse(
                conflict_id=conflict['conflict_id'],
                resource_type=conflict['resource_type'],
                resource_id=conflict['resource_id'],
                conflict_type=conflict['conflict_type'],
                client_data=conflict['client_data'],
                server_data=conflict['server_data'],
                timestamp=datetime.fromisoformat(conflict['timestamp'])
            )
            for conflict in conflicts
        ]
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get sync conflicts: {str(e)}"
        )


@router.post("/sync/conflicts/{conflict_id}/resolve", response_model=Dict[str, Any])
@retry_async(RetryConfigs.STANDARD)
async def resolve_sync_conflict(
    conflict_id: str,
    request: ConflictResolutionRequest,
    current_user: User = Depends(get_current_user)
):
    """Resolve a synchronization conflict"""
    try:
        result = await offline_data_service.resolve_conflict(
            conflict_id=conflict_id,
            resolution=request.resolution,
            merged_data=request.merged_data
        )
        
        return {
            "conflict_id": conflict_id,
            "resolution": result,
            "message": "Conflict resolved successfully"
        }
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to resolve conflict: {str(e)}"
        )


@router.delete("/sync/cleanup")
async def cleanup_old_operations(
    days: int = 7,
    current_user: User = Depends(get_current_user)
):
    """Clean up old synchronization operations (admin only)"""
    try:
        # In a real implementation, you'd check for admin permissions
        cleaned_count = await offline_data_service.cleanup_old_operations(days)
        
        return {
            "cleaned_operations": cleaned_count,
            "days": days,
            "message": f"Cleaned up {cleaned_count} old operations"
        }
    
    except AIVONITYException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to cleanup operations: {str(e)}"
        )


@router.get("/sync/health")
async def sync_health_check():
    """Health check endpoint for sync service"""
    return {
        "status": "healthy",
        "service": "offline_sync",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }