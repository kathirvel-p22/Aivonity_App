/// AIVONITY Vehicle Model
/// Comprehensive vehicle model without external dependencies
class VehicleModel {
  final String id;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String color;
  final int mileage;
  final String fuelType;
  final VehicleHealth health;
  final List<MaintenanceRecord> maintenanceHistory;
  final VehicleStats stats;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VehicleModel({
    required this.id,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.mileage,
    required this.fuelType,
    required this.health,
    this.maintenanceHistory = const [],
    required this.stats,
    required this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      vin: json['vin'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      mileage: json['mileage'] as int,
      fuelType: json['fuelType'] as String,
      health: VehicleHealth.fromJson(json['health'] as Map<String, dynamic>),
      maintenanceHistory:
          (json['maintenanceHistory'] as List<dynamic>?)
              ?.map(
                (e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      stats: VehicleStats.fromJson(json['stats'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'mileage': mileage,
      'fuelType': fuelType,
      'health': health.toJson(),
      'maintenanceHistory': maintenanceHistory.map((e) => e.toJson()).toList(),
      'stats': stats.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? vin,
    String? make,
    String? model,
    int? year,
    String? color,
    int? mileage,
    String? fuelType,
    VehicleHealth? health,
    List<MaintenanceRecord>? maintenanceHistory,
    VehicleStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      health: health ?? this.health,
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Vehicle Health Model
class VehicleHealth {
  final double overallScore;
  final List<ComponentHealth> components;
  final List<HealthAlert> alerts;
  final DateTime lastUpdated;

  const VehicleHealth({
    required this.overallScore,
    this.components = const [],
    this.alerts = const [],
    required this.lastUpdated,
  });

  factory VehicleHealth.fromJson(Map<String, dynamic> json) {
    return VehicleHealth(
      overallScore: (json['overallScore'] as num).toDouble(),
      components:
          (json['components'] as List<dynamic>?)
              ?.map((e) => ComponentHealth.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alerts:
          (json['alerts'] as List<dynamic>?)
              ?.map((e) => HealthAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'components': components.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  VehicleHealth copyWith({
    double? overallScore,
    List<ComponentHealth>? components,
    List<HealthAlert>? alerts,
    DateTime? lastUpdated,
  }) {
    return VehicleHealth(
      overallScore: overallScore ?? this.overallScore,
      components: components ?? this.components,
      alerts: alerts ?? this.alerts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Component Health Model
class ComponentHealth {
  final String componentName;
  final double healthScore;
  final String status;
  final String? description;
  final DateTime lastChecked;

  const ComponentHealth({
    required this.componentName,
    required this.healthScore,
    required this.status,
    this.description,
    required this.lastChecked,
  });

  factory ComponentHealth.fromJson(Map<String, dynamic> json) {
    return ComponentHealth(
      componentName: json['componentName'] as String,
      healthScore: (json['healthScore'] as num).toDouble(),
      status: json['status'] as String,
      description: json['description'] as String?,
      lastChecked: DateTime.parse(json['lastChecked'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'componentName': componentName,
      'healthScore': healthScore,
      'status': status,
      'description': description,
      'lastChecked': lastChecked.toIso8601String(),
    };
  }

  ComponentHealth copyWith({
    String? componentName,
    double? healthScore,
    String? status,
    String? description,
    DateTime? lastChecked,
  }) {
    return ComponentHealth(
      componentName: componentName ?? this.componentName,
      healthScore: healthScore ?? this.healthScore,
      status: status ?? this.status,
      description: description ?? this.description,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// Health Alert Model
class HealthAlert {
  final String id;
  final String title;
  final String description;
  final HealthAlertSeverity severity;
  final String category;
  final DateTime timestamp;
  final List<String>? recommendations;

  const HealthAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.timestamp,
    this.recommendations,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: HealthAlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => HealthAlertSeverity.medium,
      ),
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'recommendations': recommendations,
    };
  }

  HealthAlert copyWith({
    String? id,
    String? title,
    String? description,
    HealthAlertSeverity? severity,
    String? category,
    DateTime? timestamp,
    List<String>? recommendations,
  }) {
    return HealthAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

/// Maintenance Record Model
class MaintenanceRecord {
  final String id;
  final String serviceType;
  final String serviceCenterName;
  final DateTime serviceDate;
  final int mileageAtService;
  final double cost;
  final String status;
  final String? notes;
  final List<String> servicesPerformed;

  const MaintenanceRecord({
    required this.id,
    required this.serviceType,
    required this.serviceCenterName,
    required this.serviceDate,
    required this.mileageAtService,
    required this.cost,
    required this.status,
    this.notes,
    this.servicesPerformed = const [],
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      serviceType: json['serviceType'] as String,
      serviceCenterName: json['serviceCenterName'] as String,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      mileageAtService: json['mileageAtService'] as int,
      cost: (json['cost'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      servicesPerformed:
          (json['servicesPerformed'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'serviceCenterName': serviceCenterName,
      'serviceDate': serviceDate.toIso8601String(),
      'mileageAtService': mileageAtService,
      'cost': cost,
      'status': status,
      'notes': notes,
      'servicesPerformed': servicesPerformed,
    };
  }

  MaintenanceRecord copyWith({
    String? id,
    String? serviceType,
    String? serviceCenterName,
    DateTime? serviceDate,
    int? mileageAtService,
    double? cost,
    String? status,
    String? notes,
    List<String>? servicesPerformed,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      serviceCenterName: serviceCenterName ?? this.serviceCenterName,
      serviceDate: serviceDate ?? this.serviceDate,
      mileageAtService: mileageAtService ?? this.mileageAtService,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      servicesPerformed: servicesPerformed ?? this.servicesPerformed,
    );
  }
}

/// Vehicle Stats Model
class VehicleStats {
  final double averageFuelEfficiency;
  final int totalMilesDriven;
  final double totalFuelConsumed;
  final int totalTrips;
  final Duration totalDrivingTime;

  const VehicleStats({
    required this.averageFuelEfficiency,
    required this.totalMilesDriven,
    required this.totalFuelConsumed,
    required this.totalTrips,
    required this.totalDrivingTime,
  });

  factory VehicleStats.fromJson(Map<String, dynamic> json) {
    return VehicleStats(
      averageFuelEfficiency: (json['averageFuelEfficiency'] as num).toDouble(),
      totalMilesDriven: json['totalMilesDriven'] as int,
      totalFuelConsumed: (json['totalFuelConsumed'] as num).toDouble(),
      totalTrips: json['totalTrips'] as int,
      totalDrivingTime: Duration(
        seconds: json['totalDrivingTimeSeconds'] as int,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageFuelEfficiency': averageFuelEfficiency,
      'totalMilesDriven': totalMilesDriven,
      'totalFuelConsumed': totalFuelConsumed,
      'totalTrips': totalTrips,
      'totalDrivingTimeSeconds': totalDrivingTime.inSeconds,
    };
  }

  VehicleStats copyWith({
    double? averageFuelEfficiency,
    int? totalMilesDriven,
    double? totalFuelConsumed,
    int? totalTrips,
    Duration? totalDrivingTime,
  }) {
    return VehicleStats(
      averageFuelEfficiency:
          averageFuelEfficiency ?? this.averageFuelEfficiency,
      totalMilesDriven: totalMilesDriven ?? this.totalMilesDriven,
      totalFuelConsumed: totalFuelConsumed ?? this.totalFuelConsumed,
      totalTrips: totalTrips ?? this.totalTrips,
      totalDrivingTime: totalDrivingTime ?? this.totalDrivingTime,
    );
  }
}

/// Health Alert Severity Enum
enum HealthAlertSeverity { low, medium, high, critical }

/// Vehicle Type Enum
enum VehicleType {
  sedan,
  suv,
  hatchback,
  coupe,
  truck,
  motorcycle,
  electric,
  hybrid,
}

/// Fuel Type Enum
enum FuelType { gasoline, diesel, electric, hybrid, cng, lpg }

/// Vehicle Status Enum
enum VehicleStatus { active, inactive, maintenance, retired }

