import 'package:flutter/material.dart';

/// AIVONITY Notification Settings Screen
/// Manage notification preferences and settings
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification settings state
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Category settings
  bool _maintenanceAlerts = true;
  bool _healthAlerts = true;
  bool _serviceReminders = true;

  // Timing settings
  bool _quietHours = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // In a real app, load settings from storage/API
    // For now, using default values
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Notification Settings'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: 32),
            _buildCategorySettings(),
            const SizedBox(height: 32),
            _buildTimingSettings(),
            const SizedBox(height: 32),
            _buildTestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      title: 'General Settings',
      children: [
        _buildSwitchTile(
          title: 'Push Notifications',
          subtitle: 'Receive notifications on your device',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Email Notifications',
          subtitle: 'Receive notifications via email',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'SMS Notifications',
          subtitle: 'Receive critical alerts via SMS',
          value: _smsNotifications,
          onChanged: (value) {
            setState(() {
              _smsNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySettings() {
    return _buildSection(
      title: 'Notification Categories',
      children: [
        _buildSwitchTile(
          title: 'Maintenance Alerts',
          subtitle: 'Upcoming maintenance and service reminders',
          value: _maintenanceAlerts,
          onChanged: (value) {
            setState(() {
              _maintenanceAlerts = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Health Alerts',
          subtitle: 'Vehicle health and diagnostic notifications',
          value: _healthAlerts,
          onChanged: (value) {
            setState(() {
              _healthAlerts = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Service Reminders',
          subtitle: 'Appointment confirmations and reminders',
          value: _serviceReminders,
          onChanged: (value) {
            setState(() {
              _serviceReminders = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimingSettings() {
    return _buildSection(
      title: 'Timing & Schedule',
      children: [
        _buildSwitchTile(
          title: 'Quiet Hours',
          subtitle: 'Disable non-critical notifications during quiet hours',
          value: _quietHours,
          onChanged: (value) {
            setState(() {
              _quietHours = value;
            });
          },
        ),
        if (_quietHours) ...[
          const SizedBox(height: 16),
          _buildTimePicker(
            title: 'Quiet Hours Start',
            time: _quietStart,
            onChanged: (time) {
              setState(() {
                _quietStart = time;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTimePicker(
            title: 'Quiet Hours End',
            time: _quietEnd,
            onChanged: (time) {
              setState(() {
                _quietEnd = time;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTestSection() {
    return _buildSection(
      title: 'Test Notifications',
      children: [
        ListTile(
          leading: const Icon(Icons.notifications_active),
          title: const Text('Send Test Notification'),
          subtitle: const Text('Test your notification settings'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _sendTestNotification,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTimePicker({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time.format(context)),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.white),
            SizedBox(width: 12),
            Text('Test notification sent!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _saveSettings() async {
    // Show loading indicator
    setState(() {
      // In a real app, set loading state
    });

    try {
      // Simulate API call to save settings
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Settings saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

