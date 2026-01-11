import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service_centers_service.dart';

/// Booking Service
/// Manages service bookings with local storage
class BookingService {
  static const String _bookingsKey = 'service_bookings';
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  /// Save a new booking
  Future<bool> saveBooking(ServiceBooking booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookings = await getAllBookings();
      bookings.add(booking);

      final bookingsJson = bookings.map((b) => b.toJson()).toList();
      await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));
      return true;
    } catch (e) {
      print('Error saving booking: $e');
      return false;
    }
  }

  /// Get all bookings
  Future<List<ServiceBooking>> getAllBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_bookingsKey);

      if (bookingsJson == null) return [];

      final bookingsData = jsonDecode(bookingsJson) as List;
      return bookingsData.map((data) => ServiceBooking.fromJson(data)).toList();
    } catch (e) {
      print('Error loading bookings: $e');
      return [];
    }
  }

  /// Get upcoming bookings
  Future<List<ServiceBooking>> getUpcomingBookings() async {
    final allBookings = await getAllBookings();
    final now = DateTime.now();

    return allBookings.where((booking) {
      final bookingDateTime = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        booking.time.hour,
        booking.time.minute,
      );
      return bookingDateTime.isAfter(now) && booking.status == BookingStatus.confirmed;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get past bookings
  Future<List<ServiceBooking>> getPastBookings() async {
    final allBookings = await getAllBookings();
    final now = DateTime.now();

    return allBookings.where((booking) {
      final bookingDateTime = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        booking.time.hour,
        booking.time.minute,
      );
      return bookingDateTime.isBefore(now) || booking.status == BookingStatus.completed;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Update booking status
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      final bookings = await getAllBookings();
      final index = bookings.indexWhere((b) => b.id == bookingId);

      if (index == -1) return false;

      bookings[index] = bookings[index].copyWith(status: status);
      final bookingsJson = bookings.map((b) => b.toJson()).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    return updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Get booking by ID
  Future<ServiceBooking?> getBookingById(String bookingId) async {
    final bookings = await getAllBookings();
    return bookings.firstWhere((booking) => booking.id == bookingId);
  }
}

/// Service Booking Model
class ServiceBooking {
  final String id;
  final String serviceType;
  final ServiceCenter serviceCenter;
  final DateTime date;
  final TimeOfDay time;
  final String? additionalNotes;
  final BookingStatus status;
  final DateTime createdAt;
  final String? bookingReference;

  const ServiceBooking({
    required this.id,
    required this.serviceType,
    required this.serviceCenter,
    required this.date,
    required this.time,
    this.additionalNotes,
    this.status = BookingStatus.confirmed,
    required this.createdAt,
    this.bookingReference,
  });

  /// Create a new booking
  factory ServiceBooking.create({
    required String serviceType,
    required ServiceCenter serviceCenter,
    required DateTime date,
    required TimeOfDay time,
    String? additionalNotes,
  }) {
    return ServiceBooking(
      id: 'BK${DateTime.now().millisecondsSinceEpoch}',
      serviceType: serviceType,
      serviceCenter: serviceCenter,
      date: date,
      time: time,
      additionalNotes: additionalNotes,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
      bookingReference: 'AIV${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
  }

  /// Copy with updated fields
  ServiceBooking copyWith({
    String? id,
    String? serviceType,
    ServiceCenter? serviceCenter,
    DateTime? date,
    TimeOfDay? time,
    String? additionalNotes,
    BookingStatus? status,
    DateTime? createdAt,
    String? bookingReference,
  }) {
    return ServiceBooking(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      serviceCenter: serviceCenter ?? this.serviceCenter,
      date: date ?? this.date,
      time: time ?? this.time,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      bookingReference: bookingReference ?? this.bookingReference,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'serviceCenter': serviceCenter.id, // Store only ID, resolve when loading
      'date': date.toIso8601String(),
      'time': {'hour': time.hour, 'minute': time.minute},
      'additionalNotes': additionalNotes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'bookingReference': bookingReference,
    };
  }

  /// Create from JSON
  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    final serviceCentersService = ServiceCentersService();
    final serviceCenter = serviceCentersService.getAllServiceCenters()
        .firstWhere((center) => center.id == json['serviceCenter']);

    return ServiceBooking(
      id: json['id'],
      serviceType: json['serviceType'],
      serviceCenter: serviceCenter,
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: json['time']['hour'],
        minute: json['time']['minute'],
      ),
      additionalNotes: json['additionalNotes'],
      status: BookingStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      bookingReference: json['bookingReference'],
    );
  }

  /// Get formatted date and time
  String getFormattedDateTime() {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final timeStr = time.format(const null); // Will use default locale
    return '$dateStr at $timeStr';
  }

  /// Get service type display name
  String getServiceTypeDisplayName() {
    switch (serviceType) {
      case 'maintenance':
        return 'Regular Maintenance';
      case 'repair':
        return 'Repair Service';
      case 'emergency':
        return 'Emergency Service';
      case 'mobile':
        return 'Mobile Service';
      default:
        return serviceType;
    }
  }

  /// Check if booking is upcoming
  bool get isUpcoming {
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return bookingDateTime.isAfter(DateTime.now());
  }

  /// Check if booking is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}

/// Booking Status
enum BookingStatus {
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}