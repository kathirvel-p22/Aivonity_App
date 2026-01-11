import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/providers/service_providers.dart';
import '../../../providers/auth_provider.dart';
import 'biometric_auth_button.dart';

/// Biometric Authentication Section Widget
/// Shows biometric authentication options if available and enabled
class BiometricAuthSection extends ConsumerStatefulWidget {
  const BiometricAuthSection({super.key});

  @override
  ConsumerState<BiometricAuthSection> createState() =>
      _BiometricAuthSectionState();
}

class _BiometricAuthSectionState extends ConsumerState<BiometricAuthSection> {
  bool _isAvailable = false;
  bool _isEnabled = false;
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
      // Handle error silently - biometric section will just not show
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);
    final isLoading = authState is AuthLoading;

    // Don't show if biometric is not available or not enabled
    if (!_isAvailable || !_isEnabled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),

        // Divider with "OR" text
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 16),

        // Biometric Authentication Button
        BiometricAuthButton(
          onPressed: () => _handleBiometricAuth(authNotifier),
          isLoading: isLoading,
          availableBiometrics: _availableBiometrics,
        ),

        const SizedBox(height: 8),

        // Quick access buttons for specific biometric types
        if (_availableBiometrics.length > 1) ...[
          Row(
            children: [
              if (_availableBiometrics.contains(BiometricType.fingerprint)) ...[
                Expanded(
                  child: TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _handleFingerprintAuth(authNotifier),
                    icon: const Icon(Icons.fingerprint, size: 20),
                    label: const Text('Fingerprint'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              if (_availableBiometrics.contains(BiometricType.face)) ...[
                if (_availableBiometrics.contains(BiometricType.fingerprint))
                  const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        isLoading ? null : () => _handleFaceAuth(authNotifier),
                    icon: const Icon(Icons.face, size: 20),
                    label: const Text('Face ID'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _handleBiometricAuth(AuthNotifier authNotifier) async {
    try {
      await authNotifier.authenticateWithBiometric();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Biometric authentication failed. Please try again.',);
      }
    }
  }

  void _handleFingerprintAuth(AuthNotifier authNotifier) async {
    try {
      await authNotifier.authenticateWithFingerprint();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Fingerprint authentication failed. Please try again.',);
      }
    }
  }

  void _handleFaceAuth(AuthNotifier authNotifier) async {
    try {
      await authNotifier.authenticateWithFace();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Face recognition failed. Please try again.');
      }
    }
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

