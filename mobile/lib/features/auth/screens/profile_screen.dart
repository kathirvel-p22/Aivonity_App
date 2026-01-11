import 'package:flutter/material.dart';

/// AIVONITY Profile Screen
/// User profile management interface
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+1 (555) 123-4567',
    'avatarUrl': null,
    'isVerified': true,
    'language': 'English',
    'role': 'Premium User',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildProfileInfo(),
            const SizedBox(height: 32),
            _buildSettingsSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: const Text('Profile'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditProfileDialog(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: _userData['avatarUrl'] != null
                    ? NetworkImage(_userData['avatarUrl'] as String)
                    : null,
                child: _userData['avatarUrl'] == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white.withValues(alpha: 0.8),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (_userData['name'] as String?) ?? 'Unknown User',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_userData['isVerified'] == true) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: Colors.white, size: 20),
              ],
            ],
          ),

          const SizedBox(height: 8),

          Text(
            (_userData['role'] as String?) ?? 'User',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
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
            'Personal Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            'Full Name',
            (_userData['name'] as String?) ?? 'Not provided',
            Icons.person_outline,
          ),
          const Divider(height: 32),
          _buildInfoItem(
            'Email Address',
            (_userData['email'] as String?) ?? 'Not provided',
            Icons.email_outlined,
          ),
          const Divider(height: 32),
          _buildInfoItem(
            'Phone Number',
            (_userData['phone'] as String?) ?? 'Not provided',
            Icons.phone_outlined,
          ),
          const Divider(height: 32),
          _buildInfoItem(
            'Language',
            (_userData['language'] as String?) ?? 'English',
            Icons.language,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editField(title, value),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
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
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            'Notifications',
            'Manage your notification preferences',
            Icons.notifications_outlined,
            () => _navigateToNotifications(),
          ),
          const Divider(height: 32),
          _buildSettingItem(
            'Privacy & Security',
            'Control your privacy settings',
            Icons.security,
            () => _navigateToPrivacy(),
          ),
          const Divider(height: 32),
          _buildSettingItem(
            'Language',
            'Change app language',
            Icons.language,
            () => _showLanguageDialog(),
          ),
          const Divider(height: 32),
          _buildSettingItem(
            'Help & Support',
            'Get help and contact support',
            Icons.help_outline,
            () => _navigateToSupport(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Change Password Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showChangePasswordDialog(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Change Password'),
          ),
        ),

        const SizedBox(height: 16),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showLogoutDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editField(String field, String currentValue) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextFormField(
          initialValue: currentValue,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Perform logout
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: const Text('Hindi'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.of(context).pushNamed('/notifications');
  }

  void _navigateToPrivacy() {
    Navigator.of(context).pushNamed('/privacy');
  }

  void _navigateToSupport() {
    Navigator.of(context).pushNamed('/support');
  }
}

