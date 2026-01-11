import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// AIVONITY Location Service
/// Simplified location service without external dependencies
class LocationService extends ChangeNotifier {
  LocationData? _currentLocation;
  bool _isLocationEnabled = false;
  String? _error;

  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isLocationEnabled => _isLocationEnabled;
  String? get error => _error;

  /// Initialize location service
  Future<void> initialize() async {
    try {
      // Simulate location permission check
      await Future.delayed(const Duration(milliseconds: 500));
      _isLocationEnabled = true;

      // Get initial location
      await getCurrentLocation();

      debugPrint('Location service initialized');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize location service: ${e.toString()}';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      if (!_isLocationEnabled) {
        throw Exception('Location service not enabled');
      }

      // Simulate getting location
      await Future.delayed(const Duration(seconds: 1));

      // Mock location data (San Francisco area)
      _currentLocation = LocationData(
        latitude: 37.7749 + (math.Random().nextDouble() - 0.5) * 0.01,
        longitude: -122.4194 + (math.Random().nextDouble() - 0.5) * 0.01,
        accuracy: 10.0 + math.Random().nextDouble() * 5.0,
        timestamp: DateTime.now(),
      );

      _error = null;
      notifyListeners();
      return _currentLocation;
    } catch (e) {
      _error = 'Failed to get location: ${e.toString()}';
      debugPrint(_error);
      notifyListeners();
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Find nearby service centers
  Future<List<ServiceCenterLocation>> findNearbyServiceCenters({
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      final lat = latitude ?? _currentLocation?.latitude;
      final lon = longitude ?? _currentLocation?.longitude;

      if (lat == null || lon == null) {
        throw Exception('Location not available');
      }

      // Mock service centers
      final mockCenters = [
        ServiceCenterLocation(
          id: '1',
          name: 'Downtown Auto Service',
          latitude: lat + 0.01,
          longitude: lon + 0.01,
          address: '123 Main St, Downtown',
          phone: '+1-555-0123',
        ),
        ServiceCenterLocation(
          id: '2',
          name: 'North Side Motors',
          latitude: lat - 0.02,
          longitude: lon + 0.015,
          address: '456 North Ave, North Side',
          phone: '+1-555-0456',
        ),
        ServiceCenterLocation(
          id: '3',
          name: 'Express Auto Care',
          latitude: lat + 0.015,
          longitude: lon - 0.01,
          address: '789 Express Way, City Center',
          phone: '+1-555-0789',
        ),
      ];

      // Calculate distances and filter by radius
      final nearbyCenters = <ServiceCenterLocation>[];
      for (final center in mockCenters) {
        final distance = calculateDistance(
          lat,
          lon,
          center.latitude,
          center.longitude,
        );
        if (distance <= radiusKm) {
          nearbyCenters.add(center.copyWith(distanceKm: distance));
        }
      }

      // Sort by distance
      nearbyCenters.sort(
        (a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0),
      );

      return nearbyCenters;
    } catch (e) {
      debugPrint('Failed to find nearby service centers: $e');
      return [];
    }
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    try {
      // Simulate permission request
      await Future.delayed(const Duration(seconds: 1));
      _isLocationEnabled = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to request location permission: ${e.toString()}';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    // Simulate checking location services
    await Future.delayed(const Duration(milliseconds: 200));
    return _isLocationEnabled;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Location Data Model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }
}

/// Service Center Location Model
class ServiceCenterLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final double? distanceKm;

  const ServiceCenterLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    this.distanceKm,
  });

  ServiceCenterLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? phone,
    double? distanceKm,
  }) {
    return ServiceCenterLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

