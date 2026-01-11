import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';

class BookingService {
  final SharedPreferences _prefs;

  static const String _appointmentsKey = 'service_appointments';
  static const String _bookingPreferencesKey = 'booking_preferences';

  List<ServiceAppointment> _appointments = [];
  BookingPreferences _preferences = const BookingPreferences();

  BookingService(this._prefs) {
    _loadStoredData();
  }

  /// Get available time slots for a service center on a specific date
  Future<ServiceCenterAvailability> getAvailability({
    required String serviceCenterId,
    required DateTime date,
  }) async {
    // Simulate API call to get real availability
    await Future.delayed(const Duration(milliseconds: 500));

    return _generateMockAvailability(serviceCenterId, date);
  }

  /// Get availability for multiple days
  Future<List<ServiceCenterAvailability>> getMultiDayAvailability({
    required String serviceCenterId,
    required DateTime startDate,
    int days = 7,
  }) async {
    final availabilities = <ServiceCenterAvailability>[];

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final availability = await getAvailability(
        serviceCenterId: serviceCenterId,
        date: date,
      );
      availabilities.add(availability);
    }

    return availabilities;
  }

  /// Book an appointment
  Future<BookingConfirmation> bookAppointment(BookingRequest request) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Validate availability
    final availability = await getAvailability(
      serviceCenterId: request.serviceCenterId,
      date: request.preferredDate,
    );

    final selectedTimeSlot = request.preferredTimeSlot != null
        ? availability.timeSlots.firstWhere(
            (slot) => slot.displayTime == request.preferredTimeSlot,
            orElse: () => availability.availableTimeSlots.first,
          )
        : availability.availableTimeSlots.first;

    if (!selectedTimeSlot.hasAvailability) {
      throw Exception('Selected time slot is no longer available');
    }

    // Calculate estimated cost and duration
    double estimatedCost = 0.0;
    int estimatedDuration = 0;

    for (final service in request.requestedServices) {
      estimatedCost += availability.servicePrices[service] ?? 0.0;
      estimatedDuration += availability.serviceDurations[service] ?? 60;
    }

    // Create appointment
    final appointment = ServiceAppointment(
      id: _generateAppointmentId(),
      serviceCenterId: request.serviceCenterId,
      serviceCenterName: 'Service Center', // Would come from API
      customerName: request.customerInfo.name,
      customerPhone: request.customerInfo.phone,
      customerEmail: request.customerInfo.email,
      appointmentDate: request.preferredDate,
      timeSlot: selectedTimeSlot.displayTime,
      requestedServices: request.requestedServices,
      vehicleInfo:
          '${request.vehicleInfo.displayName} - ${request.vehicleInfo.licensePlate ?? 'N/A'}',
      specialRequests: request.specialRequests,
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
      confirmationCode: _generateConfirmationCode(),
      estimatedCost: estimatedCost,
      estimatedDurationMinutes: estimatedDuration,
    );

    // Store appointment
    _appointments.add(appointment);
    await _saveAppointments();

    // Schedule reminders
    await _scheduleReminders(appointment);

    // Create confirmation
    final confirmation = BookingConfirmation(
      appointment: appointment,
      confirmationMessage: 'Your appointment has been successfully booked!',
      preparationInstructions: _getPreparationInstructions(
        request.requestedServices,
      ),
      whatToBring: _getWhatToBring(request.requestedServices),
      cancellationPolicy:
          'Appointments can be cancelled up to 24 hours in advance without penalty.',
      reschedulePolicy:
          'Appointments can be rescheduled up to 4 hours in advance.',
      serviceCenter: ContactInfo(
        name: 'Service Center', // Would come from API
        phone: '+1-555-0123',
        email: 'service@example.com',
        address: '123 Service St, City, State 12345',
        website: 'https://example.com',
      ),
    );

    return confirmation;
  }

  /// Get user's appointments
  List<ServiceAppointment> getAppointments({
    AppointmentStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    var filtered = _appointments.where((appointment) {
      if (status != null && appointment.status != status) return false;
      if (fromDate != null && appointment.appointmentDate.isBefore(fromDate)) {
        return false;
      }
      if (toDate != null && appointment.appointmentDate.isAfter(toDate)) {
        return false;
      }
      return true;
    }).toList();

    // Sort by appointment date
    filtered.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    return filtered;
  }

  /// Get upcoming appointments
  List<ServiceAppointment> getUpcomingAppointments() {
    final now = DateTime.now();
    return getAppointments(fromDate: now)
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.pending ||
              appointment.status == AppointmentStatus.confirmed,
        )
        .toList();
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index == -1) return false;

    final appointment = _appointments[index];

    // Check if cancellation is allowed (24 hours before)
    final hoursUntilAppointment = appointment.appointmentDate
        .difference(DateTime.now())
        .inHours;
    if (hoursUntilAppointment < 24) {
      throw Exception('Appointments can only be cancelled 24 hours in advance');
    }

    // Update appointment status
    final updatedAppointment = ServiceAppointment(
      id: appointment.id,
      serviceCenterId: appointment.serviceCenterId,
      serviceCenterName: appointment.serviceCenterName,
      customerName: appointment.customerName,
      customerPhone: appointment.customerPhone,
      customerEmail: appointment.customerEmail,
      appointmentDate: appointment.appointmentDate,
      timeSlot: appointment.timeSlot,
      requestedServices: appointment.requestedServices,
      vehicleInfo: appointment.vehicleInfo,
      specialRequests: appointment.specialRequests,
      status: AppointmentStatus.cancelled,
      createdAt: appointment.createdAt,
      confirmedAt: appointment.confirmedAt,
      confirmationCode: appointment.confirmationCode,
      estimatedCost: appointment.estimatedCost,
      estimatedDurationMinutes: appointment.estimatedDurationMinutes,
    );

    _appointments[index] = updatedAppointment;
    await _saveAppointments();

    return true;
  }

  /// Reschedule an appointment
  Future<BookingConfirmation> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index == -1) throw Exception('Appointment not found');

    final appointment = _appointments[index];

    // Check if rescheduling is allowed (4 hours before)
    final hoursUntilAppointment = appointment.appointmentDate
        .difference(DateTime.now())
        .inHours;
    if (hoursUntilAppointment < 4) {
      throw Exception(
        'Appointments can only be rescheduled 4 hours in advance',
      );
    }

    // Check new slot availability
    final availability = await getAvailability(
      serviceCenterId: appointment.serviceCenterId,
      date: newDate,
    );

    final selectedTimeSlot = availability.timeSlots.firstWhere(
      (slot) => slot.displayTime == newTimeSlot,
      orElse: () => throw Exception('Selected time slot is not available'),
    );

    if (!selectedTimeSlot.hasAvailability) {
      throw Exception('Selected time slot is no longer available');
    }

    // Update appointment
    final updatedAppointment = ServiceAppointment(
      id: appointment.id,
      serviceCenterId: appointment.serviceCenterId,
      serviceCenterName: appointment.serviceCenterName,
      customerName: appointment.customerName,
      customerPhone: appointment.customerPhone,
      customerEmail: appointment.customerEmail,
      appointmentDate: newDate,
      timeSlot: newTimeSlot,
      requestedServices: appointment.requestedServices,
      vehicleInfo: appointment.vehicleInfo,
      specialRequests: appointment.specialRequests,
      status: AppointmentStatus.pending,
      createdAt: appointment.createdAt,
      confirmedAt: null,
      confirmationCode: appointment.confirmationCode,
      estimatedCost: appointment.estimatedCost,
      estimatedDurationMinutes: appointment.estimatedDurationMinutes,
    );

    _appointments[index] = updatedAppointment;
    await _saveAppointments();

    // Schedule new reminders
    await _scheduleReminders(updatedAppointment);

    return BookingConfirmation(
      appointment: updatedAppointment,
      confirmationMessage:
          'Your appointment has been successfully rescheduled!',
      preparationInstructions: _getPreparationInstructions(
        updatedAppointment.requestedServices,
      ),
      whatToBring: _getWhatToBring(updatedAppointment.requestedServices),
      cancellationPolicy:
          'Appointments can be cancelled up to 24 hours in advance without penalty.',
      reschedulePolicy:
          'Appointments can be rescheduled up to 4 hours in advance.',
      serviceCenter: ContactInfo(
        name: updatedAppointment.serviceCenterName,
        phone: '+1-555-0123',
        email: 'service@example.com',
        address: '123 Service St, City, State 12345',
      ),
    );
  }

  /// Update booking preferences
  Future<void> updatePreferences(BookingPreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
  }

  /// Get current booking preferences
  BookingPreferences getPreferences() => _preferences;

  /// Get service price estimate
  Future<double> getServiceEstimate({
    required String serviceCenterId,
    required List<String> services,
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    final availability = await getAvailability(
      serviceCenterId: serviceCenterId,
      date: DateTime.now(),
    );

    double total = 0.0;
    for (final service in services) {
      total += availability.servicePrices[service] ?? 0.0;
    }

    return total;
  }

  /// Find alternative time slots if preferred is not available
  Future<List<TimeSlot>> findAlternativeSlots({
    required String serviceCenterId,
    required DateTime preferredDate,
    required List<String> services,
    int daysToSearch = 7,
  }) async {
    final alternatives = <TimeSlot>[];

    for (int i = 0; i < daysToSearch; i++) {
      final date = preferredDate.add(Duration(days: i));
      final availability = await getAvailability(
        serviceCenterId: serviceCenterId,
        date: date,
      );

      // Filter slots that support all requested services
      final compatibleSlots = availability.availableTimeSlots.where((slot) {
        return services.every(
          (service) => slot.availableServices.contains(service),
        );
      }).toList();

      alternatives.addAll(compatibleSlots);
    }

    return alternatives;
  }

  // Private helper methods

  ServiceCenterAvailability _generateMockAvailability(
    String serviceCenterId,
    DateTime date,
  ) {
    final random = Random();
    final timeSlots = <TimeSlot>[];

    // Generate time slots from 8 AM to 6 PM
    for (int hour = 8; hour < 18; hour++) {
      final startTime = '${hour.toString().padLeft(2, '0')}:00';
      final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';

      timeSlots.add(
        TimeSlot(
          id: '${serviceCenterId}_${date.toIso8601String().split('T')[0]}_$hour',
          date: date,
          startTime: startTime,
          endTime: endTime,
          isAvailable:
              random.nextBool() || hour < 12, // More availability in morning
          maxCapacity: 3,
          currentBookings: random.nextInt(3),
          availableServices: _getAvailableServices(),
        ),
      );
    }

    return ServiceCenterAvailability(
      serviceCenterId: serviceCenterId,
      date: date,
      timeSlots: timeSlots,
      availableServices: _getAvailableServices(),
      servicePrices: _getServicePrices(),
      serviceDurations: _getServiceDurations(),
      specialNotes:
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday
          ? 'Weekend hours: Limited services available'
          : null,
    );
  }

  List<String> _getAvailableServices() {
    return [
      'Oil Change',
      'Brake Inspection',
      'Tire Rotation',
      'Battery Test',
      'AC Service',
      'Engine Diagnostics',
      'Transmission Service',
      'Wheel Alignment',
      'Brake Pad Replacement',
      'Air Filter Replacement',
    ];
  }

  Map<String, double> _getServicePrices() {
    return {
      'Oil Change': 49.99,
      'Brake Inspection': 29.99,
      'Tire Rotation': 39.99,
      'Battery Test': 19.99,
      'AC Service': 89.99,
      'Engine Diagnostics': 99.99,
      'Transmission Service': 149.99,
      'Wheel Alignment': 79.99,
      'Brake Pad Replacement': 199.99,
      'Air Filter Replacement': 24.99,
    };
  }

  Map<String, int> _getServiceDurations() {
    return {
      'Oil Change': 30,
      'Brake Inspection': 45,
      'Tire Rotation': 30,
      'Battery Test': 15,
      'AC Service': 60,
      'Engine Diagnostics': 90,
      'Transmission Service': 120,
      'Wheel Alignment': 60,
      'Brake Pad Replacement': 90,
      'Air Filter Replacement': 15,
    };
  }

  List<String> _getPreparationInstructions(List<String> services) {
    final instructions = <String>[];

    if (services.contains('Oil Change')) {
      instructions.add('Check your current oil level before arrival');
    }
    if (services.contains('Brake Inspection') ||
        services.contains('Brake Pad Replacement')) {
      instructions.add('Note any unusual brake noises or vibrations');
    }
    if (services.contains('AC Service')) {
      instructions.add('Test your AC system and note any issues');
    }
    if (services.contains('Engine Diagnostics')) {
      instructions.add('Bring any error codes or warning lights information');
    }

    instructions.addAll([
      'Arrive 10 minutes early for check-in',
      'Remove personal items from your vehicle',
      'Ensure your fuel tank is at least 1/4 full',
    ]);

    return instructions;
  }

  List<String> _getWhatToBring(List<String> services) {
    final items = [
      'Driver\'s license',
      'Vehicle registration',
      'Insurance card',
      'Previous service records (if available)',
    ];

    if (services.contains('Engine Diagnostics')) {
      items.add('Any diagnostic codes or error messages');
    }

    return items;
  }

  String _generateAppointmentId() {
    return 'APT_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateConfirmationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _scheduleReminders(ServiceAppointment appointment) async {
    // In a real app, this would schedule push notifications
    // For now, we'll just simulate the scheduling

    // Store reminders (in a real app, these would be scheduled with the notification system)
  }

  Future<void> _loadStoredData() async {
    // Load appointments
    final appointmentsJson = _prefs.getStringList(_appointmentsKey) ?? [];
    _appointments = appointmentsJson
        .map((json) {
          try {
            final data = Uri.splitQueryString(json);
            return ServiceAppointment.fromJson(
              data.map((key, value) => MapEntry(key, value)),
            );
          } catch (e) {
            return null;
          }
        })
        .where((item) => item != null)
        .cast<ServiceAppointment>()
        .toList();

    // Load preferences
    final prefsJson = _prefs.getString(_bookingPreferencesKey);
    if (prefsJson != null) {
      try {
        final data = Uri.splitQueryString(prefsJson);
        _preferences = BookingPreferences.fromJson(
          data.map((key, value) => MapEntry(key, value)),
        );
      } catch (e) {
        _preferences = const BookingPreferences();
      }
    }
  }

  Future<void> _saveAppointments() async {
    final appointmentsJson = _appointments
        .map(
          (appointment) => Uri(
            queryParameters: appointment.toJson().map(
              (key, value) => MapEntry(key, value.toString()),
            ),
          ).query,
        )
        .toList();
    await _prefs.setStringList(_appointmentsKey, appointmentsJson);
  }

  Future<void> _savePreferences() async {
    final prefsJson = Uri(
      queryParameters: _preferences.toJson().map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ).query;
    await _prefs.setString(_bookingPreferencesKey, prefsJson);
  }
}
