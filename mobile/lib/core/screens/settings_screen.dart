import 'package:flutter/material.dart';

/// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            'Account',
            [
              _buildSettingsTile(
                context,
                Icons.person_outline,
                'Profile',
                'Manage your profile information',
                () {},
              ),
              _buildSettingsTile(
                context,
                Icons.security,
                'Privacy & Security',
                'Manage your privacy settings',
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            'Preferences',
            [
              _buildSettingsTile(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Configure notification preferences',
                () {},
              ),
              _buildSettingsTile(
                context,
                Icons.dark_mode_outlined,
                'Theme',
                'Choose your preferred theme',
                () {},
              ),
              _buildSettingsTile(
                context,
                Icons.language,
                'Language',
                'Select your preferred language',
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            'Vehicle',
            [
              _buildSettingsTile(
                context,
                Icons.directions_car,
                'My Vehicles',
                'Manage your registered vehicles',
                () {},
              ),
              _buildSettingsTile(
                context,
                Icons.build,
                'Service Centers',
                'Find nearby service centers',
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            'Support',
            [
              _buildSettingsTile(
                context,
                Icons.help_outline,
                'Help & Support',
                'Get help and contact support',
                () {},
              ),
              _buildSettingsTile(
                context,
                Icons.info_outline,
                'About',
                'App version and information',
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}

