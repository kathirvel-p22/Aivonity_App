import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/chat_ai/screens/chat_screen.dart';
import '../../features/chat_ai/screens/multilingual_ai_chat_screen.dart';
import '../../features/notifications/advanced_notification_system.dart';
import '../../features/vehicles/vehicle_management_system.dart';
import '../../features/vehicles/remote_control_screen.dart';
import '../../features/vehicles/vehicle_locator_screen.dart';
import '../../features/fuel/advanced_fuel_optimizer.dart';
import '../../features/fuel/fuel_entry_screen.dart';
import '../../features/navigation/advanced_navigation_screen.dart';
import '../../features/personalization/ai_vehicle_learning.dart';
import '../../features/emergency/emergency_response_system.dart';
import '../../features/maintenance/service_scheduler.dart';
import '../../widgets/advanced_ar_diagnostic_overlay.dart';
import '../screens/settings_screen.dart';

/// Navigation Provider for managing current page
final navigationProvider = StateProvider<int>((ref) => 0);

/// Main Navigation Widget with Bottom Navigation Bar and Drawer
class AppNavigation extends ConsumerWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    final List<Widget> pages = [
      const DashboardScreen(),
      const AnalyticsScreen(),
      const ChatScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIVONITY'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showAdvancedFeaturesDrawer(context),
            tooltip: 'Advanced Features',
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).state = index;
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showAdvancedFeaturesDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🚀 Advanced Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  controller: scrollController,
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildFeatureCard(
                      context,
                      'Smart Notifications',
                      'AI-powered notification system',
                      Icons.notifications_active,
                      Colors.blue,
                      () => _navigateToScreen(
                        context,
                        const AdvancedNotificationSystem(),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Vehicle Management',
                      'Multi-vehicle fleet control',
                      Icons.directions_car,
                      Colors.green,
                      () => _navigateToScreen(
                        context,
                        const VehicleManagementSystem(),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Fuel Optimizer',
                      'AI fuel efficiency analysis',
                      Icons.local_gas_station,
                      Colors.orange,
                      () => _navigateToScreen(
                        context,
                        const AdvancedFuelOptimizer(),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Advanced Navigation',
                      'Smart route optimization',
                      Icons.navigation,
                      Colors.purple,
                      () => _navigateToScreen(
                        context,
                        const AdvancedNavigationScreen(),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'AI Vehicle Learning',
                      'Personalized vehicle insights',
                      Icons.psychology,
                      Colors.teal,
                      () =>
                          _navigateToScreen(context, const AIVehicleLearning()),
                    ),
                    _buildFeatureCard(
                      context,
                      'Emergency Response',
                      '24/7 emergency assistance',
                      Icons.emergency,
                      Colors.red,
                      () => _navigateToScreen(
                        context,
                        const EmergencyResponseSystem(),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'AR Diagnostics',
                      'Augmented reality inspection',
                      Icons.view_in_ar,
                      Colors.indigo,
                      () => _navigateToScreen(
                        context,
                        const AdvancedARDiagnosticOverlay(
                          vehicleData: {
                            'engineHealth': 0.95,
                            'batteryHealth': 0.87,
                            'transmissionHealth': 0.92,
                            'brakeHealth': 0.88,
                            'healthScore': 0.85,
                          },
                        ),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Multilingual AI Chat',
                      'Advanced conversational AI',
                      Icons.chat_bubble_outline,
                      Colors.cyan,
                      () => _navigateToScreen(
                        context,
                        const MultilingualAIChatScreen(),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Remote Control',
                      'Control your vehicle remotely',
                      Icons.settings_remote,
                      Colors.purple,
                      () => _navigateToScreen(
                        context,
                        const RemoteControlScreen(
                          vehicleId: 'vehicle_1',
                          vehicleName: 'Tesla Model 3',
                        ),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Vehicle Locator',
                      'Find your vehicle location',
                      Icons.location_searching,
                      Colors.orange,
                      () => _navigateToScreen(
                        context,
                        const VehicleLocatorScreen(
                          vehicleId: 'vehicle_1',
                          vehicleName: 'Tesla Model 3',
                        ),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      'Fuel Entry',
                      'Log fuel purchases',
                      Icons.local_gas_station,
                      Colors.amber,
                      () => _navigateToScreen(context, const FuelEntryScreen()),
                    ),
                    _buildFeatureCard(
                      context,
                      'Service Scheduler',
                      'Book maintenance appointments',
                      Icons.calendar_today,
                      Colors.teal,
                      () => _navigateToScreen(
                        context,
                        const ServiceScheduler(
                          serviceType: 'Oil Change',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // Close the drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

