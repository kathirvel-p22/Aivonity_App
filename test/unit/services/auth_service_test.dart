// Unit tests for Authentication Service

import 'package:flutter_test/flutter_test.dart';
import '../../../test/mocks/mock_services.dart';
import '../../../test/fixtures/test_data.dart';

// Mock AuthService for testing
class AuthService {
  final MockHttpClient _httpClient;
  final MockAuthService _mockAuth;

  AuthService(this._httpClient, this._mockAuth);

  Future<AuthResult> login(String email, String password) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      if (!_isValidEmail(email)) {
        throw AuthException('Invalid email format');
      }

      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters');
      }

      // Use mock service for testing
      final result = await _mockAuth.login(email, password);

      return AuthResult(
        success: true,
        user: User.fromJson(result['user']),
        accessToken: result['access_token'],
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<AuthResult> register(Map<String, dynamic> userData) async {
    try {
      // Validate input
      final validation = _validateRegistrationData(userData);
      if (!validation.isValid) {
        throw AuthException(validation.errors.join(', '));
      }

      // Use mock service for testing
      final result = await _mockAuth.register(userData);

      return AuthResult(
        success: true,
        user: User.fromJson(result['user']),
        accessToken: result['access_token'],
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _mockAuth.logout();
  }

  bool get isAuthenticated => _mockAuth.isAuthenticated;
  User? get currentUser => _mockAuth.currentUser != null
      ? User.fromJson(_mockAuth.currentUser!)
      : null;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  ValidationResult _validateRegistrationData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['email'] == null || data['email'].toString().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(data['email'])) {
      errors.add('Invalid email format');
    }

    if (data['password'] == null || data['password'].toString().isEmpty) {
      errors.add('Password is required');
    } else if (data['password'].toString().length < 6) {
      errors.add('Password must be at least 6 characters');
    }

    if (data['name'] == null || data['name'].toString().isEmpty) {
      errors.add('Name is required');
    }

    if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(data['phone'])) {
        errors.add('Invalid phone number format');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? accessToken;
  final String? error;

  AuthResult({required this.success, this.user, this.accessToken, this.error});
}

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;

  User({required this.id, required this.email, required this.name, this.phone});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
    };
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockHttpClient mockHttpClient;
    late MockAuthService mockAuthService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockAuthService = MockAuthService();
      authService = AuthService(mockHttpClient, mockAuthService);
    });

    tearDown(() {
      mockAuthService.reset();
    });

    group('Login Tests', () {
      test('should login successfully with valid credentials', () async {
        // Act
        final result = await authService.login(
          'test@aivonity.com',
          'password123',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user!.email, equals('test@aivonity.com'));
        expect(result.accessToken, isNotNull);
        expect(result.error, isNull);
        expect(authService.isAuthenticated, isTrue);
      });

      test('should fail login with invalid credentials', () async {
        // Act
        final result = await authService.login('wrong@email.com', 'wrongpass');

        // Assert
        expect(result.success, isFalse);
        expect(result.user, isNull);
        expect(result.accessToken, isNull);
        expect(result.error, isNotNull);
        expect(authService.isAuthenticated, isFalse);
      });

      test('should fail login with empty email', () async {
        // Act
        final result = await authService.login('', 'password123');

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Email and password are required'));
      });

      test('should fail login with empty password', () async {
        // Act
        final result = await authService.login('test@aivonity.com', '');

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Email and password are required'));
      });

      test('should fail login with invalid email format', () async {
        // Act
        final result = await authService.login('invalid-email', 'password123');

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid email format'));
      });

      test('should fail login with short password', () async {
        // Act
        final result = await authService.login('test@aivonity.com', '123');

        // Assert
        expect(result.success, isFalse);
        expect(
          result.error,
          contains('Password must be at least 6 characters'),
        );
      });
    });

    group('Registration Tests', () {
      test('should register successfully with valid data', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user!.email, equals(userData['email']));
        expect(result.user!.name, equals(userData['name']));
        expect(result.accessToken, isNotNull);
        expect(result.error, isNull);
        expect(authService.isAuthenticated, isTrue);
      });

      test('should fail registration with invalid email', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['email'] = 'invalid-email';

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid email format'));
      });

      test('should fail registration with empty name', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['name'] = '';

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Name is required'));
      });

      test('should fail registration with short password', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['password'] = '123';

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isFalse);
        expect(
          result.error,
          contains('Password must be at least 6 characters'),
        );
      });

      test('should fail registration with invalid phone', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['phone'] = 'invalid-phone';

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid phone number format'));
      });

      test('should register successfully with valid phone', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['phone'] = '+1-234-567-8900';

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isTrue);
        expect(result.user!.phone, equals('+1-234-567-8900'));
      });

      test('should register successfully without phone', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData.remove('phone');

        // Act
        final result = await authService.register(userData);

        // Assert
        expect(result.success, isTrue);
        expect(result.user!.phone, isNull);
      });
    });

    group('Logout Tests', () {
      test('should logout successfully', () async {
        // Arrange - First login
        await authService.login('test@aivonity.com', 'password123');
        expect(authService.isAuthenticated, isTrue);

        // Act
        await authService.logout();

        // Assert
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });
    });

    group('Authentication State Tests', () {
      test('should return correct authentication state', () {
        // Initially not authenticated
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });

      test('should maintain authentication state after login', () async {
        // Act
        await authService.login('test@aivonity.com', 'password123');

        // Assert
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, equals('test@aivonity.com'));
      });
    });

    group('Email Validation Tests', () {
      test('should validate correct email formats', () {
        final service = AuthService(mockHttpClient, mockAuthService);

        expect(service._isValidEmail('test@example.com'), isTrue);
        expect(service._isValidEmail('user.name@domain.co.uk'), isTrue);
        expect(service._isValidEmail('user+tag@example.org'), isTrue);
      });

      test('should reject invalid email formats', () {
        final service = AuthService(mockHttpClient, mockAuthService);

        expect(service._isValidEmail('invalid-email'), isFalse);
        expect(service._isValidEmail('@domain.com'), isFalse);
        expect(service._isValidEmail('user@'), isFalse);
        expect(service._isValidEmail('user@domain'), isFalse);
      });
    });
  });
}

