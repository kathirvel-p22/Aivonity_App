import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_center.dart';
import '../config/api_config.dart';

class MapsService {
  static const String _apiKeyPref = 'google_maps_api_key';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  final Dio _dio;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();
  String? _apiKey;

  MapsService(this._dio, this._prefs) {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    _apiKey = _prefs.getString(_apiKeyPref);
    if (_apiKey == null) {
      // Load from configuration
      _apiKey = ApiConfig.googleMapsApiKey;
      await _prefs.setString(_apiKeyPref, _apiKey!);
    }
  }

  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    await _prefs.setString(_apiKeyPref, apiKey);
  }

  Future<List<ServiceCenter>> findServiceCenters({
    required Coordinates location,
    double radiusKm = 50.0,
    ServiceCenterFilter? filter,
  }) async {
    try {
      // First, get nearby places using Google Places API
      final placesResponse = await _searchNearbyPlaces(
        location: location,
        radiusKm: radiusKm,
        query: 'car service center automotive repair',
      );

      // Convert places to service centers and apply filters
      List<ServiceCenter> serviceCenters = await _convertPlacesToServiceCenters(
        placesResponse,
        location,
      );

      // Apply filters
      if (filter != null) {
        serviceCenters = _applyFilters(serviceCenters, filter);
      }

      return serviceCenters;
    } catch (e) {
      throw Exception('Failed to find service centers: $e');
    }
  }

  Future<Map<String, dynamic>> _searchNearbyPlaces({
    required Coordinates location,
    required double radiusKm,
    required String query,
  }) async {
    if (_apiKey == null) await _loadApiKey();

    final response = await _dio.get(
      '$_baseUrl/place/textsearch/json',
      queryParameters: {
        'query': query,
        'location': '${location.latitude},${location.longitude}',
        'radius': (radiusKm * 1000).toInt(), // Convert to meters
        'key': _apiKey,
        'type': 'car_repair',
      },
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to search places: ${response.statusMessage}');
    }
  }

  Future<List<ServiceCenter>> _convertPlacesToServiceCenters(
    Map<String, dynamic> placesResponse,
    Coordinates userLocation,
  ) async {
    final List<dynamic> results = placesResponse['results'] ?? [];
    final List<ServiceCenter> serviceCenters = [];

    for (final place in results) {
      try {
        final placeId = place['place_id'];
        final placeDetails = await _getPlaceDetails(placeId);

        final serviceCenter = _createServiceCenterFromPlace(
          place,
          placeDetails,
          userLocation,
        );
        serviceCenters.add(serviceCenter);
      } catch (e) {
        // Log error but continue processing other places
        _logger.e('Error processing place: $e');
      }
    }

    return serviceCenters;
  }

  Future<Map<String, dynamic>> _getPlaceDetails(String placeId) async {
    if (_apiKey == null) await _loadApiKey();

    final response = await _dio.get(
      '$_baseUrl/place/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields':
            'name,formatted_address,formatted_phone_number,rating,user_ratings_total,opening_hours,website,reviews',
        'key': _apiKey,
      },
    );

    if (response.statusCode == 200) {
      return response.data['result'] ?? {};
    } else {
      throw Exception('Failed to get place details: ${response.statusMessage}');
    }
  }

  ServiceCenter _createServiceCenterFromPlace(
    Map<String, dynamic> place,
    Map<String, dynamic> placeDetails,
    Coordinates userLocation,
  ) {
    final geometry = place['geometry'];
    final location = geometry['location'];
    final lat = location['lat'].toDouble();
    final lng = location['lng'].toDouble();

    // Calculate distance
    final distance = _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      lat,
      lng,
    );

    // Extract services from place types and name
    final List<String> services = _extractServices(place, placeDetails);

    // Determine if open now
    final openingHours = placeDetails['opening_hours'];
    final isOpen = openingHours?['open_now'] ?? false;

    // Extract working hours
    final List<String> workingHours = [];
    if (openingHours?['weekday_text'] != null) {
      workingHours.addAll(List<String>.from(openingHours['weekday_text']));
    }

    return ServiceCenter(
      id: place['place_id'],
      name: placeDetails['name'] ?? place['name'] ?? 'Unknown Service Center',
      address:
          placeDetails['formatted_address'] ?? place['formatted_address'] ?? '',
      latitude: lat,
      longitude: lng,
      services: services,
      rating: (placeDetails['rating'] ?? 0.0).toDouble(),
      reviewCount: placeDetails['user_ratings_total'] ?? 0,
      phoneNumber: placeDetails['formatted_phone_number'] ?? '',
      email: '', // Not available from Google Places API
      workingHours: workingHours,
      isOpen: isOpen,
      distanceKm: distance,
      estimatedWaitTimeMinutes: _estimateWaitTime(
        placeDetails['rating'] ?? 0.0,
      ),
    );
  }

  List<String> _extractServices(
    Map<String, dynamic> place,
    Map<String, dynamic> placeDetails,
  ) {
    final List<String> services = [];
    final List<dynamic> types = place['types'] ?? [];

    // Map Google Places types to our service types
    final serviceMapping = {
      'car_repair': 'General Repair',
      'car_dealer': 'Sales & Service',
      'gas_station': 'Fuel & Basic Service',
      'car_wash': 'Car Wash',
      'parking': 'Parking',
    };

    for (final type in types) {
      if (serviceMapping.containsKey(type)) {
        services.add(serviceMapping[type]!);
      }
    }

    // Add default services if none found
    if (services.isEmpty) {
      services.addAll(['General Repair', 'Maintenance', 'Diagnostics']);
    }

    return services;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  int _estimateWaitTime(double rating) {
    // Simple estimation based on rating (higher rating = longer wait)
    if (rating >= 4.5) return 45;
    if (rating >= 4.0) return 30;
    if (rating >= 3.5) return 20;
    return 15;
  }

  List<ServiceCenter> _applyFilters(
    List<ServiceCenter> centers,
    ServiceCenterFilter filter,
  ) {
    var filtered = centers.where((center) {
      // Distance filter
      if (filter.maxDistanceKm != null &&
          center.distanceKm > filter.maxDistanceKm!) {
        return false;
      }

      // Rating filter
      if (filter.minRating != null && center.rating < filter.minRating!) {
        return false;
      }

      // Open now filter
      if (filter.openNow == true && !center.isOpen) {
        return false;
      }

      // Required services filter
      if (filter.requiredServices != null &&
          filter.requiredServices!.isNotEmpty) {
        final hasRequiredService = filter.requiredServices!.any(
          (service) => center.services.contains(service),
        );
        if (!hasRequiredService) return false;
      }

      return true;
    }).toList();

    // Apply sorting
    if (filter.sortBy != null) {
      switch (filter.sortBy) {
        case 'distance':
          filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          break;
        case 'rating':
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'wait_time':
          filtered.sort(
            (a, b) => a.estimatedWaitTimeMinutes.compareTo(
              b.estimatedWaitTimeMinutes,
            ),
          );
          break;
      }
    }

    return filtered;
  }

  Future<Coordinates> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return Coordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Stream<Coordinates> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).map(
      (position) => Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}
