"""
Notification Scheduler for AIVONITY
Handles scheduled notifications and user preferences
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, and_
from pydantic import BaseModel

from .notification_service import notification_service, NotificationTemplate, NotificationType
from ..db.database import get_db

logger = logging.getLogger(__name__)


class NotificationPreference(BaseModel):
    user_id: str
    push_enabled: bool = True
    email_enabled: bool = True
    sms_enabled: bool = False
    quiet_hours_start: Optional[int] = None  # Hour (0-23)
    quiet_hours_end: Optional[int] = None    # Hour (0-23)
    priority_threshold: str = "normal"  # low, normal, high, critical


class ScheduledNotification(BaseModel):
    id: Optional[str] = None
    user_id: str
    notification_type: str
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    action_url: Optional[str] = None
    scheduled_at: datetime
    expires_at: Optional[datetime] = None
    status: str = "pending"  # pending, sent, failed, expired


class NotificationScheduler:
    """
    Handles notification scheduling and user preferences
    """
    
    def __init__(self):
        self.running = False
        self.check_interval = 60  # Check every minute
    
    async def start_scheduler(self):
        """Start the notification scheduler background task"""
        if self.running:
            return
        
        self.running = True
        logger.info("Starting notification scheduler")
        
        while self.running:
            try:
                await self._process_scheduled_notifications()
                await asyncio.sleep(self.check_interval)
            except Exception as e:
                logger.error(f"Scheduler error: {e}")
                await asyncio.sleep(self.check_interval)
    
    def stop_scheduler(self):
        """Stop the notification scheduler"""
        self.running = False
        logger.info("Stopping notification scheduler")
    
    async def _process_scheduled_notifications(self):
        """Process pending scheduled notifications"""
        async for db in get_db():
            try:
                # Get pending notifications that are due
                current_time = datetime.utcnow()
                
                # This would use actual database models in production
                # For now, we'll simulate the query
                pending_notifications = await self._get_pending_notifications(db, current_time)
                
                for notification in pending_notifications:
                    await self._send_scheduled_notification(db, notification)
                    
            except Exception as e:
                logger.error(f"Error processing scheduled notifications: {e}")
            finally:
                await db.close()
    
    async def _get_pending_notifications(self, db: AsyncSession, current_time: datetime) -> List[Dict]:
        """Get notifications that are due to be sent"""
        # In production, this would query the actual database
        # For now, return empty list as placeholder
        return []
    
    async def _send_scheduled_notification(self, db: AsyncSession, notification: Dict):
        """Send a scheduled notification"""
        try:
            template = NotificationTemplate(
                title=notification["title"],
                body=notification["body"],
                data=notification.get("data"),
                action_url=notification.get("action_url")
            )
            
            # Get user contact info (would come from database)
            user_info = await self._get_user_contact_info(db, notification["user_id"])
            
            if notification["notification_type"] == "push":
                result = await notification_service.send_push_notification(
                    user_info.get("fcm_token", ""),
                    template.title,
                    template.body,
                    template.data
                )
            elif notification["notification_type"] == "email":
                result = await notification_service.send_email_notification(
                    user_info.get("email", ""),
                    template.title,
                    template.body,
                    template.action_url
                )
            elif notification["notification_type"] == "sms":
                result = await notification_service.send_sms_notification(
                    user_info.get("phone", ""),
                    f"{template.title}\n\n{template.body}"
                )
            
            # Update notification status
            await self._update_notification_status(
                db, 
                notification["id"], 
                "sent" if result["status"] == "success" else "failed"
            )
            
        except Exception as e:
            logger.error(f"Failed to send scheduled notification: {e}")
            await self._update_notification_status(db, notification["id"], "failed")
    
    async def _get_user_contact_info(self, db: AsyncSession, user_id: str) -> Dict[str, str]:
        """Get user contact information"""
        # Placeholder - would query actual user table
        return {
            "email": "user@example.com",
            "phone": "+1234567890",
            "fcm_token": "sample_token"
        }
    
    async def _update_notification_status(self, db: AsyncSession, notification_id: str, status: str):
        """Update notification status in database"""
        # Placeholder - would update actual database
        logger.info(f"Updated notification {notification_id} status to {status}")
    
    async def schedule_notification(
        self,
        db: AsyncSession,
        user_id: str,
        notification_type: NotificationType,
        template: NotificationTemplate,
        scheduled_at: datetime,
        expires_at: Optional[datetime] = None
    ) -> str:
        """Schedule a notification for future delivery"""
        try:
            # Check user preferences
            preferences = await self.get_user_preferences(db, user_id)
            
            if not self._is_notification_allowed(preferences, notification_type):
                raise ValueError(f"Notification type {notification_type} disabled for user")
            
            # Create scheduled notification record
            notification_data = {
                "user_id": user_id,
                "notification_type": notification_type.value,
                "title": template.title,
                "body": template.body,
                "data": template.data,
                "action_url": template.action_url,
                "scheduled_at": scheduled_at,
                "expires_at": expires_at,
                "status": "pending"
            }
            
            # In production, save to database and return ID
            notification_id = f"notif_{user_id}_{int(scheduled_at.timestamp())}"
            
            logger.info(f"Scheduled notification {notification_id} for {scheduled_at}")
            return notification_id
            
        except Exception as e:
            logger.error(f"Failed to schedule notification: {e}")
            raise
    
    async def cancel_scheduled_notification(self, db: AsyncSession, notification_id: str) -> bool:
        """Cancel a scheduled notification"""
        try:
            # In production, update database record
            logger.info(f"Cancelled scheduled notification {notification_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to cancel notification: {e}")
            return False
    
    async def get_user_preferences(self, db: AsyncSession, user_id: str) -> NotificationPreference:
        """Get user notification preferences"""
        try:
            # In production, query from database
            # For now, return default preferences
            return NotificationPreference(
                user_id=user_id,
                push_enabled=True,
                email_enabled=True,
                sms_enabled=False,
                quiet_hours_start=22,  # 10 PM
                quiet_hours_end=7,     # 7 AM
                priority_threshold="normal"
            )
        except Exception as e:
            logger.error(f"Failed to get user preferences: {e}")
            return NotificationPreference(user_id=user_id)
    
    async def update_user_preferences(
        self,
        db: AsyncSession,
        user_id: str,
        preferences: NotificationPreference
    ) -> bool:
        """Update user notification preferences"""
        try:
            # In production, update database
            logger.info(f"Updated notification preferences for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to update preferences: {e}")
            return False
    
    def _is_notification_allowed(
        self,
        preferences: NotificationPreference,
        notification_type: NotificationType
    ) -> bool:
        """Check if notification type is allowed based on user preferences"""
        if notification_type == NotificationType.PUSH:
            return preferences.push_enabled
        elif notification_type == NotificationType.EMAIL:
            return preferences.email_enabled
        elif notification_type == NotificationType.SMS:
            return preferences.sms_enabled
        return False
    
    def _is_quiet_hours(self, preferences: NotificationPreference) -> bool:
        """Check if current time is within user's quiet hours"""
        if not preferences.quiet_hours_start or not preferences.quiet_hours_end:
            return False
        
        current_hour = datetime.now().hour
        start = preferences.quiet_hours_start
        end = preferences.quiet_hours_end
        
        if start <= end:
            return start <= current_hour <= end
        else:  # Quiet hours span midnight
            return current_hour >= start or current_hour <= end


# Global scheduler instance
notification_scheduler = NotificationScheduler()