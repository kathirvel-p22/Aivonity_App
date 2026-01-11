// Unit tests for Telemetry model

import 'package:flutter_test/flutter_test.dart';
import '../../../test/fixtures/test_data.dart';

// Mock Telemetry model for testing
class TelemetryData {
  final String vehicleId;
  final DateTime timestamp;
  final double engineTemp;
  final double oilPressure;
  final double batteryVoltage;
  final int rpm;
  final double speed;
  final double fuelLevel;
  final Map<String, double>? location;

  TelemetryData({
    required this.vehicleId,
    required this.timestamp,
    required this.engineTemp,
    required this.oilPressure,
    required this.batteryVoltage,
    required this.rpm,
    required this.speed,
    required this.fuelLevel,
    this.location,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      vehicleId: json['vehicle_id'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      engineTemp: (json['engine_temp'] ?? 0.0).toDouble(),
      oilPressure: (json['oil_pressure'] ?? 0.0).toDouble(),
      batteryVoltage: (json['battery_voltage'] ?? 0.0).toDouble(),
      rpm: json['rpm'] ?? 0,
      speed: (json['speed'] ?? 0.0).toDouble(),
      fuelLevel: (json['fuel_level'] ?? 0.0).toDouble(),
      location: json['location'] != null
          ? {
              'latitude': (json['location']['latitude'] ?? 0.0).toDouble(),
              'longitude': (json['location']['longitude'] ?? 0.0).toDouble(),
            }
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'timestamp': timestamp.toIso8601String(),
      'engine_temp': engineTemp,
      'oil_pressure': oilPressure,
      'battery_voltage': batteryVoltage,
      'rpm': rpm,
      'speed': speed,
      'fuel_level': fuelLevel,
      if (location != null) 'location': location,
    };
  }

  // Health assessment methods
  bool get isEngineOverheating => engineTemp > 100.0;
  bool get isLowOilPressure => oilPressure < 20.0;
  bool get isLowBattery => batteryVoltage < 11.0;
  bool get isHighRPM => rpm > 5000;
  bool get isLowFuel => fuelLevel < 10.0;

  AlertLevel get alertLevel {
    if (isEngineOverheating || isLowOilPressure || isLowBattery) {
      return AlertLevel.critical;
    }
    if (isHighRPM || isLowFuel) {
      return AlertLevel.warning;
    }
    return AlertLevel.normal;
  }

  List<String> get activeAlerts {
    final alerts = <String>[];
    if (isEngineOverheating) alerts.add('Engine overheating');
    if (isLowOilPressure) alerts.add('Low oil pressure');
    if (isLowBattery) alerts.add('Low battery voltage');
    if (isHighRPM) alerts.add('High RPM');
    if (isLowFuel) alerts.add('Low fuel level');
    return alerts;
  }

  double get healthScore {
    double score = 100.0;

    // Deduct points for various issues
    if (isEngineOverheating) score -= 30.0;
    if (isLowOilPressure) score -= 25.0;
    if (isLowBattery) score -= 20.0;
    if (isHighRPM) score -= 15.0;
    if (isLowFuel) score -= 10.0;

    // Additional deductions for extreme values
    if (engineTemp > 120.0) score -= 20.0;
    if (oilPressure < 10.0) score -= 20.0;
    if (batteryVoltage < 10.0) score -= 15.0;

    return score.clamp(0.0, 100.0);
  }
}

enum AlertLevel { normal, warning, critical }

void main() {
  group('TelemetryData Model Tests', () {
    test('should create telemetry from valid JSON', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.normalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();

      // Act
      final telemetry = TelemetryData.fromJson(json);

      // Assert
      expect(telemetry.vehicleId, equals('vehicle_123'));
      expect(telemetry.engineTemp, equals(85.5));
      expect(telemetry.oilPressure, equals(45.2));
      expect(telemetry.batteryVoltage, equals(12.6));
      expect(telemetry.rpm, equals(2500));
      expect(telemetry.speed, equals(65.0));
      expect(telemetry.fuelLevel, equals(75.0));
      expect(telemetry.location, isNotNull);
      expect(telemetry.location!['latitude'], equals(37.7749));
      expect(telemetry.location!['longitude'], equals(-122.4194));
    });

    test('should convert telemetry to JSON', () {
      // Arrange
      final telemetry = TelemetryData(
        vehicleId: 'vehicle_123',
        timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
        engineTemp: 85.5,
        oilPressure: 45.2,
        batteryVoltage: 12.6,
        rpm: 2500,
        speed: 65.0,
        fuelLevel: 75.0,
        location: {'latitude': 37.7749, 'longitude': -122.4194},
      );

      // Act
      final json = telemetry.toJson();

      // Assert
      expect(json['vehicle_id'], equals('vehicle_123'));
      expect(json['timestamp'], equals('2024-01-01T12:00:00.000Z'));
      expect(json['engine_temp'], equals(85.5));
      expect(json['oil_pressure'], equals(45.2));
      expect(json['battery_voltage'], equals(12.6));
      expect(json['rpm'], equals(2500));
      expect(json['speed'], equals(65.0));
      expect(json['fuel_level'], equals(75.0));
      expect(json['location'], isNotNull);
    });

    test('should detect normal conditions', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.normalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();
      final telemetry = TelemetryData.fromJson(json);

      // Act & Assert
      expect(telemetry.isEngineOverheating, isFalse);
      expect(telemetry.isLowOilPressure, isFalse);
      expect(telemetry.isLowBattery, isFalse);
      expect(telemetry.isHighRPM, isFalse);
      expect(telemetry.isLowFuel, isFalse);
      expect(telemetry.alertLevel, equals(AlertLevel.normal));
      expect(telemetry.activeAlerts, isEmpty);
    });

    test('should detect critical conditions', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.criticalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();
      final telemetry = TelemetryData.fromJson(json);

      // Act & Assert
      expect(telemetry.isEngineOverheating, isTrue);
      expect(telemetry.isLowOilPressure, isTrue);
      expect(telemetry.isLowBattery, isTrue);
      expect(telemetry.isHighRPM, isTrue);
      expect(telemetry.isLowFuel, isTrue);
      expect(telemetry.alertLevel, equals(AlertLevel.critical));
      expect(telemetry.activeAlerts, hasLength(5));
    });

    test('should detect warning conditions', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.warningTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();
      final telemetry = TelemetryData.fromJson(json);

      // Act & Assert
      expect(telemetry.isEngineOverheating, isFalse);
      expect(telemetry.isLowOilPressure, isFalse);
      expect(telemetry.isLowBattery, isFalse);
      expect(telemetry.isHighRPM, isFalse);
      expect(telemetry.isLowFuel, isTrue);
      expect(telemetry.alertLevel, equals(AlertLevel.warning));
      expect(telemetry.activeAlerts, contains('Low fuel level'));
    });

    test('should calculate health score correctly for normal conditions', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.normalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();
      final telemetry = TelemetryData.fromJson(json);

      // Act & Assert
      expect(telemetry.healthScore, equals(100.0));
    });

    test('should calculate health score correctly for critical conditions', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.criticalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();
      final telemetry = TelemetryData.fromJson(json);

      // Act & Assert
      expect(telemetry.healthScore, lessThan(50.0));
    });

    test('should handle missing location data', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.normalTelemetry);
      json.remove('location');
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();

      // Act
      final telemetry = TelemetryData.fromJson(json);

      // Assert
      expect(telemetry.location, isNull);
    });

    test('should handle invalid timestamp gracefully', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.normalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json.remove('timestamp');

      // Act
      final telemetry = TelemetryData.fromJson(json);

      // Assert
      expect(telemetry.timestamp, isA<DateTime>());
    });

    test('should clamp health score between 0 and 100', () {
      // Arrange - Create extremely bad conditions
      final telemetry = TelemetryData(
        vehicleId: 'vehicle_123',
        timestamp: DateTime.now(),
        engineTemp: 150.0, // Extremely high
        oilPressure: 5.0, // Extremely low
        batteryVoltage: 8.0, // Extremely low
        rpm: 6000, // Very high
        speed: 65.0,
        fuelLevel: 2.0, // Very low
      );

      // Act & Assert
      expect(telemetry.healthScore, greaterThanOrEqualTo(0.0));
      expect(telemetry.healthScore, lessThanOrEqualTo(100.0));
    });

    test('should identify specific alert messages', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.criticalTelemetry);
      json['vehicle_id'] = 'vehicle_123';
      json['timestamp'] = DateTime.now().toIso8601String();
      final telemetry = TelemetryData.fromJson(json);

      // Act
      final alerts = telemetry.activeAlerts;

      // Assert
      expect(alerts, contains('Engine overheating'));
      expect(alerts, contains('Low oil pressure'));
      expect(alerts, contains('Low battery voltage'));
      expect(alerts, contains('High RPM'));
      expect(alerts, contains('Low fuel level'));
    });
  });
}

