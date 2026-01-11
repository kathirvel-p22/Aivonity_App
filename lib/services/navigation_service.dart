import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../models/navigation.dart';
import '../models/service_center.dart';
import '../config/api_config.dart';

class NavigationService {
  final Dio _dio;
  final SharedPreferences _prefs;
  String? _apiKey;

  NavigationService(this._dio, this._prefs) {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    _apiKey =
        _prefs.getString('google_maps_api_key') ?? ApiConfig.googleMapsApiKey;
  }

  /// Calculate route between two points using Google Directions API
  Future<NavigationRoute> calculateRoute({
    required Coordinates origin,
    required Coordinates destination,
    RouteOptions? options,
  }) async {
    if (_apiKey == null) await _loadApiKey();

    final routeOptions = options ?? const RouteOptions();

    try {
      final response = await _dio.get(
        '${ApiConfig.apiEndpoints['directions']}/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': routeOptions.travelMode,
          'avoid': _buildAvoidanceString(routeOptions),
          'departure_time':
              routeOptions.departureTime?.millisecondsSinceEpoch ?? 'now',
          'key': _apiKey,
          if (routeOptions.waypoints != null &&
              routeOptions.waypoints!.isNotEmpty)
            'waypoints': _buildWaypointsString(routeOptions.waypoints!),
        },
      );

      if (response.statusCode == 200) {
        return _parseDirectionsResponse(response.data, origin, destination);
      } else {
        throw Exception('Failed to calculate route: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Route calculation error: $e');
    }
  }

  /// Calculate routes to multiple service centers
  Future<List<ServiceCenterRoute>> calculateServiceCenterRoutes({
    required Coordinates origin,
    required List<ServiceCenter> serviceCenters,
    RouteOptions? options,
  }) async {
    final List<ServiceCenterRoute> routes = [];

    for (final serviceCenter in serviceCenters) {
      try {
        final destination = Coordinates(
          latitude: serviceCenter.latitude,
          longitude: serviceCenter.longitude,
        );

        final route = await calculateRoute(
          origin: origin,
          destination: destination,
          options: options,
        );

        final estimatedArrival = DateTime.now().add(
          Duration(seconds: route.totalDurationSeconds),
        );

        final serviceCenterRoute = ServiceCenterRoute(
          serviceCenter: serviceCenter,
          route: route,
          estimatedArrival: estimatedArrival,
          trafficCondition: _estimateTrafficCondition(
            route.totalDurationSeconds,
          ),
          fuelCostEstimate: _calculateFuelCost(route.totalDistanceMeters),
        );

        routes.add(serviceCenterRoute);
      } catch (e) {
        AppLogger.error('Error calculating route to ${serviceCenter.name}', e);
      }
    }

    // Sort by travel time
    routes.sort(
      (a, b) =>
          a.route.totalDurationSeconds.compareTo(b.route.totalDurationSeconds),
    );

    return routes;
  }

  /// Launch navigation in external app
  Future<bool> launchNavigation({
    required Coordinates destination,
    Coordinates? origin,
    NavigationApp? preferredApp,
    String? destinationName,
  }) async {
    final app = preferredApp ?? await _getPreferredNavigationApp();

    try {
      switch (app) {
        case NavigationApp.googleMaps:
          return await _launchGoogleMaps(destination, origin, destinationName);
        case NavigationApp.appleMaps:
          return await _launchAppleMaps(destination, origin, destinationName);
        case NavigationApp.waze:
          return await _launchWaze(destination, origin, destinationName);
      }
    } catch (e) {
      // Fallback to Google Maps if preferred app fails
      if (app != NavigationApp.googleMaps) {
        return await _launchGoogleMaps(destination, origin, destinationName);
      }
      throw Exception('Failed to launch navigation: $e');
    }
  }

  /// Launch navigation to service center
  Future<bool> navigateToServiceCenter(ServiceCenter serviceCenter) async {
    final destination = Coordinates(
      latitude: serviceCenter.latitude,
      longitude: serviceCenter.longitude,
    );

    return await launchNavigation(
      destination: destination,
      destinationName: serviceCenter.name,
    );
  }

  /// Get estimated travel time with current traffic
  Future<Duration> getEstimatedTravelTime({
    required Coordinates origin,
    required Coordinates destination,
    RouteOptions? options,
  }) async {
    try {
      final route = await calculateRoute(
        origin: origin,
        destination: destination,
        options: options,
      );
      return Duration(seconds: route.totalDurationSeconds);
    } catch (e) {
      // Fallback to straight-line distance estimation
      return _estimateTravelTimeByDistance(origin, destination);
    }
  }

  /// Monitor route progress and provide updates
  Stream<RouteProgress> monitorRouteProgress({
    required NavigationRoute route,
    required Stream<Coordinates> locationUpdates,
  }) {
    return locationUpdates.map((currentLocation) {
      return _calculateRouteProgress(route, currentLocation);
    });
  }

  // Private helper methods

  String _buildAvoidanceString(RouteOptions options) {
    final List<String> avoidances = [];
    if (options.avoidTolls) avoidances.add('tolls');
    if (options.avoidHighways) avoidances.add('highways');
    if (options.avoidFerries) avoidances.add('ferries');
    return avoidances.join('|');
  }

  String _buildWaypointsString(List<Coordinates> waypoints) {
    return waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
  }

  NavigationRoute _parseDirectionsResponse(
    Map<String, dynamic> data,
    Coordinates origin,
    Coordinates destination,
  ) {
    final routes = data['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    final legs = route['legs'] as List;
    final leg = legs.first;

    // Parse polyline points
    final polylinePoints = _decodePolyline(
      route['overview_polyline']['points'],
    );

    // Parse route steps
    final steps = <RouteStep>[];
    for (final step in leg['steps']) {
      steps.add(_parseRouteStep(step));
    }

    return NavigationRoute(
      routeId:
          route['summary'] ?? 'route_${DateTime.now().millisecondsSinceEpoch}',
      polylinePoints: polylinePoints,
      totalDistanceMeters: leg['distance']['value'].toDouble(),
      totalDurationSeconds: leg['duration']['value'],
      steps: steps,
      startLocation: origin,
      endLocation: destination,
      summary: route['summary'] ?? '',
      warnings: List<String>.from(route['warnings'] ?? []),
    );
  }

  RouteStep _parseRouteStep(Map<String, dynamic> step) {
    final startLoc = step['start_location'];
    final endLoc = step['end_location'];

    return RouteStep(
      instruction: _stripHtmlTags(step['html_instructions']),
      distanceMeters: step['distance']['value'].toDouble(),
      durationSeconds: step['duration']['value'],
      startLocation: Coordinates(
        latitude: startLoc['lat'].toDouble(),
        longitude: startLoc['lng'].toDouble(),
      ),
      endLocation: Coordinates(
        latitude: endLoc['lat'].toDouble(),
        longitude: endLoc['lng'].toDouble(),
      ),
      maneuver: step['maneuver'] ?? 'straight',
    );
  }

  List<Coordinates> _decodePolyline(String encoded) {
    final points = decodePolyline(encoded);
    return points
        .map(
          (point) => Coordinates(
            latitude: point[0].toDouble(),
            longitude: point[1].toDouble(),
          ),
        )
        .toList();
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Future<bool> _launchGoogleMaps(
    Coordinates destination,
    Coordinates? origin,
    String? destinationName,
  ) async {
    String url;

    if (origin != null) {
      url =
          'https://www.google.com/maps/dir/${origin.latitude},${origin.longitude}/${destination.latitude},${destination.longitude}';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
      if (destinationName != null) {
        url += '&query_place_id=$destinationName';
      }
    }

    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _launchAppleMaps(
    Coordinates destination,
    Coordinates? origin,
    String? destinationName,
  ) async {
    if (!Platform.isIOS) {
      return await _launchGoogleMaps(destination, origin, destinationName);
    }

    String url =
        'https://maps.apple.com/?daddr=${destination.latitude},${destination.longitude}';

    if (origin != null) {
      url += '&saddr=${origin.latitude},${origin.longitude}';
    }

    if (destinationName != null) {
      url += '&q=${Uri.encodeComponent(destinationName)}';
    }

    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _launchWaze(
    Coordinates destination,
    Coordinates? origin,
    String? destinationName,
  ) async {
    final url =
        'https://waze.com/ul?ll=${destination.latitude},${destination.longitude}&navigate=yes';
    final uri = Uri.parse(url);

    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps
      return await _launchGoogleMaps(destination, origin, destinationName);
    }
  }

  Future<NavigationApp> _getPreferredNavigationApp() async {
    final prefString =
        _prefs.getString('preferred_navigation_app') ?? 'googleMaps';
    switch (prefString) {
      case 'appleMaps':
        return NavigationApp.appleMaps;
      case 'waze':
        return NavigationApp.waze;
      default:
        return NavigationApp.googleMaps;
    }
  }

  String _estimateTrafficCondition(int durationSeconds) {
    // Simple traffic estimation based on duration
    // In a real app, this would use traffic data from the API
    if (durationSeconds > 3600) return 'heavy';
    if (durationSeconds > 1800) return 'moderate';
    return 'light';
  }

  double _calculateFuelCost(double distanceMeters) {
    // Simple fuel cost calculation
    // Assumes 8L/100km consumption and $1.50/L fuel price
    final distanceKm = distanceMeters / 1000;
    final fuelConsumption = distanceKm * 0.08; // 8L/100km
    return fuelConsumption * 1.50; // $1.50/L
  }

  Duration _estimateTravelTimeByDistance(
    Coordinates origin,
    Coordinates destination,
  ) {
    // Simple estimation: assume 50 km/h average speed
    final distance = _calculateStraightLineDistance(origin, destination);
    final timeHours = distance / 50; // 50 km/h
    return Duration(minutes: (timeHours * 60).round());
  }

  double _calculateStraightLineDistance(
    Coordinates origin,
    Coordinates destination,
  ) {
    // Haversine formula for straight-line distance
    const double earthRadius = 6371; // km

    final lat1Rad = origin.latitude * (3.14159 / 180);
    final lat2Rad = destination.latitude * (3.14159 / 180);
    final deltaLatRad =
        (destination.latitude - origin.latitude) * (3.14159 / 180);
    final deltaLngRad =
        (destination.longitude - origin.longitude) * (3.14159 / 180);

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  RouteProgress _calculateRouteProgress(
    NavigationRoute route,
    Coordinates currentLocation,
  ) {
    // Find the closest point on the route
    double minDistance = double.infinity;
    int closestPointIndex = 0;

    for (int i = 0; i < route.polylinePoints.length; i++) {
      final distance = _calculateStraightLineDistance(
        currentLocation,
        route.polylinePoints[i],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    // Calculate progress percentage
    final progressPercentage = closestPointIndex / route.polylinePoints.length;
    final remainingDistance =
        route.totalDistanceMeters * (1 - progressPercentage);
    final remainingTime = route.totalDurationSeconds * (1 - progressPercentage);

    return RouteProgress(
      progressPercentage: progressPercentage,
      remainingDistanceMeters: remainingDistance,
      remainingTimeSeconds: remainingTime.round(),
      currentLocation: currentLocation,
      isOnRoute: minDistance < 0.1, // Within 100m of route
    );
  }
}

class RouteProgress {
  final double progressPercentage;
  final double remainingDistanceMeters;
  final int remainingTimeSeconds;
  final Coordinates currentLocation;
  final bool isOnRoute;

  const RouteProgress({
    required this.progressPercentage,
    required this.remainingDistanceMeters,
    required this.remainingTimeSeconds,
    required this.currentLocation,
    required this.isOnRoute,
  });

  String get formattedRemainingDistance {
    if (remainingDistanceMeters < 1000) {
      return '${remainingDistanceMeters.toInt()} m';
    } else {
      return '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedRemainingTime {
    final hours = remainingTimeSeconds ~/ 3600;
    final minutes = (remainingTimeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
