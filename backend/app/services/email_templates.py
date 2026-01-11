"""
Email Templates for AIVONITY Notifications
"""

from typing import Dict, Any, Optional
from datetime import datetime


class EmailTemplates:
    """
    Email template manager for different notification types
    """
    
    @staticmethod
    def get_base_template() -> str:
        """Base HTML template for all emails"""
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AIVONITY Notification</title>
            <style>
                body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }}
                .container {{ max-width: 600px; margin: 0 auto; background-color: white; }}
                .header {{ background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 30px 20px; text-align: center; }}
                .header h1 {{ color: white; margin: 0; font-size: 28px; font-weight: bold; }}
                .content {{ padding: 30px 20px; }}
                .content h2 {{ color: #2C3E50; margin-bottom: 20px; font-size: 24px; }}
                .content p {{ color: #555; line-height: 1.6; margin-bottom: 15px; }}
                .alert-box {{ background-color: #FFF3CD; border: 1px solid #FFEAA7; border-radius: 8px; padding: 15px; margin: 20px 0; }}
                .alert-box.critical {{ background-color: #F8D7DA; border-color: #F5C6CB; }}
                .alert-box.success {{ background-color: #D4EDDA; border-color: #C3E6CB; }}
                .button {{ display: inline-block; background-color: #FF6B35; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; margin: 20px 0; }}
                .button:hover {{ background-color: #E55A2B; }}
                .footer {{ background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; }}
                .vehicle-info {{ background-color: #F8F9FA; border-radius: 8px; padding: 15px; margin: 15px 0; }}
                .metric {{ display: inline-block; margin: 10px 15px 10px 0; }}
                .metric-label {{ font-weight: bold; color: #2C3E50; }}
                .metric-value {{ color: #FF6B35; font-weight: bold; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚗 AIVONITY</h1>
                </div>
                <div class="content">
                    {content}
                </div>
                <div class="footer">
                    <p>This is an automated message from AIVONITY. Please do not reply to this email.</p>
                    <p>© 2024 AIVONITY - Intelligent Vehicle Assistant Ecosystem</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    @staticmethod
    def maintenance_reminder(vehicle_info: Dict[str, Any], service_details: Dict[str, Any]) -> str:
        """Maintenance reminder email template"""
        content = f"""
        <h2>🔧 Maintenance Reminder</h2>
        <p>Your vehicle is due for scheduled maintenance. Don't let small issues become big problems!</p>
        
        <div class="vehicle-info">
            <h3>Vehicle Information</h3>
            <div class="metric">
                <span class="metric-label">Vehicle:</span>
                <span class="metric-value">{vehicle_info.get('make', 'N/A')} {vehicle_info.get('model', 'N/A')}</span>
            </div>
            <div class="metric">
                <span class="metric-label">Year:</span>
                <span class="metric-value">{vehicle_info.get('year', 'N/A')}</span>
            </div>
            <div class="metric">
                <span class="metric-label">Mileage:</span>
                <span class="metric-value">{vehicle_info.get('mileage', 'N/A')} miles</span>
            </div>
        </div>
        
        <div class="alert-box">
            <h3>Recommended Service</h3>
            <p><strong>Service Type:</strong> {service_details.get('type', 'General Maintenance')}</p>
            <p><strong>Due Date:</strong> {service_details.get('due_date', 'Soon')}</p>
            <p><strong>Estimated Cost:</strong> ${service_details.get('estimated_cost', 'TBD')}</p>
            <p><strong>Description:</strong> {service_details.get('description', 'Routine maintenance service')}</p>
        </div>
        
        <a href="{service_details.get('booking_url', '#')}" class="button">Schedule Service</a>
        
        <p>Regular maintenance keeps your vehicle running safely and efficiently. Schedule your service today!</p>
        """
        
        return EmailTemplates.get_base_template().format(content=content)
    
    @staticmethod
    def security_alert(alert_details: Dict[str, Any]) -> str:
        """Security alert email template"""
        severity = alert_details.get('severity', 'medium')
        alert_class = 'critical' if severity == 'high' else ''
        
        content = f"""
        <h2>🚨 Security Alert</h2>
        <p>We've detected a security event that requires your attention.</p>
        
        <div class="alert-box {alert_class}">
            <h3>Alert Details</h3>
            <p><strong>Event Type:</strong> {alert_details.get('event_type', 'Security Event')}</p>
            <p><strong>Severity:</strong> {alert_details.get('severity', 'Medium').upper()}</p>
            <p><strong>Time:</strong> {alert_details.get('timestamp', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))}</p>
            <p><strong>Location:</strong> {alert_details.get('location', 'Unknown')}</p>
            <p><strong>Description:</strong> {alert_details.get('description', 'Security event detected')}</p>
        </div>
        
        <p><strong>Recommended Actions:</strong></p>
        <ul>
            <li>Verify your vehicle's location and status</li>
            <li>Check for any unauthorized access attempts</li>
            <li>Contact support if you notice anything suspicious</li>
        </ul>
        
        <a href="{alert_details.get('dashboard_url', '#')}" class="button">View Dashboard</a>
        
        <p>Your vehicle's security is our priority. If you have any concerns, please contact our support team immediately.</p>
        """
        
        return EmailTemplates.get_base_template().format(content=content)
    
    @staticmethod
    def diagnostic_report(vehicle_info: Dict[str, Any], diagnostics: Dict[str, Any]) -> str:
        """Diagnostic report email template"""
        health_score = diagnostics.get('health_score', 85)
        health_class = 'success' if health_score >= 80 else 'critical' if health_score < 60 else ''
        
        content = f"""
        <h2>📊 Vehicle Diagnostic Report</h2>
        <p>Here's your latest vehicle health report with AI-powered insights.</p>
        
        <div class="vehicle-info">
            <h3>Vehicle Overview</h3>
            <div class="metric">
                <span class="metric-label">Vehicle:</span>
                <span class="metric-value">{vehicle_info.get('make', 'N/A')} {vehicle_info.get('model', 'N/A')}</span>
            </div>
            <div class="metric">
                <span class="metric-label">Health Score:</span>
                <span class="metric-value">{health_score}%</span>
            </div>
            <div class="metric">
                <span class="metric-label">Last Scan:</span>
                <span class="metric-value">{diagnostics.get('scan_date', 'Today')}</span>
            </div>
        </div>
        
        <div class="alert-box {health_class}">
            <h3>System Status</h3>
            <p><strong>Engine:</strong> {diagnostics.get('engine_status', 'Good')}</p>
            <p><strong>Transmission:</strong> {diagnostics.get('transmission_status', 'Good')}</p>
            <p><strong>Brakes:</strong> {diagnostics.get('brake_status', 'Good')}</p>
            <p><strong>Battery:</strong> {diagnostics.get('battery_status', 'Good')}</p>
        </div>
        
        {f'<div class="alert-box critical"><h3>Issues Detected</h3><p>{diagnostics.get("issues", "")}</p></div>' if diagnostics.get('issues') else ''}
        
        <a href="{diagnostics.get('report_url', '#')}" class="button">View Full Report</a>
        
        <p>Our AI continuously monitors your vehicle's health to prevent issues before they occur.</p>
        """
        
        return EmailTemplates.get_base_template().format(content=content)
    
    @staticmethod
    def service_confirmation(booking_details: Dict[str, Any]) -> str:
        """Service booking confirmation email template"""
        content = f"""
        <h2>✅ Service Appointment Confirmed</h2>
        <p>Your service appointment has been successfully scheduled. We look forward to serving you!</p>
        
        <div class="alert-box success">
            <h3>Appointment Details</h3>
            <p><strong>Service Center:</strong> {booking_details.get('service_center', 'AIVONITY Service Center')}</p>
            <p><strong>Date & Time:</strong> {booking_details.get('appointment_date', 'TBD')}</p>
            <p><strong>Service Type:</strong> {booking_details.get('service_type', 'General Service')}</p>
            <p><strong>Estimated Duration:</strong> {booking_details.get('duration', '2-3 hours')}</p>
            <p><strong>Confirmation #:</strong> {booking_details.get('confirmation_number', 'N/A')}</p>
        </div>
        
        <div class="vehicle-info">
            <h3>Vehicle Information</h3>
            <p><strong>Vehicle:</strong> {booking_details.get('vehicle_make', 'N/A')} {booking_details.get('vehicle_model', 'N/A')}</p>
            <p><strong>License Plate:</strong> {booking_details.get('license_plate', 'N/A')}</p>
        </div>
        
        <p><strong>What to Bring:</strong></p>
        <ul>
            <li>Vehicle registration and insurance documents</li>
            <li>Any previous service records</li>
            <li>List of any concerns or issues you've noticed</li>
        </ul>
        
        <a href="{booking_details.get('manage_url', '#')}" class="button">Manage Appointment</a>
        
        <p>Need to reschedule or have questions? Contact us at {booking_details.get('contact_phone', '1-800-AIVONITY')}.</p>
        """
        
        return EmailTemplates.get_base_template().format(content=content)
    
    @staticmethod
    def welcome_email(user_info: Dict[str, Any]) -> str:
        """Welcome email for new users"""
        content = f"""
        <h2>🎉 Welcome to AIVONITY!</h2>
        <p>Thank you for joining the future of intelligent vehicle management, {user_info.get('name', 'valued customer')}!</p>
        
        <div class="alert-box success">
            <h3>Your Account is Ready</h3>
            <p>You can now access all AIVONITY features including:</p>
            <ul>
                <li>🔍 Real-time vehicle diagnostics</li>
                <li>🤖 AI-powered maintenance predictions</li>
                <li>📱 Smart notifications and alerts</li>
                <li>🗓️ Intelligent service scheduling</li>
                <li>💬 24/7 AI assistant support</li>
            </ul>
        </div>
        
        <a href="{user_info.get('dashboard_url', '#')}" class="button">Access Your Dashboard</a>
        
        <p><strong>Getting Started:</strong></p>
        <ol>
            <li>Complete your vehicle profile</li>
            <li>Connect your vehicle's diagnostic system</li>
            <li>Set up your notification preferences</li>
            <li>Schedule your first AI health check</li>
        </ol>
        
        <p>Our AI is already learning about your vehicle to provide personalized insights and recommendations.</p>
        """
        
        return EmailTemplates.get_base_template().format(content=content)
    
    @staticmethod
    def custom_notification(title: str, message: str, action_url: Optional[str] = None) -> str:
        """Generic custom notification template"""
        action_button = f'<a href="{action_url}" class="button">Take Action</a>' if action_url else ''
        
        content = f"""
        <h2>{title}</h2>
        <p>{message}</p>
        {action_button}
        """
        
        return EmailTemplates.get_base_template().format(content=content)