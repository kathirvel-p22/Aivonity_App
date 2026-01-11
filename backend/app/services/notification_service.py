"""
Notification Service for AIVONITY
Handles Firebase Cloud Messaging, email, and SMS notifications
"""

import asyncio
import json
import logging
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from enum import Enum

import firebase_admin
from firebase_admin import credentials, messaging
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from twilio.rest import Client as TwilioClient
from pydantic import BaseModel

from .email_templates import EmailTemplates
from .sms_templates import SMSTemplates

logger = logging.getLogger(__name__)


class NotificationType(str, Enum):
    PUSH = "push"
    EMAIL = "email"
    SMS = "sms"


class NotificationPriority(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    CRITICAL = "critical"


class NotificationTemplate(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    action_url: Optional[str] = None


class NotificationService:
    """
    Centralized notification service handling FCM, email, and SMS
    """
    
    def __init__(self):
        self.firebase_app = None
        self.sendgrid_client = None
        self.twilio_client = None
        self._initialize_services()
    
    def _initialize_services(self):
        """Initialize external notification services"""
        try:
            # Initialize Firebase Admin SDK
            if not firebase_admin._apps:
                try:
                    firebase_creds = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
                    if os.path.exists(firebase_creds):
                        cred = credentials.Certificate(firebase_creds)
                        self.firebase_app = firebase_admin.initialize_app(cred)
                    else:
                        logger.warning("Firebase credentials not found, push notifications disabled")
                except Exception as e:
                    logger.warning(f"Firebase initialization failed: {e}")
            
            # Initialize SendGrid
            sendgrid_key = os.getenv("SENDGRID_API_KEY")
            if sendgrid_key:
                self.sendgrid_client = SendGridAPIClient(api_key=sendgrid_key)
            else:
                logger.warning("SendGrid API key not configured")
            
            # Initialize Twilio
            twilio_sid = os.getenv("TWILIO_ACCOUNT_SID")
            twilio_token = os.getenv("TWILIO_AUTH_TOKEN")
            if twilio_sid and twilio_token:
                self.twilio_client = TwilioClient(twilio_sid, twilio_token)
            else:
                logger.warning("Twilio credentials not configured")
                
        except Exception as e:
            logger.error(f"Failed to initialize notification services: {e}")   
 
    async def send_push_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Send Firebase Cloud Messaging push notification"""
        if not self.firebase_app or not fcm_token:
            return {"status": "skipped", "reason": "fcm_not_configured"}
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                token=fcm_token,
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        icon="ic_notification",
                        color="#FF6B35",
                        sound="default"
                    )
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound="default",
                            badge=1
                        )
                    )
                )
            )
            
            response = messaging.send(message)
            logger.info(f"Push notification sent successfully: {response}")
            
            return {
                "status": "success",
                "message_id": response,
                "platform": "fcm"
            }
            
        except messaging.UnregisteredError:
            logger.warning(f"FCM token invalid: {fcm_token}")
            return {"status": "failed", "error": "invalid_token"}
        except Exception as e:
            logger.error(f"FCM send failed: {e}")
            return {"status": "failed", "error": str(e)}    

    async def send_email_notification(
        self,
        to_email: str,
        subject: str,
        body: str,
        action_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send email notification via SendGrid"""
        if not self.sendgrid_client:
            return {"status": "skipped", "reason": "email_not_configured"}
        
        try:
            html_content = self._format_email_body(subject, body, action_url)
            
            message = Mail(
                from_email="noreply@aivonity.com",
                to_emails=to_email,
                subject=subject,
                html_content=html_content
            )
            
            response = self.sendgrid_client.send(message)
            logger.info(f"Email sent successfully to {to_email}")
            
            return {
                "status": "success",
                "message_id": response.headers.get("X-Message-Id"),
                "platform": "sendgrid"
            }
            
        except Exception as e:
            logger.error(f"Email send failed: {e}")
            return {"status": "failed", "error": str(e)}
    
    async def send_sms_notification(
        self,
        to_phone: str,
        message: str
    ) -> Dict[str, Any]:
        """Send SMS notification via Twilio"""
        if not self.twilio_client:
            return {"status": "skipped", "reason": "sms_not_configured"}
        
        try:
            from_phone = os.getenv("TWILIO_PHONE_NUMBER", "+1234567890")
            
            message_obj = self.twilio_client.messages.create(
                body=message,
                from_=from_phone,
                to=to_phone
            )
            
            logger.info(f"SMS sent successfully to {to_phone}")
            
            return {
                "status": "success",
                "message_id": message_obj.sid,
                "platform": "twilio"
            }
            
        except Exception as e:
            logger.error(f"SMS send failed: {e}")
            return {"status": "failed", "error": str(e)}    

    def _format_email_body(self, title: str, body: str, action_url: Optional[str] = None) -> str:
        """Format email body with HTML template"""
        action_button = ""
        if action_url:
            action_button = f'''
            <a href="{action_url}" 
               style="background-color: #FF6B35; color: white; padding: 10px 20px; 
                      text-decoration: none; border-radius: 5px; display: inline-block; 
                      margin-top: 20px;">
                View Details
            </a>
            '''
        
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #FF6B35; padding: 20px; text-align: center;">
                <h1 style="color: white; margin: 0;">AIVONITY</h1>
            </div>
            <div style="padding: 20px;">
                <h2 style="color: #333;">{title}</h2>
                <p style="color: #666; line-height: 1.6;">{body}</p>
                {action_button}
            </div>
            <div style="background-color: #f8f9fa; padding: 15px; text-align: center; 
                        font-size: 12px; color: #666;">
                <p>This is an automated message from AIVONITY. Please do not reply to this email.</p>
            </div>
        </body>
        </html>
        """
        return html_body
    
    async def send_bulk_notification(
        self,
        recipients: List[Dict[str, str]],
        template: NotificationTemplate,
        notification_type: NotificationType = NotificationType.PUSH
    ) -> Dict[str, Any]:
        """Send notification to multiple recipients"""
        results = {
            "total": len(recipients),
            "success": 0,
            "failed": 0,
            "skipped": 0,
            "errors": []
        }
        
        for recipient in recipients:
            try:
                if notification_type == NotificationType.PUSH:
                    result = await self.send_push_notification(
                        recipient.get("fcm_token", ""),
                        template.title,
                        template.body,
                        template.data
                    )
                elif notification_type == NotificationType.EMAIL:
                    result = await self.send_email_notification(
                        recipient.get("email", ""),
                        template.title,
                        template.body,
                        template.action_url
                    )
                elif notification_type == NotificationType.SMS:
                    result = await self.send_sms_notification(
                        recipient.get("phone", ""),
                        f"{template.title}\n\n{template.body}"
                    )
                
                if result["status"] == "success":
                    results["success"] += 1
                elif result["status"] == "skipped":
                    results["skipped"] += 1
                else:
                    results["failed"] += 1
                    results["errors"].append({
                        "recipient": recipient,
                        "error": result.get("error", "unknown")
                    })
                    
            except Exception as e:
                results["failed"] += 1
                results["errors"].append({
                    "recipient": recipient,
                    "error": str(e)
                })
        
        return results


# Global notification service instance
notification_service = NotificationService()  
  
    async def send_maintenance_reminder(
        self,
        user_email: str,
        user_phone: str,
        fcm_token: str,
        vehicle_info: Dict[str, Any],
        service_details: Dict[str, Any],
        notification_types: List[NotificationType] = None
    ) -> Dict[str, Any]:
        """Send maintenance reminder via multiple channels"""
        if notification_types is None:
            notification_types = [NotificationType.PUSH, NotificationType.EMAIL]
        
        results = {}
        
        # Send push notification
        if NotificationType.PUSH in notification_types and fcm_token:
            push_result = await self.send_push_notification(
                fcm_token,
                "🔧 Maintenance Due",
                f"Your {vehicle_info.get('make', '')} {vehicle_info.get('model', '')} needs {service_details.get('type', 'service')}",
                {
                    "type": "maintenance",
                    "vehicle_id": vehicle_info.get('id', ''),
                    "service_type": service_details.get('type', ''),
                    "action_url": service_details.get('booking_url', '')
                }
            )
            results['push'] = push_result
        
        # Send email notification
        if NotificationType.EMAIL in notification_types and user_email:
            email_html = EmailTemplates.maintenance_reminder(vehicle_info, service_details)
            email_result = await self.send_email_notification(
                user_email,
                f"🔧 Maintenance Due - {vehicle_info.get('make', '')} {vehicle_info.get('model', '')}",
                email_html,
                service_details.get('booking_url')
            )
            results['email'] = email_result
        
        # Send SMS notification
        if NotificationType.SMS in notification_types and user_phone:
            sms_message = SMSTemplates.maintenance_reminder(vehicle_info, service_details)
            sms_result = await self.send_sms_notification(user_phone, sms_message)
            results['sms'] = sms_result
        
        return results
    
    async def send_security_alert(
        self,
        user_email: str,
        user_phone: str,
        fcm_token: str,
        alert_details: Dict[str, Any],
        notification_types: List[NotificationType] = None
    ) -> Dict[str, Any]:
        """Send security alert via multiple channels"""
        if notification_types is None:
            notification_types = [NotificationType.PUSH, NotificationType.EMAIL, NotificationType.SMS]
        
        results = {}
        
        # Send push notification
        if NotificationType.PUSH in notification_types and fcm_token:
            push_result = await self.send_push_notification(
                fcm_token,
                "🚨 Security Alert",
                f"{alert_details.get('event_type', 'Security event')} detected",
                {
                    "type": "security",
                    "severity": alert_details.get('severity', 'medium'),
                    "event_type": alert_details.get('event_type', ''),
                    "action_url": alert_details.get('dashboard_url', '')
                }
            )
            results['push'] = push_result
        
        # Send email notification
        if NotificationType.EMAIL in notification_types and user_email:
            email_html = EmailTemplates.security_alert(alert_details)
            email_result = await self.send_email_notification(
                user_email,
                f"🚨 Security Alert - {alert_details.get('event_type', 'Security Event')}",
                email_html,
                alert_details.get('dashboard_url')
            )
            results['email'] = email_result
        
        # Send SMS notification (for high severity alerts)
        if NotificationType.SMS in notification_types and user_phone and alert_details.get('severity') in ['high', 'critical']:
            sms_message = SMSTemplates.security_alert(alert_details)
            sms_result = await self.send_sms_notification(user_phone, sms_message)
            results['sms'] = sms_result
        
        return results
    
    async def send_diagnostic_report(
        self,
        user_email: str,
        fcm_token: str,
        vehicle_info: Dict[str, Any],
        diagnostics: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Send diagnostic report via email and push"""
        results = {}
        
        # Send push notification
        if fcm_token:
            health_score = diagnostics.get('health_score', 85)
            push_result = await self.send_push_notification(
                fcm_token,
                "📊 Vehicle Health Report",
                f"Health Score: {health_score}% - Tap to view full report",
                {
                    "type": "diagnostic",
                    "health_score": str(health_score),
                    "vehicle_id": vehicle_info.get('id', ''),
                    "action_url": diagnostics.get('report_url', '')
                }
            )
            results['push'] = push_result
        
        # Send email notification
        if user_email:
            email_html = EmailTemplates.diagnostic_report(vehicle_info, diagnostics)
            email_result = await self.send_email_notification(
                user_email,
                f"📊 Vehicle Diagnostic Report - {vehicle_info.get('make', '')} {vehicle_info.get('model', '')}",
                email_html,
                diagnostics.get('report_url')
            )
            results['email'] = email_result
        
        return results
    
    async def send_service_confirmation(
        self,
        user_email: str,
        user_phone: str,
        fcm_token: str,
        booking_details: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Send service booking confirmation"""
        results = {}
        
        # Send push notification
        if fcm_token:
            push_result = await self.send_push_notification(
                fcm_token,
                "✅ Service Confirmed",
                f"Appointment scheduled for {booking_details.get('appointment_date', 'TBD')}",
                {
                    "type": "service_confirmation",
                    "confirmation_number": booking_details.get('confirmation_number', ''),
                    "action_url": booking_details.get('manage_url', '')
                }
            )
            results['push'] = push_result
        
        # Send email notification
        if user_email:
            email_html = EmailTemplates.service_confirmation(booking_details)
            email_result = await self.send_email_notification(
                user_email,
                f"✅ Service Appointment Confirmed - {booking_details.get('confirmation_number', '')}",
                email_html,
                booking_details.get('manage_url')
            )
            results['email'] = email_result
        
        # Send SMS confirmation
        if user_phone:
            sms_message = SMSTemplates.service_confirmation(booking_details)
            sms_result = await self.send_sms_notification(user_phone, sms_message)
            results['sms'] = sms_result
        
        return results
    
    async def send_welcome_notification(
        self,
        user_email: str,
        user_phone: str,
        user_info: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Send welcome notification to new users"""
        results = {}
        
        # Send welcome email
        if user_email:
            email_html = EmailTemplates.welcome_email(user_info)
            email_result = await self.send_email_notification(
                user_email,
                "🎉 Welcome to AIVONITY - Your Intelligent Vehicle Assistant",
                email_html,
                user_info.get('dashboard_url')
            )
            results['email'] = email_result
        
        # Send welcome SMS
        if user_phone:
            sms_message = SMSTemplates.welcome_sms(user_info)
            sms_result = await self.send_sms_notification(user_phone, sms_message)
            results['sms'] = sms_result
        
        return results