import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

@JsonSerializable()
class Vehicle {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String make;
  final String model;
  final int year;
  final String vin;
  final int mileage;
  @JsonKey(name: 'registration_date')
  final DateTime? registrationDate;
  @JsonKey(name: 'last_service_date')
  final DateTime? lastServiceDate;
  @JsonKey(name: 'health_score')
  final double healthScore;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    this.mileage = 0,
    this.registrationDate,
    this.lastServiceDate,
    this.healthScore = 1.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  Vehicle copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? mileage,
    DateTime? registrationDate,
    DateTime? lastServiceDate,
    double? healthScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      mileage: mileage ?? this.mileage,
      registrationDate: registrationDate ?? this.registrationDate,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      healthScore: healthScore ?? this.healthScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, make: $make, model: $model, year: $year, healthScore: $healthScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
