import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enhanced Location Service for AIVONITY
/// Provides comprehensive location functionality with sharing capabilities
class EnhancedLocationService extends ChangeNotifier {
  static const String _serviceName = 'EnhancedLocationService';

  // Current state
  Position? _currentPosition;
  String _currentAddress = 'Unknown location';
  bool _isLoading = false;
  bool _isServiceEnabled = false;
  bool _hasPermission = false;
  String? _error;
  StreamSubscription<Position>? _positionStream;

  // Location history
  final List<LocationHistoryEntry> _locationHistory = [];
  static const int _maxHistoryEntries = 50;

  // Emergency contacts for location sharing
  final List<EmergencyContact> _emergencyContacts = [];

  // Getters
  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  bool get isServiceEnabled => _isServiceEnabled;
  bool get hasPermission => _hasPermission;
  String? get error => _error;
  List<LocationHistoryEntry> get locationHistory =>
      List.unmodifiable(_locationHistory);
  List<EmergencyContact> get emergencyContacts =>
      List.unmodifiable(_emergencyContacts);

  /// Initialize the location service
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if location services are enabled
      await _checkLocationService();

      // Check permissions
      await _checkPermissions();

      // Get initial location
      if (_isServiceEnabled && _hasPermission) {
        await getCurrentLocation();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize location service: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if location services are enabled
  Future<void> _checkLocationService() async {
    try {
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isServiceEnabled) {
        _error =
            'Location services are disabled. Please enable them in device settings.';
      }
    } catch (e) {
      _error = 'Failed to check location service status: ${e.toString()}';
    }
  }

  /// Check location permissions
  Future<void> _checkPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      _hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      _error = 'Failed to check permissions: ${e.toString()}';
    }
  }

  /// Request location permissions
  Future<bool> requestPermissions() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Request through Geolocator first
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Try requesting through permission_handler as fallback
        final status = await Permission.location.request();
        permission = status == PermissionStatus.granted ||
                status == PermissionStatus.limited
            ? LocationPermission.whileInUse
            : LocationPermission.denied;
      }

      if (permission == LocationPermission.deniedForever) {
        _error =
            'Location permissions permanently denied. Please enable them in app settings.';
        await openAppSettings();
        return false;
      }

      _hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      _isLoading = false;
      notifyListeners();

      return _hasPermission;
    } catch (e) {
      _error = 'Failed to request permissions: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (!_isServiceEnabled) {
        throw Exception('Location services are disabled');
      }

      if (!_hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return null;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = position;
      _currentAddress = await _getAddressFromCoordinates(position);

      // Add to history
      _addToHistory(position, _currentAddress);

      _isLoading = false;
      notifyListeners();

      return position;
    } catch (e) {
      _error = 'Failed to get location: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Start location tracking
  void startLocationTracking() {
    if (_positionStream != null) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _getAddressFromCoordinates(position).then((address) {
        _currentAddress = address;
        _addToHistory(position, address);
        notifyListeners();
      });
    });
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Get address from coordinates
  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}'
            .trim();
      }
    } catch (e) {
      debugPrint('Failed to get address: $e');
    }

    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Geocode an address to coordinates
  Future<List<Location>> geocodeAddress(String address) async {
    try {
      final List<Location> locations = await locationFromAddress(address);
      return locations;
    } catch (e) {
      debugPrint('Failed to geocode address: $e');
      return [];
    }
  }

  /// Add location to history
  void _addToHistory(Position position, String address) {
    final entry = LocationHistoryEntry(
      timestamp: DateTime.now(),
      position: position,
      address: address,
    );

    _locationHistory.insert(0, entry);

    // Keep only the most recent entries
    if (_locationHistory.length > _maxHistoryEntries) {
      _locationHistory.removeRange(_maxHistoryEntries, _locationHistory.length);
    }

    notifyListeners();
  }

  /// Share current location
  Future<void> shareCurrentLocation({String? message}) async {
    try {
      if (_currentPosition == null) {
        await getCurrentLocation();
        if (_currentPosition == null) {
          throw Exception('Unable to get current location');
        }
      }

      final position = _currentPosition!;
      final shareMessage = message ?? 'My current location: $_currentAddress';
      final googleMapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      final fullMessage = '$shareMessage\n\n$googleMapsUrl';

      await Share.share(
        fullMessage,
        subject: 'My Current Location',
      );
    } catch (e) {
      _error = 'Failed to share location: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Share location via specific platform
  Future<void> shareLocationViaPlatform({
    required LocationSharePlatform platform,
    String? message,
  }) async {
    try {
      if (_currentPosition == null) {
        await getCurrentLocation();
        if (_currentPosition == null) {
          throw Exception('Unable to get current location');
        }
      }

      final position = _currentPosition!;
      final shareMessage = message ?? 'My current location: $_currentAddress';
      final googleMapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      final url = _buildPlatformShareUrl(platform, position, shareMessage);

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to general share
        final fullMessage = '$shareMessage\n\n$googleMapsUrl';
        await Share.share(fullMessage, subject: 'My Current Location');
      }
    } catch (e) {
      _error =
          'Failed to share location via ${platform.displayName}: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Build platform-specific share URL
  String _buildPlatformShareUrl(
    LocationSharePlatform platform,
    Position position,
    String message,
  ) {
    final encodedMessage = Uri.encodeComponent(message);
    final googleMapsUrl =
        'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

    switch (platform) {
      case LocationSharePlatform.whatsapp:
        return 'whatsapp://send?text=${Uri.encodeComponent('$message\n\n$googleMapsUrl')}';

      case LocationSharePlatform.telegram:
        return 'tg://msg?text=${Uri.encodeComponent('$message\n\n$googleMapsUrl')}';

      case LocationSharePlatform.email:
        return 'mailto:?subject=${Uri.encodeComponent('My Current Location')}&body=${Uri.encodeComponent('$message\n\n$googleMapsUrl')}';

      case LocationSharePlatform.sms:
        return 'sms:?body=${Uri.encodeComponent('$message\n\n$googleMapsUrl')}';

      case LocationSharePlatform.facebook:
        return 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(googleMapsUrl)}&quote=$encodedMessage';

      case LocationSharePlatform.twitter:
        return 'https://twitter.com/intent/tweet?text=$encodedMessage&url=${Uri.encodeComponent(googleMapsUrl)}';

      case LocationSharePlatform.instagram:
        // Instagram doesn't support direct URL sharing, fallback to general share
        return googleMapsUrl;
      default:
        return googleMapsUrl;
    }
  }

  /// Share location with emergency contacts
  Future<void> shareLocationWithEmergencyContacts({
    required String emergencyType,
    String? customMessage,
  }) async {
    try {
      if (_currentPosition == null) {
        await getCurrentLocation();
        if (_currentPosition == null) {
          throw Exception('Unable to get current location');
        }
      }

      final position = _currentPosition!;
      final timestamp = DateTime.now();
      final emergencyMessage = customMessage ??
          'EMERGENCY: $emergencyType\n\n'
              'Location: $_currentAddress\n'
              'Time: ${timestamp.toString()}\n'
              'Coordinates: ${position.latitude}, ${position.longitude}\n\n'
              'Sent from AIVONITY Vehicle Assistant';

      final googleMapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      final fullMessage = '$emergencyMessage\n\n$googleMapsUrl';

      // Share with all emergency contacts via SMS
      for (final contact in _emergencyContacts) {
        try {
          await _sendSMS(contact.phoneNumber, fullMessage);
          debugPrint('Emergency SMS sent to ${contact.name}');
        } catch (e) {
          debugPrint('Failed to send SMS to ${contact.name}: $e');
          // Continue with other contacts even if one fails
        }
      }

      // Also share through system share dialog as fallback/additional method
      await Share.share(
        fullMessage,
        subject: 'Emergency Location - AIVONITY',
      );
    } catch (e) {
      _error = 'Failed to share emergency location: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Send SMS to a phone number with location message
  Future<void> _sendSMS(String phoneNumber, String message) async {
    try {
      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(message);
      final smsUrl = 'sms:$phoneNumber?body=$encodedMessage';

      final uri = Uri.parse(smsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try without body parameter
        final fallbackUri = Uri.parse('sms:$phoneNumber');
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Unable to launch SMS app');
        }
      }
    } catch (e) {
      // If SMS fails, try to share via other means
      debugPrint('SMS sending failed, using fallback sharing: $e');
      await Share.share(message, subject: 'Emergency Location');
    }
  }

  /// Add emergency contact
  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
    notifyListeners();
  }

  /// Remove emergency contact
  void removeEmergencyContact(String contactId) {
    _emergencyContacts.removeWhere((contact) => contact.id == contactId);
    notifyListeners();
  }

  /// Get distance between two positions in kilometers
  double getDistanceBetween(Position from, Position to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000; // Convert to kilometers
  }

  /// Check if position is within a radius of current location
  bool isWithinRadius(Position target, double radiusKm) {
    if (_currentPosition == null) return false;

    final distance = getDistanceBetween(_currentPosition!, target);
    return distance <= radiusKm;
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Launch navigation app with destination coordinates
  Future<void> launchNavigationApp({
    required double destinationLatitude,
    required double destinationLongitude,
    NavigationApp app = NavigationApp.googleMaps,
    String? destinationLabel,
  }) async {
    try {
      // Validate coordinates
      if (destinationLatitude < -90 ||
          destinationLatitude > 90 ||
          destinationLongitude < -180 ||
          destinationLongitude > 180) {
        throw Exception('Invalid coordinates provided');
      }

      debugPrint(
        'Launching ${app.displayName} to: $destinationLatitude, $destinationLongitude',
      );

      // First check if the app is installed
      final isInstalled = await isNavigationAppInstalled(app);

      if (!isInstalled) {
        debugPrint('${app.displayName} not installed, trying web fallback');
        // Try to launch with web fallback first
        final fallbackUrl = _buildFallbackNavigationUrl(
          destinationLatitude,
          destinationLongitude,
          destinationLabel,
        );
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          debugPrint('Launched web fallback successfully');
          return;
        }
        throw Exception(
          '${app.displayName} is not installed. Please install it or use a web browser for directions.',
        );
      }

      final url = _buildNavigationUrl(
        destinationLatitude,
        destinationLongitude,
        app,
        destinationLabel,
      );

      debugPrint('Attempting to launch: $url');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('Successfully launched ${app.displayName}');
        } catch (launchError) {
          debugPrint(
            'Direct launch failed for ${app.displayName}: $launchError',
          );
          // If direct launch fails, try fallback
          final fallbackUrl = _buildFallbackNavigationUrl(
            destinationLatitude,
            destinationLongitude,
            destinationLabel,
          );
          final fallbackUri = Uri.parse(fallbackUrl);
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
            debugPrint('Launched web fallback after direct launch failed');
          } else {
            throw Exception(
              'Failed to launch navigation: both app and web fallback failed',
            );
          }
        }
      } else {
        debugPrint(
          'canLaunchUrl returned false for ${app.displayName}, trying fallback',
        );
        // Try fallback URL
        final fallbackUrl = _buildFallbackNavigationUrl(
          destinationLatitude,
          destinationLongitude,
          destinationLabel,
        );
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          debugPrint('Launched web fallback successfully');
        } else {
          throw Exception(
            'Unable to launch navigation app. Please install ${app.displayName} or a compatible navigation app.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching navigation app: $e');
      _error = 'Failed to launch navigation app: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Launch navigation to current location from another location
  Future<void> launchNavigationToCurrentLocation({
    required double originLatitude,
    required double originLongitude,
    NavigationApp app = NavigationApp.googleMaps,
  }) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
      if (_currentPosition == null) {
        throw Exception('Unable to get current location');
      }
    }

    await launchNavigationApp(
      destinationLatitude: _currentPosition!.latitude,
      destinationLongitude: _currentPosition!.longitude,
      app: app,
      destinationLabel: 'Current Location',
    );
  }

  /// Build navigation URL for specific app
  String _buildNavigationUrl(
    double lat,
    double lng,
    NavigationApp app,
    String? label,
  ) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';

    switch (app) {
      case NavigationApp.googleMaps:
        if (Platform.isIOS) {
          return 'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving';
        } else {
          // Use Android intent for better app launching
          return 'intent://maps.google.com/maps?daddr=$lat,$lng&directionsmode=driving#Intent;scheme=https;package=com.google.android.apps.maps;end';
        }

      case NavigationApp.waze:
        if (Platform.isAndroid) {
          // Use Android intent for Waze
          return 'intent://waze.com/ul?ll=$lat,$lng&navigate=yes#Intent;scheme=waze;package=com.waze;end';
        } else {
          return 'waze://?ll=$lat,$lng&navigate=yes';
        }

      case NavigationApp.appleMaps:
        if (Platform.isIOS) {
          return 'http://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
        } else {
          // Fallback to Google Maps on Android
          return 'intent://maps.google.com/maps?daddr=$lat,$lng&directionsmode=driving#Intent;scheme=https;package=com.google.android.apps.maps;end';
        }

      case NavigationApp.hereWeGo:
        if (Platform.isAndroid) {
          // Use Android intent for HERE WeGo
          return 'intent://share.here.com/directions?lat=$lat&lon=$lng&mode=car#Intent;scheme=herewego;package=com.here.app.maps;end';
        } else {
          return 'herewego://directions?lat=$lat&lon=$lng&mode=car';
        }

      case NavigationApp.yandex:
        if (Platform.isAndroid) {
          // Use Android intent for Yandex Maps
          return 'intent://maps.yandex.ru/?pt=$lng,$lat&z=16&l=map#Intent;scheme=yandexmaps;package=ru.yandex.yandexmaps;end';
        } else {
          return 'yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=16&l=map';
        }

      case NavigationApp.mapsMe:
        if (Platform.isAndroid) {
          // Use Android intent for Maps.me
          return 'intent://mapswithme.com/api/v1/navigate?lat=$lat&lon=$lng&type=drive#Intent;scheme=mapswithme;package=com.mapswithme.maps.pro;end';
        } else {
          return 'mapswithme://map?v=1&ll=$lat,$lng&navigate=1';
        }

      case NavigationApp.osmAnd:
        if (Platform.isAndroid) {
          // Use Android intent for OsmAnd
          return 'intent://osmand.navigation/navigate?lat=$lat&lon=$lng&type=drive#Intent;scheme=osmand;package=net.osmand;end';
        } else {
          // OsmAnd is primarily Android, fallback to web
          return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
        }

      case NavigationApp.sygic:
        if (Platform.isAndroid) {
          // Use Android intent for Sygic
          return 'intent://com.sygic.aura://coordinate|$lng|$lat|drive#Intent;scheme=com.sygic.aura;package=com.sygic.aura;end';
        } else {
          return 'sygic://coordinate|$lng|$lat|drive';
        }

      case NavigationApp.tomtom:
        if (Platform.isAndroid) {
          // Use Android intent for TomTom GO
          return 'intent://tomtomgo://x-callback-url/navigate?destination=$lat,$lng#Intent;scheme=tomtomgo;package=com.tomtom.gplay.navapp;end';
        } else {
          return 'tomtomgo://x-callback-url/navigate?destination=$lat,$lng';
        }

      case NavigationApp.coPilot:
        if (Platform.isAndroid) {
          // Use Android intent for CoPilot
          return 'intent://copilot://navigate?to=$lat,$lng#Intent;scheme=copilot;package=com.alk.copilot.mapviewer;end';
        } else {
          return 'copilot://navigate?to=$lat,$lng';
        }

      case NavigationApp.mapQuest:
        if (Platform.isAndroid) {
          // Use Android intent for MapQuest
          return 'intent://mapquest.com/maps?daddr=$lat,$lng#Intent;scheme=https;package=com.mapquest.android.ace;end';
        } else {
          return 'mapquest://navigate?daddr=$lat,$lng';
        }
    }
  }

  /// Build fallback navigation URL
  String _buildFallbackNavigationUrl(double lat, double lng, String? label) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    final destinationParam =
        encodedLabel.isNotEmpty ? '$lat,$lng' : '$lat,$lng';

    // Use the more reliable Google Maps web URL
    return 'https://www.google.com/maps/dir/?api=1&destination=$destinationParam&travelmode=driving';
  }

  /// Check if navigation app is installed
  Future<bool> isNavigationAppInstalled(NavigationApp app) async {
    try {
      // For Android, use package manager approach for better reliability
      if (Platform.isAndroid) {
        return await _isAndroidAppInstalled(app.packageName);
      }

      // For iOS and other platforms, try URL scheme approach
      final testLat = 37.7749; // San Francisco
      final testLng = -122.4194;
      final url = _buildNavigationUrl(testLat, testLng, app, null);

      final uri = Uri.parse(url);
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint('Error checking if ${app.displayName} is installed: $e');
      return false;
    }
  }

  /// Check if Android app is installed using package name
  Future<bool> _isAndroidAppInstalled(String packageName) async {
    try {
      // Use url_launcher to test if the app can be launched
      // This is more reliable than trying to parse intents
      final testUri = Uri.parse('intent://#Intent;package=$packageName;end');
      return await canLaunchUrl(testUri);
    } catch (e) {
      debugPrint('Error checking Android app installation: $e');
      return false;
    }
  }

  /// Get available navigation apps
  Future<List<NavigationApp>> getAvailableNavigationApps() async {
    final apps = <NavigationApp>[];
    for (final app in NavigationApp.values) {
      if (await isNavigationAppInstalled(app)) {
        apps.add(app);
      }
    }
    return apps;
  }

  /// Launch app store for a specific navigation app
  Future<void> launchAppStoreForNavigationApp(NavigationApp app) async {
    try {
      final storeUrl = _getAppStoreUrl(app);
      final uri = Uri.parse(storeUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Unable to launch app store for ${app.displayName}');
      }
    } catch (e) {
      _error = 'Failed to launch app store: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Get app store URL for a navigation app
  String _getAppStoreUrl(NavigationApp app) {
    switch (app) {
      case NavigationApp.googleMaps:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.google.android.apps.maps'
            : 'https://apps.apple.com/app/google-maps/id585027354';

      case NavigationApp.waze:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.waze'
            : 'https://apps.apple.com/app/waze-navigation-live-traffic/id323229106';

      case NavigationApp.appleMaps:
        // Apple Maps is pre-installed on iOS, redirect to App Store for updates
        return 'https://apps.apple.com/app/maps/id915056765';

      case NavigationApp.hereWeGo:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.here.app.maps'
            : 'https://apps.apple.com/app/here-wego-city-navigation/id955837609';

      case NavigationApp.yandex:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=ru.yandex.yandexmaps'
            : 'https://apps.apple.com/app/yandex-maps/id313877526';

      case NavigationApp.mapsMe:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.mapswithme.maps.pro'
            : 'https://apps.apple.com/app/maps-me-offline-map-navigation/id510623322';

      case NavigationApp.osmAnd:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=net.osmand'
            : 'https://apps.apple.com/app/osmand-maps-travel-navigation/id934850257';

      case NavigationApp.sygic:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.sygic.aura'
            : 'https://apps.apple.com/app/sygic-gps-navigation-offline/id585193266';

      case NavigationApp.tomtom:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.tomtom.gplay.navapp'
            : 'https://apps.apple.com/app/tomtom-go-mobile/id561119520';

      case NavigationApp.coPilot:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.alk.copilot.mapviewer'
            : 'https://apps.apple.com/app/copilot-gps-navigation/id373048198';

      case NavigationApp.mapQuest:
        return Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.mapquest.android.ace'
            : 'https://apps.apple.com/app/mapquest-gps-navigation-maps/id316126557';
    }
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}

/// Location history entry
class LocationHistoryEntry {
  final DateTime timestamp;
  final Position position;
  final String address;

  LocationHistoryEntry({
    required this.timestamp,
    required this.position,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'address': address,
      };

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LocationHistoryEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      position: Position(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ),
      address: json['address'] as String? ?? 'Unknown location',
    );
  }
}

/// Emergency contact for location sharing
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final bool isActive;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'isActive': isActive,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

enum NavigationApp {
  googleMaps('Google Maps', 'google_maps_icon'),
  waze('Waze', 'waze_icon'),
  appleMaps('Apple Maps', 'apple_maps_icon'),
  hereWeGo('HERE WeGo', 'here_wego_icon'),
  yandex('Yandex Maps', 'yandex_icon'),
  mapsMe('Maps.me', 'maps_me_icon'),
  osmAnd('OsmAnd', 'osmand_icon'),
  sygic('Sygic', 'sygic_icon'),
  tomtom('TomTom GO', 'tomtom_icon'),
  coPilot('CoPilot', 'copilot_icon'),
  mapQuest('MapQuest', 'mapquest_icon');

  const NavigationApp(this.displayName, this.iconName);

  final String displayName;
  final String iconName;

  bool get isAvailableOnPlatform {
    switch (this) {
      case NavigationApp.appleMaps:
        return Platform.isIOS;
      case NavigationApp.yandex:
      case NavigationApp.mapsMe:
      case NavigationApp.osmAnd:
      case NavigationApp.sygic:
      case NavigationApp.tomtom:
      case NavigationApp.coPilot:
      case NavigationApp.mapQuest:
        return Platform.isAndroid; // These are more popular on Android
      default:
        return true;
    }
  }

  String get packageName {
    switch (this) {
      case NavigationApp.googleMaps:
        return 'com.google.android.apps.maps';
      case NavigationApp.waze:
        return 'com.waze';
      case NavigationApp.hereWeGo:
        return 'com.here.app.maps';
      case NavigationApp.yandex:
        return 'ru.yandex.yandexmaps';
      case NavigationApp.mapsMe:
        return 'com.mapswithme.maps.pro';
      case NavigationApp.osmAnd:
        return 'net.osmand';
      case NavigationApp.sygic:
        return 'com.sygic.aura';
      case NavigationApp.tomtom:
        return 'com.tomtom.gplay.navapp';
      case NavigationApp.coPilot:
        return 'com.alk.copilot.mapviewer';
      case NavigationApp.mapQuest:
        return 'com.mapquest.android.ace';
      case NavigationApp.appleMaps:
        return ''; // iOS doesn't use package names
    }
  }
}

/// Location sharing platforms
enum LocationSharePlatform {
  whatsapp('WhatsApp'),
  telegram('Telegram'),
  email('Email'),
  sms('SMS'),
  facebook('Facebook'),
  twitter('Twitter'),
  instagram('Instagram');

  const LocationSharePlatform(this.displayName);
  final String displayName;
}

/// Provider for enhanced location service
final enhancedLocationServiceProvider =
    Provider<EnhancedLocationService>((ref) {
  return EnhancedLocationService();
});
