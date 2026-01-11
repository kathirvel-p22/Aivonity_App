// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_recommendations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationHistory _$LocationHistoryFromJson(Map<String, dynamic> json) =>
    LocationHistory(
      id: json['id'] as String,
      location: Coordinates.fromJson(json['location'] as Map<String, dynamic>),
      address: json['address'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      purpose: json['purpose'] as String,
      visitCount: (json['visitCount'] as num).toInt(),
      lastVisited: DateTime.parse(json['lastVisited'] as String),
    );

Map<String, dynamic> _$LocationHistoryToJson(LocationHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'location': instance.location,
      'address': instance.address,
      'timestamp': instance.timestamp.toIso8601String(),
      'purpose': instance.purpose,
      'visitCount': instance.visitCount,
      'lastVisited': instance.lastVisited.toIso8601String(),
    };

FavoriteLocation _$FavoriteLocationFromJson(Map<String, dynamic> json) =>
    FavoriteLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      location: Coordinates.fromJson(json['location'] as Map<String, dynamic>),
      address: json['address'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$FavoriteLocationToJson(FavoriteLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'address': instance.address,
      'category': instance.category,
      'createdAt': instance.createdAt.toIso8601String(),
      'notes': instance.notes,
      'tags': instance.tags,
    };

RouteRecommendation _$RouteRecommendationFromJson(Map<String, dynamic> json) =>
    RouteRecommendation(
      id: json['id'] as String,
      serviceCenter: ServiceCenter.fromJson(
        json['serviceCenter'] as Map<String, dynamic>,
      ),
      relevanceScore: (json['relevanceScore'] as num).toDouble(),
      reasons: (json['reasons'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      distanceFromRoute: (json['distanceFromRoute'] as num).toDouble(),
      estimatedDetourMinutes: (json['estimatedDetourMinutes'] as num).toInt(),
      recommendationType: json['recommendationType'] as String,
    );

Map<String, dynamic> _$RouteRecommendationToJson(
  RouteRecommendation instance,
) => <String, dynamic>{
  'id': instance.id,
  'serviceCenter': instance.serviceCenter,
  'relevanceScore': instance.relevanceScore,
  'reasons': instance.reasons,
  'distanceFromRoute': instance.distanceFromRoute,
  'estimatedDetourMinutes': instance.estimatedDetourMinutes,
  'recommendationType': instance.recommendationType,
};

LocationContext _$LocationContextFromJson(Map<String, dynamic> json) =>
    LocationContext(
      currentLocation: Coordinates.fromJson(
        json['currentLocation'] as Map<String, dynamic>,
      ),
      currentAddress: json['currentAddress'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: json['heading'] as String?,
      isMoving: json['isMoving'] as bool,
      timeOfDay: json['timeOfDay'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
    );

Map<String, dynamic> _$LocationContextToJson(LocationContext instance) =>
    <String, dynamic>{
      'currentLocation': instance.currentLocation,
      'currentAddress': instance.currentAddress,
      'timestamp': instance.timestamp.toIso8601String(),
      'speed': instance.speed,
      'heading': instance.heading,
      'isMoving': instance.isMoving,
      'timeOfDay': instance.timeOfDay,
      'dayOfWeek': instance.dayOfWeek,
    };

RecommendationPreferences _$RecommendationPreferencesFromJson(
  Map<String, dynamic> json,
) => RecommendationPreferences(
  maxDetourDistance: (json['maxDetourDistance'] as num?)?.toDouble() ?? 5.0,
  maxDetourTime: (json['maxDetourTime'] as num?)?.toInt() ?? 15,
  preferredServiceTypes:
      (json['preferredServiceTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  minRating: (json['minRating'] as num?)?.toDouble() ?? 3.0,
  includeHistoricalData: json['includeHistoricalData'] as bool? ?? true,
  includeFavorites: json['includeFavorites'] as bool? ?? true,
  notifyOnRouteServices: json['notifyOnRouteServices'] as bool? ?? true,
  recommendationFrequency:
      json['recommendationFrequency'] as String? ?? 'on_request',
);

Map<String, dynamic> _$RecommendationPreferencesToJson(
  RecommendationPreferences instance,
) => <String, dynamic>{
  'maxDetourDistance': instance.maxDetourDistance,
  'maxDetourTime': instance.maxDetourTime,
  'preferredServiceTypes': instance.preferredServiceTypes,
  'minRating': instance.minRating,
  'includeHistoricalData': instance.includeHistoricalData,
  'includeFavorites': instance.includeFavorites,
  'notifyOnRouteServices': instance.notifyOnRouteServices,
  'recommendationFrequency': instance.recommendationFrequency,
};

VehicleContext _$VehicleContextFromJson(Map<String, dynamic> json) =>
    VehicleContext(
      vehicleId: json['vehicleId'] as String,
      fuelLevel: (json['fuelLevel'] as num?)?.toDouble(),
      mileage: (json['mileage'] as num?)?.toInt(),
      lastServiceDate: json['lastServiceDate'] == null
          ? null
          : DateTime.parse(json['lastServiceDate'] as String),
      upcomingMaintenanceItems:
          (json['upcomingMaintenanceItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentIssues:
          (json['currentIssues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      vehicleType: json['vehicleType'] as String,
    );

Map<String, dynamic> _$VehicleContextToJson(VehicleContext instance) =>
    <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'fuelLevel': instance.fuelLevel,
      'mileage': instance.mileage,
      'lastServiceDate': instance.lastServiceDate?.toIso8601String(),
      'upcomingMaintenanceItems': instance.upcomingMaintenanceItems,
      'currentIssues': instance.currentIssues,
      'vehicleType': instance.vehicleType,
    };

SmartRecommendation _$SmartRecommendationFromJson(Map<String, dynamic> json) =>
    SmartRecommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      serviceCenter: json['serviceCenter'] == null
          ? null
          : ServiceCenter.fromJson(
              json['serviceCenter'] as Map<String, dynamic>,
            ),
      favoriteLocation: json['favoriteLocation'] == null
          ? null
          : FavoriteLocation.fromJson(
              json['favoriteLocation'] as Map<String, dynamic>,
            ),
      priority: (json['priority'] as num).toDouble(),
      category: json['category'] as String,
      actionItems: (json['actionItems'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      validUntil: DateTime.parse(json['validUntil'] as String),
      isUrgent: json['isUrgent'] as bool,
    );

Map<String, dynamic> _$SmartRecommendationToJson(
  SmartRecommendation instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'serviceCenter': instance.serviceCenter,
  'favoriteLocation': instance.favoriteLocation,
  'priority': instance.priority,
  'category': instance.category,
  'actionItems': instance.actionItems,
  'validUntil': instance.validUntil.toIso8601String(),
  'isUrgent': instance.isUrgent,
};

