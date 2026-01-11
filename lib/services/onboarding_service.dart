import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/design_system.dart';

/// Service to manage onboarding flow
class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _appVersionKey = 'app_version';
  static const String currentVersion = '1.0.0';

  /// Check if onboarding should be shown
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_onboardingKey) ?? false;
    final lastVersion = prefs.getString(_appVersionKey) ?? '';

    // Show onboarding if never completed or if app version changed
    return !completed || lastVersion != currentVersion;
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    await prefs.setString(_appVersionKey, currentVersion);
  }

  /// Show onboarding if needed
  static Future<void> showOnboardingIfNeeded(BuildContext context) async {
    if (await shouldShowOnboarding()) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingScreen(
              steps: _getOnboardingSteps(),
              onComplete: () {
                completeOnboarding();
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    }
  }

  static List<OnboardingStep> _getOnboardingSteps() {
    return [
      const OnboardingStep(
        title: 'Welcome to AIVONITY',
        description:
            'Your intelligent vehicle assistant that helps you monitor, maintain, and optimize your vehicle\'s performance.',
        icon: Icons.directions_car,
        color: Colors.blue,
        bulletPoints: [
          'Real-time vehicle monitoring',
          'Predictive maintenance alerts',
          'Service center recommendations',
          'Comprehensive analytics',
        ],
      ),
      const OnboardingStep(
        title: 'Connect Your Vehicle',
        description:
            'Start by connecting your vehicle to unlock all features and begin monitoring your vehicle\'s health.',
        icon: Icons.bluetooth,
        color: Colors.green,
        bulletPoints: [
          'Secure OBD-II connection',
          'Automatic data synchronization',
          'Real-time diagnostics',
        ],
      ),
      const OnboardingStep(
        title: 'Explore Features',
        description:
            'Discover powerful features like telemetry monitoring, service scheduling, and predictive analytics.',
        icon: Icons.explore,
        color: Colors.purple,
        bulletPoints: [
          'Interactive dashboard',
          'Smart recommendations',
          'Performance insights',
        ],
      ),
      const OnboardingStep(
        title: 'Stay Informed',
        description:
            'Receive timely alerts and notifications to keep your vehicle in optimal condition.',
        icon: Icons.notifications_active,
        color: Colors.orange,
        bulletPoints: [
          'Maintenance reminders',
          'Performance alerts',
          'Service notifications',
        ],
      ),
      const OnboardingStep(
        title: 'You\'re All Set!',
        description:
            'Start exploring AIVONITY and discover how it can help you take better care of your vehicle.',
        icon: Icons.check_circle,
        color: Colors.green,
      ),
    ];
  }
}

