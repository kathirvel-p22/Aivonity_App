// Test data fixtures for AIVONITY testing

/// Test data fixtures and constants
class TestData {
  // User test data
  static const Map<String, dynamic> validUser = {
    'email': 'test@aivonity.com',
    'password': 'TestPassword123!',
    'name': 'Test User',
    'phone': '+1234567890',
  };

  static const Map<String, dynamic> invalidUser = {
    'email': 'invalid-email',
    'password': '123',
    'name': '',
    'phone': 'invalid-phone',
  };

  // Vehicle test data
  static const Map<String, dynamic> validVehicle = {
    'make': 'Tesla',
    'model': 'Model 3',
    'year': 2023,
    'vin': 'TEST123456789',
    'mileage': 15000,
    'fuel_type': 'electric',
  };

  static const Map<String, dynamic> invalidVehicle = {
    'make': '',
    'model': '',
    'year': 1800,
    'vin': '123',
    'mileage': -1000,
  };

  // Telemetry test data
  static const Map<String, dynamic> normalTelemetry = {
    'engine_temp': 85.5,
    'oil_pressure': 45.2,
    'battery_voltage': 12.6,
    'rpm': 2500,
    'speed': 65.0,
    'fuel_level': 75.0,
    'location': {'latitude': 37.7749, 'longitude': -122.4194},
  };

  static const Map<String, dynamic> criticalTelemetry = {
    'engine_temp': 125.0, // Critical temperature
    'oil_pressure': 15.0, // Low pressure
    'battery_voltage': 10.5, // Low voltage
    'rpm': 5500, // High RPM
    'speed': 65.0,
    'fuel_level': 5.0, // Very low fuel
    'location': {'latitude': 37.7749, 'longitude': -122.4194},
  };

  static const Map<String, dynamic> warningTelemetry = {
    'engine_temp': 95.0, // Elevated temperature
    'oil_pressure': 25.0, // Lower pressure
    'battery_voltage': 11.8, // Lower voltage
    'rpm': 4000, // Higher RPM
    'speed': 65.0,
    'fuel_level': 15.0, // Low fuel
    'location': {'latitude': 37.7749, 'longitude': -122.4194},
  };

  // Chat test data
  static const List<Map<String, String>> chatTestCases = [
    {'input': 'Hello', 'expectedType': 'greeting'},
    {'input': 'What is my vehicle health?', 'expectedType': 'health_inquiry'},
    {
      'input': 'When should I schedule maintenance?',
      'expectedType': 'maintenance_inquiry',
    },
    {
      'input': 'Find service centers near me',
      'expectedType': 'location_inquiry',
    },
    {'input': 'My engine is making noise', 'expectedType': 'problem_report'},
  ];

  // Service center test data
  static const List<Map<String, dynamic>> serviceCenters = [
    {
      'id': 'sc_001',
      'name': 'Tesla Service Center Downtown',
      'address': '123 Main St, San Francisco, CA',
      'phone': '+1-555-0123',
      'rating': 4.5,
      'services': ['maintenance', 'repair', 'inspection'],
      'location': {'latitude': 37.7849, 'longitude': -122.4094},
      'hours': {
        'monday': '8:00 AM - 6:00 PM',
        'tuesday': '8:00 AM - 6:00 PM',
        'wednesday': '8:00 AM - 6:00 PM',
        'thursday': '8:00 AM - 6:00 PM',
        'friday': '8:00 AM - 6:00 PM',
        'saturday': '9:00 AM - 4:00 PM',
        'sunday': 'Closed',
      },
    },
    {
      'id': 'sc_002',
      'name': 'AutoCare Plus',
      'address': '456 Oak Ave, San Francisco, CA',
      'phone': '+1-555-0456',
      'rating': 4.2,
      'services': ['maintenance', 'repair', 'towing'],
      'location': {'latitude': 37.7649, 'longitude': -122.4294},
      'hours': {
        'monday': '7:00 AM - 7:00 PM',
        'tuesday': '7:00 AM - 7:00 PM',
        'wednesday': '7:00 AM - 7:00 PM',
        'thursday': '7:00 AM - 7:00 PM',
        'friday': '7:00 AM - 7:00 PM',
        'saturday': '8:00 AM - 5:00 PM',
        'sunday': '10:00 AM - 3:00 PM',
      },
    },
  ];

  // Notification test data
  static const Map<String, dynamic> criticalAlert = {
    'type': 'critical',
    'title': 'Critical Engine Alert',
    'message': 'Engine temperature is critically high. Pull over safely.',
    'priority': 'high',
    'category': 'safety',
  };

  static const Map<String, dynamic> maintenanceReminder = {
    'type': 'maintenance',
    'title': 'Maintenance Due',
    'message': 'Your vehicle is due for scheduled maintenance.',
    'priority': 'medium',
    'category': 'maintenance',
  };

  static const Map<String, dynamic> infoNotification = {
    'type': 'info',
    'title': 'Trip Summary',
    'message': 'Your recent trip has been recorded.',
    'priority': 'low',
    'category': 'info',
  };

  // Analytics test data
  static const Map<String, dynamic> performanceMetrics = {
    'fuel_efficiency': 28.5,
    'average_speed': 45.2,
    'total_distance': 1250.0,
    'engine_hours': 45.5,
    'maintenance_score': 85,
    'safety_score': 92,
  };

  static const List<Map<String, dynamic>> trendData = [
    {'date': '2024-01-01', 'fuel_efficiency': 28.0, 'maintenance_score': 80},
    {'date': '2024-01-02', 'fuel_efficiency': 28.5, 'maintenance_score': 82},
    {'date': '2024-01-03', 'fuel_efficiency': 29.0, 'maintenance_score': 85},
    {'date': '2024-01-04', 'fuel_efficiency': 28.8, 'maintenance_score': 87},
    {'date': '2024-01-05', 'fuel_efficiency': 29.2, 'maintenance_score': 85},
  ];

  // Error test cases
  static const Map<String, dynamic> networkError = {
    'type': 'network',
    'message': 'Network connection failed',
    'code': 'NETWORK_ERROR',
  };

  static const Map<String, dynamic> authError = {
    'type': 'authentication',
    'message': 'Authentication failed',
    'code': 'AUTH_ERROR',
  };

  static const Map<String, dynamic> validationError = {
    'type': 'validation',
    'message': 'Invalid input data',
    'code': 'VALIDATION_ERROR',
    'details': {
      'email': 'Invalid email format',
      'password': 'Password too short',
    },
  };

  // Performance test data
  static const Map<String, dynamic> performanceThresholds = {
    'app_startup_time': 3000, // milliseconds
    'screen_transition_time': 500, // milliseconds
    'api_response_time': 2000, // milliseconds
    'websocket_connection_time': 1000, // milliseconds
    'memory_usage_limit': 100, // MB
    'cpu_usage_limit': 50, // percentage
  };

  // Load test scenarios
  static const List<Map<String, dynamic>> loadTestScenarios = [
    {
      'name': 'Normal Load',
      'concurrent_users': 10,
      'duration_minutes': 5,
      'requests_per_second': 5,
    },
    {
      'name': 'Peak Load',
      'concurrent_users': 50,
      'duration_minutes': 10,
      'requests_per_second': 20,
    },
    {
      'name': 'Stress Load',
      'concurrent_users': 100,
      'duration_minutes': 15,
      'requests_per_second': 50,
    },
  ];

  // API endpoints for testing
  static const Map<String, String> apiEndpoints = {
    'auth_login': '/api/v1/auth/login',
    'auth_register': '/api/v1/auth/register',
    'auth_profile': '/api/v1/auth/profile',
    'vehicles': '/api/v1/vehicles',
    'telemetry_ingest': '/api/v1/telemetry/ingest',
    'telemetry_alerts': '/api/v1/telemetry/alerts',
    'chat_message': '/api/v1/chat/message',
    'chat_history': '/api/v1/chat/history',
    'notifications_send': '/api/v1/notifications/send',
    'notifications_preferences': '/api/v1/notifications/preferences',
    'service_centers': '/api/v1/service-centers',
    'predictions': '/api/v1/predictions',
  };

  // WebSocket endpoints
  static const Map<String, String> websocketEndpoints = {
    'telemetry': '/ws/telemetry',
    'chat': '/ws/chat',
    'alerts': '/ws/alerts',
  };

  // Test timeouts
  static const Map<String, Duration> testTimeouts = {
    'short': Duration(seconds: 5),
    'medium': Duration(seconds: 10),
    'long': Duration(seconds: 30),
    'extended': Duration(minutes: 2),
  };
}

