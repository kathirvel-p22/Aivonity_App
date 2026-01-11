import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Remote Monitoring Service for AIVONITY
/// Handles vehicle location tracking, geofencing, remote diagnostics, and theft detection
class RemoteMonitoringService {
  static const String _baseUrl = 'http://localhost:8000/api';
  static const String _geofenceKey = 'geofences';
  static const String _lastLocationKey = 'last_known_location';

  final StreamController<LocationUpdate> _locationController =
      StreamController<LocationUpdate>.broadcast();
  final StreamController<GeofenceAlert> _geofenceController =
      StreamController<GeofenceAlert>.broadcast();
  final StreamController<SecurityAlert> _securityController =
      StreamController<SecurityAlert>.broadcast();
  final StreamController<DiagnosticResult> _diagnosticController =
      StreamController<DiagnosticResult>.broadcast();

  Timer? _locationTimer;
  Timer? _diagnosticTimer;
  Timer? _securityTimer;

  List<Geofence> _geofences = [];
  Position? _lastKnownPosition;
  bool _isMonitoring = false;
  String? _vehicleId;

  // Streams for real-time updates
  Stream<LocationUpdate> get locationStream => _locationController.stream;
  Stream<GeofenceAlert> get geofenceStream => _geofenceController.stream;
  Stream<SecurityAlert> get securityStream => _securityController.stream;
  Stream<DiagnosticResult> get diagnosticStream => _diagnosticController.stream;

  /// Initialize remote monitoring for a vehicle
  Future<void> initialize(String vehicleId) async {
    _vehicleId = vehicleId;
    await _loadGeofences();
    await _loadLastKnownLocation();
    debugPrint('🔍 Remote monitoring initialized for vehicle: $vehicleId');
  }

  /// Start remote monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Start location tracking (every 30 seconds)
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _trackLocation(),
    );

    // Start remote diagnostics (every 5 minutes)
    _diagnosticTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performRemoteDiagnostics(),
    );

    // Start security monitoring (every 2 minutes)
    _securityTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkSecurityStatus(),
    );

    print('🚀 Remote monitoring started');
  }

  /// Stop remote monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _locationTimer?.cancel();
    _diagnosticTimer?.cancel();
    _securityTimer?.cancel();
    print('⏹️ Remote monitoring stopped');
  }

  /// Track vehicle location and check geofences
  Future<void> _trackLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create location update
      LocationUpdate update = LocationUpdate(
        vehicleId: _vehicleId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
      );

      // Check for movement if we have a previous position
      if (_lastKnownPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        update.distanceMoved = distance;

        // Check for unexpected movement (potential theft)
        if (distance > 100 && position.speed > 5) {
          // Moved more than 100m at speed > 5 m/s
          await _checkForTheft(update);
        }
      }

      _lastKnownPosition = position;
      await _saveLastKnownLocation(position);

      // Check geofences
      await _checkGeofences(update);

      // Send to backend
      await _sendLocationUpdate(update);

      // Emit to stream
      _locationController.add(update);
    } catch (e) {
      print('❌ Error tracking location: $e');
    }
  }

  /// Perform remote diagnostics
  Future<void> _performRemoteDiagnostics() async {
    try {
      if (_vehicleId == null) return;

      // Simulate diagnostic checks (in real implementation, this would connect to vehicle's OBD-II port)
      DiagnosticResult result = DiagnosticResult(
        vehicleId: _vehicleId!,
        timestamp: DateTime.now(),
        batteryVoltage:
            12.6 + (Random().nextDouble() - 0.5) * 0.4, // 12.4 - 12.8V
        engineTemperature: 90 + Random().nextInt(20), // 90-110°C
        oilPressure: 30 + Random().nextInt(20), // 30-50 PSI
        fuelLevel: 25 + Random().nextInt(50), // 25-75%
        diagnosticCodes: _generateDiagnosticCodes(),
        overallHealth: _calculateOverallHealth(),
      );

      // Check for critical issues
      await _checkCriticalIssues(result);

      // Send to backend
      await _sendDiagnosticResult(result);

      // Emit to stream
      _diagnosticController.add(result);
    } catch (e) {
      print('❌ Error performing remote diagnostics: $e');
    }
  }

  /// Check security status for theft detection
  Future<void> _checkSecurityStatus() async {
    try {
      if (_vehicleId == null || _lastKnownPosition == null) return;

      // Check for security anomalies
      SecurityStatus status = SecurityStatus(
        vehicleId: _vehicleId!,
        timestamp: DateTime.now(),
        isLocked: Random()
            .nextBool(), // In real implementation, get from vehicle
        alarmStatus: Random().nextBool() ? 'armed' : 'disarmed',
        windowsStatus: _generateWindowsStatus(),
        doorStatus: _generateDoorStatus(),
        ignitionStatus: Random().nextBool() ? 'on' : 'off',
      );

      // Detect potential theft scenarios
      List<String> threats = [];

      if (status.ignitionStatus == 'on' && status.alarmStatus == 'armed') {
        threats.add('Ignition turned on while alarm is armed');
      }

      if (!status.isLocked && status.alarmStatus == 'disarmed') {
        threats.add('Vehicle unlocked without proper authorization');
      }

      if (threats.isNotEmpty) {
        SecurityAlert alert = SecurityAlert(
          vehicleId: _vehicleId!,
          alertType: 'theft_attempt',
          severity: 'high',
          message: 'Potential theft detected: ${threats.join(', ')}',
          location: VehicleLocation(
            latitude: _lastKnownPosition!.latitude,
            longitude: _lastKnownPosition!.longitude,
          ),
          timestamp: DateTime.now(),
          threats: threats,
        );

        await _sendSecurityAlert(alert);
        _securityController.add(alert);
      }
    } catch (e) {
      print('❌ Error checking security status: $e');
    }
  }

  /// Check geofences for violations
  Future<void> _checkGeofences(LocationUpdate update) async {
    for (Geofence geofence in _geofences) {
      double distance = Geolocator.distanceBetween(
        update.latitude,
        update.longitude,
        geofence.centerLatitude,
        geofence.centerLongitude,
      );

      bool isInside = distance <= geofence.radius;
      bool wasInside = geofence.isVehicleInside;

      if (isInside != wasInside) {
        // Geofence violation detected
        GeofenceAlert alert = GeofenceAlert(
          vehicleId: _vehicleId!,
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          alertType: isInside ? 'entered' : 'exited',
          location: VehicleLocation(
            latitude: update.latitude,
            longitude: update.longitude,
          ),
          timestamp: DateTime.now(),
        );

        geofence.isVehicleInside = isInside;
        await _saveGeofences();

        await _sendGeofenceAlert(alert);
        _geofenceController.add(alert);
      }
    }
  }

  /// Check for potential theft based on movement patterns
  Future<void> _checkForTheft(LocationUpdate update) async {
    // Implement theft detection logic
    List<String> suspiciousActivities = [];

    // Check for rapid movement without ignition (towing)
    if (update.speed != null &&
        update.speed! > 10 &&
        update.distanceMoved! > 500) {
      suspiciousActivities.add('Vehicle moving at high speed without ignition');
    }

    // Check for movement during unusual hours (2 AM - 5 AM)
    int hour = DateTime.now().hour;
    if ((hour >= 2 && hour <= 5) && update.distanceMoved! > 100) {
      suspiciousActivities.add('Vehicle movement during unusual hours');
    }

    if (suspiciousActivities.isNotEmpty) {
      SecurityAlert alert = SecurityAlert(
        vehicleId: _vehicleId!,
        alertType: 'theft_detection',
        severity: 'critical',
        message: 'Potential theft detected based on movement patterns',
        location: VehicleLocation(
          latitude: update.latitude,
          longitude: update.longitude,
        ),
        timestamp: DateTime.now(),
        threats: suspiciousActivities,
      );

      await _sendSecurityAlert(alert);
      _securityController.add(alert);
    }
  }

  /// Add a new geofence
  Future<void> addGeofence(Geofence geofence) async {
    _geofences.add(geofence);
    await _saveGeofences();
    print('📍 Geofence added: ${geofence.name}');
  }

  /// Remove a geofence
  Future<void> removeGeofence(String geofenceId) async {
    _geofences.removeWhere((g) => g.id == geofenceId);
    await _saveGeofences();
    print('🗑️ Geofence removed: $geofenceId');
  }

  /// Get current vehicle location
  Future<VehicleLocation?> getCurrentLocation() async {
    if (_lastKnownPosition == null) return null;

    return VehicleLocation(
      latitude: _lastKnownPosition!.latitude,
      longitude: _lastKnownPosition!.longitude,
    );
  }

  /// Get all geofences
  List<Geofence> getGeofences() => List.from(_geofences);

  // Helper methods for generating mock data (replace with real vehicle data in production)
  List<String> _generateDiagnosticCodes() {
    List<String> possibleCodes = ['P0171', 'P0300', 'P0420', 'P0128'];
    if (Random().nextDouble() < 0.2) {
      // 20% chance of having codes
      return [possibleCodes[Random().nextInt(possibleCodes.length)]];
    }
    return [];
  }

  double _calculateOverallHealth() {
    return 75 + Random().nextInt(20).toDouble(); // 75-95% health
  }

  Map<String, bool> _generateWindowsStatus() {
    return {
      'front_left': Random().nextBool(),
      'front_right': Random().nextBool(),
      'rear_left': Random().nextBool(),
      'rear_right': Random().nextBool(),
    };
  }

  Map<String, bool> _generateDoorStatus() {
    return {
      'driver': Random().nextBool(),
      'passenger': Random().nextBool(),
      'rear_left': Random().nextBool(),
      'rear_right': Random().nextBool(),
      'trunk': Random().nextBool(),
    };
  }

  Future<void> _checkCriticalIssues(DiagnosticResult result) async {
    List<String> criticalIssues = [];

    if (result.batteryVoltage < 12.0) {
      criticalIssues.add('Low battery voltage: ${result.batteryVoltage}V');
    }

    if (result.engineTemperature > 105) {
      criticalIssues.add('Engine overheating: ${result.engineTemperature}°C');
    }

    if (result.oilPressure < 20) {
      criticalIssues.add('Low oil pressure: ${result.oilPressure} PSI');
    }

    if (result.diagnosticCodes.isNotEmpty) {
      criticalIssues.add(
        'Diagnostic codes detected: ${result.diagnosticCodes.join(', ')}',
      );
    }

    if (criticalIssues.isNotEmpty) {
      SecurityAlert alert = SecurityAlert(
        vehicleId: _vehicleId!,
        alertType: 'critical_diagnostic',
        severity: 'high',
        message: 'Critical vehicle issues detected',
        location: await getCurrentLocation(),
        timestamp: DateTime.now(),
        threats: criticalIssues,
      );

      await _sendSecurityAlert(alert);
      _securityController.add(alert);
    }
  }

  // Backend communication methods
  Future<void> _sendLocationUpdate(LocationUpdate update) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/vehicles/$_vehicleId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(update.toJson()),
      );
    } catch (e) {
      print('❌ Error sending location update: $e');
    }
  }

  Future<void> _sendDiagnosticResult(DiagnosticResult result) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/vehicles/$_vehicleId/diagnostics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(result.toJson()),
      );
    } catch (e) {
      print('❌ Error sending diagnostic result: $e');
    }
  }

  Future<void> _sendSecurityAlert(SecurityAlert alert) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/vehicles/$_vehicleId/security-alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alert.toJson()),
      );
    } catch (e) {
      print('❌ Error sending security alert: $e');
    }
  }

  Future<void> _sendGeofenceAlert(GeofenceAlert alert) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/vehicles/$_vehicleId/geofence-alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alert.toJson()),
      );
    } catch (e) {
      print('❌ Error sending geofence alert: $e');
    }
  }

  // Local storage methods
  Future<void> _loadGeofences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? geofencesJson = prefs.getString(_geofenceKey);
      if (geofencesJson != null) {
        List<dynamic> geofencesList = jsonDecode(geofencesJson);
        _geofences = geofencesList
            .map((json) => Geofence.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('❌ Error loading geofences: $e');
    }
  }

  Future<void> _saveGeofences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String geofencesJson = jsonEncode(
        _geofences.map((g) => g.toJson()).toList(),
      );
      await prefs.setString(_geofenceKey, geofencesJson);
    } catch (e) {
      print('❌ Error saving geofences: $e');
    }
  }

  Future<void> _loadLastKnownLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? locationJson = prefs.getString(_lastLocationKey);
      if (locationJson != null) {
        Map<String, dynamic> locationData = jsonDecode(locationJson);
        _lastKnownPosition = Position(
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
          timestamp: DateTime.parse(locationData['timestamp']),
          accuracy: locationData['accuracy'],
          altitude: locationData['altitude'] ?? 0.0,
          altitudeAccuracy: locationData['altitudeAccuracy'] ?? 0.0,
          heading: locationData['heading'] ?? 0.0,
          headingAccuracy: locationData['headingAccuracy'] ?? 0.0,
          speed: locationData['speed'] ?? 0.0,
          speedAccuracy: locationData['speedAccuracy'] ?? 0.0,
        );
      }
    } catch (e) {
      print('❌ Error loading last known location: $e');
    }
  }

  Future<void> _saveLastKnownLocation(Position position) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
      };
      await prefs.setString(_lastLocationKey, jsonEncode(locationData));
    } catch (e) {
      print('❌ Error saving last known location: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _locationController.close();
    _geofenceController.close();
    _securityController.close();
    _diagnosticController.close();
  }
}

// Data models for remote monitoring
class LocationUpdate {
  final String vehicleId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  double? distanceMoved;

  LocationUpdate({
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
    this.distanceMoved,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'distanceMoved': distanceMoved,
  };
}

class Geofence {
  final String id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radius;
  final String type; // 'home', 'work', 'service', 'restricted'
  bool isVehicleInside;

  Geofence({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radius,
    required this.type,
    this.isVehicleInside = false,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    id: json['id'],
    name: json['name'],
    centerLatitude: json['centerLatitude'],
    centerLongitude: json['centerLongitude'],
    radius: json['radius'],
    type: json['type'],
    isVehicleInside: json['isVehicleInside'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'centerLatitude': centerLatitude,
    'centerLongitude': centerLongitude,
    'radius': radius,
    'type': type,
    'isVehicleInside': isVehicleInside,
  };
}

class GeofenceAlert {
  final String vehicleId;
  final String geofenceId;
  final String geofenceName;
  final String alertType; // 'entered', 'exited'
  final VehicleLocation location;
  final DateTime timestamp;

  GeofenceAlert({
    required this.vehicleId,
    required this.geofenceId,
    required this.geofenceName,
    required this.alertType,
    required this.location,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'geofenceId': geofenceId,
    'geofenceName': geofenceName,
    'alertType': alertType,
    'location': location.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class SecurityAlert {
  final String vehicleId;
  final String alertType;
  final String severity;
  final String message;
  final VehicleLocation? location;
  final DateTime timestamp;
  final List<String> threats;

  SecurityAlert({
    required this.vehicleId,
    required this.alertType,
    required this.severity,
    required this.message,
    this.location,
    required this.timestamp,
    required this.threats,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'alertType': alertType,
    'severity': severity,
    'message': message,
    'location': location?.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'threats': threats,
  };
}

class DiagnosticResult {
  final String vehicleId;
  final DateTime timestamp;
  final double batteryVoltage;
  final int engineTemperature;
  final int oilPressure;
  final int fuelLevel;
  final List<String> diagnosticCodes;
  final double overallHealth;

  DiagnosticResult({
    required this.vehicleId,
    required this.timestamp,
    required this.batteryVoltage,
    required this.engineTemperature,
    required this.oilPressure,
    required this.fuelLevel,
    required this.diagnosticCodes,
    required this.overallHealth,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'timestamp': timestamp.toIso8601String(),
    'batteryVoltage': batteryVoltage,
    'engineTemperature': engineTemperature,
    'oilPressure': oilPressure,
    'fuelLevel': fuelLevel,
    'diagnosticCodes': diagnosticCodes,
    'overallHealth': overallHealth,
  };
}

class SecurityStatus {
  final String vehicleId;
  final DateTime timestamp;
  final bool isLocked;
  final String alarmStatus;
  final Map<String, bool> windowsStatus;
  final Map<String, bool> doorStatus;
  final String ignitionStatus;

  SecurityStatus({
    required this.vehicleId,
    required this.timestamp,
    required this.isLocked,
    required this.alarmStatus,
    required this.windowsStatus,
    required this.doorStatus,
    required this.ignitionStatus,
  });
}

class VehicleLocation {
  final double latitude;
  final double longitude;

  VehicleLocation({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}
