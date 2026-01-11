import 'package:flutter/foundation.dart';

import '../models/service_center.dart';
import '../models/booking.dart';

/// AIVONITY Booking Provider
/// Manages booking state and service center data using basic Flutter state management
class BookingProvider extends ChangeNotifier {
  List<ServiceCenter> _serviceCenters = [];
  final List<Booking> _userBookings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ServiceCenter> get serviceCenters => List.unmodifiable(_serviceCenters);
  List<Booking> get userBookings => List.unmodifiable(_userBookings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServiceCenters({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock service centers
      _serviceCenters = _generateMockServiceCenters();

      debugPrint('Loaded ${_serviceCenters.length} service centers');
      notifyListeners();
    } catch (error) {
      _setError('Failed to load service centers: ${error.toString()}');
      debugPrint('Failed to load service centers: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createBooking(Booking booking) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Add booking to local list
      _userBookings.add(booking);

      debugPrint('Booking created successfully: ${booking.id}');
      notifyListeners();
    } catch (error) {
      _setError('Failed to create booking: ${error.toString()}');
      debugPrint('Failed to create booking: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserBookings() async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Loaded ${_userBookings.length} user bookings');
      notifyListeners();
    } catch (error) {
      _setError('Failed to load user bookings: ${error.toString()}');
      debugPrint('Failed to load user bookings: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      _userBookings.removeWhere((booking) => booking.id == bookingId);

      debugPrint('Booking cancelled: $bookingId');
      notifyListeners();
    } catch (error) {
      _setError('Failed to cancel booking: ${error.toString()}');
      debugPrint('Failed to cancel booking: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBooking(Booking updatedBooking) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _userBookings.indexWhere(
        (booking) => booking.id == updatedBooking.id,
      );
      if (index != -1) {
        _userBookings[index] = updatedBooking;
        debugPrint('Booking updated: ${updatedBooking.id}');
        notifyListeners();
      } else {
        throw Exception('Booking not found');
      }
    } catch (error) {
      _setError('Failed to update booking: ${error.toString()}');
      debugPrint('Failed to update booking: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  ServiceCenter? getServiceCenterById(String id) {
    try {
      return _serviceCenters.firstWhere((center) => center.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ServiceCenter> getServiceCentersByDistance({double? maxDistanceKm}) {
    if (maxDistanceKm == null) return serviceCenters;

    return _serviceCenters
        .where(
          (center) =>
              center.distanceKm != null && center.distanceKm! <= maxDistanceKm,
        )
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
  }

  List<ServiceCenter> searchServiceCenters(String query) {
    if (query.isEmpty) return serviceCenters;

    final lowercaseQuery = query.toLowerCase();
    return _serviceCenters
        .where(
          (center) =>
              center.name.toLowerCase().contains(lowercaseQuery) ||
              center.address.toLowerCase().contains(lowercaseQuery) ||
              center.services.any(
                (service) => service.toLowerCase().contains(lowercaseQuery),
              ),
        )
        .toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  List<ServiceCenter> _generateMockServiceCenters() {
    return [
      const ServiceCenter(
        id: '1',
        name: 'AutoCare Plus',
        address: '123 Main Street, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        rating: 4.8,
        reviewCount: 245,
        services: ['Maintenance', 'Repair', 'Oil Change', 'Tire Service'],
        workingHours: {
          'monday': '8:00-18:00',
          'tuesday': '8:00-18:00',
          'wednesday': '8:00-18:00',
          'thursday': '8:00-18:00',
          'friday': '8:00-18:00',
          'saturday': '9:00-16:00',
          'sunday': 'closed',
        },
        phone: '+1-555-0123',
        email: 'info@autocareplus.com',
        distanceKm: 2.5,
      ),
      const ServiceCenter(
        id: '2',
        name: 'Premium Motors Service',
        address: '456 Oak Avenue, Midtown',
        latitude: 40.7589,
        longitude: -73.9851,
        rating: 4.6,
        reviewCount: 189,
        services: [
          'Maintenance',
          'Engine Service',
          'Brake Service',
          'Electrical',
        ],
        workingHours: {
          'monday': '7:30-19:00',
          'tuesday': '7:30-19:00',
          'wednesday': '7:30-19:00',
          'thursday': '7:30-19:00',
          'friday': '7:30-19:00',
          'saturday': '8:00-17:00',
          'sunday': '10:00-15:00',
        },
        phone: '+1-555-0456',
        email: 'service@premiummotors.com',
        distanceKm: 4.2,
      ),
      const ServiceCenter(
        id: '3',
        name: 'Quick Fix Auto',
        address: '789 Pine Road, Uptown',
        latitude: 40.7831,
        longitude: -73.9712,
        rating: 4.4,
        reviewCount: 156,
        services: [
          'Oil Change',
          'Tire Service',
          'Battery Service',
          'Inspection',
        ],
        workingHours: {
          'monday': '8:00-17:00',
          'tuesday': '8:00-17:00',
          'wednesday': '8:00-17:00',
          'thursday': '8:00-17:00',
          'friday': '8:00-17:00',
          'saturday': '9:00-15:00',
          'sunday': 'closed',
        },
        phone: '+1-555-0789',
        email: 'contact@quickfixauto.com',
        distanceKm: 6.8,
      ),
      const ServiceCenter(
        id: '4',
        name: 'Elite Auto Service',
        address: '321 Elm Street, Westside',
        latitude: 40.7505,
        longitude: -74.0134,
        rating: 4.9,
        reviewCount: 312,
        services: [
          'Luxury Car Service',
          'Engine Diagnostics',
          'Transmission Service',
          'Air Conditioning',
        ],
        workingHours: {
          'monday': '8:00-19:00',
          'tuesday': '8:00-19:00',
          'wednesday': '8:00-19:00',
          'thursday': '8:00-19:00',
          'friday': '8:00-19:00',
          'saturday': '9:00-17:00',
          'sunday': '10:00-16:00',
        },
        phone: '+1-555-0321',
        email: 'service@eliteauto.com',
        distanceKm: 3.7,
      ),
      const ServiceCenter(
        id: '5',
        name: 'Budget Auto Repair',
        address: '654 Cedar Avenue, Eastside',
        latitude: 40.7282,
        longitude: -73.9942,
        rating: 4.2,
        reviewCount: 98,
        services: [
          'Basic Maintenance',
          'Oil Change',
          'Tire Rotation',
          'Battery Service',
        ],
        workingHours: {
          'monday': '8:00-17:00',
          'tuesday': '8:00-17:00',
          'wednesday': '8:00-17:00',
          'thursday': '8:00-17:00',
          'friday': '8:00-17:00',
          'saturday': '9:00-15:00',
          'sunday': 'closed',
        },
        phone: '+1-555-0654',
        email: 'info@budgetauto.com',
        distanceKm: 5.1,
      ),
    ];
  }
}

