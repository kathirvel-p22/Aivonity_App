"""
Notification Manager for AIVONITY
Integrates notifications with AI agents and system events
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from sqlalchemy.ext.asyncio import AsyncSession

from .notification_service import notification_service, NotificationType
from .notification_scheduler import notification_scheduler
from ..db.database import get_db

logger = logging.getLogger(__name__)


class NotificationManager:
    """
    Central manager for all notification workflows and integrations
    """
    
    def __init__(self):
        self.active_alerts = {}  # Track active alerts to prevent spam
        self.alert_cooldown = 300  # 5 minutes cooldown for similar alerts
    
    async def handle_maintenance_prediction(
        self,
        user_id: str,
        vehicle_info: Dict[str, Any],
        prediction_data: Dict[str, Any]
    ):
        """Handle maintenance predictions from Diagnosis Agent"""
        try:
            # Check if we've already sent this alert recently
            alert_key = f"maintenance_{user_id}_{vehicle_info.get('id', '')}"
            if self._is_alert_on_cooldown(alert_key):
                return
            
            # Get user contact info and preferences
            async for db in get_db():
                try:
                    user_info = await self._get_user_contact_info(db, user_id)
                    preferences = await notification_scheduler.get_user_preferences(db, user_id)
                    
                    # Prepare service details
                    service_details = {
                        'type': prediction_data.get('service_type', 'Maintenance'),
                        'due_date': prediction_data.get('due_date', 'Soon'),
                        'estimated_cost': prediction_data.get('estimated_cost', 'TBD'),
                        'description': prediction_data.get('description', 'Routine maintenance required'),
                        'booking_url': f"https://app.aivonity.com/booking?vehicle={vehicle_info.get('id', '')}"
                    }
                    
                    # Determine notification types based on urgency and preferences
                    notification_types = []
                    if preferences.push_enabled:
                        notification_types.append(NotificationType.PUSH)
                    if preferences.email_enabled:
                        notification_types.append(NotificationType.EMAIL)
                    if prediction_data.get('urgency') == 'high' and preferences.sms_enabled:
                        notification_types.append(NotificationType.SMS)
                    
                    # Send maintenance reminder
                    result = await notification_service.send_maintenance_reminder(
                        user_email=user_info.get('email', ''),
                        user_phone=user_info.get('phone', ''),
                        fcm_token=user_info.get('fcm_token', ''),
                        vehicle_info=vehicle_info,
                        service_details=service_details,
                        notification_types=notification_types
                    )
                    
                    # Mark alert as sent
                    self._mark_alert_sent(alert_key)
                    
                    logger.info(f"Maintenance notification sent to user {user_id}: {result}")
                    
                finally:
                    await db.close()
                    
        except Exception as e:
            logger.error(f"Failed to handle maintenance prediction: {e}")
    
    async def handle_security_event(
        self,
        user_id: str,
        vehicle_info: Dict[str, Any],
        security_event: Dict[str, Any]
    ):
        """Handle security events from UEBA Agent"""
        try:
            # Security alerts are always sent (no cooldown for critical events)
            severity = security_event.get('severity', 'medium')
            
            async for db in get_db():
                try:
                    user_info = await self._get_user_contact_info(db, user_id)
                    preferences = await notification_scheduler.get_user_preferences(db, user_id)
                    
                    # Prepare alert details
                    alert_details = {
                        'event_type': security_event.get('event_type', 'Security Event'),
                        'severity': severity,
                        'timestamp': security_event.get('timestamp', datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                        'location': security_event.get('location', 'Unknown'),
                        'description': security_event.get('description', 'Security event detected'),
                        'dashboard_url': f"https://app.aivonity.com/security?event={security_event.get('id', '')}"
                    }
                    
                    # Determine notification types (security alerts override some preferences)
                    notification_types = []
                    if preferences.push_enabled or severity in ['high', 'critical']:
                        notification_types.append(NotificationType.PUSH)
                    if preferences.email_enabled or severity in ['high', 'critical']:
                        notification_types.append(NotificationType.EMAIL)
                    if severity in ['high', 'critical']:  # Always send SMS for critical security
                        notification_types.append(NotificationType.SMS)
                    
                    # Send security alert
                    result = await notification_service.send_security_alert(
                        user_email=user_info.get('email', ''),
                        user_phone=user_info.get('phone', ''),
                        fcm_token=user_info.get('fcm_token', ''),
                        alert_details=alert_details,
                        notification_types=notification_types
                    )
                    
                    logger.info(f"Security alert sent to user {user_id}: {result}")
                    
                finally:
                    await db.close()
                    
        except Exception as e:
            logger.error(f"Failed to handle security event: {e}")
    
    async def handle_diagnostic_completion(
        self,
        user_id: str,
        vehicle_info: Dict[str, Any],
        diagnostic_results: Dict[str, Any]
    ):
        """Handle completed diagnostic scans"""
        try:
            # Only send diagnostic reports for significant changes or weekly summaries
            health_score = diagnostic_results.get('health_score', 85)
            has_issues = diagnostic_results.get('issues') is not None
            
            # Check if this is a scheduled report or significant change
            if not (has_issues or diagnostic_results.get('scheduled_report', False)):
                return
            
            async for db in get_db():
                try:
                    user_info = await self._get_user_contact_info(db, user_id)
                    preferences = await notification_scheduler.get_user_preferences(db, user_id)
                    
                    # Only send if user has email notifications enabled
                    if not preferences.email_enabled:
                        return
                    
                    # Prepare diagnostic data
                    diagnostics = {
                        'health_score': health_score,
                        'scan_date': diagnostic_results.get('scan_date', datetime.now().strftime('%Y-%m-%d')),
                        'engine_status': diagnostic_results.get('engine_status', 'Good'),
                        'transmission_status': diagnostic_results.get('transmission_status', 'Good'),
                        'brake_status': diagnostic_results.get('brake_status', 'Good'),
                        'battery_status': diagnostic_results.get('battery_status', 'Good'),
                        'issues': diagnostic_results.get('issues'),
                        'report_url': f"https://app.aivonity.com/diagnostics?report={diagnostic_results.get('id', '')}"
                    }
                    
                    # Send diagnostic report
                    result = await notification_service.send_diagnostic_report(
                        user_email=user_info.get('email', ''),
                        fcm_token=user_info.get('fcm_token', ''),
                        vehicle_info=vehicle_info,
                        diagnostics=diagnostics
                    )
                    
                    logger.info(f"Diagnostic report sent to user {user_id}: {result}")
                    
                finally:
                    await db.close()
                    
        except Exception as e:
            logger.error(f"Failed to handle diagnostic completion: {e}")
    
    async def handle_service_booking(
        self,
        user_id: str,
        booking_details: Dict[str, Any]
    ):
        """Handle service booking confirmations"""
        try:
            async for db in get_db():
                try:
                    user_info = await self._get_user_contact_info(db, user_id)
                    
                    # Prepare booking details
                    booking_data = {
                        'service_center': booking_details.get('service_center', 'AIVONITY Service Center'),
                        'appointment_date': booking_details.get('appointment_date', 'TBD'),
                        'service_type': booking_details.get('service_type', 'General Service'),
                        'duration': booking_details.get('duration', '2-3 hours'),
                        'confirmation_number': booking_details.get('confirmation_number', 'N/A'),
                        'vehicle_make': booking_details.get('vehicle_make', 'N/A'),
                        'vehicle_model': booking_details.get('vehicle_model', 'N/A'),
                        'license_plate': booking_details.get('license_plate', 'N/A'),
                        'manage_url': f"https://app.aivonity.com/bookings/{booking_details.get('id', '')}",
                        'contact_phone': '1-800-AIVONITY'
                    }
                    
                    # Send service confirmation
                    result = await notification_service.send_service_confirmation(
                        user_email=user_info.get('email', ''),
                        user_phone=user_info.get('phone', ''),
                        fcm_token=user_info.get('fcm_token', ''),
                        booking_details=booking_data
                    )
                    
                    # Schedule reminder notification 24 hours before appointment
                    if booking_details.get('appointment_datetime'):
                        reminder_time = booking_details['appointment_datetime'] - timedelta(hours=24)
                        if reminder_time > datetime.now():
                            await self._schedule_service_reminder(db, user_id, booking_data, reminder_time)
                    
                    logger.info(f"Service confirmation sent to user {user_id}: {result}")
                    
                finally:
                    await db.close()
                    
        except Exception as e:
            logger.error(f"Failed to handle service booking: {e}")
    
    async def handle_new_user_registration(
        self,
        user_id: str,
        user_info: Dict[str, Any]
    ):
        """Handle new user welcome notifications"""
        try:
            # Prepare user info
            welcome_data = {
                'name': user_info.get('name', 'valued customer'),
                'dashboard_url': 'https://app.aivonity.com/dashboard',
                'app_url': 'https://app.aivonity.com'
            }
            
            # Send welcome notifications
            result = await notification_service.send_welcome_notification(
                user_email=user_info.get('email', ''),
                user_phone=user_info.get('phone', ''),
                user_info=welcome_data
            )
            
            logger.info(f"Welcome notification sent to user {user_id}: {result}")
            
        except Exception as e:
            logger.error(f"Failed to handle new user registration: {e}")
    
    async def _schedule_service_reminder(
        self,
        db: AsyncSession,
        user_id: str,
        booking_details: Dict[str, Any],
        reminder_time: datetime
    ):
        """Schedule a service appointment reminder"""
        try:
            from .notification_service import NotificationTemplate
            
            template = NotificationTemplate(
                title="🔔 Service Reminder",
                body=f"Your appointment is tomorrow at {booking_details.get('service_center', 'AIVONITY Service')}",
                data={
                    "type": "service_reminder",
                    "confirmation_number": booking_details.get('confirmation_number', ''),
                    "action_url": booking_details.get('manage_url', '')
                },
                action_url=booking_details.get('manage_url')
            )
            
            await notification_scheduler.schedule_notification(
                db=db,
                user_id=user_id,
                notification_type=NotificationType.PUSH,
                template=template,
                scheduled_at=reminder_time
            )
            
        except Exception as e:
            logger.error(f"Failed to schedule service reminder: {e}")
    
    def _is_alert_on_cooldown(self, alert_key: str) -> bool:
        """Check if an alert is on cooldown to prevent spam"""
        if alert_key not in self.active_alerts:
            return False
        
        last_sent = self.active_alerts[alert_key]
        return (datetime.now() - last_sent).seconds < self.alert_cooldown
    
    def _mark_alert_sent(self, alert_key: str):
        """Mark an alert as sent"""
        self.active_alerts[alert_key] = datetime.now()
    
    async def _get_user_contact_info(self, db: AsyncSession, user_id: str) -> Dict[str, str]:
        """Get user contact information from database"""
        # In production, query actual user table
        # For now, return placeholder data
        return {
            "email": f"user{user_id}@example.com",
            "phone": "+1234567890",
            "fcm_token": f"fcm_token_{user_id}"
        }


# Global notification manager instance
notification_manager = NotificationManager()