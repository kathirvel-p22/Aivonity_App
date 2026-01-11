/// Simple service locator for dependency management
/// This will be enhanced with GetIt once dependencies are properly installed
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// Check if service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }
}

final serviceLocator = ServiceLocator();

/// Initialize all services and dependencies
Future<void> initializeServices() async {
  // This will be enhanced with proper dependency injection later
  // For now, services will be initialized as needed
}

