// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAppointment _$ServiceAppointmentFromJson(Map<String, dynamic> json) =>
    ServiceAppointment(
      id: json['id'] as String,
      serviceCenterId: json['serviceCenterId'] as String,
      serviceCenterName: json['serviceCenterName'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      customerEmail: json['customerEmail'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      timeSlot: json['timeSlot'] as String,
      requestedServices: (json['requestedServices'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      vehicleInfo: json['vehicleInfo'] as String,
      specialRequests: json['specialRequests'] as String?,
      status: $enumDecode(_$AppointmentStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      confirmationCode: json['confirmationCode'] as String?,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)
          ?.toInt(),
    );

Map<String, dynamic> _$ServiceAppointmentToJson(ServiceAppointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceCenterId': instance.serviceCenterId,
      'serviceCenterName': instance.serviceCenterName,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'customerEmail': instance.customerEmail,
      'appointmentDate': instance.appointmentDate.toIso8601String(),
      'timeSlot': instance.timeSlot,
      'requestedServices': instance.requestedServices,
      'vehicleInfo': instance.vehicleInfo,
      'specialRequests': instance.specialRequests,
      'status': _$AppointmentStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'confirmationCode': instance.confirmationCode,
      'estimatedCost': instance.estimatedCost,
      'estimatedDurationMinutes': instance.estimatedDurationMinutes,
    };

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.pending: 'pending',
  AppointmentStatus.confirmed: 'confirmed',
  AppointmentStatus.inProgress: 'inProgress',
  AppointmentStatus.completed: 'completed',
  AppointmentStatus.cancelled: 'cancelled',
  AppointmentStatus.noShow: 'noShow',
};

TimeSlot _$TimeSlotFromJson(Map<String, dynamic> json) => TimeSlot(
  id: json['id'] as String,
  date: DateTime.parse(json['date'] as String),
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  isAvailable: json['isAvailable'] as bool,
  maxCapacity: (json['maxCapacity'] as num).toInt(),
  currentBookings: (json['currentBookings'] as num).toInt(),
  availableServices: (json['availableServices'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TimeSlotToJson(TimeSlot instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'isAvailable': instance.isAvailable,
  'maxCapacity': instance.maxCapacity,
  'currentBookings': instance.currentBookings,
  'availableServices': instance.availableServices,
};

ServiceCenterAvailability _$ServiceCenterAvailabilityFromJson(
  Map<String, dynamic> json,
) => ServiceCenterAvailability(
  serviceCenterId: json['serviceCenterId'] as String,
  date: DateTime.parse(json['date'] as String),
  timeSlots: (json['timeSlots'] as List<dynamic>)
      .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  availableServices: (json['availableServices'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  servicePrices: (json['servicePrices'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  serviceDurations: Map<String, int>.from(json['serviceDurations'] as Map),
  specialNotes: json['specialNotes'] as String?,
);

Map<String, dynamic> _$ServiceCenterAvailabilityToJson(
  ServiceCenterAvailability instance,
) => <String, dynamic>{
  'serviceCenterId': instance.serviceCenterId,
  'date': instance.date.toIso8601String(),
  'timeSlots': instance.timeSlots,
  'availableServices': instance.availableServices,
  'servicePrices': instance.servicePrices,
  'serviceDurations': instance.serviceDurations,
  'specialNotes': instance.specialNotes,
};

BookingRequest _$BookingRequestFromJson(Map<String, dynamic> json) =>
    BookingRequest(
      serviceCenterId: json['serviceCenterId'] as String,
      preferredDate: DateTime.parse(json['preferredDate'] as String),
      preferredTimeSlot: json['preferredTimeSlot'] as String?,
      requestedServices: (json['requestedServices'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      customerInfo: CustomerInfo.fromJson(
        json['customerInfo'] as Map<String, dynamic>,
      ),
      vehicleInfo: VehicleInfo.fromJson(
        json['vehicleInfo'] as Map<String, dynamic>,
      ),
      specialRequests: json['specialRequests'] as String?,
      flexibleTiming: json['flexibleTiming'] as bool? ?? false,
      alternativeDates: (json['alternativeDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
    );

Map<String, dynamic> _$BookingRequestToJson(BookingRequest instance) =>
    <String, dynamic>{
      'serviceCenterId': instance.serviceCenterId,
      'preferredDate': instance.preferredDate.toIso8601String(),
      'preferredTimeSlot': instance.preferredTimeSlot,
      'requestedServices': instance.requestedServices,
      'customerInfo': instance.customerInfo,
      'vehicleInfo': instance.vehicleInfo,
      'specialRequests': instance.specialRequests,
      'flexibleTiming': instance.flexibleTiming,
      'alternativeDates': instance.alternativeDates
          ?.map((e) => e.toIso8601String())
          .toList(),
    };

CustomerInfo _$CustomerInfoFromJson(Map<String, dynamic> json) => CustomerInfo(
  name: json['name'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  address: json['address'] as String?,
  isReturningCustomer: json['isReturningCustomer'] as bool? ?? false,
  loyaltyNumber: json['loyaltyNumber'] as String?,
);

Map<String, dynamic> _$CustomerInfoToJson(CustomerInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'isReturningCustomer': instance.isReturningCustomer,
      'loyaltyNumber': instance.loyaltyNumber,
    };

VehicleInfo _$VehicleInfoFromJson(Map<String, dynamic> json) => VehicleInfo(
  make: json['make'] as String,
  model: json['model'] as String,
  year: (json['year'] as num).toInt(),
  licensePlate: json['licensePlate'] as String?,
  vin: json['vin'] as String?,
  mileage: (json['mileage'] as num?)?.toInt(),
  fuelType: json['fuelType'] as String,
  color: json['color'] as String?,
);

Map<String, dynamic> _$VehicleInfoToJson(VehicleInfo instance) =>
    <String, dynamic>{
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'licensePlate': instance.licensePlate,
      'vin': instance.vin,
      'mileage': instance.mileage,
      'fuelType': instance.fuelType,
      'color': instance.color,
    };

BookingConfirmation _$BookingConfirmationFromJson(Map<String, dynamic> json) =>
    BookingConfirmation(
      appointment: ServiceAppointment.fromJson(
        json['appointment'] as Map<String, dynamic>,
      ),
      confirmationMessage: json['confirmationMessage'] as String,
      preparationInstructions:
          (json['preparationInstructions'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      whatToBring: (json['whatToBring'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      cancellationPolicy: json['cancellationPolicy'] as String?,
      reschedulePolicy: json['reschedulePolicy'] as String?,
      serviceCenter: ContactInfo.fromJson(
        json['serviceCenter'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BookingConfirmationToJson(
  BookingConfirmation instance,
) => <String, dynamic>{
  'appointment': instance.appointment,
  'confirmationMessage': instance.confirmationMessage,
  'preparationInstructions': instance.preparationInstructions,
  'whatToBring': instance.whatToBring,
  'cancellationPolicy': instance.cancellationPolicy,
  'reschedulePolicy': instance.reschedulePolicy,
  'serviceCenter': instance.serviceCenter,
};

ContactInfo _$ContactInfoFromJson(Map<String, dynamic> json) => ContactInfo(
  name: json['name'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  address: json['address'] as String,
  website: json['website'] as String?,
);

Map<String, dynamic> _$ContactInfoToJson(ContactInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'website': instance.website,
    };

ServiceReminder _$ServiceReminderFromJson(Map<String, dynamic> json) =>
    ServiceReminder(
      id: json['id'] as String,
      appointmentId: json['appointmentId'] as String,
      reminderTime: DateTime.parse(json['reminderTime'] as String),
      message: json['message'] as String,
      type: $enumDecode(_$ReminderTypeEnumMap, json['type']),
      isSent: json['isSent'] as bool,
    );

Map<String, dynamic> _$ServiceReminderToJson(ServiceReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appointmentId': instance.appointmentId,
      'reminderTime': instance.reminderTime.toIso8601String(),
      'message': instance.message,
      'type': _$ReminderTypeEnumMap[instance.type]!,
      'isSent': instance.isSent,
    };

const _$ReminderTypeEnumMap = {
  ReminderType.confirmation: 'confirmation',
  ReminderType.dayBefore: 'dayBefore',
  ReminderType.hourBefore: 'hourBefore',
  ReminderType.arrival: 'arrival',
};

BookingPreferences _$BookingPreferencesFromJson(Map<String, dynamic> json) =>
    BookingPreferences(
      preferredServiceCenter: json['preferredServiceCenter'] as String?,
      preferredTimeSlots:
          (json['preferredTimeSlots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      allowFlexibleTiming: json['allowFlexibleTiming'] as bool? ?? true,
      reminderHoursBefore: (json['reminderHoursBefore'] as num?)?.toInt() ?? 24,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      defaultCustomerInfo: json['defaultCustomerInfo'] == null
          ? null
          : CustomerInfo.fromJson(
              json['defaultCustomerInfo'] as Map<String, dynamic>,
            ),
      defaultVehicleInfo: json['defaultVehicleInfo'] == null
          ? null
          : VehicleInfo.fromJson(
              json['defaultVehicleInfo'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BookingPreferencesToJson(BookingPreferences instance) =>
    <String, dynamic>{
      'preferredServiceCenter': instance.preferredServiceCenter,
      'preferredTimeSlots': instance.preferredTimeSlots,
      'allowFlexibleTiming': instance.allowFlexibleTiming,
      'reminderHoursBefore': instance.reminderHoursBefore,
      'emailNotifications': instance.emailNotifications,
      'smsNotifications': instance.smsNotifications,
      'pushNotifications': instance.pushNotifications,
      'defaultCustomerInfo': instance.defaultCustomerInfo,
      'defaultVehicleInfo': instance.defaultVehicleInfo,
    };

