import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Settings screen with theme and accessibility options
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: AivonitySpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            Text('Appearance', style: theme.textTheme.headlineSmall),
            AivonitySpacing.vGapMD,

            AivonityCard(
              child: Column(
                children: [
                  const ThemeToggleButton(showLabel: true),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('Choose your preferred theme'),
                    trailing: _buildThemeModeSelector(context),
                  ),
                ],
              ),
            ),

            AivonitySpacing.vGapXL,

            // Accessibility Section
            Text('Accessibility', style: theme.textTheme.headlineSmall),
            AivonitySpacing.vGapMD,

            AivonityCard(child: const AccessibilitySettings()),

            AivonitySpacing.vGapXL,

            // Dashboard Customization Section
            Text('Dashboard', style: theme.textTheme.headlineSmall),
            AivonitySpacing.vGapMD,

            AivonityCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.grid_view_rounded),
                    title: const Text('Responsive Dashboard'),
                    subtitle: const Text('Try the new adaptive layout'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () =>
                        Navigator.pushNamed(context, '/responsive-dashboard'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize),
                    title: const Text('Customize Dashboard'),
                    subtitle: const Text('Arrange and hide dashboard widgets'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showDashboardCustomization(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Reset Dashboard'),
                    subtitle: const Text('Restore default dashboard layout'),
                    onTap: () => _showResetConfirmation(context),
                  ),
                ],
              ),
            ),

            AivonitySpacing.vGapXL,

            // About Section
            Text('About', style: theme.textTheme.headlineSmall),
            AivonitySpacing.vGapMD,

            AivonityCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showHelpDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showPrivacyDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context) {
    final themeManager = ThemeProvider.of(context);
    if (themeManager == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, child) {
        return DropdownButton<ThemeMode>(
          value: themeManager.themeMode,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          ],
          onChanged: (mode) {
            if (mode != null) {
              themeManager.setThemeMode(mode);
            }
          },
        );
      },
    );
  }

  void _showDashboardCustomization(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Customization'),
        content: const Text(
          'Dashboard customization allows you to:\n\n'
          '• Reorder widgets by dragging\n'
          '• Hide/show widgets\n'
          '• Reset to default layout\n\n'
          'This feature will be available in the main dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Dashboard'),
        content: const Text(
          'This will restore the dashboard to its default layout. '
          'All customizations will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard reset to default layout'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Getting Started',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Connect your vehicle to start monitoring'),
              Text('• Explore the dashboard for real-time data'),
              Text('• Use the AI chat for assistance'),
              SizedBox(height: 16),
              Text('Features', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Real-time telemetry monitoring'),
              Text('• Service center finder'),
              Text('• Predictive analytics'),
              Text('• Comprehensive reporting'),
              SizedBox(height: 16),
              Text(
                'Contact Support',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Email: support@aivonity.com'),
              Text('Phone: 1-800-AIVONITY'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'AIVONITY Privacy Policy\n\n'
            'We are committed to protecting your privacy and ensuring the security of your personal information.\n\n'
            'Data Collection:\n'
            '• Vehicle telemetry data for monitoring and analytics\n'
            '• Location data for service center recommendations\n'
            '• Usage data to improve our services\n\n'
            'Data Usage:\n'
            '• Provide real-time vehicle monitoring\n'
            '• Generate maintenance recommendations\n'
            '• Improve service quality\n\n'
            'Data Protection:\n'
            '• All data is encrypted in transit and at rest\n'
            '• We do not sell your personal information\n'
            '• You can request data deletion at any time\n\n'
            'For the complete privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

