// Unit tests for Vehicle model

import 'package:flutter_test/flutter_test.dart';
import '../../../test/fixtures/test_data.dart';

// Mock Vehicle model for testing
class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String vin;
  final int mileage;
  final String fuelType;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.mileage,
    required this.fuelType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      vin: json['vin'] ?? '',
      mileage: json['mileage'] ?? 0,
      fuelType: json['fuel_type'] ?? 'gasoline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'mileage': mileage,
      'fuel_type': fuelType,
    };
  }

  bool isValid() {
    return make.isNotEmpty &&
        model.isNotEmpty &&
        year > 1900 &&
        year <= DateTime.now().year + 1 &&
        vin.length >= 10 &&
        mileage >= 0;
  }

  String get displayName => '$year $make $model';

  bool get isElectric => fuelType.toLowerCase() == 'electric';
  bool get isHybrid => fuelType.toLowerCase() == 'hybrid';
  bool get isGasoline => fuelType.toLowerCase() == 'gasoline';
}

void main() {
  group('Vehicle Model Tests', () {
    test('should create vehicle from valid JSON', () {
      // Arrange
      final json = Map<String, dynamic>.from(TestData.validVehicle);
      json['id'] = 'vehicle_123';

      // Act
      final vehicle = Vehicle.fromJson(json);

      // Assert
      expect(vehicle.id, equals('vehicle_123'));
      expect(vehicle.make, equals('Tesla'));
      expect(vehicle.model, equals('Model 3'));
      expect(vehicle.year, equals(2023));
      expect(vehicle.vin, equals('TEST123456789'));
      expect(vehicle.mileage, equals(15000));
      expect(vehicle.fuelType, equals('electric'));
    });

    test('should convert vehicle to JSON', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act
      final json = vehicle.toJson();

      // Assert
      expect(json['id'], equals('vehicle_123'));
      expect(json['make'], equals('Tesla'));
      expect(json['model'], equals('Model 3'));
      expect(json['year'], equals(2023));
      expect(json['vin'], equals('TEST123456789'));
      expect(json['mileage'], equals(15000));
      expect(json['fuel_type'], equals('electric'));
    });

    test('should validate valid vehicle data', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.isValid(), isTrue);
    });

    test('should invalidate vehicle with empty make', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: '',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.isValid(), isFalse);
    });

    test('should invalidate vehicle with invalid year', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 1800,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.isValid(), isFalse);
    });

    test('should invalidate vehicle with short VIN', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: '123',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.isValid(), isFalse);
    });

    test('should invalidate vehicle with negative mileage', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: -1000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.isValid(), isFalse);
    });

    test('should generate correct display name', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.displayName, equals('2023 Tesla Model 3'));
    });

    test('should correctly identify electric vehicle', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'electric',
      );

      // Act & Assert
      expect(vehicle.isElectric, isTrue);
      expect(vehicle.isHybrid, isFalse);
      expect(vehicle.isGasoline, isFalse);
    });

    test('should correctly identify hybrid vehicle', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Toyota',
        model: 'Prius',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'hybrid',
      );

      // Act & Assert
      expect(vehicle.isElectric, isFalse);
      expect(vehicle.isHybrid, isTrue);
      expect(vehicle.isGasoline, isFalse);
    });

    test('should correctly identify gasoline vehicle', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Honda',
        model: 'Civic',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'gasoline',
      );

      // Act & Assert
      expect(vehicle.isElectric, isFalse);
      expect(vehicle.isHybrid, isFalse);
      expect(vehicle.isGasoline, isTrue);
    });

    test('should handle case insensitive fuel type', () {
      // Arrange
      final vehicle = Vehicle(
        id: 'vehicle_123',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: 'TEST123456789',
        mileage: 15000,
        fuelType: 'ELECTRIC',
      );

      // Act & Assert
      expect(vehicle.isElectric, isTrue);
    });
  });
}

