import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'websocket_service.dart';
import 'telemetry_service.dart';
import 'alert_service.dart';
import 'maps_service.dart';
import 'navigation_service.dart';
import 'location_recommendations_service.dart';
import 'booking_service.dart';
import 'analytics_service.dart';
import 'predictive_analytics_service.dart';
import 'reporting_service.dart';
import 'data_export_service.dart';
// import 'security/security_service_coordinator.dart';
import 'performance/performance_optimization_service.dart';
import 'performance/cache_manager.dart';
import 'performance/image_optimization_service.dart';
import 'performance/lazy_loading_service.dart';
import 'performance/load_balancer_service.dart';
import 'performance/database_optimization_service.dart';
import 'performance/redis_cache_service.dart';
import 'performance/monitoring_service.dart';

/// Service locator for dependency injection
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services
Future<void> initializeServices() async {
  // Register shared dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

  serviceLocator.registerLazySingleton<Dio>(() => Dio());

  // Register WebSocket service as singleton
  serviceLocator.registerLazySingleton<WebSocketService>(
    () => WebSocketService(),
  );

  // Register Alert service as singleton
  serviceLocator.registerLazySingleton<AlertService>(() => AlertService());

  // Register Telemetry service as singleton
  serviceLocator.registerLazySingleton<TelemetryService>(
    () => TelemetryService(serviceLocator<WebSocketService>()),
  );

  // Register Maps service as singleton
  serviceLocator.registerLazySingleton<MapsService>(
    () =>
        MapsService(serviceLocator<Dio>(), serviceLocator<SharedPreferences>()),
  );

  // Register Navigation service as singleton
  serviceLocator.registerLazySingleton<NavigationService>(
    () => NavigationService(
      serviceLocator<Dio>(),
      serviceLocator<SharedPreferences>(),
    ),
  );

  // Register Location Recommendations service as singleton
  serviceLocator.registerLazySingleton<LocationRecommendationsService>(
    () => LocationRecommendationsService(
      serviceLocator<SharedPreferences>(),
      serviceLocator<MapsService>(),
    ),
  );

  // Register Booking service as singleton
  serviceLocator.registerLazySingleton<BookingService>(
    () => BookingService(serviceLocator<SharedPreferences>()),
  );

  // Register Analytics service as singleton
  serviceLocator.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(serviceLocator<Dio>()),
  );

  // Register Predictive Analytics service as singleton
  serviceLocator.registerLazySingleton<PredictiveAnalyticsService>(
    () => PredictiveAnalyticsService(serviceLocator<Dio>()),
  );

  // Register Reporting service as singleton
  serviceLocator.registerLazySingleton<ReportingService>(
    () => ReportingService(serviceLocator<Dio>()),
  );

  // Register Data Export service as singleton
  serviceLocator.registerLazySingleton<DataExportService>(
    () => DataExportService(serviceLocator<Dio>()),
  );

  // Register Security Service Coordinator as singleton
  // serviceLocator.registerLazySingleton<SecurityServiceCoordinator>(
  //   () => SecurityServiceCoordinator(),
  // );

  // Initialize security services
  // await serviceLocator<SecurityServiceCoordinator>().initialize();

  // Register Performance Services
  serviceLocator.registerLazySingleton<PerformanceOptimizationService>(
    () => PerformanceOptimizationService(),
  );

  serviceLocator.registerLazySingleton<AdvancedCacheManager>(
    () => AdvancedCacheManager(),
  );

  serviceLocator.registerLazySingleton<ImageOptimizationService>(
    () => ImageOptimizationService(),
  );

  serviceLocator.registerLazySingleton<LazyLoadingService>(
    () => LazyLoadingService(),
  );

  serviceLocator.registerLazySingleton<LoadBalancerService>(
    () => LoadBalancerService(),
  );

  serviceLocator.registerLazySingleton<DatabaseOptimizationService>(
    () => DatabaseOptimizationService(),
  );

  serviceLocator.registerLazySingleton<RedisCacheService>(
    () => RedisCacheService(),
  );

  serviceLocator.registerLazySingleton<MonitoringService>(
    () => MonitoringService(),
  );

  // Initialize performance services
  await serviceLocator<PerformanceOptimizationService>().initialize();
  await serviceLocator<AdvancedCacheManager>().initialize();
  await serviceLocator<ImageOptimizationService>().initialize();
  await serviceLocator<LoadBalancerService>().initialize();
  await serviceLocator<DatabaseOptimizationService>().initialize();
  await serviceLocator<RedisCacheService>().initialize();
  await serviceLocator<MonitoringService>().initialize();
}

/// Dispose all services
Future<void> disposeServices() async {
  if (serviceLocator.isRegistered<TelemetryService>()) {
    serviceLocator<TelemetryService>().dispose();
  }

  if (serviceLocator.isRegistered<AlertService>()) {
    serviceLocator<AlertService>().dispose();
  }

  if (serviceLocator.isRegistered<WebSocketService>()) {
    serviceLocator<WebSocketService>().dispose();
  }

  if (serviceLocator.isRegistered<AnalyticsService>()) {
    serviceLocator<AnalyticsService>().dispose();
  }

  if (serviceLocator.isRegistered<PredictiveAnalyticsService>()) {
    serviceLocator<PredictiveAnalyticsService>().dispose();
  }

  if (serviceLocator.isRegistered<ReportingService>()) {
    serviceLocator<ReportingService>().dispose();
  }

  // if (serviceLocator.isRegistered<SecurityServiceCoordinator>()) {
  //   serviceLocator<SecurityServiceCoordinator>().dispose();
  // }

  if (serviceLocator.isRegistered<PerformanceOptimizationService>()) {
    serviceLocator<PerformanceOptimizationService>().dispose();
  }

  if (serviceLocator.isRegistered<AdvancedCacheManager>()) {
    serviceLocator<AdvancedCacheManager>().dispose();
  }

  if (serviceLocator.isRegistered<ImageOptimizationService>()) {
    serviceLocator<ImageOptimizationService>().dispose();
  }

  if (serviceLocator.isRegistered<LazyLoadingService>()) {
    serviceLocator<LazyLoadingService>().dispose();
  }

  if (serviceLocator.isRegistered<LoadBalancerService>()) {
    serviceLocator<LoadBalancerService>().dispose();
  }

  if (serviceLocator.isRegistered<DatabaseOptimizationService>()) {
    serviceLocator<DatabaseOptimizationService>().dispose();
  }

  if (serviceLocator.isRegistered<RedisCacheService>()) {
    serviceLocator<RedisCacheService>().dispose();
  }

  if (serviceLocator.isRegistered<MonitoringService>()) {
    serviceLocator<MonitoringService>().dispose();
  }

  await serviceLocator.reset();
}
