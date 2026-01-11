import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import 'social_login_button.dart';

/// Social Login Section Widget
/// Contains Google and Apple Sign-In buttons with proper platform handling
class SocialLoginSection extends ConsumerWidget {
  const SocialLoginSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);
    final isLoading = authState is AuthLoading;

    return Column(
      children: [
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

        const SizedBox(height: 24),

        // Google Sign-In Button
        SocialLoginButton.google(
          onPressed: () => _handleGoogleSignIn(context, authNotifier),
          isLoading: isLoading,
        ),

        const SizedBox(height: 16),

        // Apple Sign-In Button (iOS only, not on web)
        if (!kIsWeb && Platform.isIOS) ...[
          SocialLoginButton.apple(
            onPressed: () => _handleAppleSignIn(context, authNotifier),
            isLoading: isLoading,
          ),
        ],

        const SizedBox(height: 24),

        // Privacy notice
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'By continuing, you agree to our Terms of Service and Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _handleGoogleSignIn(
    BuildContext context,
    AuthNotifier authNotifier,
  ) async {
    try {
      await authNotifier.signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Google Sign-In failed. Please try again.');
      }
    }
  }

  void _handleAppleSignIn(
    BuildContext context,
    AuthNotifier authNotifier,
  ) async {
    try {
      await authNotifier.signInWithApple();
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Apple Sign-In failed. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
