import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric Authentication Button Widget
/// Displays appropriate biometric authentication option based on available biometrics
class BiometricAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final List<BiometricType> availableBiometrics;

  const BiometricAuthButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.availableBiometrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (availableBiometrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasFingerprint =
        availableBiometrics.contains(BiometricType.fingerprint);
    final hasFace = availableBiometrics.contains(BiometricType.face);

    IconData icon;
    String text;

    if (hasFingerprint && hasFace) {
      icon = Icons.fingerprint;
      text = 'Use Biometric Authentication';
    } else if (hasFingerprint) {
      icon = Icons.fingerprint;
      text = 'Use Fingerprint';
    } else if (hasFace) {
      icon = Icons.face;
      text = 'Use Face Recognition';
    } else {
      icon = Icons.security;
      text = 'Use Biometric Authentication';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Floating Biometric Authentication Button
/// Circular floating button for quick biometric authentication
class BiometricFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final List<BiometricType> availableBiometrics;

  const BiometricFloatingButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.availableBiometrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (availableBiometrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasFingerprint =
        availableBiometrics.contains(BiometricType.fingerprint);
    final hasFace = availableBiometrics.contains(BiometricType.face);

    IconData icon;
    if (hasFingerprint) {
      icon = Icons.fingerprint;
    } else if (hasFace) {
      icon = Icons.face;
    } else {
      icon = Icons.security;
    }

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(icon, size: 28),
    );
  }
}

/// Biometric Authentication Tile
/// List tile for settings screen to enable/disable biometric authentication
class BiometricAuthTile extends StatelessWidget {
  final bool isEnabled;
  final bool isAvailable;
  final VoidCallback? onToggle;
  final List<BiometricType> availableBiometrics;

  const BiometricAuthTile({
    super.key,
    required this.isEnabled,
    required this.isAvailable,
    this.onToggle,
    this.availableBiometrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    final hasFingerprint =
        availableBiometrics.contains(BiometricType.fingerprint);
    final hasFace = availableBiometrics.contains(BiometricType.face);

    String title;
    String subtitle;
    IconData icon;

    if (hasFingerprint && hasFace) {
      title = 'Biometric Authentication';
      subtitle = 'Use fingerprint or face recognition to sign in';
      icon = Icons.fingerprint;
    } else if (hasFingerprint) {
      title = 'Fingerprint Authentication';
      subtitle = 'Use your fingerprint to sign in';
      icon = Icons.fingerprint;
    } else if (hasFace) {
      title = 'Face Recognition';
      subtitle = 'Use face recognition to sign in';
      icon = Icons.face;
    } else {
      title = 'Biometric Authentication';
      subtitle = 'Use biometric authentication to sign in';
      icon = Icons.security;
    }

    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isEnabled,
        onChanged: onToggle != null ? (_) => onToggle!() : null,
      ),
      onTap: onToggle,
    );
  }
}

