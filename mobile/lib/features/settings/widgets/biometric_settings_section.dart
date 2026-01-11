import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/providers/service_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/widgets/biometric_auth_button.dart';

/// Biometric Settings Section Widget
/// Allows users to enable/disable biometric authentication in settings
class BiometricSettingsSection extends ConsumerStatefulWidget {
  const BiometricSettingsSection({super.key});

  @override
  ConsumerState<BiometricSettingsSection> createState() =>
      _BiometricSettingsSectionState();
}

class _BiometricSettingsSectionState
    extends ConsumerState<BiometricSettingsSection> {
  bool _isAvailable = false;
  bool _isEnabled = false;
  bool _isLoading = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final biometricService = ref.read(biometricAuthServiceProvider);
      final authNotifier = ref.read(authStateProvider.notifier);

      final isAvailable = await biometricService.isBiometricAvailable();
      final isEnabled = await authNotifier.isBiometricEnabled();
      final availableBiometrics =
          await biometricService.getAvailableBiometrics();

      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _isEnabled = isEnabled;
          _availableBiometrics = availableBiometrics;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biometric Authentication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use your fingerprint or face recognition to quickly and securely access your account.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),

            // Biometric Authentication Toggle
            BiometricAuthTile(
              isEnabled: _isEnabled,
              isAvailable: _isAvailable,
              availableBiometrics: _availableBiometrics,
              onToggle: _isLoading ? null : _handleToggleBiometric,
            ),
          ],
        ),
      ),
    );
  }

  void _handleToggleBiometric() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);

      if (_isEnabled) {
        // Disable biometric
        await authNotifier.disableBiometric();
        setState(() {
          _isEnabled = false;
        });
        _showSuccessSnackBar('Biometric authentication disabled');
      } else {
        // Enable biometric
        await authNotifier.enableBiometric();

        // Check if it was successfully enabled
        final isNowEnabled = await authNotifier.isBiometricEnabled();
        setState(() {
          _isEnabled = isNowEnabled;
        });

        if (isNowEnabled) {
          _showSuccessSnackBar('Biometric authentication enabled');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update biometric settings');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

