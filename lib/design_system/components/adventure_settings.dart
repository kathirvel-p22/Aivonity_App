import 'package:flutter/material.dart';
import '../theme.dart';

/// Advanced Adventure-themed Settings Interface
/// Provides comprehensive settings management with adventure styling

/// Settings categories for adventure app
enum AdventureSettingsCategory {
  profile,
  notifications,
  privacy,
  adventure,
  equipment,
  social,
  support,
}

/// Settings item types
enum AdventureSettingsItemType {
  toggle,
  selection,
  action,
  navigation,
  slider,
  checkbox,
}

/// Adventure settings item model
class AdventureSettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final AdventureSettingsItemType type;
  final List<String>? options;
  final dynamic value;
  final VoidCallback? onTap;
  final ValueChanged<dynamic>? onChanged;
  final bool enabled;
  final Color? iconColor;

  const AdventureSettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    this.options,
    this.value,
    this.onTap,
    this.onChanged,
    this.enabled = true,
    this.iconColor,
  });
}

/// Adventure settings section component
class AdventureSettingsSection extends StatelessWidget {
  final String title;
  final List<AdventureSettingsItem> items;
  final IconData? sectionIcon;

  const AdventureSettingsSection({
    super.key,
    required this.title,
    required this.items,
    this.sectionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          if (sectionIcon != null) ...[
            Row(
              children: [
                Icon(
                  sectionIcon,
                  color: AivonityTheme.primaryAlpineBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AivonityTheme.primaryAlpineBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AivonityTheme.primaryAlpineBlue,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Settings items
          ...items.map((item) => _buildSettingsItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, AdventureSettingsItem item) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.enabled ? item.onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: item.enabled ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AivonityTheme.primaryAlpineBlue.withValues(alpha:0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AivonityTheme.primaryAlpineBlue.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (item.iconColor ?? AivonityTheme.primaryAlpineBlue)
                            .withValues(alpha:0.1),
                        (item.iconColor ?? AivonityTheme.primaryAlpineBlue)
                            .withValues(alpha:0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (item.iconColor ?? AivonityTheme.primaryAlpineBlue)
                          .withValues(alpha:0.2),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.enabled
                        ? (item.iconColor ?? AivonityTheme.primaryAlpineBlue)
                        : Colors.grey,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: item.enabled
                              ? theme.colorScheme.onSurface
                              : Colors.grey,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: item.enabled
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Control based on type
                _buildControl(context, item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControl(BuildContext context, AdventureSettingsItem item) {
    switch (item.type) {
      case AdventureSettingsItemType.toggle:
        return Switch(
          value: item.value ?? false,
          onChanged: item.enabled ? item.onChanged : null,
          activeThumbColor: AivonityTheme.primaryAlpineBlue,
        );

      case AdventureSettingsItemType.selection:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.value?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AivonityTheme.primaryAlpineBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AivonityTheme.primaryAlpineBlue),
          ],
        );

      case AdventureSettingsItemType.action:
        return Icon(
          Icons.arrow_forward_ios,
          color: AivonityTheme.primaryAlpineBlue,
          size: 16,
        );

      case AdventureSettingsItemType.navigation:
        return Icon(
          Icons.chevron_right,
          color: AivonityTheme.primaryAlpineBlue,
        );

      case AdventureSettingsItemType.slider:
        return SizedBox(
          width: 100,
          child: Slider(
            value: item.value?.toDouble() ?? 0,
            onChanged: item.enabled ? item.onChanged : null,
            activeColor: AivonityTheme.primaryAlpineBlue,
          ),
        );

      case AdventureSettingsItemType.checkbox:
        return Checkbox(
          value: item.value ?? false,
          onChanged: item.enabled ? item.onChanged : null,
          activeColor: AivonityTheme.primaryAlpineBlue,
        );
    }
  }
}

/// Complete adventure settings screen
class AdventureSettingsScreen extends StatefulWidget {
  const AdventureSettingsScreen({super.key});

  @override
  State<AdventureSettingsScreen> createState() =>
      _AdventureSettingsScreenState();
}

class _AdventureSettingsScreenState extends State<AdventureSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _highContrast = false;
  double _textSize = 1.0;
  String _selectedLanguage = 'English';
  String _selectedUnits = 'Metric';
  String _selectedTheme = 'Auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AivonityTheme.neutralMistGray,
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AivonityTheme.primaryAlpineBlue,
                      AivonityTheme.primaryBlueLight,
                    ],
                  ),
                ),
              ),
              title: Text(
                'Adventure Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
            backgroundColor: AivonityTheme.primaryAlpineBlue,
            foregroundColor: Colors.white,
          ),

          // Settings sections
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Settings
                AdventureSettingsSection(
                  title: 'Profile & Account',
                  sectionIcon: Icons.person,
                  items: [
                    AdventureSettingsItem(
                      title: 'Edit Profile',
                      subtitle: 'Update your adventure profile',
                      icon: Icons.edit,
                      type: AdventureSettingsItemType.action,
                      onTap: () => _navigateToEditProfile(),
                    ),
                    AdventureSettingsItem(
                      title: 'Privacy Settings',
                      subtitle: 'Manage your privacy preferences',
                      icon: Icons.privacy_tip,
                      type: AdventureSettingsItemType.navigation,
                      onTap: () => _navigateToPrivacy(),
                    ),
                    AdventureSettingsItem(
                      title: 'Sync Data',
                      subtitle: 'Synchronize across devices',
                      icon: Icons.sync,
                      type: AdventureSettingsItemType.action,
                      onTap: () => _syncData(),
                    ),
                  ],
                ),

                // Adventure Settings
                AdventureSettingsSection(
                  title: 'Adventure Preferences',
                  sectionIcon: Icons.explore,
                  items: [
                    AdventureSettingsItem(
                      title: 'Auto-location Tracking',
                      subtitle: 'Enable GPS for adventure logging',
                      icon: Icons.location_on,
                      type: AdventureSettingsItemType.toggle,
                      value: _locationEnabled,
                      onChanged: (value) =>
                          setState(() => _locationEnabled = value),
                      iconColor: AivonityTheme.accentPineGreen,
                    ),
                    AdventureSettingsItem(
                      title: 'Adventure Notifications',
                      subtitle: 'Get updates on your adventures',
                      icon: Icons.notifications_active,
                      type: AdventureSettingsItemType.toggle,
                      value: _notificationsEnabled,
                      onChanged: (value) =>
                          setState(() => _notificationsEnabled = value),
                      iconColor: AivonityTheme.accentSummitOrange,
                    ),
                    AdventureSettingsItem(
                      title: 'Measurement Units',
                      subtitle: _selectedUnits,
                      icon: Icons.straighten,
                      type: AdventureSettingsItemType.selection,
                      value: _selectedUnits,
                      onTap: () => _showUnitsSelection(),
                      iconColor: AivonityTheme.accentMountainGray,
                    ),
                  ],
                ),

                // Appearance Settings
                AdventureSettingsSection(
                  title: 'Appearance & Accessibility',
                  sectionIcon: Icons.palette,
                  items: [
                    AdventureSettingsItem(
                      title: 'Theme',
                      subtitle: _selectedTheme,
                      icon: Icons.dark_mode,
                      type: AdventureSettingsItemType.selection,
                      value: _selectedTheme,
                      onTap: () => _showThemeSelection(),
                      iconColor: AivonityTheme.primaryAlpineBlue,
                    ),
                    AdventureSettingsItem(
                      title: 'Text Size',
                      subtitle: '${(_textSize * 100).round()}%',
                      icon: Icons.text_fields,
                      type: AdventureSettingsItemType.slider,
                      value: _textSize,
                      onChanged: (value) => setState(() => _textSize = value),
                      iconColor: AivonityTheme.accentSunsetCoral,
                    ),
                    AdventureSettingsItem(
                      title: 'High Contrast',
                      subtitle: 'Improve visibility',
                      icon: Icons.contrast,
                      type: AdventureSettingsItemType.toggle,
                      value: _highContrast,
                      onChanged: (value) =>
                          setState(() => _highContrast = value),
                      iconColor: AivonityTheme.accentSummitOrange,
                    ),
                    AdventureSettingsItem(
                      title: 'Language',
                      subtitle: _selectedLanguage,
                      icon: Icons.language,
                      type: AdventureSettingsItemType.selection,
                      value: _selectedLanguage,
                      onTap: () => _showLanguageSelection(),
                      iconColor: AivonityTheme.accentPineGreen,
                    ),
                  ],
                ),

                // Equipment Settings
                AdventureSettingsSection(
                  title: 'Equipment & Gear',
                  sectionIcon: Icons.backpack,
                  items: [
                    AdventureSettingsItem(
                      title: 'Equipment Database',
                      subtitle: 'Manage your gear collection',
                      icon: Icons.inventory,
                      type: AdventureSettingsItemType.navigation,
                      onTap: () => _navigateToEquipment(),
                    ),
                    AdventureSettingsItem(
                      title: 'Maintenance Reminders',
                      subtitle: 'Get alerts for gear maintenance',
                      icon: Icons.build,
                      type: AdventureSettingsItemType.toggle,
                      value: true,
                      iconColor: AivonityTheme.accentMountainGray,
                    ),
                    AdventureSettingsItem(
                      title: 'Gear Recommendations',
                      subtitle: 'AI-powered gear suggestions',
                      icon: Icons.lightbulb,
                      type: AdventureSettingsItemType.toggle,
                      value: true,
                      iconColor: AivonityTheme.accentSunsetCoral,
                    ),
                  ],
                ),

                // Support Settings
                AdventureSettingsSection(
                  title: 'Support & About',
                  sectionIcon: Icons.help,
                  items: [
                    AdventureSettingsItem(
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      icon: Icons.help_center,
                      type: AdventureSettingsItemType.navigation,
                      onTap: () => _navigateToHelp(),
                    ),
                    AdventureSettingsItem(
                      title: 'Send Feedback',
                      subtitle: 'Help us improve the app',
                      icon: Icons.feedback,
                      type: AdventureSettingsItemType.action,
                      onTap: () => _sendFeedback(),
                    ),
                    AdventureSettingsItem(
                      title: 'About Adventure App',
                      subtitle: 'Version 1.0.0',
                      icon: Icons.info,
                      type: AdventureSettingsItemType.action,
                      onTap: () => _showAbout(),
                    ),
                    AdventureSettingsItem(
                      title: 'Sign Out',
                      subtitle: 'Sign out of your account',
                      icon: Icons.logout,
                      type: AdventureSettingsItemType.action,
                      onTap: () => _signOut(),
                      iconColor: AivonityTheme.accentRed,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToEditProfile() {
    // Implementation for editing profile
  }

  void _navigateToPrivacy() {
    // Implementation for privacy settings
  }

  void _navigateToEquipment() {
    // Implementation for equipment management
  }

  void _navigateToHelp() {
    // Implementation for help center
  }

  void _syncData() {
    // Implementation for data synchronization
  }

  void _sendFeedback() {
    // Implementation for sending feedback
  }

  void _signOut() {
    // Implementation for signing out
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Adventure App'),
        content: Text('Version 1.0.0\n\nYour ultimate adventure companion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUnitsSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Units', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...['Metric', 'Imperial'].map(
              (unit) => ListTile(
                title: Text(unit),
                trailing: _selectedUnits == unit
                    ? Icon(Icons.check, color: AivonityTheme.primaryAlpineBlue)
                    : null,
                onTap: () {
                  setState(() => _selectedUnits = unit);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Theme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...['Auto', 'Light', 'Dark'].map(
              (theme) => ListTile(
                title: Text(theme),
                trailing: _selectedTheme == theme
                    ? Icon(Icons.check, color: AivonityTheme.primaryAlpineBlue)
                    : null,
                onTap: () {
                  setState(() => _selectedTheme = theme);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...['English', 'Spanish', 'French', 'German'].map(
              (language) => ListTile(
                title: Text(language),
                trailing: _selectedLanguage == language
                    ? Icon(Icons.check, color: AivonityTheme.primaryAlpineBlue)
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = language);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

