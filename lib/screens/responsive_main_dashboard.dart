import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Responsive main dashboard that adapts to different screen sizes
class ResponsiveMainDashboard extends StatelessWidget {
  const ResponsiveMainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationItems = [
      NavigationItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard,
        builder: (context) => const DashboardContent(),
      ),
      NavigationItem(
        id: 'telemetry',
        label: 'Telemetry',
        icon: Icons.speed,
        builder: (context) => const TelemetryContent(),
      ),
      NavigationItem(
        id: 'monitoring',
        label: 'Monitoring',
        icon: Icons.location_on,
        builder: (context) => const MonitoringContent(),
      ),
      NavigationItem(
        id: 'services',
        label: 'Services',
        icon: Icons.build,
        builder: (context) => const ServicesContent(),
      ),
      NavigationItem(
        id: 'analytics',
        label: 'Analytics',
        icon: Icons.analytics,
        builder: (context) => const AnalyticsContent(),
        showInBottomNav: false, // Only show in drawer/rail for space
      ),
      NavigationItem(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings,
        builder: (context) => const SettingsContent(),
        showInBottomNav: false,
      ),
    ];

    return ResponsiveNavigation(title: 'AIVONITY', items: navigationItems);
  }
}

/// Dashboard content with responsive layout
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(context),
            AivonitySpacing.vGapXL,

            // Quick stats
            _buildQuickStats(context),
            AivonitySpacing.vGapXL,

            // Main features
            _buildMainFeatures(context),
            AivonitySpacing.vGapXL,

            // Recent activity
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveColumns(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to AIVONITY', style: theme.textTheme.headlineLarge),
            AivonitySpacing.vGapSM,
            Text(
              'Your intelligent vehicle assistant',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (AivonityBreakpoints.isDesktop(context))
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const ThemeToggleButton(),
              AivonitySpacing.hGapMD,
              AivonityButton(
                text: 'Settings',
                type: ButtonType.secondary,
                icon: Icons.settings,
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return ResponsiveGrid(
      childAspectRatio: AivonityBreakpoints.isMobile(context) ? 2.5 : 1.5,
      children: [
        MetricCard(
          title: 'Vehicle Health',
          value: '92%',
          subtitle: 'Excellent condition',
          icon: Icons.favorite,
          iconColor: Colors.green,
        ),
        MetricCard(
          title: 'Fuel Level',
          value: '68%',
          subtitle: '~340 miles range',
          icon: Icons.local_gas_station,
          iconColor: Colors.blue,
        ),
        MetricCard(
          title: 'Next Service',
          value: '2,450',
          subtitle: 'miles remaining',
          icon: Icons.build,
          iconColor: Colors.orange,
        ),
        MetricCard(
          title: 'Alerts',
          value: '0',
          subtitle: 'All systems normal',
          icon: Icons.notifications,
          iconColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildMainFeatures(BuildContext context) {
    final features = [
      _FeatureItem(
        title: 'Real-time Telemetry',
        description: 'Monitor your vehicle\'s performance in real-time',
        icon: Icons.speed,
        route: '/telemetry',
      ),
      _FeatureItem(
        title: 'Remote Monitoring',
        description: 'Track location and security status',
        icon: Icons.location_on,
        route: '/remote-monitoring',
      ),
      _FeatureItem(
        title: 'Service Centers',
        description: 'Find and book nearby service appointments',
        icon: Icons.map,
        route: '/service-centers',
      ),
      _FeatureItem(
        title: 'Analytics',
        description: 'Detailed performance and maintenance insights',
        icon: Icons.analytics,
        route: '/analytics',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features', style: Theme.of(context).textTheme.headlineMedium),
        AivonitySpacing.vGapMD,
        ResponsiveGrid(
          childAspectRatio: AivonityBreakpoints.isMobile(context) ? 1.2 : 1.0,
          children: features
              .map((feature) => _buildFeatureCard(context, feature))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem feature) {
    return AnimatedInteractiveContainer(
      onTap: () => Navigator.pushNamed(context, feature.route),
      child: AivonityCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              feature.icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            AivonitySpacing.vGapMD,
            Text(feature.title, style: Theme.of(context).textTheme.titleMedium),
            AivonitySpacing.vGapSM,
            Expanded(
              child: Text(
                feature.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AivonitySpacing.vGapMD,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        AivonitySpacing.vGapMD,
        AivonityCard(
          child: Column(
            children: [
              _buildActivityItem(
                context,
                'Vehicle Health Check',
                'Completed successfully',
                Icons.check_circle,
                Colors.green,
                '2 hours ago',
              ),
              const Divider(),
              _buildActivityItem(
                context,
                'Service Reminder',
                'Oil change due in 500 miles',
                Icons.build,
                Colors.orange,
                '1 day ago',
              ),
              const Divider(),
              _buildActivityItem(
                context,
                'Trip Summary',
                'Last trip: 45.2 miles, 32.1 MPG',
                Icons.route,
                Colors.blue,
                '2 days ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    String time,
  ) {
    return Padding(
      padding: AivonitySpacing.verticalSM,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          AivonitySpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final String route;

  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });
}

// Placeholder content widgets for other navigation items
class TelemetryContent extends StatelessWidget {
  const TelemetryContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            AivonitySpacing.vGapMD,
            Text(
              'Telemetry Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AivonitySpacing.vGapSM,
            Text(
              'Real-time vehicle data and diagnostics',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AivonitySpacing.vGapXL,
            AivonityButton(
              text: 'View Full Dashboard',
              onPressed: () => Navigator.pushNamed(context, '/telemetry'),
            ),
          ],
        ),
      ),
    );
  }
}

class MonitoringContent extends StatelessWidget {
  const MonitoringContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            AivonitySpacing.vGapMD,
            Text(
              'Remote Monitoring',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AivonitySpacing.vGapSM,
            Text(
              'Location tracking and security monitoring',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AivonitySpacing.vGapXL,
            AivonityButton(
              text: 'View Monitoring',
              onPressed: () =>
                  Navigator.pushNamed(context, '/remote-monitoring'),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicesContent extends StatelessWidget {
  const ServicesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            AivonitySpacing.vGapMD,
            Text(
              'Service Centers',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AivonitySpacing.vGapSM,
            Text(
              'Find nearby service centers and book appointments',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AivonitySpacing.vGapXL,
            AivonityButton(
              text: 'Find Services',
              onPressed: () => Navigator.pushNamed(context, '/service-centers'),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsContent extends StatelessWidget {
  const AnalyticsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            AivonitySpacing.vGapMD,
            Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AivonitySpacing.vGapSM,
            Text(
              'Performance metrics and trend analysis',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AivonitySpacing.vGapXL,
            AivonityButton(
              text: 'View Analytics',
              onPressed: () => Navigator.pushNamed(context, '/analytics'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            AivonitySpacing.vGapMD,
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            AivonitySpacing.vGapSM,
            Text(
              'Customize your app experience',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AivonitySpacing.vGapXL,
            AivonityButton(
              text: 'Open Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

