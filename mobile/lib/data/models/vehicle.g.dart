// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      vin: json['vin'] as String,
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
      registrationDate: json['registration_date'] == null
          ? null
          : DateTime.parse(json['registration_date'] as String),
      lastServiceDate: json['last_service_date'] == null
          ? null
          : DateTime.parse(json['last_service_date'] as String),
      healthScore: (json['health_score'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'vin': instance.vin,
      'mileage': instance.mileage,
      'registration_date': instance.registrationDate?.toIso8601String(),
      'last_service_date': instance.lastServiceDate?.toIso8601String(),
      'health_score': instance.healthScore,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

