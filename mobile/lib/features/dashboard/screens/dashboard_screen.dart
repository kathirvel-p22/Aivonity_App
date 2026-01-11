import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import '../../analytics/screens/analytics_screen.dart';
import '../../analytics/screens/rca_reports_screen.dart';
import '../../chat_ai/screens/chat_screen.dart';
import '../../chat_ai/screens/voice_demo_screen.dart';
import '../../fuel/fuel_entry_screen.dart';
import '../../vehicles/vehicle_locator_screen.dart';
import '../../vehicles/remote_control_screen.dart';
import '../../telemetry/screens/telemetry_screen.dart';
import '../../maintenance/service_scheduler.dart';
import '../../booking/screens/service_booking_screen.dart';
import '../../emergency/emergency_response_system.dart';
import '../../navigation/advanced_navigation_screen.dart';
import '../../settings/screens/notification_settings_screen.dart';

/// Simple sound service for UI feedback
class _SoundService {
  static Future<void> playTapSound() async {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silent fallback
    }
  }
}

/// Animated container with tap effects
class _AnimatedInteractiveContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration = const Duration(milliseconds: 150);
  final double tapScale = 0.95;

  const _AnimatedInteractiveContainer({
    required this.child,
    this.onTap,
  });

  @override
  State<_AnimatedInteractiveContainer> createState() =>
      _AnimatedInteractiveContainerState();
}

class _AnimatedInteractiveContainerState
    extends State<_AnimatedInteractiveContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: widget.tapScale,
    ).animate(_controller);

    _controller.reset();
    _controller.forward().then((_) {
      _scaleAnimation = Tween<double>(
        begin: widget.tapScale,
        end: 1.0,
      ).animate(_controller);
      _controller.reset();
      _controller.forward();
    });

    _SoundService.playTapSound();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Quick Action Item
class QuickActionItem {
  final IconData icon;
  final String title;
  final Widget screen;

  const QuickActionItem({
    required this.icon,
    required this.title,
    required this.screen,
  });
}

/// Dashboard Widget Types
enum DashboardWidgetType {
  vehicleSelector,
  healthScore,
  quickActions,
  recentAlerts,
  performanceOverview,
  fuelEfficiency,
  maintenanceSchedule,
  tripHistory,
  weatherInfo,
  trafficUpdates,
}

/// Base Dashboard Widget
abstract class DashboardWidget {
  final DashboardWidgetType type;
  final String title;
  final bool isVisible;
  final int order;

  const DashboardWidget({
    required this.type,
    required this.title,
    this.isVisible = true,
    this.order = 0,
  });

  Widget build(BuildContext context, Map<String, dynamic> vehicleData);
}

/// Dashboard Layout Mode
enum DashboardLayoutMode {
  compact,
  normal,
  spacious,
}

/// Vehicle Selector Widget
class VehicleSelectorWidget extends DashboardWidget {
  const VehicleSelectorWidget({
    super.order = 0,
    super.isVisible = true,
  }) : super(
          type: DashboardWidgetType.vehicleSelector,
          title: 'Vehicle Selector',
        );

  @override
  Widget build(BuildContext context, Map<String, dynamic> vehicleData) {
    // Implementation will be added in the dashboard screen
    return const SizedBox.shrink();
  }
}

/// Health Score Widget
class HealthScoreWidget extends DashboardWidget {
  const HealthScoreWidget({
    super.order = 1,
    super.isVisible = true,
  }) : super(
          type: DashboardWidgetType.healthScore,
          title: 'Vehicle Health',
        );

  @override
  Widget build(BuildContext context, Map<String, dynamic> vehicleData) {
    // Implementation will be added in the dashboard screen
    return const SizedBox.shrink();
  }
}

/// Quick Actions Widget
class QuickActionsWidget extends DashboardWidget {
  const QuickActionsWidget({
    super.order = 2,
    super.isVisible = true,
  }) : super(
          type: DashboardWidgetType.quickActions,
          title: 'Quick Actions',
        );

  @override
  Widget build(BuildContext context, Map<String, dynamic> vehicleData) {
    // Implementation will be added in the dashboard screen
    return const SizedBox.shrink();
  }
}

/// Recent Alerts Widget
class RecentAlertsWidget extends DashboardWidget {
  const RecentAlertsWidget({
    super.order = 3,
    super.isVisible = true,
  }) : super(
          type: DashboardWidgetType.recentAlerts,
          title: 'Recent Alerts',
        );

  @override
  Widget build(BuildContext context, Map<String, dynamic> vehicleData) {
    // Implementation will be added in the dashboard screen
    return const SizedBox.shrink();
  }
}

/// Performance Overview Widget
class PerformanceOverviewWidget extends DashboardWidget {
  const PerformanceOverviewWidget({
    super.order = 4,
    super.isVisible = true,
  }) : super(
          type: DashboardWidgetType.performanceOverview,
          title: 'Performance Overview',
        );

  @override
  Widget build(BuildContext context, Map<String, dynamic> vehicleData) {
    // Implementation will be added in the dashboard screen
    return const SizedBox.shrink();
  }
}

/// AIVONITY Dashboard Screen
/// Main dashboard showing vehicle health and quick actions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _staggeredAnimationController;
  int _selectedVehicleIndex = 0;
  final DashboardLayoutMode _layoutMode = DashboardLayoutMode.normal;
  bool _isEditMode = false;

  // Available dashboard widgets
  late List<DashboardWidget> _availableWidgets;
  late List<DashboardWidget> _activeWidgets;

  // Real-time updates
  Timer? _realTimeUpdateTimer;
  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _alertSubscription;

  final List<Map<String, dynamic>> _vehicles = [
    {
      'id': '1',
      'name': 'Tesla Model 3',
      'year': '2023',
      'healthScore': 0.92,
      'mileage': '15,420',
      'status': 'Excellent',
    },
    {
      'id': '2',
      'name': 'BMW X5',
      'year': '2022',
      'healthScore': 0.78,
      'mileage': '28,150',
      'status': 'Good',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();

    _staggeredAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggeredAnimationController.forward();

    // Initialize dashboard widgets
    _initializeWidgets();

    // Initialize real-time updates
    _initializeRealTimeUpdates();
  }

  void _initializeWidgets() {
    _availableWidgets = [
      const VehicleSelectorWidget(order: 0),
      const HealthScoreWidget(order: 1),
      const QuickActionsWidget(order: 2),
      const RecentAlertsWidget(order: 3),
      const PerformanceOverviewWidget(order: 4),
    ];

    // Load user's widget preferences (for now, use defaults)
    _activeWidgets = _availableWidgets
        .where((widget) => widget.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  void _initializeRealTimeUpdates() {
    // Simulate real-time updates with a timer
    _realTimeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateVehicleDataWithRealTimeInfo();
      }
    });

    // In a real implementation, you would subscribe to WebSocket streams:
    // _telemetrySubscription = websocketService.telemetryStream.listen(_onTelemetryUpdate);
    // _alertSubscription = websocketService.alertStream.listen(_onAlertUpdate);
  }

  void _updateVehicleDataWithRealTimeInfo() {
    setState(() {
      // Simulate real-time updates to vehicle health scores and metrics
      for (final vehicle in _vehicles) {
        final currentHealth = vehicle['healthScore'] as double;
        // Add small random variations to simulate real-time data
        final variation =
            (DateTime.now().millisecondsSinceEpoch % 10 - 5) / 100.0;
        final newHealth = (currentHealth + variation).clamp(0.0, 1.0);
        vehicle['healthScore'] = newHealth;

        // Update status based on health score
        if (newHealth >= 0.9) {
          vehicle['status'] = 'Excellent';
        } else if (newHealth >= 0.7) {
          vehicle['status'] = 'Good';
        } else if (newHealth >= 0.5) {
          vehicle['status'] = 'Fair';
        } else {
          vehicle['status'] = 'Needs Attention';
        }
      }
    });
  }

  void _onTelemetryUpdate(Map<String, dynamic> telemetry) {
    // Handle real-time telemetry updates
    setState(() {
      // Update vehicle data based on telemetry
      final vehicleId = telemetry['vehicle_id'];
      final vehicle = _vehicles.firstWhere(
        (v) => v['id'] == vehicleId,
        orElse: () => <String, dynamic>{},
      );

      if (vehicle.isNotEmpty) {
        if (telemetry.containsKey('fuel_level')) {
          vehicle['fuelLevel'] = telemetry['fuel_level'];
        }
        if (telemetry.containsKey('engine_temp')) {
          vehicle['engineTemp'] = telemetry['engine_temp'];
        }
        if (telemetry.containsKey('battery_voltage')) {
          vehicle['batteryVoltage'] = telemetry['battery_voltage'];
        }
      }
    });
  }

  void _onAlertUpdate(Map<String, dynamic> alert) {
    // Handle real-time alert updates
    setState(() {
      // Add new alert to the alerts list
      final newAlert = {
        'title': alert['title'] ?? 'New Alert',
        'description': alert['message'] ?? 'Alert received',
        'severity': alert['severity'] ?? 'medium',
        'time': 'Just now',
      };

      // In a real implementation, you'd update the alerts list
      // _alerts.insert(0, newAlert);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggeredAnimationController.dispose();
    _realTimeUpdateTimer?.cancel();
    _telemetrySubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  List<Widget> _buildDashboardWidgets(Map<String, dynamic> currentVehicle) {
    final widgets = <Widget>[];

    for (final dashboardWidget in _activeWidgets) {
      switch (dashboardWidget.type) {
        case DashboardWidgetType.vehicleSelector:
          widgets.add(_buildVehicleSelector());
          break;
        case DashboardWidgetType.healthScore:
          widgets.add(_buildHealthScoreCard(currentVehicle));
          break;
        case DashboardWidgetType.quickActions:
          widgets.add(_buildQuickActions());
          break;
        case DashboardWidgetType.recentAlerts:
          widgets.add(_buildRecentAlerts());
          break;
        case DashboardWidgetType.performanceOverview:
          widgets.add(_buildPerformanceOverview(currentVehicle));
          break;
        default:
          // Handle other widget types
          break;
      }

      // Add spacing between widgets
      if (dashboardWidget != _activeWidgets.last) {
        widgets.add(const SizedBox(height: 20));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final currentVehicle = _vehicles[_selectedVehicleIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildDashboardWidgets(currentVehicle),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Good Morning',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit_outlined),
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
            tooltip: _isEditMode ? 'Done' : 'Edit Dashboard',
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _navigateToNotifications(),
            tooltip: 'Notifications',
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _navigateToProfile(),
            tooltip: 'Profile',
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelector() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          final isSelected = index == _selectedVehicleIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 220,
            margin: EdgeInsets.only(
              right: index < _vehicles.length - 1 ? 16 : 0,
            ),
            child: _AnimatedInteractiveContainer(
              onTap: () {
                setState(() {
                  _selectedVehicleIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.9),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.8),
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.shadow)
                          .withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: (isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.shadow)
                          .withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vehicle['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${vehicle['year']} • ${vehicle['mileage']} miles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthScoreCard(Map<String, dynamic> vehicle) {
    final healthScore = vehicle['healthScore'] as double;
    final status = vehicle['status'] as String;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Vehicle Health',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  // Health Score Circle with Pulse Animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                alpha: 0.1 + 0.1 * _animationController.value,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: healthScore,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${(healthScore * 100).toInt()}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 28),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Last updated: 2 hours ago',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: healthScore,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final List<QuickActionItem> actions = [
      const QuickActionItem(
        icon: Icons.analytics,
        title: 'Analytics',
        screen: AnalyticsScreen(),
      ),
      const QuickActionItem(
        icon: Icons.chat,
        title: 'AI Chat',
        screen: ChatScreen(),
      ),
      const QuickActionItem(
        icon: Icons.local_gas_station,
        title: 'Fuel Entry',
        screen: FuelEntryScreen(),
      ),
      const QuickActionItem(
        icon: Icons.location_on,
        title: 'Find Vehicle',
        screen: VehicleLocatorScreen(
          vehicleId: '1',
          vehicleName: 'Tesla Model 3',
        ),
      ),
      const QuickActionItem(
        icon: Icons.settings_remote,
        title: 'Remote Control',
        screen: RemoteControlScreen(
          vehicleId: '1',
          vehicleName: 'Tesla Model 3',
        ),
      ),
      const QuickActionItem(
        icon: Icons.schedule,
        title: 'Service Scheduler',
        screen: ServiceScheduler(),
      ),
      const QuickActionItem(
        icon: Icons.emergency,
        title: 'Emergency',
        screen: EmergencyResponseSystem(),
      ),
      const QuickActionItem(
        icon: Icons.navigation,
        title: 'Navigation',
        screen: AdvancedNavigationScreen(),
      ),
      const QuickActionItem(
        icon: Icons.settings,
        title: 'Settings',
        screen: NotificationSettingsScreen(),
      ),
      const QuickActionItem(
        icon: Icons.monitor_heart,
        title: 'Telemetry',
        screen: TelemetryScreen(vehicleId: '1'),
      ),
      const QuickActionItem(
        icon: Icons.calendar_today,
        title: 'Book Service',
        screen: ServiceBookingScreen(vehicleId: '1'),
      ),
      const QuickActionItem(
        icon: Icons.assessment,
        title: 'RCA Reports',
        screen: RCAReportsScreen(vehicleId: '1'),
      ),
      const QuickActionItem(
        icon: Icons.mic,
        title: 'Voice Demo',
        screen: VoiceDemoScreen(),
      ),
      const QuickActionItem(
        icon: Icons.search,
        title: 'Diagnostics',
        screen: TelemetryScreen(vehicleId: '1'),
      ),
    ];

    // Colorful gradients for modern theme
    final List<List<Color>> gradientColors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)], // Purple to Blue
      [const Color(0xFFF093FB), const Color(0xFFF5576C)], // Pink to Red
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Blue to Cyan
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)], // Green to Cyan
      [const Color(0xFFFA709A), const Color(0xFFFEE140)], // Pink to Yellow
      [const Color(0xFFA8EDEA), const Color(0xFFFDC1B7)], // Light Blue to Pink
      [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)], // Red to Pink
      [
        const Color(0xFF667EEA),
        const Color(0xFF764BA2),
      ], // Repeat Purple to Blue
      [const Color(0xFFF093FB), const Color(0xFFF5576C)], // Repeat Pink to Red
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Repeat Blue to Cyan
      [
        const Color(0xFF43E97B),
        const Color(0xFF38F9D7),
      ], // Repeat Green to Cyan
      [
        const Color(0xFFFA709A),
        const Color(0xFFFEE140),
      ], // Repeat Pink to Yellow
      [
        const Color(0xFFA8EDEA),
        const Color(0xFFFDC1B7),
      ], // Repeat Light Blue to Pink
      [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)], // Repeat Red to Pink
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flash_on,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 5 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final QuickActionItem action = actions[index];
                final delay = index * 80; // Faster stagger
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _staggeredAnimationController,
                    curve: Interval(
                      delay / 1000.0, // Adjusted for faster animation
                      1.0,
                      curve: Curves.elasticOut,
                    ),
                  ),
                );

                final colors = gradientColors[index % gradientColors.length];

                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * animation.value,
                        child: _AnimatedInteractiveContainer(
                          onTap: () => _navigateToAction(action.screen),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colors[0].withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: colors[0].withValues(alpha: 0.2),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    action.icon,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  action.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    final alerts = [
      {
        'title': 'Oil Change Due',
        'description': 'Your vehicle is due for an oil change in 500 miles',
        'severity': 'medium',
        'time': '2 hours ago',
        'icon': Icons.oil_barrel,
      },
      {
        'title': 'Tire Pressure Low',
        'description': 'Front left tire pressure is below recommended level',
        'severity': 'high',
        'time': '1 day ago',
        'icon': Icons.tire_repair,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Recent Alerts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _navigateToAlerts(),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            final severity = alert['severity'] as String;
            final alertColor = _getAlertColor(severity);

            return AnimatedBuilder(
              animation: _staggeredAnimationController,
              builder: (context, child) {
                final delay = (index + 10) * 100; // After quick actions
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _staggeredAnimationController,
                    curve: Interval(
                      delay / 1000.0,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: Transform.translate(
                    offset: Offset(30 * (1 - animation.value), 0),
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: index < alerts.length - 1 ? 16 : 0,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: alertColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: alertColor.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  alertColor.withValues(alpha: 0.2),
                                  alertColor.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: alertColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              alert['icon'] as IconData? ??
                                  _getAlertIcon(severity),
                              color: alertColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert['title'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            alertColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        severity.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: alertColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert['description'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        height: 1.4,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      alert['time'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceOverview(Map<String, dynamic> vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPerformanceMetric(
                'Fuel Efficiency',
                '32.5 MPG',
                0.825,
                Icons.local_gas_station,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 20),
              _buildPerformanceMetric(
                'Engine Health',
                '95%',
                0.95,
                Icons.settings,
                const Color(0xFF2196F3),
              ),
              const SizedBox(height: 20),
              _buildPerformanceMetric(
                'Battery Status',
                '87%',
                0.87,
                Icons.battery_charging_full,
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(
    String title,
    String value,
    double progress,
    IconData icon,
    Color accentColor,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                    fontSize: 14,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress * _animationController.value,
                        backgroundColor: accentColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String severity) {
    switch (severity) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.notifications;
      default:
        return Icons.circle;
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    // Refresh data logic here
  }

  void _navigateToNotifications() {
    Navigator.of(context).pushNamed('/notifications');
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  void _navigateToAction(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateToAlerts() {
    Navigator.of(context).pushNamed('/alerts');
  }
}

