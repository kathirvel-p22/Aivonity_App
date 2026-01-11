import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'websocket_service.dart';

/// Vehicle telemetry data model
class TelemetryData {
  final String vehicleId;
  final DateTime timestamp;
  final Map<String, dynamic> location;
  final double speed;
  final Map<String, dynamic> engineMetrics;
  final Map<String, dynamic> batteryMetrics;
  final Map<String, dynamic> fuelMetrics;
  final List<String> diagnosticCodes;
  final Map<String, dynamic> environmentalData;

  TelemetryData({
    required this.vehicleId,
    required this.timestamp,
    required this.location,
    required this.speed,
    required this.engineMetrics,
    required this.batteryMetrics,
    required this.fuelMetrics,
    required this.diagnosticCodes,
    required this.environmentalData,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      vehicleId: json['vehicle_id'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      location: json['location'] ?? {},
      speed: (json['speed'] ?? 0.0).toDouble(),
      engineMetrics: json['engine_metrics'] ?? {},
      batteryMetrics: json['battery_metrics'] ?? {},
      fuelMetrics: json['fuel_metrics'] ?? {},
      diagnosticCodes: List<String>.from(json['diagnostic_codes'] ?? []),
      environmentalData: json['environmental_data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'speed': speed,
      'engine_metrics': engineMetrics,
      'battery_metrics': batteryMetrics,
      'fuel_metrics': fuelMetrics,
      'diagnostic_codes': diagnosticCodes,
      'environmental_data': environmentalData,
    };
  }
}

/// Vehicle status model
class VehicleStatus {
  final bool isOnline;
  final DateTime lastUpdate;
  final Map<String, dynamic> engineStatus;
  final double batteryLevel;
  final double fuelLevel;
  final Map<String, dynamic> location;
  final List<Map<String, dynamic>> alerts;

  VehicleStatus({
    required this.isOnline,
    required this.lastUpdate,
    required this.engineStatus,
    required this.batteryLevel,
    required this.fuelLevel,
    required this.location,
    required this.alerts,
  });

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    return VehicleStatus(
      isOnline: json['is_online'] ?? false,
      lastUpdate: DateTime.parse(
        json['last_update'] ?? DateTime.now().toIso8601String(),
      ),
      engineStatus: json['engine_status'] ?? {},
      batteryLevel: (json['battery_level'] ?? 0.0).toDouble(),
      fuelLevel: (json['fuel_level'] ?? 0.0).toDouble(),
      location: json['location'] ?? {},
      alerts: List<Map<String, dynamic>>.from(json['alerts'] ?? []),
    );
  }
}

/// Alert model
class VehicleAlert {
  final String id;
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool acknowledged;

  VehicleAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.data,
    this.acknowledged = false,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> json) {
    return VehicleAlert(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'info',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'] ?? {},
      acknowledged: json['acknowledged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'acknowledged': acknowledged,
    };
  }
}

/// Real-time telemetry service
class TelemetryService {
  final WebSocketService _webSocketService;

  // Data streams
  final BehaviorSubject<TelemetryData?> _currentTelemetryController =
      BehaviorSubject<TelemetryData?>.seeded(null);
  final BehaviorSubject<VehicleStatus?> _vehicleStatusController =
      BehaviorSubject<VehicleStatus?>.seeded(null);
  final PublishSubject<VehicleAlert> _alertController =
      PublishSubject<VehicleAlert>();

  // Connection state
  final BehaviorSubject<bool> _isConnectedController =
      BehaviorSubject<bool>.seeded(false);

  // Subscriptions
  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _alertSubscription;
  StreamSubscription? _connectionSubscription;

  String? _currentVehicleId;
  String? _currentUserId;

  TelemetryService(this._webSocketService) {
    _initializeSubscriptions();
  }

  // Getters for streams
  Stream<TelemetryData?> get telemetryStream =>
      _currentTelemetryController.stream;
  Stream<VehicleStatus?> get vehicleStatusStream =>
      _vehicleStatusController.stream;
  Stream<VehicleAlert> get alertStream => _alertController.stream;
  Stream<bool> get connectionStream => _isConnectedController.stream;

  TelemetryData? get currentTelemetry => _currentTelemetryController.value;
  VehicleStatus? get currentVehicleStatus => _vehicleStatusController.value;
  bool get isConnected => _isConnectedController.value;

  /// Initialize WebSocket subscriptions
  void _initializeSubscriptions() {
    // Listen to telemetry updates
    _telemetrySubscription = _webSocketService.telemetryStream.listen(
      (data) {
        try {
          final telemetry = TelemetryData.fromJson(data);
          _currentTelemetryController.add(telemetry);
          _updateVehicleStatus(telemetry);
          debugPrint(
            'Telemetry: Received data for vehicle ${telemetry.vehicleId}',
          );
        } catch (e) {
          debugPrint('Telemetry: Error parsing telemetry data: $e');
        }
      },
      onError: (error) {
        debugPrint('Telemetry: Error in telemetry stream: $error');
      },
    );

    // Listen to alerts
    _alertSubscription = _webSocketService.alertStream.listen(
      (data) {
        try {
          final alert = VehicleAlert.fromJson(data);
          _alertController.add(alert);
          debugPrint(
            'Telemetry: Received alert: ${alert.type} - ${alert.severity}',
          );
        } catch (e) {
          debugPrint('Telemetry: Error parsing alert data: $e');
        }
      },
      onError: (error) {
        debugPrint('Telemetry: Error in alert stream: $error');
      },
    );

    // Listen to connection state changes
    _connectionSubscription = _webSocketService.connectionState.listen((state) {
      final connected = state == WebSocketState.connected;
      _isConnectedController.add(connected);

      if (!connected) {
        // Clear current data when disconnected
        _currentTelemetryController.add(null);
        _vehicleStatusController.add(null);
      }

      debugPrint('Telemetry: Connection state changed to $state');
    });
  }

  /// Subscribe to vehicle telemetry
  Future<void> subscribeToVehicle(String vehicleId) async {
    if (_currentVehicleId == vehicleId && isConnected) {
      debugPrint('Telemetry: Already subscribed to vehicle $vehicleId');
      return;
    }

    _currentVehicleId = vehicleId;

    try {
      await _webSocketService.connectToTelemetry(vehicleId);
      debugPrint('Telemetry: Subscribed to vehicle $vehicleId');
    } catch (e) {
      debugPrint('Telemetry: Error subscribing to vehicle $vehicleId: $e');
      rethrow;
    }
  }

  /// Subscribe to user alerts
  Future<void> subscribeToAlerts(String userId) async {
    if (_currentUserId == userId) {
      debugPrint('Telemetry: Already subscribed to alerts for user $userId');
      return;
    }

    _currentUserId = userId;

    try {
      await _webSocketService.connectToAlerts(userId);
      debugPrint('Telemetry: Subscribed to alerts for user $userId');
    } catch (e) {
      debugPrint('Telemetry: Error subscribing to alerts for user $userId: $e');
      rethrow;
    }
  }

  /// Update vehicle status from telemetry data
  void _updateVehicleStatus(TelemetryData telemetry) {
    final currentStatus = _vehicleStatusController.value;

    final updatedStatus = VehicleStatus(
      isOnline: true,
      lastUpdate: telemetry.timestamp,
      engineStatus: telemetry.engineMetrics,
      batteryLevel: telemetry.batteryMetrics['level']?.toDouble() ?? 0.0,
      fuelLevel: telemetry.fuelMetrics['level']?.toDouble() ?? 0.0,
      location: telemetry.location,
      alerts: currentStatus?.alerts ?? [],
    );

    _vehicleStatusController.add(updatedStatus);
  }

  /// Send telemetry data (for testing or manual data entry)
  Future<void> sendTelemetryData(TelemetryData telemetry) async {
    try {
      await _webSocketService.sendTelemetryData(telemetry.toJson());
      debugPrint(
        'Telemetry: Sent telemetry data for vehicle ${telemetry.vehicleId}',
      );
    } catch (e) {
      debugPrint('Telemetry: Error sending telemetry data: $e');
      rethrow;
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _webSocketService.acknowledgeAlert(alertId);
      debugPrint('Telemetry: Acknowledged alert $alertId');
    } catch (e) {
      debugPrint('Telemetry: Error acknowledging alert $alertId: $e');
      rethrow;
    }
  }

  /// Get historical telemetry data (would typically call REST API)
  Future<List<TelemetryData>> getHistoricalData(
    String vehicleId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    // This would typically make an HTTP request to get historical data
    // For now, return empty list as placeholder
    debugPrint(
      'Telemetry: Fetching historical data for $vehicleId from $startTime to $endTime',
    );
    return [];
  }

  /// Export telemetry data
  Future<String> exportTelemetryData(
    String vehicleId,
    String format, // 'csv' or 'json'
  ) async {
    // This would typically make an HTTP request to export data
    // For now, return empty string as placeholder
    debugPrint('Telemetry: Exporting data for $vehicleId in $format format');
    return '';
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'is_connected': isConnected,
      'current_vehicle_id': _currentVehicleId,
      'current_user_id': _currentUserId,
      'websocket_stats': _webSocketService.getConnectionStats(),
      'has_current_telemetry': currentTelemetry != null,
      'has_current_status': currentVehicleStatus != null,
    };
  }

  /// Reconnect to WebSocket
  Future<void> reconnect() async {
    try {
      await _webSocketService.reconnect();
      debugPrint('Telemetry: Reconnection initiated');
    } catch (e) {
      debugPrint('Telemetry: Error during reconnection: $e');
      rethrow;
    }
  }

  /// Disconnect from all subscriptions
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      _currentVehicleId = null;
      _currentUserId = null;
      debugPrint('Telemetry: Disconnected from all subscriptions');
    } catch (e) {
      debugPrint('Telemetry: Error during disconnect: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _telemetrySubscription?.cancel();
    _alertSubscription?.cancel();
    _connectionSubscription?.cancel();

    _currentTelemetryController.close();
    _vehicleStatusController.close();
    _alertController.close();
    _isConnectedController.close();

    _webSocketService.dispose();
  }
}

