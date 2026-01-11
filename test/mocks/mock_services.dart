// Mock services for testing AIVONITY application

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Mock HTTP client for testing
class MockHttpClient {
  final Map<String, dynamic> _responses = {};
  final List<String> _requestLog = [];

  void setResponse(String endpoint, dynamic response, {int statusCode = 200}) {
    _responses[endpoint] = {'data': response, 'statusCode': statusCode};
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _requestLog.add('GET $path');

    final mockResponse = _responses[path];
    if (mockResponse != null) {
      return Response<T>(
        data: mockResponse['data'] as T,
        statusCode: mockResponse['statusCode'],
        requestOptions: RequestOptions(path: path),
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _requestLog.add('POST $path');

    final mockResponse = _responses[path];
    if (mockResponse != null) {
      return Response<T>(
        data: mockResponse['data'] as T,
        statusCode: mockResponse['statusCode'],
        requestOptions: RequestOptions(path: path),
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _requestLog.add('PUT $path');

    final mockResponse = _responses[path];
    if (mockResponse != null) {
      return Response<T>(
        data: mockResponse['data'] as T,
        statusCode: mockResponse['statusCode'],
        requestOptions: RequestOptions(path: path),
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _requestLog.add('DELETE $path');

    final mockResponse = _responses[path];
    if (mockResponse != null) {
      return Response<T>(
        data: mockResponse['data'] as T,
        statusCode: mockResponse['statusCode'],
        requestOptions: RequestOptions(path: path),
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  List<String> get requestLog => List.unmodifiable(_requestLog);

  void clearLog() => _requestLog.clear();
  void clearResponses() => _responses.clear();
}

/// Mock WebSocket service
class MockWebSocketService {
  final List<String> _messages = [];
  bool _isConnected = false;
  Function(String)? _onMessage;

  bool get isConnected => _isConnected;
  List<String> get messages => List.unmodifiable(_messages);

  Future<void> connect(String url) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isConnected = true;
  }

  void disconnect() {
    _isConnected = false;
  }

  void send(String message) {
    if (_isConnected) {
      _messages.add(message);
    }
  }

  void onMessage(Function(String) callback) {
    _onMessage = callback;
  }

  void simulateMessage(String message) {
    if (_isConnected && _onMessage != null) {
      _onMessage!(message);
    }
  }

  void clearMessages() => _messages.clear();
}

/// Mock Authentication Service
class MockAuthService {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _accessToken;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email == 'test@aivonity.com' && password == 'password123') {
      _isAuthenticated = true;
      _accessToken = 'mock_access_token_123';
      _currentUser = {'id': 'user_123', 'email': email, 'name': 'Test User'};

      return {
        'success': true,
        'user': _currentUser,
        'access_token': _accessToken,
      };
    }

    throw Exception('Invalid credentials');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(milliseconds: 500));

    _isAuthenticated = true;
    _accessToken = 'mock_access_token_456';
    _currentUser = {
      'id': 'user_456',
      'email': userData['email'],
      'name': userData['name'],
    };

    return {
      'success': true,
      'user': _currentUser,
      'access_token': _accessToken,
    };
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isAuthenticated = false;
    _currentUser = null;
    _accessToken = null;
  }

  void reset() {
    _isAuthenticated = false;
    _currentUser = null;
    _accessToken = null;
  }
}

/// Mock Telemetry Service
class MockTelemetryService {
  final List<Map<String, dynamic>> _telemetryData = [];
  final List<Map<String, dynamic>> _alerts = [];

  List<Map<String, dynamic>> get telemetryData =>
      List.unmodifiable(_telemetryData);
  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);

  Future<void> sendTelemetry(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _telemetryData.add({
      ...data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Simulate alert generation for anomalous data
    if (data['engine_temp'] != null && data['engine_temp'] > 100) {
      _alerts.add({
        'id': 'alert_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'critical',
        'message': 'High engine temperature detected',
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getTelemetryHistory(
    String vehicleId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _telemetryData
        .where((data) => data['vehicle_id'] == vehicleId)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAlerts(String vehicleId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _alerts;
  }

  void clearData() {
    _telemetryData.clear();
    _alerts.clear();
  }
}

/// Mock AI Chat Service
class MockAIChatService {
  final List<Map<String, dynamic>> _chatHistory = [];
  final Map<String, String> _responses = {
    'hello': 'Hello! How can I help you with your vehicle today?',
    'health':
        'Your vehicle is in good condition. All systems are operating normally.',
    'maintenance':
        'Based on your vehicle data, I recommend scheduling maintenance in the next 2 weeks.',
    'default': 'I understand your question. Let me help you with that.',
  };

  List<Map<String, dynamic>> get chatHistory => List.unmodifiable(_chatHistory);

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Add user message to history
    final userMessage = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'user',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _chatHistory.add(userMessage);

    // Generate AI response
    String response = _responses['default']!;
    final lowerMessage = message.toLowerCase();

    for (final key in _responses.keys) {
      if (lowerMessage.contains(key)) {
        response = _responses[key]!;
        break;
      }
    }

    final aiMessage = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
      'type': 'ai',
      'message': response,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _chatHistory.add(aiMessage);

    return aiMessage;
  }

  void setCustomResponse(String trigger, String response) {
    _responses[trigger] = response;
  }

  void clearHistory() => _chatHistory.clear();
}

/// Mock Notification Service
class MockNotificationService {
  final List<Map<String, dynamic>> _notifications = [];
  bool _permissionGranted = true;

  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);
  bool get permissionGranted => _permissionGranted;

  Future<bool> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _permissionGranted;
  }

  Future<void> sendNotification(Map<String, dynamic> notification) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notifications.add({
      ...notification,
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> scheduleNotification(
    Map<String, dynamic> notification,
    DateTime scheduledTime,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notifications.add({
      ...notification,
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'scheduled_time': scheduledTime.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
  }

  void clearNotifications() => _notifications.clear();
}

/// Provider overrides for testing
final mockHttpClientProvider = Provider<MockHttpClient>(
  (ref) => MockHttpClient(),
);
final mockWebSocketServiceProvider = Provider<MockWebSocketService>(
  (ref) => MockWebSocketService(),
);
final mockAuthServiceProvider = Provider<MockAuthService>(
  (ref) => MockAuthService(),
);
final mockTelemetryServiceProvider = Provider<MockTelemetryService>(
  (ref) => MockTelemetryService(),
);
final mockAIChatServiceProvider = Provider<MockAIChatService>(
  (ref) => MockAIChatService(),
);
final mockNotificationServiceProvider = Provider<MockNotificationService>(
  (ref) => MockNotificationService(),
);

