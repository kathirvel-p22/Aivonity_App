import 'package:json_annotation/json_annotation.dart';

part 'service_center.g.dart';

@JsonSerializable()
class ServiceCenter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> services;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String email;
  final List<String> workingHours;
  final bool isOpen;
  final double distanceKm;
  final int estimatedWaitTimeMinutes;

  const ServiceCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.email,
    required this.workingHours,
    required this.isOpen,
    required this.distanceKm,
    required this.estimatedWaitTimeMinutes,
  });

  factory ServiceCenter.fromJson(Map<String, dynamic> json) =>
      _$ServiceCenterFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCenterToJson(this);
}

@JsonSerializable()
class ServiceCenterFilter {
  final double? maxDistanceKm;
  final List<String>? requiredServices;
  final double? minRating;
  final bool? openNow;
  final String? sortBy; // 'distance', 'rating', 'wait_time'

  const ServiceCenterFilter({
    this.maxDistanceKm,
    this.requiredServices,
    this.minRating,
    this.openNow,
    this.sortBy,
  });

  factory ServiceCenterFilter.fromJson(Map<String, dynamic> json) =>
      _$ServiceCenterFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCenterFilterToJson(this);
}

@JsonSerializable()
class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);

  Map<String, dynamic> toJson() => _$CoordinatesToJson(this);
}

