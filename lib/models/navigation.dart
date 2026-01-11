import 'package:json_annotation/json_annotation.dart';
import 'service_center.dart';

part 'navigation.g.dart';

@JsonSerializable()
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final int durationSeconds;
  final Coordinates startLocation;
  final Coordinates endLocation;
  final String maneuver;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) =>
      _$RouteStepFromJson(json);

  Map<String, dynamic> toJson() => _$RouteStepToJson(this);
}

@JsonSerializable()
class NavigationRoute {
  final String routeId;
  final List<Coordinates> polylinePoints;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final List<RouteStep> steps;
  final Coordinates startLocation;
  final Coordinates endLocation;
  final String summary;
  final List<String> warnings;

  const NavigationRoute({
    required this.routeId,
    required this.polylinePoints,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.steps,
    required this.startLocation,
    required this.endLocation,
    required this.summary,
    required this.warnings,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) =>
      _$NavigationRouteFromJson(json);

  Map<String, dynamic> toJson() => _$NavigationRouteToJson(this);

  String get formattedDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.toInt()} m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedDuration {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

@JsonSerializable()
class RouteOptions {
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final String travelMode; // 'driving', 'walking', 'bicycling', 'transit'
  final List<Coordinates>? waypoints;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  const RouteOptions({
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
    this.travelMode = 'driving',
    this.waypoints,
    this.departureTime,
    this.arrivalTime,
  });

  factory RouteOptions.fromJson(Map<String, dynamic> json) =>
      _$RouteOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$RouteOptionsToJson(this);
}

@JsonSerializable()
class ServiceCenterRoute {
  final ServiceCenter serviceCenter;
  final NavigationRoute route;
  final DateTime estimatedArrival;
  final String trafficCondition; // 'light', 'moderate', 'heavy'
  final double fuelCostEstimate;

  const ServiceCenterRoute({
    required this.serviceCenter,
    required this.route,
    required this.estimatedArrival,
    required this.trafficCondition,
    required this.fuelCostEstimate,
  });

  factory ServiceCenterRoute.fromJson(Map<String, dynamic> json) =>
      _$ServiceCenterRouteFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCenterRouteToJson(this);
}

enum NavigationApp { googleMaps, appleMaps, waze }

@JsonSerializable()
class NavigationPreferences {
  final NavigationApp preferredApp;
  final RouteOptions defaultRouteOptions;
  final bool showTrafficAlerts;
  final bool voiceNavigation;
  final String units; // 'metric', 'imperial'

  const NavigationPreferences({
    this.preferredApp = NavigationApp.googleMaps,
    this.defaultRouteOptions = const RouteOptions(),
    this.showTrafficAlerts = true,
    this.voiceNavigation = true,
    this.units = 'metric',
  });

  factory NavigationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NavigationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NavigationPreferencesToJson(this);
}

