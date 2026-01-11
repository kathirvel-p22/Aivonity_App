"""
Notification API endpoints for AIVONITY
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from ..db.database import get_db
from ..services.notification_service import notification_service, NotificationTemplate, NotificationType
from ..services.notification_scheduler import notification_scheduler, NotificationPreference

router = APIRouter(prefix="/notifications", tags=["notifications"])


class SendNotificationRequest(BaseModel):
    user_id: str
    notification_type: NotificationType
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    action_url: Optional[str] = None


class ScheduleNotificationRequest(BaseModel):
    user_id: str
    notification_type: NotificationType
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    action_url: Optional[str] = None
    scheduled_at: datetime
    expires_at: Optional[datetime] = None


class BulkNotificationRequest(BaseModel):
    recipients: List[Dict[str, str]]  # List of user contact info
    notification_type: NotificationType
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    action_url: Optional[str] = None


class UpdateFCMTokenRequest(BaseModel):
    user_id: str
    fcm_token: str


class UpdatePreferencesRequest(BaseModel):
    push_enabled: bool = True
    email_enabled: bool = True
    sms_enabled: bool = False
    quiet_hours_start: Optional[int] = None
    quiet_hours_end: Optional[int] = None
    priority_threshold: str = "normal"


@router.post("/send")
async def send_notification(
    request: SendNotificationRequest,
    db: AsyncSession = Depends(get_db)
):
    """Send immediate notification to a user"""
    try:
        template = NotificationTemplate(
            title=request.title,
            body=request.body,
            data=request.data,
            action_url=request.action_url
        )
        
        # Get user contact info based on notification type
        user_info = await _get_user_contact_info(db, request.user_id)
        
        if request.notification_type == NotificationType.PUSH:
            result = await notification_service.send_push_notification(
                user_info.get("fcm_token", ""),
                template.title,
                template.body,
                template.data
            )
        elif request.notification_type == NotificationType.EMAIL:
            result = await notification_service.send_email_notification(
                user_info.get("email", ""),
                template.title,
                template.body,
                template.action_url
            )
        elif request.notification_type == NotificationType.SMS:
            result = await notification_service.send_sms_notification(
                user_info.get("phone", ""),
                f"{template.title}\n\n{template.body}"
            )
        else:
            raise HTTPException(status_code=400, detail="Invalid notification type")
        
        return {
            "success": result["status"] == "success",
            "result": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/schedule")
async def schedule_notification(
    request: ScheduleNotificationRequest,
    db: AsyncSession = Depends(get_db)
):
    """Schedule a notification for future delivery"""
    try:
        template = NotificationTemplate(
            title=request.title,
            body=request.body,
            data=request.data,
            action_url=request.action_url
        )
        
        notification_id = await notification_scheduler.schedule_notification(
            db=db,
            user_id=request.user_id,
            notification_type=request.notification_type,
            template=template,
            scheduled_at=request.scheduled_at,
            expires_at=request.expires_at
        )
        
        return {
            "success": True,
            "notification_id": notification_id,
            "scheduled_at": request.scheduled_at.isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/schedule/{notification_id}")
async def cancel_scheduled_notification(
    notification_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Cancel a scheduled notification"""
    try:
        success = await notification_scheduler.cancel_scheduled_notification(db, notification_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        return {"success": True, "message": "Notification cancelled"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/bulk")
async def send_bulk_notification(
    request: BulkNotificationRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    """Send notification to multiple recipients"""
    try:
        template = NotificationTemplate(
            title=request.title,
            body=request.body,
            data=request.data,
            action_url=request.action_url
        )
        
        # Process bulk notifications in background
        background_tasks.add_task(
            _process_bulk_notification,
            request.recipients,
            template,
            request.notification_type
        )
        
        return {
            "success": True,
            "message": f"Bulk notification queued for {len(request.recipients)} recipients"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/fcm-token")
async def update_fcm_token(
    request: UpdateFCMTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """Update user's FCM token for push notifications"""
    try:
        # In production, update user's FCM token in database
        # For now, just return success
        
        return {
            "success": True,
            "message": "FCM token updated successfully"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/preferences/{user_id}")
async def get_notification_preferences(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get user's notification preferences"""
    try:
        preferences = await notification_scheduler.get_user_preferences(db, user_id)
        return preferences.dict()
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/preferences/{user_id}")
async def update_notification_preferences(
    user_id: str,
    request: UpdatePreferencesRequest,
    db: AsyncSession = Depends(get_db)
):
    """Update user's notification preferences"""
    try:
        preferences = NotificationPreference(
            user_id=user_id,
            push_enabled=request.push_enabled,
            email_enabled=request.email_enabled,
            sms_enabled=request.sms_enabled,
            quiet_hours_start=request.quiet_hours_start,
            quiet_hours_end=request.quiet_hours_end,
            priority_threshold=request.priority_threshold
        )
        
        success = await notification_scheduler.update_user_preferences(db, user_id, preferences)
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to update preferences")
        
        return {
            "success": True,
            "message": "Preferences updated successfully"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/test/{notification_type}")
async def test_notification(
    notification_type: NotificationType,
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Send a test notification"""
    try:
        template = NotificationTemplate(
            title="AIVONITY Test Notification",
            body="This is a test notification from your AIVONITY system. If you received this, notifications are working correctly!",
            data={"test": "true", "timestamp": datetime.now().isoformat()},
            action_url="https://app.aivonity.com/dashboard"
        )
        
        user_info = await _get_user_contact_info(db, user_id)
        
        if notification_type == NotificationType.PUSH:
            result = await notification_service.send_push_notification(
                user_info.get("fcm_token", ""),
                template.title,
                template.body,
                template.data
            )
        elif notification_type == NotificationType.EMAIL:
            result = await notification_service.send_email_notification(
                user_info.get("email", ""),
                template.title,
                template.body,
                template.action_url
            )
        elif notification_type == NotificationType.SMS:
            result = await notification_service.send_sms_notification(
                user_info.get("phone", ""),
                f"{template.title}\n\n{template.body}"
            )
        
        return {
            "success": result["status"] == "success",
            "result": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def _get_user_contact_info(db: AsyncSession, user_id: str) -> Dict[str, str]:
    """Get user contact information from database"""
    # In production, query actual user table
    # For now, return placeholder data
    return {
        "email": f"user{user_id}@example.com",
        "phone": "+1234567890",
        "fcm_token": f"fcm_token_{user_id}"
    }


async def _process_bulk_notification(
    recipients: List[Dict[str, str]],
    template: NotificationTemplate,
    notification_type: NotificationType
):
    """Process bulk notification in background"""
    try:
        result = await notification_service.send_bulk_notification(
            recipients, template, notification_type
        )
        
        # Log bulk notification results
        print(f"Bulk notification completed: {result}")
        
    except Exception as e:
        print(f"Bulk notification failed: {e}")