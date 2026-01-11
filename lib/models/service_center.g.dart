// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_center.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceCenter _$ServiceCenterFromJson(Map<String, dynamic> json) =>
    ServiceCenter(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      services: (json['services'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      workingHours: (json['workingHours'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isOpen: json['isOpen'] as bool,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      estimatedWaitTimeMinutes: (json['estimatedWaitTimeMinutes'] as num)
          .toInt(),
    );

Map<String, dynamic> _$ServiceCenterToJson(ServiceCenter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'services': instance.services,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'workingHours': instance.workingHours,
      'isOpen': instance.isOpen,
      'distanceKm': instance.distanceKm,
      'estimatedWaitTimeMinutes': instance.estimatedWaitTimeMinutes,
    };

ServiceCenterFilter _$ServiceCenterFilterFromJson(Map<String, dynamic> json) =>
    ServiceCenterFilter(
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble(),
      requiredServices: (json['requiredServices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      minRating: (json['minRating'] as num?)?.toDouble(),
      openNow: json['openNow'] as bool?,
      sortBy: json['sortBy'] as String?,
    );

Map<String, dynamic> _$ServiceCenterFilterToJson(
  ServiceCenterFilter instance,
) => <String, dynamic>{
  'maxDistanceKm': instance.maxDistanceKm,
  'requiredServices': instance.requiredServices,
  'minRating': instance.minRating,
  'openNow': instance.openNow,
  'sortBy': instance.sortBy,
};

Coordinates _$CoordinatesFromJson(Map<String, dynamic> json) => Coordinates(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$CoordinatesToJson(Coordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

