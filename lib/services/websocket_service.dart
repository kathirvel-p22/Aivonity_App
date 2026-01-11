import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:rxdart/rxdart.dart';

/// WebSocket connection states
enum WebSocketState { disconnected, connecting, connected, reconnecting, error }

/// WebSocket message types
enum MessageType { telemetry, alert, heartbeat, connectionEstablished, error }

/// WebSocket message model
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final String timestamp;
  final String messageId;

  WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
    required this.messageId,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp: json['timestamp'] ?? '',
      messageId: json['message_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp,
      'message_id': messageId,
    };
  }
}

/// WebSocket service for real-time communication
class WebSocketService {
  static const String _baseUrl = 'ws://localhost:8000';
  static const int _reconnectDelay = 5; // seconds
  static const int _maxReconnectAttempts = 5;
  static const int _heartbeatInterval = 30; // seconds

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  String? _lastUrl;

  // State management
  final BehaviorSubject<WebSocketState> _stateController =
      BehaviorSubject<WebSocketState>.seeded(WebSocketState.disconnected);

  // Message streams
  final PublishSubject<WebSocketMessage> _messageController =
      PublishSubject<WebSocketMessage>();
  final PublishSubject<Map<String, dynamic>> _telemetryController =
      PublishSubject<Map<String, dynamic>>();
  final PublishSubject<Map<String, dynamic>> _alertController =
      PublishSubject<Map<String, dynamic>>();

  // Getters for streams
  Stream<WebSocketState> get connectionState => _stateController.stream;
  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;

  WebSocketState get currentState => _stateController.value;
  bool get isConnected => currentState == WebSocketState.connected;

  /// Connect to telemetry WebSocket for a specific vehicle
  Future<void> connectToTelemetry(String vehicleId) async {
    final url = '$_baseUrl/ws/telemetry/$vehicleId';
    await _connect(url);
  }

  /// Connect to alerts WebSocket for a specific user
  Future<void> connectToAlerts(String userId) async {
    final url = '$_baseUrl/ws/alerts/$userId';
    await _connect(url);
  }

  /// Connect to chat WebSocket for a specific user
  Future<void> connectToChat(String userId) async {
    final url = '$_baseUrl/ws/chat/$userId';
    await _connect(url);
  }

  /// Internal connection method
  Future<void> _connect(String url) async {
    if (_stateController.value == WebSocketState.connecting) {
      debugPrint('WebSocket: Already connecting...');
      return;
    }

    _lastUrl = url;
    _stateController.add(WebSocketState.connecting);

    try {
      debugPrint('WebSocket: Connecting to $url');

      _channel = WebSocketChannel.connect(
        Uri.parse(url),
        protocols: ['websocket'],
      );

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
        cancelOnError: false,
      );

      _stateController.add(WebSocketState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      debugPrint('WebSocket: Connected successfully');
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
      _stateController.add(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  /// Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final wsMessage = WebSocketMessage.fromJson(data);

      debugPrint('WebSocket: Received message: ${wsMessage.type}');

      // Emit to general message stream
      _messageController.add(wsMessage);

      // Route to specific streams based on message type
      switch (wsMessage.type) {
        case 'telemetry_update':
          _telemetryController.add(wsMessage.data);
          break;
        case 'alert':
        case 'critical_alert':
          _alertController.add(wsMessage.data);
          break;
        case 'heartbeat':
          // Handle heartbeat - connection is alive
          break;
        case 'connection_established':
          debugPrint(
            'WebSocket: Connection established with ID: ${wsMessage.data['connection_id']}',
          );
          break;
        default:
          debugPrint('WebSocket: Unknown message type: ${wsMessage.type}');
      }
    } catch (e) {
      debugPrint('WebSocket: Error parsing message: $e');
    }
  }

  /// Handle connection errors
  void _onError(error) {
    debugPrint('WebSocket: Error occurred: $error');
    _stateController.add(WebSocketState.error);
    _scheduleReconnect();
  }

  /// Handle disconnection
  void _onDisconnected() {
    debugPrint('WebSocket: Connection closed');
    _stateController.add(WebSocketState.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  /// Send message through WebSocket
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected) {
      debugPrint('WebSocket: Cannot send message - not connected');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel?.sink.add(jsonMessage);
      debugPrint('WebSocket: Message sent: ${message['type']}');
    } catch (e) {
      debugPrint('WebSocket: Error sending message: $e');
    }
  }

  /// Send telemetry data
  Future<void> sendTelemetryData(Map<String, dynamic> telemetryData) async {
    await sendMessage({
      'type': 'telemetry_data',
      'data': telemetryData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId) async {
    await sendMessage({
      'type': 'acknowledge_alert',
      'data': {'alert_id': alertId},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnection attempts reached');
      _stateController.add(WebSocketState.error);
      return;
    }

    if (_lastUrl == null) {
      debugPrint('WebSocket: No URL to reconnect to');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts; // Linear backoff

    debugPrint(
      'WebSocket: Scheduling reconnect in ${delay}s (attempt $_reconnectAttempts)',
    );
    _stateController.add(WebSocketState.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_lastUrl != null) {
        _connect(_lastUrl!);
      }
    });
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(Duration(seconds: _heartbeatInterval), (
      timer,
    ) {
      if (isConnected) {
        sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    if (_lastUrl != null) {
      _reconnectAttempts = 0;
      await disconnect();
      await Future.delayed(Duration(seconds: 1));
      await _connect(_lastUrl!);
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    debugPrint('WebSocket: Disconnecting...');

    _reconnectTimer?.cancel();
    _stopHeartbeat();

    try {
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
      debugPrint('WebSocket: Error during disconnect: $e');
    }

    _channel = null;
    _stateController.add(WebSocketState.disconnected);
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'state': currentState.toString(),
      'reconnect_attempts': _reconnectAttempts,
      'last_url': _lastUrl,
      'is_connected': isConnected,
    };
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    _telemetryController.close();
    _alertController.close();
  }
}

