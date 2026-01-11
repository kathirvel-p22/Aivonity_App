/// AIVONITY Service Center Model
/// Represents a service center with location and availability info
class ServiceCenter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final List<String> services;
  final Map<String, dynamic> workingHours;
  final String? phone;
  final String? email;
  final double? distanceKm;
  final bool isAuthorized;

  const ServiceCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.services,
    required this.workingHours,
    this.phone,
    this.email,
    this.distanceKm,
    this.isAuthorized = true,
  });

  factory ServiceCenter.fromJson(Map<String, dynamic> json) {
    return ServiceCenter(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      services: (json['services'] as List).cast<String>(),
      workingHours: json['workingHours'] as Map<String, dynamic>,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isAuthorized: json['isAuthorized'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'services': services,
      'workingHours': workingHours,
      'phone': phone,
      'email': email,
      'distanceKm': distanceKm,
      'isAuthorized': isAuthorized,
    };
  }

  ServiceCenter copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    List<String>? services,
    Map<String, dynamic>? workingHours,
    String? phone,
    String? email,
    double? distanceKm,
    bool? isAuthorized,
  }) {
    return ServiceCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      distanceKm: distanceKm ?? this.distanceKm,
      isAuthorized: isAuthorized ?? this.isAuthorized,
    );
  }
}

