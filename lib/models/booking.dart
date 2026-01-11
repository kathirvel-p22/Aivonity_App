import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class ServiceAppointment {
  final String id;
  final String serviceCenterId;
  final String serviceCenterName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final DateTime appointmentDate;
  final String timeSlot; // e.g., "09:00-10:00"
  final List<String> requestedServices;
  final String vehicleInfo;
  final String? specialRequests;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? confirmationCode;
  final double? estimatedCost;
  final int? estimatedDurationMinutes;

  const ServiceAppointment({
    required this.id,
    required this.serviceCenterId,
    required this.serviceCenterName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.appointmentDate,
    required this.timeSlot,
    required this.requestedServices,
    required this.vehicleInfo,
    this.specialRequests,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.confirmationCode,
    this.estimatedCost,
    this.estimatedDurationMinutes,
  });

  factory ServiceAppointment.fromJson(Map<String, dynamic> json) =>
      _$ServiceAppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAppointmentToJson(this);
}

enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

@JsonSerializable()
class TimeSlot {
  final String id;
  final DateTime date;
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final bool isAvailable;
  final int maxCapacity;
  final int currentBookings;
  final List<String> availableServices;

  const TimeSlot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.maxCapacity,
    required this.currentBookings,
    required this.availableServices,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);

  String get displayTime => '$startTime - $endTime';

  bool get hasAvailability => isAvailable && currentBookings < maxCapacity;
}

@JsonSerializable()
class ServiceCenterAvailability {
  final String serviceCenterId;
  final DateTime date;
  final List<TimeSlot> timeSlots;
  final List<String> availableServices;
  final Map<String, double> servicePrices;
  final Map<String, int> serviceDurations; // in minutes
  final String? specialNotes;

  const ServiceCenterAvailability({
    required this.serviceCenterId,
    required this.date,
    required this.timeSlots,
    required this.availableServices,
    required this.servicePrices,
    required this.serviceDurations,
    this.specialNotes,
  });

  factory ServiceCenterAvailability.fromJson(Map<String, dynamic> json) =>
      _$ServiceCenterAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCenterAvailabilityToJson(this);

  List<TimeSlot> get availableTimeSlots =>
      timeSlots.where((slot) => slot.hasAvailability).toList();
}

@JsonSerializable()
class BookingRequest {
  final String serviceCenterId;
  final DateTime preferredDate;
  final String? preferredTimeSlot;
  final List<String> requestedServices;
  final CustomerInfo customerInfo;
  final VehicleInfo vehicleInfo;
  final String? specialRequests;
  final bool flexibleTiming;
  final List<DateTime>? alternativeDates;

  const BookingRequest({
    required this.serviceCenterId,
    required this.preferredDate,
    this.preferredTimeSlot,
    required this.requestedServices,
    required this.customerInfo,
    required this.vehicleInfo,
    this.specialRequests,
    this.flexibleTiming = false,
    this.alternativeDates,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) =>
      _$BookingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BookingRequestToJson(this);
}

@JsonSerializable()
class CustomerInfo {
  final String name;
  final String phone;
  final String email;
  final String? address;
  final bool isReturningCustomer;
  final String? loyaltyNumber;

  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.email,
    this.address,
    this.isReturningCustomer = false,
    this.loyaltyNumber,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) =>
      _$CustomerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerInfoToJson(this);
}

@JsonSerializable()
class VehicleInfo {
  final String make;
  final String model;
  final int year;
  final String? licensePlate;
  final String? vin;
  final int? mileage;
  final String fuelType; // 'gasoline', 'diesel', 'electric', 'hybrid'
  final String? color;

  const VehicleInfo({
    required this.make,
    required this.model,
    required this.year,
    this.licensePlate,
    this.vin,
    this.mileage,
    required this.fuelType,
    this.color,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) =>
      _$VehicleInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleInfoToJson(this);

  String get displayName => '$year $make $model';
}

@JsonSerializable()
class BookingConfirmation {
  final ServiceAppointment appointment;
  final String confirmationMessage;
  final List<String> preparationInstructions;
  final List<String> whatToBring;
  final String? cancellationPolicy;
  final String? reschedulePolicy;
  final ContactInfo serviceCenter;

  const BookingConfirmation({
    required this.appointment,
    required this.confirmationMessage,
    required this.preparationInstructions,
    required this.whatToBring,
    this.cancellationPolicy,
    this.reschedulePolicy,
    required this.serviceCenter,
  });

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) =>
      _$BookingConfirmationFromJson(json);

  Map<String, dynamic> toJson() => _$BookingConfirmationToJson(this);
}

@JsonSerializable()
class ContactInfo {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? website;

  const ContactInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.website,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) =>
      _$ContactInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ContactInfoToJson(this);
}

@JsonSerializable()
class ServiceReminder {
  final String id;
  final String appointmentId;
  final DateTime reminderTime;
  final String message;
  final ReminderType type;
  final bool isSent;

  const ServiceReminder({
    required this.id,
    required this.appointmentId,
    required this.reminderTime,
    required this.message,
    required this.type,
    required this.isSent,
  });

  factory ServiceReminder.fromJson(Map<String, dynamic> json) =>
      _$ServiceReminderFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceReminderToJson(this);
}

enum ReminderType { confirmation, dayBefore, hourBefore, arrival }

@JsonSerializable()
class BookingPreferences {
  final String? preferredServiceCenter;
  final List<String> preferredTimeSlots;
  final bool allowFlexibleTiming;
  final int reminderHoursBefore;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final CustomerInfo? defaultCustomerInfo;
  final VehicleInfo? defaultVehicleInfo;

  const BookingPreferences({
    this.preferredServiceCenter,
    this.preferredTimeSlots = const [],
    this.allowFlexibleTiming = true,
    this.reminderHoursBefore = 24,
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.pushNotifications = true,
    this.defaultCustomerInfo,
    this.defaultVehicleInfo,
  });

  factory BookingPreferences.fromJson(Map<String, dynamic> json) =>
      _$BookingPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPreferencesToJson(this);
}

