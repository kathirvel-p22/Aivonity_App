import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_recommendations.dart';
import '../models/service_center.dart';
import '../models/navigation.dart';
import 'maps_service.dart';

class LocationRecommendationsService {
  final SharedPreferences _prefs;
  final MapsService _mapsService;

  static const String _locationHistoryKey = 'location_history';
  static const String _favoritesKey = 'favorite_locations';
  static const String _preferencesKey = 'recommendation_preferences';

  List<LocationHistory> _locationHistory = [];
  List<FavoriteLocation> _favoriteLocations = [];
  RecommendationPreferences _preferences = const RecommendationPreferences();

  LocationRecommendationsService(this._prefs, this._mapsService) {
    _loadStoredData();
  }

  /// Get GPS-based service center recommendations
  Future<List<RouteRecommendation>> getGPSBasedRecommendations({
    required Coordinates currentLocation,
    VehicleContext? vehicleContext,
    double radiusKm = 10.0,
  }) async {
    try {
      // Get nearby service centers
      final serviceCenters = await _mapsService.findServiceCenters(
        location: currentLocation,
        radiusKm: radiusKm,
      );

      // Create location context
      final locationContext = await _createLocationContext(currentLocation);

      // Generate recommendations with scoring
      final recommendations = <RouteRecommendation>[];

      for (final serviceCenter in serviceCenters) {
        final recommendation = await _createRecommendation(
          serviceCenter: serviceCenter,
          currentLocation: currentLocation,
          locationContext: locationContext,
          vehicleContext: vehicleContext,
        );

        if (recommendation != null) {
          recommendations.add(recommendation);
        }
      }

      // Sort by relevance score
      recommendations.sort(
        (a, b) => b.relevanceScore.compareTo(a.relevanceScore),
      );

      return recommendations.take(10).toList(); // Limit to top 10
    } catch (e) {
      throw Exception('Failed to get GPS-based recommendations: $e');
    }
  }

  /// Get route-based service recommendations
  Future<List<RouteRecommendation>> getRouteBasedRecommendations({
    required NavigationRoute route,
    required Coordinates currentLocation,
    VehicleContext? vehicleContext,
  }) async {
    try {
      final recommendations = <RouteRecommendation>[];

      // Find service centers along the route
      final routeServiceCenters = await _findServiceCentersAlongRoute(route);

      // Create location context
      final locationContext = await _createLocationContext(currentLocation);

      for (final serviceCenter in routeServiceCenters) {
        final distanceFromRoute = _calculateDistanceFromRoute(
          serviceCenter,
          route.polylinePoints,
        );

        if (distanceFromRoute <= _preferences.maxDetourDistance) {
          final recommendation = await _createRouteRecommendation(
            serviceCenter: serviceCenter,
            route: route,
            currentLocation: currentLocation,
            locationContext: locationContext,
            vehicleContext: vehicleContext,
            distanceFromRoute: distanceFromRoute,
          );

          if (recommendation != null) {
            recommendations.add(recommendation);
          }
        }
      }

      // Sort by relevance and distance from route
      recommendations.sort((a, b) {
        final scoreComparison = b.relevanceScore.compareTo(a.relevanceScore);
        if (scoreComparison != 0) return scoreComparison;
        return a.distanceFromRoute.compareTo(b.distanceFromRoute);
      });

      return recommendations;
    } catch (e) {
      throw Exception('Failed to get route-based recommendations: $e');
    }
  }

  /// Get smart recommendations based on context and history
  Future<List<SmartRecommendation>> getSmartRecommendations({
    required Coordinates currentLocation,
    VehicleContext? vehicleContext,
  }) async {
    try {
      final recommendations = <SmartRecommendation>[];
      final locationContext = await _createLocationContext(currentLocation);

      // Maintenance-based recommendations
      if (vehicleContext != null) {
        recommendations.addAll(
          await _generateMaintenanceRecommendations(
            currentLocation,
            vehicleContext,
            locationContext,
          ),
        );
      }

      // Historical pattern recommendations
      recommendations.addAll(
        await _generateHistoricalRecommendations(
          currentLocation,
          locationContext,
        ),
      );

      // Favorite location recommendations
      recommendations.addAll(
        await _generateFavoriteLocationRecommendations(
          currentLocation,
          locationContext,
        ),
      );

      // Emergency/urgent recommendations
      recommendations.addAll(
        await _generateEmergencyRecommendations(
          currentLocation,
          vehicleContext,
          locationContext,
        ),
      );

      // Sort by priority and urgency
      recommendations.sort((a, b) {
        if (a.isUrgent != b.isUrgent) {
          return a.isUrgent ? -1 : 1;
        }
        return b.priority.compareTo(a.priority);
      });

      return recommendations;
    } catch (e) {
      throw Exception('Failed to get smart recommendations: $e');
    }
  }

  /// Add location to history
  Future<void> addLocationToHistory({
    required Coordinates location,
    required String address,
    required String purpose,
  }) async {
    final existingIndex = _locationHistory.indexWhere(
      (history) =>
          _calculateDistance(history.location, location) < 0.1, // Within 100m
    );

    if (existingIndex != -1) {
      // Update existing location
      final existing = _locationHistory[existingIndex];
      _locationHistory[existingIndex] = LocationHistory(
        id: existing.id,
        location: location,
        address: address,
        timestamp: existing.timestamp,
        purpose: purpose,
        visitCount: existing.visitCount + 1,
        lastVisited: DateTime.now(),
      );
    } else {
      // Add new location
      _locationHistory.add(
        LocationHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          location: location,
          address: address,
          timestamp: DateTime.now(),
          purpose: purpose,
          visitCount: 1,
          lastVisited: DateTime.now(),
        ),
      );
    }

    // Keep only last 100 locations
    if (_locationHistory.length > 100) {
      _locationHistory.removeRange(0, _locationHistory.length - 100);
    }

    await _saveLocationHistory();
  }

  /// Add favorite location
  Future<void> addFavoriteLocation({
    required String name,
    required Coordinates location,
    required String address,
    required String category,
    String? notes,
    List<String> tags = const [],
  }) async {
    final favorite = FavoriteLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      address: address,
      category: category,
      createdAt: DateTime.now(),
      notes: notes,
      tags: tags,
    );

    _favoriteLocations.add(favorite);
    await _saveFavoriteLocations();
  }

  /// Remove favorite location
  Future<void> removeFavoriteLocation(String id) async {
    _favoriteLocations.removeWhere((favorite) => favorite.id == id);
    await _saveFavoriteLocations();
  }

  /// Update recommendation preferences
  Future<void> updatePreferences(RecommendationPreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
  }

  /// Get location history
  List<LocationHistory> getLocationHistory() => List.from(_locationHistory);

  /// Get favorite locations
  List<FavoriteLocation> getFavoriteLocations() =>
      List.from(_favoriteLocations);

  /// Get current preferences
  RecommendationPreferences getPreferences() => _preferences;

  // Private helper methods

  Future<LocationContext> _createLocationContext(Coordinates location) async {
    final now = DateTime.now();
    final hour = now.hour;

    String timeOfDay;
    if (hour >= 6 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }

    final dayOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];

    return LocationContext(
      currentLocation: location,
      timestamp: now,
      isMoving: false, // Would need GPS speed data
      timeOfDay: timeOfDay,
      dayOfWeek: dayOfWeek,
    );
  }

  Future<RouteRecommendation?> _createRecommendation({
    required ServiceCenter serviceCenter,
    required Coordinates currentLocation,
    required LocationContext locationContext,
    VehicleContext? vehicleContext,
  }) async {
    final reasons = <String>[];
    double score = 0.0;

    // Base score from rating
    score += serviceCenter.rating / 5.0 * 0.3;

    // Distance factor (closer is better)
    final distance = serviceCenter.distanceKm;
    if (distance <= 2.0) {
      score += 0.3;
      reasons.add('Very close to your location');
    } else if (distance <= 5.0) {
      score += 0.2;
      reasons.add('Nearby location');
    } else if (distance <= 10.0) {
      score += 0.1;
    }

    // Open now bonus
    if (serviceCenter.isOpen) {
      score += 0.2;
      reasons.add('Currently open');
    }

    // Historical visits
    final hasVisited = _locationHistory.any(
      (history) =>
          _calculateDistance(
            history.location,
            Coordinates(
              latitude: serviceCenter.latitude,
              longitude: serviceCenter.longitude,
            ),
          ) <
          0.5,
    );

    if (hasVisited) {
      score += 0.15;
      reasons.add('You\'ve visited before');
    }

    // Favorite location
    final isFavorite = _favoriteLocations.any(
      (favorite) =>
          _calculateDistance(
            favorite.location,
            Coordinates(
              latitude: serviceCenter.latitude,
              longitude: serviceCenter.longitude,
            ),
          ) <
          0.1,
    );

    if (isFavorite) {
      score += 0.25;
      reasons.add('One of your favorites');
    }

    // Vehicle context matching
    if (vehicleContext != null) {
      final matchingServices = serviceCenter.services
          .where(
            (service) => _isServiceRelevantForVehicle(service, vehicleContext),
          )
          .toList();

      if (matchingServices.isNotEmpty) {
        score += 0.2;
        reasons.add('Offers services for your vehicle');
      }
    }

    // Time-based factors
    if (locationContext.timeOfDay == 'morning' &&
        serviceCenter.services.contains('Oil Change')) {
      score += 0.1;
      reasons.add('Good time for maintenance');
    }

    if (score < 0.3) return null; // Filter out low-relevance recommendations

    return RouteRecommendation(
      id: '${serviceCenter.id}_${DateTime.now().millisecondsSinceEpoch}',
      serviceCenter: serviceCenter,
      relevanceScore: min(score, 1.0),
      reasons: reasons,
      distanceFromRoute: distance,
      estimatedDetourMinutes: (distance / 30 * 60)
          .round(), // Assume 30 km/h average
      recommendationType: distance <= 2.0 ? 'nearby' : 'on_route',
    );
  }

  Future<RouteRecommendation?> _createRouteRecommendation({
    required ServiceCenter serviceCenter,
    required NavigationRoute route,
    required Coordinates currentLocation,
    required LocationContext locationContext,
    VehicleContext? vehicleContext,
    required double distanceFromRoute,
  }) async {
    final baseRecommendation = await _createRecommendation(
      serviceCenter: serviceCenter,
      currentLocation: currentLocation,
      locationContext: locationContext,
      vehicleContext: vehicleContext,
    );

    if (baseRecommendation == null) return null;

    // Adjust score for route context
    double routeScore = baseRecommendation.relevanceScore;

    // Bonus for being on route
    if (distanceFromRoute <= 1.0) {
      routeScore += 0.2;
    } else if (distanceFromRoute <= 3.0) {
      routeScore += 0.1;
    }

    final detourMinutes = _calculateDetourTime(distanceFromRoute);

    return RouteRecommendation(
      id: baseRecommendation.id,
      serviceCenter: serviceCenter,
      relevanceScore: min(routeScore, 1.0),
      reasons: [
        ...baseRecommendation.reasons,
        if (distanceFromRoute <= 1.0) 'Directly on your route',
        if (distanceFromRoute <= 3.0 && distanceFromRoute > 1.0)
          'Small detour from route',
      ],
      distanceFromRoute: distanceFromRoute,
      estimatedDetourMinutes: detourMinutes,
      recommendationType: distanceFromRoute <= 1.0 ? 'on_route' : 'nearby',
    );
  }

  Future<List<ServiceCenter>> _findServiceCentersAlongRoute(
    NavigationRoute route,
  ) async {
    final serviceCenters = <ServiceCenter>[];

    // Sample points along the route
    final samplePoints = _sampleRoutePoints(
      route.polylinePoints,
      5.0,
    ); // Every 5km

    for (final point in samplePoints) {
      try {
        final nearby = await _mapsService.findServiceCenters(
          location: point,
          radiusKm: _preferences.maxDetourDistance,
        );
        serviceCenters.addAll(nearby);
      } catch (e) {
        // Continue with other points if one fails
      }
    }

    // Remove duplicates
    final uniqueServiceCenters = <ServiceCenter>[];
    for (final center in serviceCenters) {
      if (!uniqueServiceCenters.any((existing) => existing.id == center.id)) {
        uniqueServiceCenters.add(center);
      }
    }

    return uniqueServiceCenters;
  }

  List<Coordinates> _sampleRoutePoints(
    List<Coordinates> polylinePoints,
    double intervalKm,
  ) {
    if (polylinePoints.isEmpty) return [];

    final sampledPoints = <Coordinates>[polylinePoints.first];
    double accumulatedDistance = 0.0;

    for (int i = 1; i < polylinePoints.length; i++) {
      final distance = _calculateDistance(
        polylinePoints[i - 1],
        polylinePoints[i],
      );
      accumulatedDistance += distance;

      if (accumulatedDistance >= intervalKm) {
        sampledPoints.add(polylinePoints[i]);
        accumulatedDistance = 0.0;
      }
    }

    // Always include the last point
    if (polylinePoints.isNotEmpty &&
        sampledPoints.last != polylinePoints.last) {
      sampledPoints.add(polylinePoints.last);
    }

    return sampledPoints;
  }

  double _calculateDistanceFromRoute(
    ServiceCenter serviceCenter,
    List<Coordinates> routePoints,
  ) {
    if (routePoints.isEmpty) return double.infinity;

    final serviceCenterLocation = Coordinates(
      latitude: serviceCenter.latitude,
      longitude: serviceCenter.longitude,
    );

    double minDistance = double.infinity;

    for (final point in routePoints) {
      final distance = _calculateDistance(serviceCenterLocation, point);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  int _calculateDetourTime(double distanceKm) {
    // Estimate detour time: distance to service center + time at service center + return to route
    final travelTime = (distanceKm * 2 / 30 * 60)
        .round(); // Round trip at 30 km/h
    final serviceTime = 15; // Assume 15 minutes at service center
    return travelTime + serviceTime;
  }

  double _calculateDistance(Coordinates point1, Coordinates point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000; // Convert to km
  }

  bool _isServiceRelevantForVehicle(
    String service,
    VehicleContext vehicleContext,
  ) {
    // Simple service matching logic
    final lowFuel =
        vehicleContext.fuelLevel != null && vehicleContext.fuelLevel! < 0.25;
    final needsMaintenance = vehicleContext.upcomingMaintenanceItems.isNotEmpty;
    final hasIssues = vehicleContext.currentIssues.isNotEmpty;

    if (lowFuel && service.toLowerCase().contains('fuel')) return true;
    if (needsMaintenance && service.toLowerCase().contains('maintenance')) {
      return true;
    }
    if (hasIssues && service.toLowerCase().contains('repair')) return true;

    return false;
  }

  Future<List<SmartRecommendation>> _generateMaintenanceRecommendations(
    Coordinates currentLocation,
    VehicleContext vehicleContext,
    LocationContext locationContext,
  ) async {
    final recommendations = <SmartRecommendation>[];

    // Low fuel recommendation
    if (vehicleContext.fuelLevel != null && vehicleContext.fuelLevel! < 0.25) {
      recommendations.add(
        SmartRecommendation(
          id: 'fuel_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Low Fuel Alert',
          description:
              'Your fuel level is low (${(vehicleContext.fuelLevel! * 100).toInt()}%). Find a nearby fuel station.',
          priority: vehicleContext.fuelLevel! < 0.1 ? 0.9 : 0.7,
          category: 'fuel',
          actionItems: ['Find fuel station', 'Navigate to station'],
          validUntil: DateTime.now().add(const Duration(hours: 2)),
          isUrgent: vehicleContext.fuelLevel! < 0.1,
        ),
      );
    }

    // Upcoming maintenance
    if (vehicleContext.upcomingMaintenanceItems.isNotEmpty) {
      recommendations.add(
        SmartRecommendation(
          id: 'maintenance_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Maintenance Due',
          description:
              'You have ${vehicleContext.upcomingMaintenanceItems.length} maintenance items due: ${vehicleContext.upcomingMaintenanceItems.join(", ")}',
          priority: 0.6,
          category: 'maintenance',
          actionItems: ['Schedule service', 'Find service center'],
          validUntil: DateTime.now().add(const Duration(days: 7)),
          isUrgent: false,
        ),
      );
    }

    return recommendations;
  }

  Future<List<SmartRecommendation>> _generateHistoricalRecommendations(
    Coordinates currentLocation,
    LocationContext locationContext,
  ) async {
    final recommendations = <SmartRecommendation>[];

    // Find frequently visited locations nearby
    final nearbyHistory = _locationHistory
        .where(
          (history) =>
              _calculateDistance(history.location, currentLocation) <= 5.0,
        )
        .toList();

    if (nearbyHistory.isNotEmpty) {
      final mostVisited = nearbyHistory.reduce(
        (a, b) => a.visitCount > b.visitCount ? a : b,
      );

      if (mostVisited.visitCount >= 3) {
        recommendations.add(
          SmartRecommendation(
            id: 'history_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Familiar Area',
            description:
                'You\'ve visited ${mostVisited.address} ${mostVisited.visitCount} times before.',
            priority: 0.4,
            category: 'convenience',
            actionItems: ['View nearby services', 'Add to favorites'],
            validUntil: DateTime.now().add(const Duration(hours: 4)),
            isUrgent: false,
          ),
        );
      }
    }

    return recommendations;
  }

  Future<List<SmartRecommendation>> _generateFavoriteLocationRecommendations(
    Coordinates currentLocation,
    LocationContext locationContext,
  ) async {
    final recommendations = <SmartRecommendation>[];

    // Find nearby favorite locations
    final nearbyFavorites = _favoriteLocations
        .where(
          (favorite) =>
              _calculateDistance(favorite.location, currentLocation) <= 10.0,
        )
        .toList();

    for (final favorite in nearbyFavorites) {
      final distance = _calculateDistance(favorite.location, currentLocation);

      recommendations.add(
        SmartRecommendation(
          id: 'favorite_${favorite.id}',
          title: 'Nearby Favorite',
          description:
              '${favorite.name} is ${distance.toStringAsFixed(1)}km away.',
          priority: 0.5,
          category: 'convenience',
          actionItems: ['Navigate to location', 'View details'],
          validUntil: DateTime.now().add(const Duration(hours: 6)),
          isUrgent: false,
        ),
      );
    }

    return recommendations;
  }

  Future<List<SmartRecommendation>> _generateEmergencyRecommendations(
    Coordinates currentLocation,
    VehicleContext? vehicleContext,
    LocationContext locationContext,
  ) async {
    final recommendations = <SmartRecommendation>[];

    // Critical fuel level
    if (vehicleContext?.fuelLevel != null &&
        vehicleContext!.fuelLevel! < 0.05) {
      recommendations.add(
        SmartRecommendation(
          id: 'emergency_fuel_${DateTime.now().millisecondsSinceEpoch}',
          title: 'CRITICAL: Fuel Emergency',
          description:
              'Your fuel level is critically low! Find fuel immediately.',
          priority: 1.0,
          category: 'emergency',
          actionItems: [
            'Find nearest fuel station',
            'Call roadside assistance',
          ],
          validUntil: DateTime.now().add(const Duration(minutes: 30)),
          isUrgent: true,
        ),
      );
    }

    // Vehicle issues
    if (vehicleContext?.currentIssues.isNotEmpty == true) {
      final criticalIssues = vehicleContext!.currentIssues
          .where(
            (issue) =>
                issue.toLowerCase().contains('engine') ||
                issue.toLowerCase().contains('brake') ||
                issue.toLowerCase().contains('warning'),
          )
          .toList();

      if (criticalIssues.isNotEmpty) {
        recommendations.add(
          SmartRecommendation(
            id: 'emergency_repair_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Vehicle Issue Detected',
            description:
                'Critical issues detected: ${criticalIssues.join(", ")}',
            priority: 0.9,
            category: 'emergency',
            actionItems: ['Find emergency service', 'Pull over safely'],
            validUntil: DateTime.now().add(const Duration(hours: 1)),
            isUrgent: true,
          ),
        );
      }
    }

    return recommendations;
  }

  Future<void> _loadStoredData() async {
    // Load location history
    final historyJson = _prefs.getStringList(_locationHistoryKey) ?? [];
    _locationHistory = historyJson
        .map((json) {
          try {
            return LocationHistory.fromJson(
              Map<String, dynamic>.from(
                Uri.splitQueryString(
                  json,
                ).map((key, value) => MapEntry(key, value)),
              ),
            );
          } catch (e) {
            return null;
          }
        })
        .where((item) => item != null)
        .cast<LocationHistory>()
        .toList();

    // Load favorites
    final favoritesJson = _prefs.getStringList(_favoritesKey) ?? [];
    _favoriteLocations = favoritesJson
        .map((json) {
          try {
            return FavoriteLocation.fromJson(
              Map<String, dynamic>.from(
                Uri.splitQueryString(
                  json,
                ).map((key, value) => MapEntry(key, value)),
              ),
            );
          } catch (e) {
            return null;
          }
        })
        .where((item) => item != null)
        .cast<FavoriteLocation>()
        .toList();

    // Load preferences
    final prefsJson = _prefs.getString(_preferencesKey);
    if (prefsJson != null) {
      try {
        _preferences = RecommendationPreferences.fromJson(
          Map<String, dynamic>.from(Uri.splitQueryString(prefsJson)),
        );
      } catch (e) {
        _preferences = const RecommendationPreferences();
      }
    }
  }

  Future<void> _saveLocationHistory() async {
    final historyJson = _locationHistory
        .map(
          (history) => Uri(
            queryParameters: history.toJson().map(
              (key, value) => MapEntry(key, value.toString()),
            ),
          ).query,
        )
        .toList();
    await _prefs.setStringList(_locationHistoryKey, historyJson);
  }

  Future<void> _saveFavoriteLocations() async {
    final favoritesJson = _favoriteLocations
        .map(
          (favorite) => Uri(
            queryParameters: favorite.toJson().map(
              (key, value) => MapEntry(key, value.toString()),
            ),
          ).query,
        )
        .toList();
    await _prefs.setStringList(_favoritesKey, favoritesJson);
  }

  Future<void> _savePreferences() async {
    final prefsJson = Uri(
      queryParameters: _preferences.toJson().map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ).query;
    await _prefs.setString(_preferencesKey, prefsJson);
  }
}
