import 'package:json_annotation/json_annotation.dart';

part 'telemetry_data.g.dart';

@JsonSerializable()
class TelemetryData {
  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final DateTime timestamp;
  @JsonKey(name: 'sensor_data')
  final Map<String, dynamic> sensorData;
  final Map<String, dynamic>? location;
  @JsonKey(name: 'anomaly_score')
  final double? anomalyScore;
  final bool processed;

  TelemetryData({
    required this.id,
    required this.vehicleId,
    required this.timestamp,
    required this.sensorData,
    this.location,
    this.anomalyScore,
    this.processed = false,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) =>
      _$TelemetryDataFromJson(json);
  Map<String, dynamic> toJson() => _$TelemetryDataToJson(this);

  TelemetryData copyWith({
    String? id,
    String? vehicleId,
    DateTime? timestamp,
    Map<String, dynamic>? sensorData,
    Map<String, dynamic>? location,
    double? anomalyScore,
    bool? processed,
  }) {
    return TelemetryData(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      timestamp: timestamp ?? this.timestamp,
      sensorData: sensorData ?? this.sensorData,
      location: location ?? this.location,
      anomalyScore: anomalyScore ?? this.anomalyScore,
      processed: processed ?? this.processed,
    );
  }

  /// Get sensor value by key
  double? getSensorValue(String key) {
    final value = sensorData[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  /// Check if telemetry indicates an anomaly
  bool get hasAnomaly => anomalyScore != null && anomalyScore! > 0.7;

  /// Get GPS coordinates if available
  Map<String, double>? get gpsCoordinates {
    if (location != null &&
        location!.containsKey('latitude') &&
        location!.containsKey('longitude')) {
      return {
        'latitude': (location!['latitude'] as num).toDouble(),
        'longitude': (location!['longitude'] as num).toDouble(),
      };
    }
    return null;
  }

  @override
  String toString() {
    return 'TelemetryData(id: $id, vehicleId: $vehicleId, timestamp: $timestamp, anomalyScore: $anomalyScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelemetryData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

