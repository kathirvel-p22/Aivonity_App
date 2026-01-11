import 'package:flutter/material.dart';
import 'services/service_locator.dart';
import 'screens/comprehensive_telemetry_dashboard.dart';
import 'screens/remote_monitoring_dashboard.dart';
import 'screens/service_center_finder_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/analytics_dashboard.dart';
import 'screens/predictive_dashboard.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/responsive_main_dashboard.dart';
import 'design_system/design_system.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await initializeServices();

  // Initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.initialize();

  runApp(MainApp(themeManager: themeManager));
}

class MainApp extends StatelessWidget {
  final ThemeManager themeManager;

  const MainApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeManager: themeManager,
      child: ListenableBuilder(
        listenable: themeManager,
        builder: (context, child) {
          return MaterialApp(
            title: 'AIVONITY Vehicle Assistant',
            theme: themeManager.getThemeData(AivonityTheme.lightTheme),
            darkTheme: themeManager.getThemeData(AivonityTheme.darkTheme),
            themeMode: themeManager.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeManager.textScaleFactor),
                ),
                child: child!,
              );
            },
            home: const MainDashboard(),
            routes: {
              '/telemetry': (context) =>
                  const ComprehensiveTelemetryDashboard(),
              '/remote-monitoring': (context) =>
                  const RemoteMonitoringDashboard(vehicleId: 'vehicle_001'),
              '/service-centers': (context) =>
                  const ServiceCenterFinderScreen(),
              '/navigation': (context) => const NavigationScreen(),
              '/recommendations': (context) => const RecommendationsScreen(),
              '/appointments': (context) => const AppointmentsScreen(),
              '/analytics': (context) =>
                  const AnalyticsDashboard(vehicleId: 'vehicle_001'),
              '/predictive': (context) =>
                  const PredictiveDashboard(vehicleId: 'vehicle_001'),
              '/reports': (context) =>
                  const ReportsScreen(vehicleId: 'vehicle_001'),
              '/settings': (context) => const SettingsScreen(),
              '/responsive-dashboard': (context) =>
                  const ResponsiveMainDashboard(),
            },
          );
        },
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  @override
  void initState() {
    super.initState();
    // Show onboarding after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingService.showOnboardingIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIVONITY Vehicle Assistant'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AivonitySpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vehicle Management Dashboard',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AivonitySpacing.vGapXL,

            // Dashboard Cards with animations
            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/telemetry'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.dashboard, size: 32),
                  title: const Text('Telemetry Dashboard'),
                  subtitle: const Text(
                    'Real-time vehicle data and diagnostics',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/remote-monitoring'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.location_on, size: 32),
                  title: const Text('Remote Monitoring'),
                  subtitle: const Text(
                    'Location tracking, geofencing, and security',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/service-centers'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.map, size: 32),
                  title: const Text('Service Centers'),
                  subtitle: const Text(
                    'Find nearby service centers and book appointments',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/recommendations'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb, size: 32),
                  title: const Text('Smart Recommendations'),
                  subtitle: const Text(
                    'Location-based suggestions and favorites',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/appointments'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, size: 32),
                  title: const Text('My Appointments'),
                  subtitle: const Text('View and manage service appointments'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/analytics'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.analytics, size: 32),
                  title: const Text('Analytics Dashboard'),
                  subtitle: const Text(
                    'Performance metrics and trend analysis',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/predictive'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.psychology, size: 32),
                  title: const Text('Predictive Analytics'),
                  subtitle: const Text(
                    'Maintenance predictions and ML insights',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapMD,

            AnimatedInteractiveContainer(
              onTap: () => Navigator.pushNamed(context, '/reports'),
              child: AivonityCard(
                child: ListTile(
                  leading: const Icon(Icons.description, size: 32),
                  title: const Text('Reports & Export'),
                  subtitle: const Text(
                    'Generate and share comprehensive reports',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),

            AivonitySpacing.vGapXL,

            AivonityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remote Monitoring Features',
                    style: theme.textTheme.titleLarge,
                  ),
                  AivonitySpacing.vGapSM,
                  const Text('✓ Real-time location tracking'),
                  const Text('✓ Geofencing with alerts'),
                  const Text('✓ Theft detection and security monitoring'),
                  const Text('✓ Remote diagnostics'),
                  const Text('✓ Push notifications for critical events'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const HelpButton(helpContext: 'Dashboard'),
    );
  }
}

