// Integration tests for Authentication API endpoints

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../../../test/mocks/mock_services.dart';
import '../../../test/fixtures/test_data.dart';

class AuthApiClient {
  final MockHttpClient _httpClient;
  final String baseUrl;

  AuthApiClient(this._httpClient, {this.baseUrl = 'http://localhost:8000'});

  Future<Response> register(Map<String, dynamic> userData) async {
    return await _httpClient.post(
      '$baseUrl${TestData.apiEndpoints['auth_register']}',
      data: userData,
    );
  }

  Future<Response> login(String email, String password) async {
    return await _httpClient.post(
      '$baseUrl${TestData.apiEndpoints['auth_login']}',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> getProfile(String accessToken) async {
    return await _httpClient.get(
      '$baseUrl${TestData.apiEndpoints['auth_profile']}',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response> refreshToken(String refreshToken) async {
    return await _httpClient.post(
      '$baseUrl/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
  }

  Future<Response> logout(String accessToken) async {
    return await _httpClient.post(
      '$baseUrl/api/v1/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }
}

void main() {
  group('Authentication API Integration Tests', () {
    late AuthApiClient authClient;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      authClient = AuthApiClient(mockHttpClient);

      // Setup mock responses
      _setupMockResponses(mockHttpClient);
    });

    tearDown(() {
      mockHttpClient.clearResponses();
      mockHttpClient.clearLog();
    });

    group('User Registration', () {
      test('should register user successfully with valid data', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);

        // Act
        final response = await authClient.register(userData);

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['user']['email'], equals(userData['email']));
        expect(response.data['access_token'], isNotNull);
        expect(response.data['refresh_token'], isNotNull);
      });

      test('should fail registration with invalid email', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['email'] = 'invalid-email';

        // Act & Assert
        expect(
          () async => await authClient.register(userData),
          throwsA(isA<DioException>()),
        );
      });

      test('should fail registration with missing required fields', () async {
        // Arrange
        final userData = <String, dynamic>{
          'email': 'test@example.com',
          // Missing password and name
        };

        // Act & Assert
        expect(
          () async => await authClient.register(userData),
          throwsA(isA<DioException>()),
        );
      });

      test('should fail registration with duplicate email', () async {
        // Arrange
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['email'] = 'existing@aivonity.com';

        // Act & Assert
        expect(
          () async => await authClient.register(userData),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('User Login', () {
      test('should login successfully with valid credentials', () async {
        // Act
        final response = await authClient.login(
          'test@aivonity.com',
          'password123',
        );

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['user']['email'], equals('test@aivonity.com'));
        expect(response.data['access_token'], isNotNull);
        expect(response.data['refresh_token'], isNotNull);
      });

      test('should fail login with invalid credentials', () async {
        // Act & Assert
        expect(
          () async => await authClient.login('wrong@email.com', 'wrongpass'),
          throwsA(isA<DioException>()),
        );
      });

      test('should fail login with empty credentials', () async {
        // Act & Assert
        expect(
          () async => await authClient.login('', ''),
          throwsA(isA<DioException>()),
        );
      });

      test('should return user profile data on successful login', () async {
        // Act
        final response = await authClient.login(
          'test@aivonity.com',
          'password123',
        );

        // Assert
        final user = response.data['user'];
        expect(user['id'], isNotNull);
        expect(user['email'], equals('test@aivonity.com'));
        expect(user['name'], isNotNull);
        expect(user['created_at'], isNotNull);
      });
    });

    group('Profile Management', () {
      test('should get user profile with valid token', () async {
        // Arrange
        const accessToken = 'valid_access_token';

        // Act
        final response = await authClient.getProfile(accessToken);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['id'], isNotNull);
        expect(response.data['email'], isNotNull);
        expect(response.data['name'], isNotNull);
      });

      test('should fail to get profile with invalid token', () async {
        // Act & Assert
        expect(
          () async => await authClient.getProfile('invalid_token'),
          throwsA(isA<DioException>()),
        );
      });

      test('should fail to get profile without token', () async {
        // Act & Assert
        expect(
          () async => await authClient.getProfile(''),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('Token Management', () {
      test('should refresh token successfully', () async {
        // Arrange
        const refreshToken = 'valid_refresh_token';

        // Act
        final response = await authClient.refreshToken(refreshToken);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['access_token'], isNotNull);
        expect(response.data['refresh_token'], isNotNull);
        expect(response.data['expires_in'], isNotNull);
      });

      test('should fail to refresh with invalid token', () async {
        // Act & Assert
        expect(
          () async => await authClient.refreshToken('invalid_refresh_token'),
          throwsA(isA<DioException>()),
        );
      });

      test('should fail to refresh with expired token', () async {
        // Act & Assert
        expect(
          () async => await authClient.refreshToken('expired_refresh_token'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('Logout', () {
      test('should logout successfully with valid token', () async {
        // Arrange
        const accessToken = 'valid_access_token';

        // Act
        final response = await authClient.logout(accessToken);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['message'], contains('logged out'));
      });

      test('should handle logout with invalid token gracefully', () async {
        // Act & Assert
        expect(
          () async => await authClient.logout('invalid_token'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('Authentication Flow Integration', () {
      test('should complete full authentication flow', () async {
        // Step 1: Register
        final userData = Map<String, dynamic>.from(TestData.validUser);
        userData['email'] = 'flow_test@aivonity.com';

        final registerResponse = await authClient.register(userData);
        expect(registerResponse.statusCode, equals(201));

        final accessToken = registerResponse.data['access_token'];
        expect(accessToken, isNotNull);

        // Step 2: Get Profile
        final profileResponse = await authClient.getProfile(accessToken);
        expect(profileResponse.statusCode, equals(200));
        expect(profileResponse.data['email'], equals('flow_test@aivonity.com'));

        // Step 3: Logout
        final logoutResponse = await authClient.logout(accessToken);
        expect(logoutResponse.statusCode, equals(200));

        // Step 4: Try to access profile after logout (should fail)
        expect(
          () async => await authClient.getProfile(accessToken),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle token refresh flow', () async {
        // Step 1: Login
        final loginResponse = await authClient.login(
          'test@aivonity.com',
          'password123',
        );
        final refreshToken = loginResponse.data['refresh_token'];

        // Step 2: Refresh token
        final refreshResponse = await authClient.refreshToken(refreshToken);
        expect(refreshResponse.statusCode, equals(200));

        final newAccessToken = refreshResponse.data['access_token'];
        expect(newAccessToken, isNotNull);

        // Step 3: Use new token to access profile
        final profileResponse = await authClient.getProfile(newAccessToken);
        expect(profileResponse.statusCode, equals(200));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        mockHttpClient.setResponse(
          TestData.apiEndpoints['auth_login']!,
          null,
          statusCode: 500,
        );

        // Act & Assert
        expect(
          () async =>
              await authClient.login('test@aivonity.com', 'password123'),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle validation errors', () async {
        // Arrange
        mockHttpClient.setResponse(TestData.apiEndpoints['auth_register']!, {
          'success': false,
          'errors': {
            'email': ['Email already exists'],
            'password': ['Password too weak'],
          },
        }, statusCode: 400);

        // Act & Assert
        expect(
          () async => await authClient.register(TestData.validUser),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle rate limiting', () async {
        // Arrange
        mockHttpClient.setResponse(TestData.apiEndpoints['auth_login']!, {
          'error': 'Rate limit exceeded',
          'retry_after': 60,
        }, statusCode: 429);

        // Act & Assert
        expect(
          () async =>
              await authClient.login('test@aivonity.com', 'password123'),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}

void _setupMockResponses(MockHttpClient mockHttpClient) {
  // Successful registration
  mockHttpClient.setResponse(TestData.apiEndpoints['auth_register']!, {
    'success': true,
    'user': {
      'id': 'user_123',
      'email': 'test@aivonity.com',
      'name': 'Test User',
      'created_at': DateTime.now().toIso8601String(),
    },
    'access_token': 'mock_access_token_123',
    'refresh_token': 'mock_refresh_token_123',
    'expires_in': 3600,
  }, statusCode: 201);

  // Successful login
  mockHttpClient.setResponse(TestData.apiEndpoints['auth_login']!, {
    'success': true,
    'user': {
      'id': 'user_123',
      'email': 'test@aivonity.com',
      'name': 'Test User',
      'created_at': DateTime.now().toIso8601String(),
    },
    'access_token': 'mock_access_token_123',
    'refresh_token': 'mock_refresh_token_123',
    'expires_in': 3600,
  }, statusCode: 200);

  // Profile endpoint
  mockHttpClient.setResponse(TestData.apiEndpoints['auth_profile']!, {
    'id': 'user_123',
    'email': 'test@aivonity.com',
    'name': 'Test User',
    'phone': '+1234567890',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  }, statusCode: 200);

  // Token refresh
  mockHttpClient.setResponse('/api/v1/auth/refresh', {
    'access_token': 'new_mock_access_token_456',
    'refresh_token': 'new_mock_refresh_token_456',
    'expires_in': 3600,
  }, statusCode: 200);

  // Logout
  mockHttpClient.setResponse('/api/v1/auth/logout', {
    'success': true,
    'message': 'Successfully logged out',
  }, statusCode: 200);
}

