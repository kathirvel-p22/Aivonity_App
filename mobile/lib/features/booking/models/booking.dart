/// AIVONITY Booking Model
/// Represents a service booking with all details
class Booking {
  final String id;
  final String vehicleId;
  final String serviceCenterId;
  final String serviceType;
  final DateTime appointmentDateTime;
  final String? description;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const Booking({
    required this.id,
    required this.vehicleId,
    required this.serviceCenterId,
    required this.serviceType,
    required this.appointmentDateTime,
    this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      serviceCenterId: json['serviceCenterId'] as String,
      serviceType: json['serviceType'] as String,
      appointmentDateTime: DateTime.parse(
        json['appointmentDateTime'] as String,
      ),
      description: json['description'] as String?,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceCenterId': serviceCenterId,
      'serviceType': serviceType,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Booking copyWith({
    String? id,
    String? vehicleId,
    String? serviceCenterId,
    String? serviceType,
    DateTime? appointmentDateTime,
    String? description,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Booking(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceCenterId: serviceCenterId ?? this.serviceCenterId,
      serviceType: serviceType ?? this.serviceType,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Booking Status Enum
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled,
}

/// Service Type Enum
enum ServiceType {
  maintenance,
  repair,
  inspection,
  oilChange,
  tireService,
  batteryService,
  brakeService,
  engineService,
  transmission,
  airConditioning,
  electrical,
  bodyWork,
  other,
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.maintenance:
        return 'General Maintenance';
      case ServiceType.repair:
        return 'Repair Service';
      case ServiceType.inspection:
        return 'Vehicle Inspection';
      case ServiceType.oilChange:
        return 'Oil Change';
      case ServiceType.tireService:
        return 'Tire Service';
      case ServiceType.batteryService:
        return 'Battery Service';
      case ServiceType.brakeService:
        return 'Brake Service';
      case ServiceType.engineService:
        return 'Engine Service';
      case ServiceType.transmission:
        return 'Transmission Service';
      case ServiceType.airConditioning:
        return 'A/C Service';
      case ServiceType.electrical:
        return 'Electrical Service';
      case ServiceType.bodyWork:
        return 'Body Work';
      case ServiceType.other:
        return 'Other Service';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.maintenance:
        return 'Regular maintenance and check-up';
      case ServiceType.repair:
        return 'Fix specific issues or problems';
      case ServiceType.inspection:
        return 'Safety and emissions inspection';
      case ServiceType.oilChange:
        return 'Engine oil and filter replacement';
      case ServiceType.tireService:
        return 'Tire rotation, balancing, or replacement';
      case ServiceType.batteryService:
        return 'Battery testing and replacement';
      case ServiceType.brakeService:
        return 'Brake pad and system service';
      case ServiceType.engineService:
        return 'Engine diagnostics and repair';
      case ServiceType.transmission:
        return 'Transmission service and repair';
      case ServiceType.airConditioning:
        return 'A/C system service and repair';
      case ServiceType.electrical:
        return 'Electrical system diagnostics';
      case ServiceType.bodyWork:
        return 'Exterior and interior repairs';
      case ServiceType.other:
        return 'Custom or specialized service';
    }
  }
}

