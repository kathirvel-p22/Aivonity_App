// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TelemetryData _$TelemetryDataFromJson(Map<String, dynamic> json) =>
    TelemetryData(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sensorData: json['sensor_data'] as Map<String, dynamic>,
      location: json['location'] as Map<String, dynamic>?,
      anomalyScore: (json['anomaly_score'] as num?)?.toDouble(),
      processed: json['processed'] as bool? ?? false,
    );

Map<String, dynamic> _$TelemetryDataToJson(TelemetryData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'timestamp': instance.timestamp.toIso8601String(),
      'sensor_data': instance.sensorData,
      'location': instance.location,
      'anomaly_score': instance.anomalyScore,
      'processed': instance.processed,
    };

