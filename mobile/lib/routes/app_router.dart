import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/screens/profile_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/telemetry/screens/telemetry_screen.dart';
import '../features/chat_ai/screens/chat_screen.dart';
import '../features/chat_ai/screens/multilingual_ai_chat_screen.dart';
import '../features/fuel/fuel_entry_screen.dart';
import '../features/vehicles/vehicle_locator_screen.dart';
import '../features/vehicles/remote_control_screen.dart';
import '../features/vehicles/vehicle_management_system.dart';
import '../features/maintenance/service_scheduler.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/emergency/emergency_response_system.dart';
import '../features/navigation/google_maps_navigation_screen.dart';
import '../features/navigation/advanced_navigation_screen.dart';
import '../features/notifications/advanced_notification_system.dart';
import '../features/personalization/ai_vehicle_learning.dart';
import '../features/fuel/advanced_fuel_optimizer.dart';
import '../features/settings/screens/notification_settings_screen.dart';
import '../features/booking/screens/booking_screen.dart';
import '../features/booking/screens/service_centers_screen.dart';

/// AIVONITY Advanced App Router
/// Handles navigation with authentication and deep linking
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String vehicleDetails = '/vehicle/:vehicleId';
  static const String telemetry = '/telemetry/:vehicleId';
  static const String chat = '/chat';
  static const String booking = '/booking';
  static const String serviceCenters = '/service-centers';
  static const String feedback = '/feedback';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String fuelEntry = '/fuel-entry';
  static const String vehicleLocator = '/vehicle-locator';
  static const String remoteControl = '/remote-control';
  static const String serviceScheduler = '/service-scheduler';
  static const String analytics = '/analytics';
  static const String emergency = '/emergency';
  static const String navigation = '/navigation';
  static const String advancedNavigation = '/advanced-navigation';
  static const String notifications = '/notifications';
  static const String vehicleManagement = '/vehicle-management';
  static const String fuelOptimizer = '/fuel-optimizer';
  static const String aiLearning = '/ai-learning';
  static const String multilingualChat = '/multilingual-chat';

  static GoRouter createRouter(Ref ref) {
    return GoRouter(
      initialLocation: dashboard, // Start directly at dashboard
      debugLogDiagnostics: true,
      redirect: (context, state) {
        // Remove all authentication redirects - go directly to dashboard
        return null;
      },
      routes: [
        // Main app routes - no authentication required
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: dashboard,
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            // TODO: Implement VehicleDetailsScreen
            // GoRoute(
            //   path: vehicleDetails,
            //   name: 'vehicleDetails',
            //   builder: (context, state) {
            //     final vehicleId = state.pathParameters['vehicleId']!;
            //     return VehicleDetailsScreen(vehicleId: vehicleId);
            //   },
            // ),
            GoRoute(
              path: telemetry,
              name: 'telemetry',
              builder: (context, state) {
                final vehicleId = state.pathParameters['vehicleId']!;
                return TelemetryScreen(vehicleId: vehicleId);
              },
            ),
            GoRoute(
              path: chat,
              name: 'chat',
              builder: (context, state) => const ChatScreen(),
            ),
            GoRoute(
              path: booking,
              name: 'booking',
              builder: (context, state) => const BookingScreen(),
            ),
            GoRoute(
              path: serviceCenters,
              name: 'serviceCenters',
              builder: (context, state) => const ServiceCentersScreen(),
            ),
            // GoRoute(
            //   path: feedback,
            //   name: 'feedback',
            //   builder: (context, state) => const FeedbackScreen(),
            // ),
            GoRoute(
              path: profile,
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: fuelEntry,
              name: 'fuelEntry',
              builder: (context, state) => const FuelEntryScreen(),
            ),
            GoRoute(
              path: vehicleLocator,
              name: 'vehicleLocator',
              builder: (context, state) => const VehicleLocatorScreen(
                vehicleId: '1',
                vehicleName: 'Tesla Model 3',
              ),
            ),
            GoRoute(
              path: remoteControl,
              name: 'remoteControl',
              builder: (context, state) => const RemoteControlScreen(
                vehicleId: '1',
                vehicleName: 'Tesla Model 3',
              ),
            ),
            GoRoute(
              path: serviceScheduler,
              name: 'serviceScheduler',
              builder: (context, state) => const ServiceScheduler(),
            ),
            GoRoute(
              path: analytics,
              name: 'analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: emergency,
              name: 'emergency',
              builder: (context, state) => const EmergencyResponseSystem(),
            ),
            GoRoute(
              path: navigation,
              name: 'navigation',
              builder: (context, state) => const GoogleMapsNavigationScreen(),
            ),
            GoRoute(
              path: advancedNavigation,
              name: 'advancedNavigation',
              builder: (context, state) => const AdvancedNavigationScreen(),
            ),
            GoRoute(
              path: settings,
              name: 'settings',
              builder: (context, state) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: notifications,
              name: 'notifications',
              builder: (context, state) => const AdvancedNotificationSystem(),
            ),
            GoRoute(
              path: vehicleManagement,
              name: 'vehicleManagement',
              builder: (context, state) => const VehicleManagementSystem(),
            ),
            GoRoute(
              path: fuelOptimizer,
              name: 'fuelOptimizer',
              builder: (context, state) => const AdvancedFuelOptimizer(),
            ),
            GoRoute(
              path: aiLearning,
              name: 'aiLearning',
              builder: (context, state) => const AIVehicleLearning(),
            ),
            GoRoute(
              path: multilingualChat,
              name: 'multilingualChat',
              builder: (context, state) => const MultilingualAIChatScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => ErrorScreen(error: state.error),
    );
  }
}

/// Splash screen with loading animation
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Go directly to dashboard - no authentication check needed
      GoRouter.of(context).go(AppRouter.dashboard);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 60,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 24),

              // App name
              Text(
                'AIVONITY',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Intelligent Vehicle Assistant',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main shell with bottom navigation
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Bottom navigation bar
class MainBottomNavigation extends ConsumerWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(currentLocation),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Telemetry',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chat'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Booking',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/telemetry')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/booking')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboard);
        break;
      case 1:
        // Navigate to telemetry for first vehicle or show vehicle selection
        context.go('/telemetry/default');
        break;
      case 2:
        context.go(AppRouter.chat);
        break;
      case 3:
        context.go(AppRouter.booking);
        break;
      case 4:
        context.go(AppRouter.profile);
        break;
    }
  }
}

/// Error screen for navigation errors
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider for app router
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});
