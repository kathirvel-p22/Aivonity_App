"""
SMS Templates for AIVONITY Notifications
"""

from typing import Dict, Any
from datetime import datetime


class SMSTemplates:
    """
    SMS template manager for different notification types
    """
    
    @staticmethod
    def maintenance_reminder(vehicle_info: Dict[str, Any], service_details: Dict[str, Any]) -> str:
        """Maintenance reminder SMS template"""
        vehicle = f"{vehicle_info.get('make', '')} {vehicle_info.get('model', '')}".strip()
        service_type = service_details.get('type', 'maintenance')
        due_date = service_details.get('due_date', 'soon')
        
        return f"""🔧 AIVONITY MAINTENANCE ALERT

Your {vehicle} is due for {service_type} by {due_date}.

Don't wait - schedule now to avoid costly repairs!

Book: {service_details.get('booking_url', 'Call 1-800-AIVONITY')}

Reply STOP to opt out."""
    
    @staticmethod
    def security_alert(alert_details: Dict[str, Any]) -> str:
        """Security alert SMS template"""
        event_type = alert_details.get('event_type', 'security event')
        severity = alert_details.get('severity', 'medium').upper()
        location = alert_details.get('location', 'unknown location')
        
        return f"""🚨 AIVONITY SECURITY ALERT

{severity} PRIORITY: {event_type} detected at {location}

Time: {alert_details.get('timestamp', datetime.now().strftime('%H:%M'))}

Check your vehicle immediately and contact support if needed.

Dashboard: {alert_details.get('dashboard_url', 'app.aivonity.com')}

Reply STOP to opt out."""
    
    @staticmethod
    def critical_diagnostic(vehicle_info: Dict[str, Any], issue_details: Dict[str, Any]) -> str:
        """Critical diagnostic issue SMS template"""
        vehicle = f"{vehicle_info.get('make', '')} {vehicle_info.get('model', '')}".strip()
        issue = issue_details.get('issue', 'critical system issue')
        
        return f"""⚠️ AIVONITY CRITICAL ALERT

{vehicle}: {issue} detected!

IMMEDIATE ACTION REQUIRED
- Stop driving safely if possible
- Contact roadside assistance: {issue_details.get('roadside_number', '1-800-ROADSIDE')}

Details: {issue_details.get('report_url', 'app.aivonity.com')}

Reply STOP to opt out."""
    
    @staticmethod
    def service_confirmation(booking_details: Dict[str, Any]) -> str:
        """Service booking confirmation SMS template"""
        service_center = booking_details.get('service_center', 'AIVONITY Service')
        appointment_date = booking_details.get('appointment_date', 'TBD')
        confirmation_number = booking_details.get('confirmation_number', 'N/A')
        
        return f"""✅ AIVONITY SERVICE CONFIRMED

Appointment: {appointment_date}
Location: {service_center}
Confirmation: {confirmation_number}

Bring: Registration, insurance, service history

Manage: {booking_details.get('manage_url', 'app.aivonity.com')}
Call: {booking_details.get('contact_phone', '1-800-AIVONITY')}

Reply STOP to opt out."""
    
    @staticmethod
    def service_reminder(booking_details: Dict[str, Any]) -> str:
        """Service appointment reminder SMS template"""
        appointment_date = booking_details.get('appointment_date', 'tomorrow')
        service_center = booking_details.get('service_center', 'AIVONITY Service')
        
        return f"""🔔 AIVONITY SERVICE REMINDER

Your appointment is {appointment_date} at {service_center}

Confirmation: {booking_details.get('confirmation_number', 'N/A')}

Need to reschedule? {booking_details.get('manage_url', 'Call 1-800-AIVONITY')}

Reply STOP to opt out."""
    
    @staticmethod
    def battery_low_alert(vehicle_info: Dict[str, Any], battery_details: Dict[str, Any]) -> str:
        """Low battery alert SMS template"""
        vehicle = f"{vehicle_info.get('make', '')} {vehicle_info.get('model', '')}".strip()
        battery_level = battery_details.get('level', 'low')
        
        return f"""🔋 AIVONITY BATTERY ALERT

{vehicle}: Battery level {battery_level}

Risk of no-start condition. Consider:
- Jump start kit
- Professional inspection
- Battery replacement

Find service: {battery_details.get('service_url', 'app.aivonity.com')}

Reply STOP to opt out."""
    
    @staticmethod
    def fuel_low_alert(vehicle_info: Dict[str, Any], fuel_details: Dict[str, Any]) -> str:
        """Low fuel alert SMS template"""
        vehicle = f"{vehicle_info.get('make', '')} {vehicle_info.get('model', '')}".strip()
        fuel_level = fuel_details.get('level', 'low')
        range_remaining = fuel_details.get('range', 'limited')
        
        return f"""⛽ AIVONITY FUEL ALERT

{vehicle}: Fuel {fuel_level}
Range: {range_remaining}

Nearest stations: {fuel_details.get('stations_url', 'app.aivonity.com')}

Reply STOP to opt out."""
    
    @staticmethod
    def trip_summary(trip_details: Dict[str, Any]) -> str:
        """Trip summary SMS template"""
        distance = trip_details.get('distance', 'N/A')
        duration = trip_details.get('duration', 'N/A')
        fuel_used = trip_details.get('fuel_used', 'N/A')
        
        return f"""📊 AIVONITY TRIP SUMMARY

Distance: {distance}
Duration: {duration}
Fuel used: {fuel_used}
Avg efficiency: {trip_details.get('efficiency', 'N/A')}

Full report: {trip_details.get('report_url', 'app.aivonity.com')}

Reply STOP to opt out."""
    
    @staticmethod
    def welcome_sms(user_info: Dict[str, Any]) -> str:
        """Welcome SMS for new users"""
        name = user_info.get('name', 'valued customer')
        
        return f"""🎉 Welcome to AIVONITY, {name}!

Your intelligent vehicle assistant is ready. Get started:

1. Download the app
2. Connect your vehicle
3. Set up alerts

App: {user_info.get('app_url', 'app.aivonity.com')}
Support: 1-800-AIVONITY

Reply STOP to opt out."""
    
    @staticmethod
    def custom_alert(title: str, message: str, action_url: str = None) -> str:
        """Generic custom alert SMS template"""
        action_text = f"\n\nMore info: {action_url}" if action_url else ""
        
        return f"""🚗 AIVONITY ALERT

{title}

{message}{action_text}

Reply STOP to opt out."""
    
    @staticmethod
    def opt_out_confirmation() -> str:
        """SMS opt-out confirmation"""
        return """✅ AIVONITY SMS UNSUBSCRIBED

You will no longer receive SMS notifications.

Critical safety alerts may still be sent.

To resubscribe, visit app.aivonity.com or text START."""
    
    @staticmethod
    def opt_in_confirmation() -> str:
        """SMS opt-in confirmation"""
        return """✅ AIVONITY SMS SUBSCRIBED

You will now receive important vehicle alerts via SMS.

Manage preferences: app.aivonity.com
Unsubscribe: Reply STOP"""
    
    @staticmethod
    def validate_sms_length(message: str) -> bool:
        """Validate SMS message length (160 characters for single SMS)"""
        return len(message) <= 160
    
    @staticmethod
    def truncate_sms(message: str, max_length: int = 160) -> str:
        """Truncate SMS message to fit length limit"""
        if len(message) <= max_length:
            return message
        
        # Reserve space for "..." at the end
        truncated = message[:max_length - 3] + "..."
        return truncated