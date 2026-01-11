import 'package:json_annotation/json_annotation.dart';
import 'service_center.dart';

part 'location_recommendations.g.dart';

@JsonSerializable()
class LocationHistory {
  final String id;
  final Coordinates location;
  final String address;
  final DateTime timestamp;
  final String purpose; // 'service', 'fuel', 'parking', 'other'
  final int visitCount;
  final DateTime lastVisited;

  const LocationHistory({
    required this.id,
    required this.location,
    required this.address,
    required this.timestamp,
    required this.purpose,
    required this.visitCount,
    required this.lastVisited,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) =>
      _$LocationHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$LocationHistoryToJson(this);
}

@JsonSerializable()
class FavoriteLocation {
  final String id;
  final String name;
  final Coordinates location;
  final String address;
  final String
  category; // 'service_center', 'fuel_station', 'parking', 'custom'
  final DateTime createdAt;
  final String? notes;
  final List<String> tags;

  const FavoriteLocation({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.category,
    required this.createdAt,
    this.notes,
    required this.tags,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) =>
      _$FavoriteLocationFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteLocationToJson(this);
}

@JsonSerializable()
class RouteRecommendation {
  final String id;
  final ServiceCenter serviceCenter;
  final double relevanceScore; // 0.0 to 1.0
  final List<String> reasons; // Why this is recommended
  final double distanceFromRoute; // km from planned route
  final int estimatedDetourMinutes;
  final String
  recommendationType; // 'on_route', 'nearby', 'preferred', 'emergency'

  const RouteRecommendation({
    required this.id,
    required this.serviceCenter,
    required this.relevanceScore,
    required this.reasons,
    required this.distanceFromRoute,
    required this.estimatedDetourMinutes,
    required this.recommendationType,
  });

  factory RouteRecommendation.fromJson(Map<String, dynamic> json) =>
      _$RouteRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$RouteRecommendationToJson(this);
}

@JsonSerializable()
class LocationContext {
  final Coordinates currentLocation;
  final String? currentAddress;
  final DateTime timestamp;
  final double? speed; // km/h
  final String? heading; // N, NE, E, SE, S, SW, W, NW
  final bool isMoving;
  final String timeOfDay; // 'morning', 'afternoon', 'evening', 'night'
  final String dayOfWeek;

  const LocationContext({
    required this.currentLocation,
    this.currentAddress,
    required this.timestamp,
    this.speed,
    this.heading,
    required this.isMoving,
    required this.timeOfDay,
    required this.dayOfWeek,
  });

  factory LocationContext.fromJson(Map<String, dynamic> json) =>
      _$LocationContextFromJson(json);

  Map<String, dynamic> toJson() => _$LocationContextToJson(this);
}

@JsonSerializable()
class RecommendationPreferences {
  final double maxDetourDistance; // km
  final int maxDetourTime; // minutes
  final List<String> preferredServiceTypes;
  final double minRating;
  final bool includeHistoricalData;
  final bool includeFavorites;
  final bool notifyOnRouteServices;
  final String recommendationFrequency; // 'always', 'on_request', 'never'

  const RecommendationPreferences({
    this.maxDetourDistance = 5.0,
    this.maxDetourTime = 15,
    this.preferredServiceTypes = const [],
    this.minRating = 3.0,
    this.includeHistoricalData = true,
    this.includeFavorites = true,
    this.notifyOnRouteServices = true,
    this.recommendationFrequency = 'on_request',
  });

  factory RecommendationPreferences.fromJson(Map<String, dynamic> json) =>
      _$RecommendationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationPreferencesToJson(this);
}

@JsonSerializable()
class VehicleContext {
  final String vehicleId;
  final double? fuelLevel; // 0.0 to 1.0
  final int? mileage;
  final DateTime? lastServiceDate;
  final List<String> upcomingMaintenanceItems;
  final List<String> currentIssues;
  final String vehicleType; // 'sedan', 'suv', 'truck', 'electric', etc.

  const VehicleContext({
    required this.vehicleId,
    this.fuelLevel,
    this.mileage,
    this.lastServiceDate,
    this.upcomingMaintenanceItems = const [],
    this.currentIssues = const [],
    required this.vehicleType,
  });

  factory VehicleContext.fromJson(Map<String, dynamic> json) =>
      _$VehicleContextFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleContextToJson(this);
}

@JsonSerializable()
class SmartRecommendation {
  final String id;
  final String title;
  final String description;
  final ServiceCenter? serviceCenter;
  final FavoriteLocation? favoriteLocation;
  final double priority; // 0.0 to 1.0
  final String category; // 'maintenance', 'fuel', 'emergency', 'convenience'
  final List<String> actionItems;
  final DateTime validUntil;
  final bool isUrgent;

  const SmartRecommendation({
    required this.id,
    required this.title,
    required this.description,
    this.serviceCenter,
    this.favoriteLocation,
    required this.priority,
    required this.category,
    required this.actionItems,
    required this.validUntil,
    required this.isUrgent,
  });

  factory SmartRecommendation.fromJson(Map<String, dynamic> json) =>
      _$SmartRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$SmartRecommendationToJson(this);
}

