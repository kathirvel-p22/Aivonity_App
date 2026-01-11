// Integration tests for Telemetry API endpoints

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../../../test/mocks/mock_services.dart';
import '../../../test/fixtures/test_data.dart';

class TelemetryApiClient {
  final MockHttpClient _httpClient;
  final String baseUrl;

  TelemetryApiClient(
    this._httpClient, {
    this.baseUrl = 'http://localhost:8000',
  });

  Future<Response> ingestTelemetry(
    Map<String, dynamic> telemetryData,
    String accessToken,
  ) async {
    return await _httpClient.post(
      '$baseUrl${TestData.apiEndpoints['telemetry_ingest']}',
      data: telemetryData,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response> getVehicleAlerts(
    String vehicleId,
    String accessToken,
  ) async {
    return await _httpClient.get(
      '$baseUrl${TestData.apiEndpoints['telemetry_alerts']}/$vehicleId',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response> getVehicleStatus(
    String vehicleId,
    String accessToken,
  ) async {
    return await _httpClient.get(
      '$baseUrl/api/v1/telemetry/status/$vehicleId',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response> getTelemetryHistory(
    String vehicleId,
    String accessToken, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (limit != null) queryParams['limit'] = limit;

    return await _httpClient.get(
      '$baseUrl/api/v1/telemetry/history/$vehicleId',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response> acknowledgeAlert(String alertId, String accessToken) async {
    return await _httpClient.post(
      '$baseUrl/api/v1/telemetry/alerts/$alertId/acknowledge',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response> getHealthScore(String vehicleId, String accessToken) async {
    return await _httpClient.get(
      '$baseUrl/api/v1/telemetry/health/$vehicleId',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }
}

void main() {
  group('Telemetry API Integration Tests', () {
    late TelemetryApiClient telemetryClient;
    late MockHttpClient mockHttpClient;
    const accessToken = 'valid_access_token';
    const vehicleId = 'vehicle_123';

    setUp(() {
      mockHttpClient = MockHttpClient();
      telemetryClient = TelemetryApiClient(mockHttpClient);

      // Setup mock responses
      _setupMockResponses(mockHttpClient);
    });

    tearDown(() {
      mockHttpClient.clearResponses();
      mockHttpClient.clearLog();
    });

    group('Telemetry Ingestion', () {
      test('should ingest normal telemetry data successfully', () async {
        // Arrange
        final telemetryData = {
          'vehicle_id': vehicleId,
          'timestamp': DateTime.now().toIso8601String(),
          'sensor_data': TestData.normalTelemetry,
        };

        // Act
        final response = await telemetryClient.ingestTelemetry(
          telemetryData,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['processed'], isTrue);
        expect(response.data['alerts_generated'], equals(0));
      });

      test('should ingest critical telemetry and generate alerts', () async {
        // Arrange
        final telemetryData = {
          'vehicle_id': vehicleId,
          'timestamp': DateTime.now().toIso8601String(),
          'sensor_data': TestData.criticalTelemetry,
        };

        // Act
        final response = await telemetryClient.ingestTelemetry(
          telemetryData,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['processed'], isTrue);
        expect(response.data['alerts_generated'], greaterThan(0));
        expect(response.data['alert_level'], equals('critical'));
      });

      test('should fail ingestion with invalid data', () async {
        // Arrange
        final invalidData = {
          'vehicle_id': '', // Invalid vehicle ID
          'sensor_data': {}, // Empty sensor data
        };

        // Act & Assert
        expect(
          () async =>
              await telemetryClient.ingestTelemetry(invalidData, accessToken),
          throwsA(isA<DioException>()),
        );
      });

      test('should fail ingestion without authentication', () async {
        // Arrange
        final telemetryData = {
          'vehicle_id': vehicleId,
          'timestamp': DateTime.now().toIso8601String(),
          'sensor_data': TestData.normalTelemetry,
        };

        // Act & Assert
        expect(
          () async => await telemetryClient.ingestTelemetry(telemetryData, ''),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle batch telemetry ingestion', () async {
        // Arrange
        final batchData = {
          'vehicle_id': vehicleId,
          'batch': [
            {
              'timestamp': DateTime.now()
                  .subtract(const Duration(minutes: 2))
                  .toIso8601String(),
              'sensor_data': TestData.normalTelemetry,
            },
            {
              'timestamp': DateTime.now()
                  .subtract(const Duration(minutes: 1))
                  .toIso8601String(),
              'sensor_data': TestData.warningTelemetry,
            },
            {
              'timestamp': DateTime.now().toIso8601String(),
              'sensor_data': TestData.criticalTelemetry,
            },
          ],
        };

        // Act
        final response = await telemetryClient.ingestTelemetry(
          batchData,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['processed_count'], equals(3));
        expect(response.data['alerts_generated'], greaterThan(0));
      });
    });

    group('Alert Management', () {
      test('should retrieve vehicle alerts', () async {
        // Act
        final response = await telemetryClient.getVehicleAlerts(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data, isList);

        if (response.data.isNotEmpty) {
          final alert = response.data[0];
          expect(alert['id'], isNotNull);
          expect(alert['vehicle_id'], equals(vehicleId));
          expect(alert['type'], isNotNull);
          expect(alert['severity'], isNotNull);
          expect(alert['message'], isNotNull);
          expect(alert['timestamp'], isNotNull);
        }
      });

      test('should acknowledge alert successfully', () async {
        // Arrange
        const alertId = 'alert_123';

        // Act
        final response = await telemetryClient.acknowledgeAlert(
          alertId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['acknowledged'], isTrue);
        expect(response.data['acknowledged_at'], isNotNull);
      });

      test('should fail to acknowledge non-existent alert', () async {
        // Act & Assert
        expect(
          () async => await telemetryClient.acknowledgeAlert(
            'non_existent_alert',
            accessToken,
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('should filter alerts by severity', () async {
        // Act
        final response = await telemetryClient.getVehicleAlerts(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));

        final criticalAlerts = response.data
            .where((alert) => alert['severity'] == 'critical')
            .toList();
        final warningAlerts = response.data
            .where((alert) => alert['severity'] == 'warning')
            .toList();

        expect(criticalAlerts, isNotEmpty);
        expect(warningAlerts, isNotEmpty);
      });
    });

    group('Vehicle Status', () {
      test('should get current vehicle status', () async {
        // Act
        final response = await telemetryClient.getVehicleStatus(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['vehicle_id'], equals(vehicleId));
        expect(response.data['is_online'], isNotNull);
        expect(response.data['last_update'], isNotNull);
        expect(response.data['current_location'], isNotNull);
        expect(response.data['health_score'], isNotNull);
        expect(response.data['active_alerts_count'], isNotNull);
      });

      test('should get health score', () async {
        // Act
        final response = await telemetryClient.getHealthScore(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['vehicle_id'], equals(vehicleId));
        expect(response.data['health_score'], isA<num>());
        expect(response.data['health_score'], greaterThanOrEqualTo(0));
        expect(response.data['health_score'], lessThanOrEqualTo(100));
        expect(response.data['factors'], isList);
        expect(response.data['recommendations'], isList);
      });

      test('should handle offline vehicle status', () async {
        // Arrange - Mock offline vehicle
        mockHttpClient.setResponse('/api/v1/telemetry/status/$vehicleId', {
          'vehicle_id': vehicleId,
          'is_online': false,
          'last_update': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'current_location': null,
          'health_score': 85.0,
          'active_alerts_count': 1,
          'connection_status': 'offline',
        });

        // Act
        final response = await telemetryClient.getVehicleStatus(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['is_online'], isFalse);
        expect(response.data['connection_status'], equals('offline'));
      });
    });

    group('Telemetry History', () {
      test('should retrieve telemetry history', () async {
        // Act
        final response = await telemetryClient.getTelemetryHistory(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['data'], isList);
        expect(response.data['total_count'], isA<int>());
        expect(response.data['page'], isA<int>());
        expect(response.data['page_size'], isA<int>());

        if (response.data['data'].isNotEmpty) {
          final record = response.data['data'][0];
          expect(record['timestamp'], isNotNull);
          expect(record['sensor_data'], isNotNull);
          expect(record['vehicle_id'], equals(vehicleId));
        }
      });

      test('should retrieve telemetry history with date range', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();

        // Act
        final response = await telemetryClient.getTelemetryHistory(
          vehicleId,
          accessToken,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['data'], isList);
        expect(
          response.data['date_range']['start'],
          equals(startDate.toIso8601String()),
        );
        expect(
          response.data['date_range']['end'],
          equals(endDate.toIso8601String()),
        );
      });

      test('should retrieve limited telemetry history', () async {
        // Act
        final response = await telemetryClient.getTelemetryHistory(
          vehicleId,
          accessToken,
          limit: 10,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['data'], isList);
        expect(response.data['data'].length, lessThanOrEqualTo(10));
      });

      test('should handle empty telemetry history', () async {
        // Arrange - Mock empty history
        mockHttpClient.setResponse('/api/v1/telemetry/history/$vehicleId', {
          'data': [],
          'total_count': 0,
          'page': 1,
          'page_size': 50,
        });

        // Act
        final response = await telemetryClient.getTelemetryHistory(
          vehicleId,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['data'], isEmpty);
        expect(response.data['total_count'], equals(0));
      });
    });

    group('Real-time Processing', () {
      test('should process telemetry in real-time', () async {
        // Arrange
        final telemetryData = {
          'vehicle_id': vehicleId,
          'timestamp': DateTime.now().toIso8601String(),
          'sensor_data': TestData.criticalTelemetry,
          'real_time': true,
        };

        // Act
        final response = await telemetryClient.ingestTelemetry(
          telemetryData,
          accessToken,
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['processed'], isTrue);
        expect(response.data['processing_time_ms'], lessThan(1000));
        expect(response.data['real_time_processed'], isTrue);
      });

      test('should handle high-frequency telemetry', () async {
        // Arrange - Simulate rapid telemetry ingestion
        final futures = <Future<Response>>[];

        for (int i = 0; i < 5; i++) {
          final telemetryData = {
            'vehicle_id': vehicleId,
            'timestamp': DateTime.now()
                .add(Duration(seconds: i))
                .toIso8601String(),
            'sensor_data': TestData.normalTelemetry,
            'sequence_number': i,
          };

          futures.add(
            telemetryClient.ingestTelemetry(telemetryData, accessToken),
          );
        }

        // Act
        final responses = await Future.wait(futures);

        // Assert
        for (final response in responses) {
          expect(response.statusCode, equals(201));
          expect(response.data['success'], isTrue);
        }
      });
    });

    group('Error Handling', () {
      test('should handle malformed telemetry data', () async {
        // Arrange
        final malformedData = {
          'vehicle_id': vehicleId,
          'sensor_data': 'invalid_json_string',
        };

        // Act & Assert
        expect(
          () async =>
              await telemetryClient.ingestTelemetry(malformedData, accessToken),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle unauthorized access', () async {
        // Act & Assert
        expect(
          () async => await telemetryClient.getVehicleAlerts(
            vehicleId,
            'invalid_token',
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle vehicle not found', () async {
        // Act & Assert
        expect(
          () async => await telemetryClient.getVehicleStatus(
            'non_existent_vehicle',
            accessToken,
          ),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}

void _setupMockResponses(MockHttpClient mockHttpClient) {
  const vehicleId = 'vehicle_123';

  // Telemetry ingestion - normal
  mockHttpClient.setResponse(TestData.apiEndpoints['telemetry_ingest']!, {
    'success': true,
    'processed': true,
    'alerts_generated': 0,
    'processing_time_ms': 150,
    'real_time_processed': true,
  }, statusCode: 201);

  // Vehicle alerts
  mockHttpClient.setResponse(
    '${TestData.apiEndpoints['telemetry_alerts']}/$vehicleId',
    [
      {
        'id': 'alert_123',
        'vehicle_id': vehicleId,
        'type': 'engine_temperature',
        'severity': 'critical',
        'message': 'Engine temperature critically high',
        'timestamp': DateTime.now().toIso8601String(),
        'acknowledged': false,
        'data': TestData.criticalTelemetry,
      },
      {
        'id': 'alert_124',
        'vehicle_id': vehicleId,
        'type': 'fuel_level',
        'severity': 'warning',
        'message': 'Low fuel level detected',
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
        'acknowledged': true,
        'data': TestData.warningTelemetry,
      },
    ],
  );

  // Vehicle status
  mockHttpClient.setResponse('/api/v1/telemetry/status/$vehicleId', {
    'vehicle_id': vehicleId,
    'is_online': true,
    'last_update': DateTime.now().toIso8601String(),
    'current_location': {
      'latitude': 37.7749,
      'longitude': -122.4194,
      'address': 'San Francisco, CA',
    },
    'health_score': 75.5,
    'active_alerts_count': 2,
    'connection_status': 'online',
  });

  // Health score
  mockHttpClient.setResponse('/api/v1/telemetry/health/$vehicleId', {
    'vehicle_id': vehicleId,
    'health_score': 75.5,
    'factors': [
      {'name': 'Engine Temperature', 'score': 60, 'status': 'warning'},
      {'name': 'Oil Pressure', 'score': 85, 'status': 'good'},
      {'name': 'Battery Voltage', 'score': 90, 'status': 'good'},
      {'name': 'Fuel Level', 'score': 70, 'status': 'warning'},
    ],
    'recommendations': [
      'Schedule engine inspection due to high temperature readings',
      'Consider refueling soon',
    ],
    'last_calculated': DateTime.now().toIso8601String(),
  });

  // Telemetry history
  mockHttpClient.setResponse('/api/v1/telemetry/history/$vehicleId', {
    'data': [
      {
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'sensor_data': TestData.normalTelemetry,
        'vehicle_id': vehicleId,
        'health_score': 85.0,
      },
      {
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'sensor_data': TestData.warningTelemetry,
        'vehicle_id': vehicleId,
        'health_score': 78.0,
      },
    ],
    'total_count': 2,
    'page': 1,
    'page_size': 50,
  });

  // Alert acknowledgment
  mockHttpClient.setResponse('/api/v1/telemetry/alerts/alert_123/acknowledge', {
    'success': true,
    'acknowledged': true,
    'acknowledged_at': DateTime.now().toIso8601String(),
  });
}

