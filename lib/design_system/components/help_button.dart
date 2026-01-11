import 'package:flutter/material.dart';
import '../design_system.dart';

/// Floating help button that provides contextual assistance
class HelpButton extends StatelessWidget {
  final String? helpContext;
  final bool showOnboarding;

  const HelpButton({super.key, this.helpContext, this.showOnboarding = true});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      onPressed: () => _showHelpMenu(context),
      child: const Icon(Icons.help_outline),
    );
  }

  void _showHelpMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => HelpBottomSheet(
        helpContext: helpContext,
        showOnboarding: showOnboarding,
      ),
    );
  }
}

/// Bottom sheet with help options
class HelpBottomSheet extends StatelessWidget {
  final String? helpContext;
  final bool showOnboarding;

  const HelpBottomSheet({
    super.key,
    this.helpContext,
    this.showOnboarding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AivonitySpacing.paddingLG,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          AivonitySpacing.vGapMD,

          // Title
          Text(
            helpContext != null ? 'Help: $helpContext' : 'Help & Support',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          AivonitySpacing.vGapLG,

          // Help options
          _buildHelpOption(
            context,
            'Help Center',
            'Browse FAQ and user guides',
            Icons.help_center,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenter()),
              );
            },
          ),

          if (showOnboarding)
            _buildHelpOption(
              context,
              'Getting Started',
              'Replay the onboarding tutorial',
              Icons.play_arrow,
              () {
                Navigator.pop(context);
                _showOnboarding(context);
              },
            ),

          _buildHelpOption(
            context,
            'Contact Support',
            'Get help from our support team',
            Icons.support_agent,
            () {
              Navigator.pop(context);
              _contactSupport(context);
            },
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHelpOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return AnimatedInteractiveContainer(
      onTap: onTap,
      child: Container(
        margin: AivonitySpacing.verticalXS,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            AivonitySpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showOnboarding(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          steps: _getOnboardingSteps(),
          onComplete: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get help from our support team:'),
            SizedBox(height: 16),
            Text('📧 support@aivonity.com'),
            Text('📞 1-800-AIVONITY'),
            Text('💬 Live Chat: Available 24/7'),
          ],
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

  List<OnboardingStep> _getOnboardingSteps() {
    return [
      const OnboardingStep(
        title: 'Welcome to AIVONITY',
        description:
            'Your intelligent vehicle assistant that helps you monitor, maintain, and optimize your vehicle\'s performance.',
        icon: Icons.directions_car,
        color: Colors.blue,
      ),
      const OnboardingStep(
        title: 'Connect Your Vehicle',
        description: 'Start by connecting your vehicle to unlock all features.',
        icon: Icons.bluetooth,
        color: Colors.green,
      ),
      const OnboardingStep(
        title: 'You\'re All Set!',
        description: 'Start exploring AIVONITY and discover its features.',
        icon: Icons.check_circle,
        color: Colors.green,
      ),
    ];
  }
}

