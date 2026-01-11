import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

// Import the service to test
// ignore: avoid_relative_lib_imports
import '../../../mobile/lib/core/services/enhanced_location_service.dart';

void main() {
  group('EnhancedLocationService', () {
    late EnhancedLocationService locationService;

    setUp(() {
      // Initialize the service
      locationService = EnhancedLocationService();
    });

    tearDown(() {
      // Clean up
      locationService.dispose();
    });

    test('should initialize with default values', () {
      // Assert
      expect(locationService.currentPosition, isNull);
      expect(locationService.currentAddress, 'Unknown location');
      expect(locationService.isLoading, false);
      expect(locationService.isServiceEnabled, false);
      expect(locationService.hasPermission, false);
      expect(locationService.error, isNull);
      expect(locationService.locationHistory, isEmpty);
      expect(locationService.emergencyContacts, isEmpty);
    });

    test('should manage emergency contacts', () {
      // Arrange
      final emergencyContact = EmergencyContact(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        email: 'john.doe@example.com',
      );

      // Act
      locationService.addEmergencyContact(emergencyContact);

      // Assert
      expect(locationService.emergencyContacts.length, 1);
      expect(locationService.emergencyContacts.first.name, 'John Doe');
    });

    test('should remove emergency contacts', () {
      // Arrange
      final emergencyContact = EmergencyContact(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        email: 'john.doe@example.com',
      );
      locationService.addEmergencyContact(emergencyContact);
      expect(locationService.emergencyContacts.length, 1);

      // Act
      locationService.removeEmergencyContact('1');

      // Assert
      expect(locationService.emergencyContacts.length, 0);
    });

    test('should calculate distance between positions', () {
      // Arrange
      final position1 = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 180.0,
        headingAccuracy: 15.0,
        speed: 2.0,
        speedAccuracy: 1.0,
      );

      final position2 = Position(
        latitude: 37.7849,
        longitude: -122.4094,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 180.0,
        headingAccuracy: 15.0,
        speed: 2.0,
        speedAccuracy: 1.0,
      );

      // Act
      final distance = locationService.getDistanceBetween(position1, position2);

      // Assert
      expect(distance, greaterThan(0));
      expect(distance, lessThan(2)); // Should be approximately 1.4 km
    });

    test('should check if position is within radius', () {
      // Arrange
      final position1 = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 180.0,
        headingAccuracy: 15.0,
        speed: 2.0,
        speedAccuracy: 1.0,
      );

      final position2 = Position(
        latitude: 37.7799,
        longitude: -122.4144,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 180.0,
        headingAccuracy: 15.0,
        speed: 2.0,
        speedAccuracy: 1.0,
      );

      // Act
      final isWithinRadius =
          locationService.getDistanceBetween(position1, position2) <=
          1000; // 1 km

      // Assert
      expect(isWithinRadius, true);
    });

    test('should have emergency contacts functionality', () {
      // This test verifies that emergency contact methods exist
      // Since we can't test actual functionality without mocking,
      // we just verify the methods are available
      expect(locationService.emergencyContacts, isNotNull);
      expect(locationService.emergencyContacts, isEmpty);
    });

    test('should have location history functionality', () {
      // This test verifies that location history methods exist
      // Since we can't test actual functionality without mocking,
      // we just verify the properties are available
      expect(locationService.locationHistory, isNotNull);
      expect(locationService.locationHistory, isEmpty);
    });
  });

  group('NavigationApp', () {
    test('should provide correct display names', () {
      // Assert
      expect(NavigationApp.googleMaps.displayName, 'Google Maps');
      expect(NavigationApp.waze.displayName, 'Waze');
      expect(NavigationApp.appleMaps.displayName, 'Apple Maps');
    });

    test('should provide correct package names', () {
      // Assert
      expect(
        NavigationApp.googleMaps.packageName,
        'com.google.android.apps.maps',
      );
      expect(NavigationApp.waze.packageName, 'com.waze');
    });

    test('should provide correct availability information', () {
      // These tests depend on the platform, so they may vary
      // Just verify the method doesn't throw exceptions
      expect(
        () => NavigationApp.googleMaps.isAvailableOnPlatform,
        returnsNormally,
      );
    });
  });

  group('LocationSharePlatform', () {
    test('should provide correct display names', () {
      // Assert
      expect(LocationSharePlatform.whatsapp.displayName, 'WhatsApp');
      expect(LocationSharePlatform.telegram.displayName, 'Telegram');
      expect(LocationSharePlatform.email.displayName, 'Email');
    });
  });

  group('LocationHistoryEntry', () {
    test('should create location history entry', () {
      // Arrange
      final position = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 180.0,
        headingAccuracy: 15.0,
        speed: 2.0,
        speedAccuracy: 1.0,
      );

      // Act
      final entry = LocationHistoryEntry(
        timestamp: DateTime.now(),
        position: position,
        address: 'Test Address',
      );

      // Assert
      expect(entry.position, isNotNull);
      expect(entry.address, 'Test Address');
    });

    test('should serialize and deserialize location history entry', () {
      // Arrange
      final position = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 180.0,
        headingAccuracy: 15.0,
        speed: 2.0,
        speedAccuracy: 1.0,
      );

      final originalEntry = LocationHistoryEntry(
        timestamp: DateTime.now(),
        position: position,
        address: 'Test Address',
      );

      // Act
      final json = originalEntry.toJson();
      final restoredEntry = LocationHistoryEntry.fromJson(json);

      // Assert
      expect(restoredEntry.address, originalEntry.address);
      expect(restoredEntry.position.latitude, originalEntry.position.latitude);
      expect(
        restoredEntry.position.longitude,
        originalEntry.position.longitude,
      );
    });
  });

  group('EmergencyContact', () {
    test('should create emergency contact', () {
      // Act
      final contact = EmergencyContact(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        email: 'john.doe@example.com',
      );

      // Assert
      expect(contact.id, '1');
      expect(contact.name, 'John Doe');
      expect(contact.phoneNumber, '+1234567890');
      expect(contact.email, 'john.doe@example.com');
      expect(contact.isActive, true);
    });

    test('should serialize and deserialize emergency contact', () {
      // Arrange
      final originalContact = EmergencyContact(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        email: 'john.doe@example.com',
        isActive: false,
      );

      // Act
      final json = originalContact.toJson();
      final restoredContact = EmergencyContact.fromJson(json);

      // Assert
      expect(restoredContact.id, originalContact.id);
      expect(restoredContact.name, originalContact.name);
      expect(restoredContact.phoneNumber, originalContact.phoneNumber);
      expect(restoredContact.email, originalContact.email);
      expect(restoredContact.isActive, originalContact.isActive);
    });
  });
}
