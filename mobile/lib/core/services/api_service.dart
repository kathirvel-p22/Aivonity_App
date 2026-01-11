import 'dart:convert';
import 'package:http/http.dart' as http;

/// AIVONITY API Service
/// Simplified HTTP client for API communication without external dependencies
class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;

  ApiService() : _client = http.Client();

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await _client.get(uri, headers: _buildHeaders(headers));

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = _buildHeaders(headers);
      if (data != null) {
        requestHeaders['Content-Type'] = 'application/json';
      }
      final response = await _client.post(
        uri,
        headers: requestHeaders,
        body: data != null ? jsonEncode(data) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = _buildHeaders(headers);
      if (data != null) {
        requestHeaders['Content-Type'] = 'application/json';
      }
      final response = await _client.put(
        uri,
        headers: requestHeaders,
        body: data != null ? jsonEncode(data) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response =
          await _client.delete(uri, headers: _buildHeaders(headers));

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Vehicle-specific endpoints
  Future<ApiResponse<Map<String, dynamic>>> getVehicleHealth(
    String vehicleId,
  ) async {
    return get<Map<String, dynamic>>('/vehicles/$vehicleId/health');
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getServiceCenters({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    final queryParams = <String, dynamic>{};
    if (latitude != null) queryParams['lat'] = latitude.toString();
    if (longitude != null) queryParams['lng'] = longitude.toString();
    if (radius != null) queryParams['radius'] = radius.toString();

    return get<List<Map<String, dynamic>>>(
      '/service-centers',
      queryParameters: queryParams,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    return post<Map<String, dynamic>>('/bookings', data: bookingData);
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getTelemetryData(
    String vehicleId,
  ) async {
    return get<List<Map<String, dynamic>>>('/vehicles/$vehicleId/telemetry');
  }

  Future<ApiResponse<Map<String, dynamic>>> sendChatMessage(
    String message,
  ) async {
    return post<Map<String, dynamic>>('/chat', data: {'message': message});
  }

  // Helper methods
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }
    return uri;
  }

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final Map<String, String> defaultHeaders = {
      'Accept': 'application/json',
      'User-Agent': 'AIVONITY-Mobile/1.0',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    return defaultHeaders;
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body.isNotEmpty ? jsonDecode(body) : null;
        return ApiResponse.success(data as T);
      } else {
        final errorData = body.isNotEmpty ? jsonDecode(body) : null;
        final errorMessage =
            (errorData is Map<String, dynamic> && errorData['message'] != null)
                ? errorData['message'].toString()
                : 'HTTP ${response.statusCode}';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: ${e.toString()}');
    }
  }

  // Authentication-specific endpoints

  /// Login user
  Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> credentials,
  ) async {
    return post<Map<String, dynamic>>('/auth/login', data: credentials);
  }

  /// Register user
  Future<ApiResponse<Map<String, dynamic>>> register(
    Map<String, dynamic> registrationData,
  ) async {
    return post<Map<String, dynamic>>('/auth/register', data: registrationData);
  }

  /// Request password reset
  Future<ApiResponse<Map<String, dynamic>>> requestPasswordReset(
    Map<String, dynamic> request,
  ) async {
    return post<Map<String, dynamic>>('/auth/password-reset', data: request);
  }

  /// Confirm password reset
  Future<ApiResponse<Map<String, dynamic>>> confirmPasswordReset(
    Map<String, dynamic> confirmation,
  ) async {
    return post<Map<String, dynamic>>(
      '/auth/password-reset/confirm',
      data: confirmation,
    );
  }

  /// Verify email
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail(
    Map<String, dynamic> request,
  ) async {
    return post<Map<String, dynamic>>('/auth/verify-email', data: request);
  }

  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    return get<Map<String, dynamic>>('/auth/profile');
  }

  /// Refresh authentication token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(
    Map<String, dynamic> tokenData,
  ) async {
    return post<Map<String, dynamic>>('/auth/refresh', data: tokenData);
  }

  /// Logout user
  Future<ApiResponse<void>> logout(Map<String, dynamic> tokenData) async {
    return post<void>('/auth/logout', data: tokenData);
  }

  /// Social login (Google, Apple, etc.)
  Future<ApiResponse<Map<String, dynamic>>> socialLogin(
    Map<String, dynamic> socialData,
  ) async {
    return post<Map<String, dynamic>>('/auth/social-login', data: socialData);
  }

  // Device Management endpoints

  /// Register device
  Future<ApiResponse<Map<String, dynamic>>> registerDevice(
    Map<String, dynamic> deviceData,
  ) async {
    return post<Map<String, dynamic>>('/devices/register', data: deviceData);
  }

  /// Get registered devices
  Future<ApiResponse<List<Map<String, dynamic>>>> getRegisteredDevices() async {
    return get<List<Map<String, dynamic>>>('/devices');
  }

  /// Revoke device
  Future<ApiResponse<void>> revokeDevice(
    Map<String, dynamic> deviceData,
  ) async {
    return post<void>('/devices/revoke', data: deviceData);
  }

  /// Revoke all other devices
  Future<ApiResponse<void>> revokeAllOtherDevices(
    Map<String, dynamic> deviceData,
  ) async {
    return post<void>('/devices/revoke-others', data: deviceData);
  }

  /// Update device activity
  Future<ApiResponse<void>> updateDeviceActivity(
    Map<String, dynamic> activityData,
  ) async {
    return post<void>('/devices/activity', data: activityData);
  }

  /// Validate session
  Future<ApiResponse<Map<String, dynamic>>> validateSession(
    Map<String, dynamic> sessionData,
  ) async {
    return post<Map<String, dynamic>>(
      '/devices/validate-session',
      data: sessionData,
    );
  }

  void dispose() {
    _client.close();
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(error: error, isSuccess: false);
  }
}

