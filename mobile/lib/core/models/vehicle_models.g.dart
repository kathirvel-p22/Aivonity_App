// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      id: json['id'] as String,
      userId: json['userId'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      vin: json['vin'] as String?,
      odometer: (json['odometer'] as num).toInt(),
      fuelType: $enumDecode(_$FuelTypeEnumMap, json['fuelType']),
      specifications: json['specifications'] == null
          ? null
          : VehicleSpecs.fromJson(
              json['specifications'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'vin': instance.vin,
      'odometer': instance.odometer,
      'fuelType': _$FuelTypeEnumMap[instance.fuelType]!,
      'specifications': instance.specifications,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
    };

const _$FuelTypeEnumMap = {
  FuelType.gasoline: 'gasoline',
  FuelType.diesel: 'diesel',
  FuelType.electric: 'electric',
  FuelType.hybrid: 'hybrid',
  FuelType.pluginHybrid: 'pluginHybrid',
};

VehicleSpecs _$VehicleSpecsFromJson(Map<String, dynamic> json) => VehicleSpecs(
      engine: json['engine'] as String?,
      transmission: json['transmission'] as String?,
      horsepower: (json['horsepower'] as num?)?.toInt(),
      torque: (json['torque'] as num?)?.toInt(),
      fuelCapacity: (json['fuelCapacity'] as num?)?.toDouble(),
      cityMpg: (json['cityMpg'] as num?)?.toDouble(),
      highwayMpg: (json['highwayMpg'] as num?)?.toDouble(),
      seatingCapacity: (json['seatingCapacity'] as num?)?.toInt(),
      drivetrain: json['drivetrain'] as String?,
    );

Map<String, dynamic> _$VehicleSpecsToJson(VehicleSpecs instance) =>
    <String, dynamic>{
      'engine': instance.engine,
      'transmission': instance.transmission,
      'horsepower': instance.horsepower,
      'torque': instance.torque,
      'fuelCapacity': instance.fuelCapacity,
      'cityMpg': instance.cityMpg,
      'highwayMpg': instance.highwayMpg,
      'seatingCapacity': instance.seatingCapacity,
      'drivetrain': instance.drivetrain,
    };

VehicleHealth _$VehicleHealthFromJson(Map<String, dynamic> json) =>
    VehicleHealth(
      vehicleId: json['vehicleId'] as String,
      overallScore: (json['overallScore'] as num).toDouble(),
      engine: EngineHealth.fromJson(json['engine'] as Map<String, dynamic>),
      battery: BatteryHealth.fromJson(json['battery'] as Map<String, dynamic>),
      transmission: TransmissionHealth.fromJson(
          json['transmission'] as Map<String, dynamic>),
      brakes: BrakesHealth.fromJson(json['brakes'] as Map<String, dynamic>),
      tires: TiresHealth.fromJson(json['tires'] as Map<String, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$VehicleHealthToJson(VehicleHealth instance) =>
    <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'overallScore': instance.overallScore,
      'engine': instance.engine,
      'battery': instance.battery,
      'transmission': instance.transmission,
      'brakes': instance.brakes,
      'tires': instance.tires,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

EngineHealth _$EngineHealthFromJson(Map<String, dynamic> json) => EngineHealth(
      score: (json['score'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      oilPressure: (json['oilPressure'] as num).toDouble(),
      rpm: (json['rpm'] as num).toDouble(),
      issues:
          (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$EngineHealthToJson(EngineHealth instance) =>
    <String, dynamic>{
      'score': instance.score,
      'temperature': instance.temperature,
      'oilPressure': instance.oilPressure,
      'rpm': instance.rpm,
      'issues': instance.issues,
    };

BatteryHealth _$BatteryHealthFromJson(Map<String, dynamic> json) =>
    BatteryHealth(
      score: (json['score'] as num).toDouble(),
      voltage: (json['voltage'] as num).toDouble(),
      chargeLevel: (json['chargeLevel'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      issues:
          (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BatteryHealthToJson(BatteryHealth instance) =>
    <String, dynamic>{
      'score': instance.score,
      'voltage': instance.voltage,
      'chargeLevel': instance.chargeLevel,
      'temperature': instance.temperature,
      'issues': instance.issues,
    };

TransmissionHealth _$TransmissionHealthFromJson(Map<String, dynamic> json) =>
    TransmissionHealth(
      score: (json['score'] as num).toDouble(),
      fluidLevel: (json['fluidLevel'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      issues:
          (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TransmissionHealthToJson(TransmissionHealth instance) =>
    <String, dynamic>{
      'score': instance.score,
      'fluidLevel': instance.fluidLevel,
      'temperature': instance.temperature,
      'issues': instance.issues,
    };

BrakesHealth _$BrakesHealthFromJson(Map<String, dynamic> json) => BrakesHealth(
      score: (json['score'] as num).toDouble(),
      padThickness: (json['padThickness'] as num).toDouble(),
      fluidLevel: (json['fluidLevel'] as num).toDouble(),
      issues:
          (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BrakesHealthToJson(BrakesHealth instance) =>
    <String, dynamic>{
      'score': instance.score,
      'padThickness': instance.padThickness,
      'fluidLevel': instance.fluidLevel,
      'issues': instance.issues,
    };

TiresHealth _$TiresHealthFromJson(Map<String, dynamic> json) => TiresHealth(
      score: (json['score'] as num).toDouble(),
      frontLeftPressure: (json['frontLeftPressure'] as num).toDouble(),
      frontRightPressure: (json['frontRightPressure'] as num).toDouble(),
      rearLeftPressure: (json['rearLeftPressure'] as num).toDouble(),
      rearRightPressure: (json['rearRightPressure'] as num).toDouble(),
      treadDepth: (json['treadDepth'] as num).toDouble(),
      issues:
          (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TiresHealthToJson(TiresHealth instance) =>
    <String, dynamic>{
      'score': instance.score,
      'frontLeftPressure': instance.frontLeftPressure,
      'frontRightPressure': instance.frontRightPressure,
      'rearLeftPressure': instance.rearLeftPressure,
      'rearRightPressure': instance.rearRightPressure,
      'treadDepth': instance.treadDepth,
      'issues': instance.issues,
    };

TelemetryData _$TelemetryDataFromJson(Map<String, dynamic> json) =>
    TelemetryData(
      vehicleId: json['vehicleId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
      speed: (json['speed'] as num).toDouble(),
      engine: EngineMetrics.fromJson(json['engine'] as Map<String, dynamic>),
      battery: BatteryMetrics.fromJson(json['battery'] as Map<String, dynamic>),
      fuel: FuelMetrics.fromJson(json['fuel'] as Map<String, dynamic>),
      diagnosticCodes: (json['diagnosticCodes'] as List<dynamic>)
          .map((e) => DiagnosticCode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TelemetryDataToJson(TelemetryData instance) =>
    <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'timestamp': instance.timestamp.toIso8601String(),
      'location': instance.location,
      'speed': instance.speed,
      'engine': instance.engine,
      'battery': instance.battery,
      'fuel': instance.fuel,
      'diagnosticCodes': instance.diagnosticCodes,
    };

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'accuracy': instance.accuracy,
    };

EngineMetrics _$EngineMetricsFromJson(Map<String, dynamic> json) =>
    EngineMetrics(
      rpm: (json['rpm'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      oilPressure: (json['oilPressure'] as num).toDouble(),
      load: (json['load'] as num).toDouble(),
    );

Map<String, dynamic> _$EngineMetricsToJson(EngineMetrics instance) =>
    <String, dynamic>{
      'rpm': instance.rpm,
      'temperature': instance.temperature,
      'oilPressure': instance.oilPressure,
      'load': instance.load,
    };

BatteryMetrics _$BatteryMetricsFromJson(Map<String, dynamic> json) =>
    BatteryMetrics(
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      chargeLevel: (json['chargeLevel'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
    );

Map<String, dynamic> _$BatteryMetricsToJson(BatteryMetrics instance) =>
    <String, dynamic>{
      'voltage': instance.voltage,
      'current': instance.current,
      'chargeLevel': instance.chargeLevel,
      'temperature': instance.temperature,
    };

FuelMetrics _$FuelMetricsFromJson(Map<String, dynamic> json) => FuelMetrics(
      level: (json['level'] as num).toDouble(),
      consumption: (json['consumption'] as num).toDouble(),
      efficiency: (json['efficiency'] as num).toDouble(),
    );

Map<String, dynamic> _$FuelMetricsToJson(FuelMetrics instance) =>
    <String, dynamic>{
      'level': instance.level,
      'consumption': instance.consumption,
      'efficiency': instance.efficiency,
    };

DiagnosticCode _$DiagnosticCodeFromJson(Map<String, dynamic> json) =>
    DiagnosticCode(
      code: json['code'] as String,
      description: json['description'] as String,
      severity: $enumDecode(_$DiagnosticSeverityEnumMap, json['severity']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$DiagnosticCodeToJson(DiagnosticCode instance) =>
    <String, dynamic>{
      'code': instance.code,
      'description': instance.description,
      'severity': _$DiagnosticSeverityEnumMap[instance.severity]!,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$DiagnosticSeverityEnumMap = {
  DiagnosticSeverity.info: 'info',
  DiagnosticSeverity.warning: 'warning',
  DiagnosticSeverity.error: 'error',
  DiagnosticSeverity.critical: 'critical',
};

