import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service Centers Service
/// Manages service center data across India with location-based features
class ServiceCentersService {
  static final ServiceCentersService _instance =
      ServiceCentersService._internal();
  factory ServiceCentersService() => _instance;
  ServiceCentersService._internal();

  /// Get all service centers across India
  List<ServiceCenter> getAllServiceCenters() {
    return [
      // Tamil Nadu Service Centers
      const ServiceCenter(
        id: 'tn-chennai-001',
        name: 'Aivonity Service Center - Chennai T. Nagar',
        address: '123 Anna Salai, T. Nagar, Chennai, Tamil Nadu 600017',
        phone: '+91-44-1234-5678',
        state: 'Tamil Nadu',
        district: 'Chennai',
        coordinates: LocationCoordinates(13.0827, 80.2707),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Emergency Service'],
        rating: 4.8,
        isOpen: true,
        operatingHours: '9:00 AM - 8:00 PM',
        facilities: ['Free WiFi', 'Waiting Lounge', 'Coffee Shop', 'Parking'],
      ),
      const ServiceCenter(
        id: 'tn-trichy-001',
        name: 'Aivonity Service Center - Trichy Central',
        address: '456 Rockins Road, Cantonment, Trichy, Tamil Nadu 620001',
        phone: '+91-431-2345-6789',
        state: 'Tamil Nadu',
        district: 'Tiruchirappalli',
        coordinates: LocationCoordinates(10.7905, 78.7047),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Mobile Service'],
        rating: 4.7,
        isOpen: true,
        operatingHours: '8:30 AM - 7:30 PM',
        facilities: ['Waiting Lounge', 'Parking', 'Tea/Coffee'],
      ),
      const ServiceCenter(
        id: 'tn-kanniyakumari-001',
        name: 'Aivonity Service Center - Kanniyakumari',
        address: '789 Main Road, Kanniyakumari Town, Tamil Nadu 629702',
        phone: '+91-4652-3456-7890',
        state: 'Tamil Nadu',
        district: 'Kanniyakumari',
        coordinates: LocationCoordinates(8.0883, 77.5385),
        services: [
          'Maintenance',
          'Repair',
          'Emergency Service',
          'Mobile Service',
        ],
        rating: 4.6,
        isOpen: true,
        operatingHours: '9:00 AM - 6:00 PM',
        facilities: ['Parking', 'Waiting Area'],
      ),
      const ServiceCenter(
        id: 'tn-madurai-001',
        name: 'Aivonity Service Center - Madurai Anna Nagar',
        address: '321 KK Nagar Main Road, Madurai, Tamil Nadu 625020',
        phone: '+91-452-4567-8901',
        state: 'Tamil Nadu',
        district: 'Madurai',
        coordinates: LocationCoordinates(9.9252, 78.1198),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Emergency Service'],
        rating: 4.9,
        isOpen: true,
        operatingHours: '9:00 AM - 8:00 PM',
        facilities: ['Free WiFi', 'Waiting Lounge', 'Parking', 'AC'],
      ),

      // Other Major Indian Cities
      const ServiceCenter(
        id: 'mh-mumbai-001',
        name: 'Aivonity Service Center - Mumbai Andheri',
        address: '567 SV Road, Andheri West, Mumbai, Maharashtra 400058',
        phone: '+91-22-5678-9012',
        state: 'Maharashtra',
        district: 'Mumbai',
        coordinates: LocationCoordinates(19.1197, 72.8464),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Emergency Service'],
        rating: 4.7,
        isOpen: true,
        operatingHours: '9:00 AM - 8:00 PM',
        facilities: ['Free WiFi', 'Waiting Lounge', 'Coffee Shop', 'Parking'],
      ),
      const ServiceCenter(
        id: 'dl-delhi-001',
        name: 'Aivonity Service Center - Delhi Connaught Place',
        address: '890 Radial Road, Connaught Place, New Delhi 110001',
        phone: '+91-11-6789-0123',
        state: 'Delhi',
        district: 'New Delhi',
        coordinates: LocationCoordinates(28.6139, 77.2090),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Mobile Service'],
        rating: 4.8,
        isOpen: true,
        operatingHours: '9:00 AM - 7:00 PM',
        facilities: ['Waiting Lounge', 'Parking', 'AC'],
      ),
      const ServiceCenter(
        id: 'ka-bangalore-001',
        name: 'Aivonity Service Center - Bangalore Koramangala',
        address: '123 80 Feet Road, Koramangala, Bangalore, Karnataka 560034',
        phone: '+91-80-7890-1234',
        state: 'Karnataka',
        district: 'Bangalore',
        coordinates: LocationCoordinates(12.9352, 77.6245),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Emergency Service'],
        rating: 4.9,
        isOpen: true,
        operatingHours: '9:00 AM - 8:00 PM',
        facilities: ['Free WiFi', 'Waiting Lounge', 'Coffee Shop', 'Parking'],
      ),
      const ServiceCenter(
        id: 'tn-coimbatore-001',
        name: 'Aivonity Service Center - Coimbatore Gandhipuram',
        address:
            '456 Cross Cut Road, Gandhipuram, Coimbatore, Tamil Nadu 641012',
        phone: '+91-422-8901-2345',
        state: 'Tamil Nadu',
        district: 'Coimbatore',
        coordinates: LocationCoordinates(11.0168, 76.9558),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Mobile Service'],
        rating: 4.6,
        isOpen: true,
        operatingHours: '9:00 AM - 7:00 PM',
        facilities: ['Waiting Lounge', 'Parking', 'Tea/Coffee'],
      ),
      const ServiceCenter(
        id: 'tn-salem-001',
        name: 'Aivonity Service Center - Salem',
        address: '789 Omalur Main Road, Salem, Tamil Nadu 636009',
        phone: '+91-427-9012-3456',
        state: 'Tamil Nadu',
        district: 'Salem',
        coordinates: LocationCoordinates(11.6643, 78.1460),
        services: ['Maintenance', 'Repair', 'Emergency Service'],
        rating: 4.5,
        isOpen: true,
        operatingHours: '9:00 AM - 6:00 PM',
        facilities: ['Parking', 'Waiting Area'],
      ),
      const ServiceCenter(
        id: 'wb-kolkata-001',
        name: 'Aivonity Service Center - Kolkata Salt Lake',
        address: '321 Sector V, Salt Lake City, Kolkata, West Bengal 700091',
        phone: '+91-33-0123-4567',
        state: 'West Bengal',
        district: 'Kolkata',
        coordinates: LocationCoordinates(22.5726, 88.3639),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Mobile Service'],
        rating: 4.7,
        isOpen: true,
        operatingHours: '9:00 AM - 7:00 PM',
        facilities: ['Waiting Lounge', 'Parking', 'AC'],
      ),
      const ServiceCenter(
        id: 'gj-ahmedabad-001',
        name: 'Aivonity Service Center - Ahmedabad SG Highway',
        address: '654 SG Highway, Ahmedabad, Gujarat 380015',
        phone: '+91-79-1234-5678',
        state: 'Gujarat',
        district: 'Ahmedabad',
        coordinates: LocationCoordinates(23.0225, 72.5714),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Emergency Service'],
        rating: 4.6,
        isOpen: true,
        operatingHours: '9:00 AM - 8:00 PM',
        facilities: ['Free WiFi', 'Waiting Lounge', 'Parking'],
      ),
      const ServiceCenter(
        id: 'rj-jaipur-001',
        name: 'Aivonity Service Center - Jaipur Malviya Nagar',
        address: '987 Malviya Nagar, Jaipur, Rajasthan 302017',
        phone: '+91-141-2345-6789',
        state: 'Rajasthan',
        district: 'Jaipur',
        coordinates: LocationCoordinates(26.9124, 75.7873),
        services: ['Maintenance', 'Repair', 'Mobile Service'],
        rating: 4.4,
        isOpen: true,
        operatingHours: '9:00 AM - 6:00 PM',
        facilities: ['Parking', 'Waiting Area'],
      ),
      const ServiceCenter(
        id: 'up-lucknow-001',
        name: 'Aivonity Service Center - Lucknow Hazratganj',
        address: '147 MG Marg, Hazratganj, Lucknow, Uttar Pradesh 226001',
        phone: '+91-522-3456-7890',
        state: 'Uttar Pradesh',
        district: 'Lucknow',
        coordinates: LocationCoordinates(26.8467, 80.9462),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Emergency Service'],
        rating: 4.5,
        isOpen: true,
        operatingHours: '9:00 AM - 7:00 PM',
        facilities: ['Waiting Lounge', 'Parking', 'AC'],
      ),
      const ServiceCenter(
        id: 'pb-chandigarh-001',
        name: 'Aivonity Service Center - Chandigarh Sector 17',
        address: '258 Sector 17, Chandigarh 160017',
        phone: '+91-172-4567-8901',
        state: 'Punjab',
        district: 'Chandigarh',
        coordinates: LocationCoordinates(30.7333, 76.7794),
        services: ['Maintenance', 'Repair', 'Diagnostics', 'Mobile Service'],
        rating: 4.8,
        isOpen: true,
        operatingHours: '9:00 AM - 8:00 PM',
        facilities: ['Free WiFi', 'Waiting Lounge', 'Coffee Shop', 'Parking'],
      ),
    ];
  }

  /// Get service centers by state
  List<ServiceCenter> getServiceCentersByState(String state) {
    return getAllServiceCenters()
        .where((center) => center.state == state)
        .toList();
  }

  /// Get service centers by district
  List<ServiceCenter> getServiceCentersByDistrict(String district) {
    return getAllServiceCenters()
        .where((center) => center.district == district)
        .toList();
  }

  /// Get Tamil Nadu service centers
  List<ServiceCenter> getTamilNaduServiceCenters() {
    return getServiceCentersByState('Tamil Nadu');
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Sort service centers by distance from user location
  List<ServiceCenter> sortByDistance(
    List<ServiceCenter> centers,
    double userLat,
    double userLon,
  ) {
    final centersWithDistance = centers.map((center) {
      final distance = calculateDistance(
        userLat,
        userLon,
        center.coordinates.latitude,
        center.coordinates.longitude,
      );
      return ServiceCenterWithDistance(center: center, distance: distance);
    }).toList();

    centersWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return centersWithDistance.map((item) => item.center).toList();
  }

  /// Get nearest service centers
  List<ServiceCenter> getNearestServiceCenters(
    double userLat,
    double userLon, {
    int limit = 5,
  }) {
    final allCenters = getAllServiceCenters();
    final sortedCenters = sortByDistance(allCenters, userLat, userLon);
    return sortedCenters.take(limit).toList();
  }

  /// Search service centers by name or address
  List<ServiceCenter> searchServiceCenters(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllServiceCenters().where((center) {
      return center.name.toLowerCase().contains(lowercaseQuery) ||
          center.address.toLowerCase().contains(lowercaseQuery) ||
          center.state.toLowerCase().contains(lowercaseQuery) ||
          center.district.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filter service centers by services offered
  List<ServiceCenter> filterByServices(
    List<ServiceCenter> centers,
    List<String> services,
  ) {
    if (services.isEmpty) return centers;
    return centers.where((center) {
      return services.any((service) => center.services.contains(service));
    }).toList();
  }
}

/// Service Center with calculated distance
class ServiceCenterWithDistance {
  final ServiceCenter center;
  final double distance;

  const ServiceCenterWithDistance({
    required this.center,
    required this.distance,
  });
}

/// Service Center Data Model
class ServiceCenter {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String state;
  final String district;
  final LocationCoordinates coordinates;
  final List<String> services;
  final double rating;
  final bool isOpen;
  final String operatingHours;
  final List<String> facilities;

  const ServiceCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.state,
    required this.district,
    required this.coordinates,
    required this.services,
    required this.rating,
    this.isOpen = true,
    this.operatingHours = '9:00 AM - 6:00 PM',
    this.facilities = const [],
  });

  /// Get formatted distance string
  String getFormattedDistance(double userLat, double userLon) {
    final distance = ServiceCentersService().calculateDistance(
      userLat,
      userLon,
      coordinates.latitude,
      coordinates.longitude,
    );
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  /// Get Google Maps directions URL
  String getGoogleMapsUrl(double? userLat, double? userLon) {
    final destination = '${coordinates.latitude},${coordinates.longitude}';
    if (userLat != null && userLon != null) {
      final origin = '$userLat,$userLon';
      return 'https://www.google.com/maps/dir/$origin/$destination';
    } else {
      return 'https://www.google.com/maps/dir/?api=1&destination=$destination&destination_place_id=$name';
    }
  }
}

/// Location Coordinates
class LocationCoordinates {
  final double latitude;
  final double longitude;

  const LocationCoordinates(this.latitude, this.longitude);

  @override
  String toString() => '$latitude,$longitude';
}
