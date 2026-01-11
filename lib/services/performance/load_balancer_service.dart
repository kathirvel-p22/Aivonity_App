import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing load balancing and backend reliability
class LoadBalancerService {
  static const String _serverHealthPrefix = 'server_health_';
  static const Duration _healthCheckInterval = Duration(minutes: 1);
  static const Duration _serverTimeout = Duration(seconds: 10);

  final List<BackendServer> _servers = [];
  final Map<String, ServerHealth> _serverHealth = {};
  final CircuitBreakerManager _circuitBreaker = CircuitBreakerManager();

  SharedPreferences? _prefs;
  Timer? _healthCheckTimer;

  LoadBalancingStrategy _strategy = LoadBalancingStrategy.roundRobin;
  int _currentServerIndex = 0;

  /// Initialize the load balancer service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadServerConfiguration();
    _startHealthChecks();

    print(
      '⚖️ Load balancer service initialized with ${_servers.length} servers',
    );
  }

  /// Add a backend server to the pool
  void addServer(BackendServer server) {
    _servers.add(server);
    _serverHealth[server.id] = ServerHealth(
      serverId: server.id,
      isHealthy: true,
      lastCheck: DateTime.now(),
      responseTime: Duration.zero,
      errorCount: 0,
    );

    print('➕ Added server: ${server.url}');
  }

  /// Remove a server from the pool
  void removeServer(String serverId) {
    _servers.removeWhere((server) => server.id == serverId);
    _serverHealth.remove(serverId);

    print('➖ Removed server: $serverId');
  }

  /// Set load balancing strategy
  void setStrategy(LoadBalancingStrategy strategy) {
    _strategy = strategy;
    print('🔄 Load balancing strategy set to: ${strategy.name}');
  }

  /// Get the next available server based on strategy
  BackendServer? getNextServer() {
    final healthyServers = _getHealthyServers();

    if (healthyServers.isEmpty) {
      print('❌ No healthy servers available');
      return null;
    }

    switch (_strategy) {
      case LoadBalancingStrategy.roundRobin:
        return _getRoundRobinServer(healthyServers);
      case LoadBalancingStrategy.leastConnections:
        return _getLeastConnectionsServer(healthyServers);
      case LoadBalancingStrategy.weightedRoundRobin:
        return _getWeightedRoundRobinServer(healthyServers);
      case LoadBalancingStrategy.leastResponseTime:
        return _getLeastResponseTimeServer(healthyServers);
    }
  }

  /// Make a request with automatic failover
  Future<Response<T>> makeRequest<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 3,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final server = getNextServer();
      if (server == null) {
        throw Exception('No available servers');
      }

      // Check circuit breaker
      if (!_circuitBreaker.canMakeRequest(server.id)) {
        continue;
      }

      try {
        final dio = Dio();
        dio.options.baseUrl = server.url;
        dio.options.connectTimeout = _serverTimeout;
        dio.options.receiveTimeout = _serverTimeout;

        final stopwatch = Stopwatch()..start();

        Response<T> response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await dio.get<T>(
              path,
              queryParameters: queryParameters,
              options: options,
            );
            break;
          case 'POST':
            response = await dio.post<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            );
            break;
          case 'PUT':
            response = await dio.put<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            );
            break;
          case 'DELETE':
            response = await dio.delete<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            );
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        stopwatch.stop();

        // Record successful request
        _circuitBreaker.recordSuccess(server.id);
        _updateServerHealth(server.id, true, stopwatch.elapsed);

        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Record failed request
        _circuitBreaker.recordFailure(server.id);
        _updateServerHealth(server.id, false, Duration.zero);

        print('❌ Request failed on server ${server.id}: $e');

        // If this is the last attempt, throw the exception
        if (attempt == maxRetries - 1) {
          break;
        }
      }
    }

    throw lastException ?? Exception('All servers failed');
  }

  /// Get server health statistics
  Map<String, ServerHealth> getServerHealth() {
    return Map.from(_serverHealth);
  }

  /// Get load balancer statistics
  LoadBalancerStats getStats() {
    final totalServers = _servers.length;
    final healthyServers = _getHealthyServers().length;
    final averageResponseTime = _calculateAverageResponseTime();

    return LoadBalancerStats(
      totalServers: totalServers,
      healthyServers: healthyServers,
      averageResponseTime: averageResponseTime,
      circuitBreakerStats: _circuitBreaker.getStats(),
    );
  }

  // Private helper methods

  List<BackendServer> _getHealthyServers() {
    return _servers.where((server) {
      final health = _serverHealth[server.id];
      return health?.isHealthy == true;
    }).toList();
  }

  BackendServer _getRoundRobinServer(List<BackendServer> servers) {
    final server = servers[_currentServerIndex % servers.length];
    _currentServerIndex = (_currentServerIndex + 1) % servers.length;
    return server;
  }

  BackendServer _getLeastConnectionsServer(List<BackendServer> servers) {
    // For simplicity, return the first server
    // In a real implementation, you'd track active connections
    return servers.first;
  }

  BackendServer _getWeightedRoundRobinServer(List<BackendServer> servers) {
    // Calculate weighted selection based on server weights
    final totalWeight = servers.fold<int>(
      0,
      (sum, server) => sum + server.weight,
    );
    final random = Random().nextInt(totalWeight);

    int currentWeight = 0;
    for (final server in servers) {
      currentWeight += server.weight;
      if (random < currentWeight) {
        return server;
      }
    }

    return servers.first;
  }

  BackendServer _getLeastResponseTimeServer(List<BackendServer> servers) {
    BackendServer? bestServer;
    Duration bestTime = Duration(days: 1);

    for (final server in servers) {
      final health = _serverHealth[server.id];
      if (health != null && health.responseTime < bestTime) {
        bestTime = health.responseTime;
        bestServer = server;
      }
    }

    return bestServer ?? servers.first;
  }

  void _startHealthChecks() {
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      await _performHealthChecks();
    });
  }

  Future<void> _performHealthChecks() async {
    for (final server in _servers) {
      await _checkServerHealth(server);
    }
  }

  Future<void> _checkServerHealth(BackendServer server) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = Duration(seconds: 5);
      dio.options.receiveTimeout = Duration(seconds: 5);

      final stopwatch = Stopwatch()..start();
      await dio.get('${server.url}/health');
      stopwatch.stop();

      _updateServerHealth(server.id, true, stopwatch.elapsed);
    } catch (e) {
      _updateServerHealth(server.id, false, Duration.zero);
    }
  }

  void _updateServerHealth(
    String serverId,
    bool isHealthy,
    Duration responseTime,
  ) {
    final health = _serverHealth[serverId];
    if (health != null) {
      health.isHealthy = isHealthy;
      health.lastCheck = DateTime.now();
      health.responseTime = responseTime;

      if (!isHealthy) {
        health.errorCount++;
      } else {
        health.errorCount = 0;
      }
    }
  }

  Duration _calculateAverageResponseTime() {
    final healthyServers = _serverHealth.values.where(
      (health) => health.isHealthy,
    );
    if (healthyServers.isEmpty) return Duration.zero;

    final totalMs = healthyServers
        .map((health) => health.responseTime.inMilliseconds)
        .fold<int>(0, (sum, ms) => sum + ms);

    return Duration(milliseconds: totalMs ~/ healthyServers.length);
  }

  Future<void> _loadServerConfiguration() async {
    // Load server configuration from preferences or config file
    // For now, add some default servers
    addServer(
      BackendServer(
        id: 'server1',
        url: 'https://api1.aivonity.com',
        weight: 10,
        region: 'us-east-1',
      ),
    );

    addServer(
      BackendServer(
        id: 'server2',
        url: 'https://api2.aivonity.com',
        weight: 10,
        region: 'us-west-1',
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _circuitBreaker.dispose();
  }
}

/// Circuit breaker for handling server failures
class CircuitBreakerManager {
  final Map<String, CircuitBreaker> _breakers = {};

  static const int _failureThreshold = 5;
  static const Duration _timeout = Duration(minutes: 1);

  bool canMakeRequest(String serverId) {
    final breaker = _getOrCreateBreaker(serverId);
    return breaker.canMakeRequest();
  }

  void recordSuccess(String serverId) {
    final breaker = _getOrCreateBreaker(serverId);
    breaker.recordSuccess();
  }

  void recordFailure(String serverId) {
    final breaker = _getOrCreateBreaker(serverId);
    breaker.recordFailure();
  }

  Map<String, CircuitBreakerState> getStats() {
    return _breakers.map((key, breaker) => MapEntry(key, breaker.state));
  }

  CircuitBreaker _getOrCreateBreaker(String serverId) {
    return _breakers.putIfAbsent(
      serverId,
      () => CircuitBreaker(_failureThreshold, _timeout),
    );
  }

  void dispose() {
    _breakers.clear();
  }
}

/// Individual circuit breaker
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  CircuitBreaker(this.failureThreshold, this.timeout);

  CircuitBreakerState get state => _state;

  bool canMakeRequest() {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.open:
        if (_shouldAttemptReset()) {
          _state = CircuitBreakerState.halfOpen;
          return true;
        }
        return false;
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) > timeout;
  }
}

/// Backend server configuration
class BackendServer {
  final String id;
  final String url;
  final int weight;
  final String region;

  BackendServer({
    required this.id,
    required this.url,
    this.weight = 1,
    required this.region,
  });
}

/// Server health information
class ServerHealth {
  final String serverId;
  bool isHealthy;
  DateTime lastCheck;
  Duration responseTime;
  int errorCount;

  ServerHealth({
    required this.serverId,
    required this.isHealthy,
    required this.lastCheck,
    required this.responseTime,
    required this.errorCount,
  });
}

/// Load balancing strategies
enum LoadBalancingStrategy {
  roundRobin,
  leastConnections,
  weightedRoundRobin,
  leastResponseTime,
}

/// Circuit breaker states
enum CircuitBreakerState { closed, open, halfOpen }

/// Load balancer statistics
class LoadBalancerStats {
  final int totalServers;
  final int healthyServers;
  final Duration averageResponseTime;
  final Map<String, CircuitBreakerState> circuitBreakerStats;

  LoadBalancerStats({
    required this.totalServers,
    required this.healthyServers,
    required this.averageResponseTime,
    required this.circuitBreakerStats,
  });
}

