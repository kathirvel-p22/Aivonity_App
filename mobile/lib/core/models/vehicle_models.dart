import 'package:json_annotation/json_annotation.dart';

part 'vehicle_models.g.dart';

/// Enhanced vehicle model
@JsonSerializable()
class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String model;
  final int year;
  final String? vin;
  final int odometer;
  final FuelType fuelType;
  final VehicleSpecs? specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    this.vin,
    required this.odometer,
    required this.fuelType,
    this.specifications,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  /// Get display name for vehicle
  String get displayName => '$year $make $model';

  /// Get short display name
  String get shortName => '$make $model';
}

/// Vehicle specifications
@JsonSerializable()
class VehicleSpecs {
  final String? engine;
  final String? transmission;
  final int? horsepower;
  final int? torque;
  final double? fuelCapacity;
  final double? cityMpg;
  final double? highwayMpg;
  final int? seatingCapacity;
  final String? drivetrain;

  const VehicleSpecs({
    this.engine,
    this.transmission,
    this.horsepower,
    this.torque,
    this.fuelCapacity,
    this.cityMpg,
    this.highwayMpg,
    this.seatingCapacity,
    this.drivetrain,
  });

  factory VehicleSpecs.fromJson(Map<String, dynamic> json) =>
      _$VehicleSpecsFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleSpecsToJson(this);
}

/// Fuel types
enum FuelType {
  gasoline,
  diesel,
  electric,
  hybrid,
  pluginHybrid,
}

/// Vehicle health status
@JsonSerializable()
class VehicleHealth {
  final String vehicleId;
  final double overallScore;
  final EngineHealth engine;
  final BatteryHealth battery;
  final TransmissionHealth transmission;
  final BrakesHealth brakes;
  final TiresHealth tires;
  final DateTime lastUpdated;

  const VehicleHealth({
    required this.vehicleId,
    required this.overallScore,
    required this.engine,
    required this.battery,
    required this.transmission,
    required this.brakes,
    required this.tires,
    required this.lastUpdated,
  });

  factory VehicleHealth.fromJson(Map<String, dynamic> json) =>
      _$VehicleHealthFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleHealthToJson(this);

  /// Get health status text
  String get statusText {
    if (overallScore >= 0.9) return 'Excellent';
    if (overallScore >= 0.7) return 'Good';
    if (overallScore >= 0.5) return 'Fair';
    if (overallScore >= 0.3) return 'Poor';
    return 'Critical';
  }

  /// Get health color based on score
  String get statusColor {
    if (overallScore >= 0.9) return '#22C55E'; // Green
    if (overallScore >= 0.7) return '#3B82F6'; // Blue
    if (overallScore >= 0.5) return '#F59E0B'; // Amber
    if (overallScore >= 0.3) return '#F97316'; // Orange
    return '#EF4444'; // Red
  }
}

/// Engine health metrics
@JsonSerializable()
class EngineHealth {
  final double score;
  final double temperature;
  final double oilPressure;
  final double rpm;
  final List<String> issues;

  const EngineHealth({
    required this.score,
    required this.temperature,
    required this.oilPressure,
    required this.rpm,
    required this.issues,
  });

  factory EngineHealth.fromJson(Map<String, dynamic> json) =>
      _$EngineHealthFromJson(json);

  Map<String, dynamic> toJson() => _$EngineHealthToJson(this);
}

/// Battery health metrics
@JsonSerializable()
class BatteryHealth {
  final double score;
  final double voltage;
  final double chargeLevel;
  final double temperature;
  final List<String> issues;

  const BatteryHealth({
    required this.score,
    required this.voltage,
    required this.chargeLevel,
    required this.temperature,
    required this.issues,
  });

  factory BatteryHealth.fromJson(Map<String, dynamic> json) =>
      _$BatteryHealthFromJson(json);

  Map<String, dynamic> toJson() => _$BatteryHealthToJson(this);
}

/// Transmission health metrics
@JsonSerializable()
class TransmissionHealth {
  final double score;
  final double fluidLevel;
  final double temperature;
  final List<String> issues;

  const TransmissionHealth({
    required this.score,
    required this.fluidLevel,
    required this.temperature,
    required this.issues,
  });

  factory TransmissionHealth.fromJson(Map<String, dynamic> json) =>
      _$TransmissionHealthFromJson(json);

  Map<String, dynamic> toJson() => _$TransmissionHealthToJson(this);
}

/// Brakes health metrics
@JsonSerializable()
class BrakesHealth {
  final double score;
  final double padThickness;
  final double fluidLevel;
  final List<String> issues;

  const BrakesHealth({
    required this.score,
    required this.padThickness,
    required this.fluidLevel,
    required this.issues,
  });

  factory BrakesHealth.fromJson(Map<String, dynamic> json) =>
      _$BrakesHealthFromJson(json);

  Map<String, dynamic> toJson() => _$BrakesHealthToJson(this);
}

/// Tires health metrics
@JsonSerializable()
class TiresHealth {
  final double score;
  final double frontLeftPressure;
  final double frontRightPressure;
  final double rearLeftPressure;
  final double rearRightPressure;
  final double treadDepth;
  final List<String> issues;

  const TiresHealth({
    required this.score,
    required this.frontLeftPressure,
    required this.frontRightPressure,
    required this.rearLeftPressure,
    required this.rearRightPressure,
    required this.treadDepth,
    required this.issues,
  });

  factory TiresHealth.fromJson(Map<String, dynamic> json) =>
      _$TiresHealthFromJson(json);

  Map<String, dynamic> toJson() => _$TiresHealthToJson(this);
}

/// Real-time telemetry data
@JsonSerializable()
class TelemetryData {
  final String vehicleId;
  final DateTime timestamp;
  final Location? location;
  final double speed;
  final EngineMetrics engine;
  final BatteryMetrics battery;
  final FuelMetrics fuel;
  final List<DiagnosticCode> diagnosticCodes;

  const TelemetryData({
    required this.vehicleId,
    required this.timestamp,
    this.location,
    required this.speed,
    required this.engine,
    required this.battery,
    required this.fuel,
    required this.diagnosticCodes,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) =>
      _$TelemetryDataFromJson(json);

  Map<String, dynamic> toJson() => _$TelemetryDataToJson(this);
}

/// Location data
@JsonSerializable()
class Location {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;

  const Location({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

/// Engine metrics
@JsonSerializable()
class EngineMetrics {
  final double rpm;
  final double temperature;
  final double oilPressure;
  final double load;

  const EngineMetrics({
    required this.rpm,
    required this.temperature,
    required this.oilPressure,
    required this.load,
  });

  factory EngineMetrics.fromJson(Map<String, dynamic> json) =>
      _$EngineMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$EngineMetricsToJson(this);
}

/// Battery metrics
@JsonSerializable()
class BatteryMetrics {
  final double voltage;
  final double current;
  final double chargeLevel;
  final double temperature;

  const BatteryMetrics({
    required this.voltage,
    required this.current,
    required this.chargeLevel,
    required this.temperature,
  });

  factory BatteryMetrics.fromJson(Map<String, dynamic> json) =>
      _$BatteryMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$BatteryMetricsToJson(this);
}

/// Fuel metrics
@JsonSerializable()
class FuelMetrics {
  final double level;
  final double consumption;
  final double efficiency;

  const FuelMetrics({
    required this.level,
    required this.consumption,
    required this.efficiency,
  });

  factory FuelMetrics.fromJson(Map<String, dynamic> json) =>
      _$FuelMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$FuelMetricsToJson(this);
}

/// Diagnostic trouble code
@JsonSerializable()
class DiagnosticCode {
  final String code;
  final String description;
  final DiagnosticSeverity severity;
  final DateTime timestamp;

  const DiagnosticCode({
    required this.code,
    required this.description,
    required this.severity,
    required this.timestamp,
  });

  factory DiagnosticCode.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticCodeFromJson(json);

  Map<String, dynamic> toJson() => _$DiagnosticCodeToJson(this);
}

/// Diagnostic code severity
enum DiagnosticSeverity {
  info,
  warning,
  error,
  critical,
}

