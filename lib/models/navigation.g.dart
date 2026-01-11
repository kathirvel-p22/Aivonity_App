// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteStep _$RouteStepFromJson(Map<String, dynamic> json) => RouteStep(
  instruction: json['instruction'] as String,
  distanceMeters: (json['distanceMeters'] as num).toDouble(),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  startLocation: Coordinates.fromJson(
    json['startLocation'] as Map<String, dynamic>,
  ),
  endLocation: Coordinates.fromJson(
    json['endLocation'] as Map<String, dynamic>,
  ),
  maneuver: json['maneuver'] as String,
);

Map<String, dynamic> _$RouteStepToJson(RouteStep instance) => <String, dynamic>{
  'instruction': instance.instruction,
  'distanceMeters': instance.distanceMeters,
  'durationSeconds': instance.durationSeconds,
  'startLocation': instance.startLocation,
  'endLocation': instance.endLocation,
  'maneuver': instance.maneuver,
};

NavigationRoute _$NavigationRouteFromJson(Map<String, dynamic> json) =>
    NavigationRoute(
      routeId: json['routeId'] as String,
      polylinePoints: (json['polylinePoints'] as List<dynamic>)
          .map((e) => Coordinates.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
      totalDurationSeconds: (json['totalDurationSeconds'] as num).toInt(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => RouteStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      startLocation: Coordinates.fromJson(
        json['startLocation'] as Map<String, dynamic>,
      ),
      endLocation: Coordinates.fromJson(
        json['endLocation'] as Map<String, dynamic>,
      ),
      summary: json['summary'] as String,
      warnings: (json['warnings'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$NavigationRouteToJson(NavigationRoute instance) =>
    <String, dynamic>{
      'routeId': instance.routeId,
      'polylinePoints': instance.polylinePoints,
      'totalDistanceMeters': instance.totalDistanceMeters,
      'totalDurationSeconds': instance.totalDurationSeconds,
      'steps': instance.steps,
      'startLocation': instance.startLocation,
      'endLocation': instance.endLocation,
      'summary': instance.summary,
      'warnings': instance.warnings,
    };

RouteOptions _$RouteOptionsFromJson(Map<String, dynamic> json) => RouteOptions(
  avoidTolls: json['avoidTolls'] as bool? ?? false,
  avoidHighways: json['avoidHighways'] as bool? ?? false,
  avoidFerries: json['avoidFerries'] as bool? ?? false,
  travelMode: json['travelMode'] as String? ?? 'driving',
  waypoints: (json['waypoints'] as List<dynamic>?)
      ?.map((e) => Coordinates.fromJson(e as Map<String, dynamic>))
      .toList(),
  departureTime: json['departureTime'] == null
      ? null
      : DateTime.parse(json['departureTime'] as String),
  arrivalTime: json['arrivalTime'] == null
      ? null
      : DateTime.parse(json['arrivalTime'] as String),
);

Map<String, dynamic> _$RouteOptionsToJson(RouteOptions instance) =>
    <String, dynamic>{
      'avoidTolls': instance.avoidTolls,
      'avoidHighways': instance.avoidHighways,
      'avoidFerries': instance.avoidFerries,
      'travelMode': instance.travelMode,
      'waypoints': instance.waypoints,
      'departureTime': instance.departureTime?.toIso8601String(),
      'arrivalTime': instance.arrivalTime?.toIso8601String(),
    };

ServiceCenterRoute _$ServiceCenterRouteFromJson(Map<String, dynamic> json) =>
    ServiceCenterRoute(
      serviceCenter: ServiceCenter.fromJson(
        json['serviceCenter'] as Map<String, dynamic>,
      ),
      route: NavigationRoute.fromJson(json['route'] as Map<String, dynamic>),
      estimatedArrival: DateTime.parse(json['estimatedArrival'] as String),
      trafficCondition: json['trafficCondition'] as String,
      fuelCostEstimate: (json['fuelCostEstimate'] as num).toDouble(),
    );

Map<String, dynamic> _$ServiceCenterRouteToJson(ServiceCenterRoute instance) =>
    <String, dynamic>{
      'serviceCenter': instance.serviceCenter,
      'route': instance.route,
      'estimatedArrival': instance.estimatedArrival.toIso8601String(),
      'trafficCondition': instance.trafficCondition,
      'fuelCostEstimate': instance.fuelCostEstimate,
    };

NavigationPreferences _$NavigationPreferencesFromJson(
  Map<String, dynamic> json,
) => NavigationPreferences(
  preferredApp:
      $enumDecodeNullable(_$NavigationAppEnumMap, json['preferredApp']) ??
      NavigationApp.googleMaps,
  defaultRouteOptions: json['defaultRouteOptions'] == null
      ? const RouteOptions()
      : RouteOptions.fromJson(
          json['defaultRouteOptions'] as Map<String, dynamic>,
        ),
  showTrafficAlerts: json['showTrafficAlerts'] as bool? ?? true,
  voiceNavigation: json['voiceNavigation'] as bool? ?? true,
  units: json['units'] as String? ?? 'metric',
);

Map<String, dynamic> _$NavigationPreferencesToJson(
  NavigationPreferences instance,
) => <String, dynamic>{
  'preferredApp': _$NavigationAppEnumMap[instance.preferredApp]!,
  'defaultRouteOptions': instance.defaultRouteOptions,
  'showTrafficAlerts': instance.showTrafficAlerts,
  'voiceNavigation': instance.voiceNavigation,
  'units': instance.units,
};

const _$NavigationAppEnumMap = {
  NavigationApp.googleMaps: 'googleMaps',
  NavigationApp.appleMaps: 'appleMaps',
  NavigationApp.waze: 'waze',
};

