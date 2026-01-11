import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system.dart';

/// Onboarding step configuration
class OnboardingStep {
  final String title;
  final String description;
  final Widget? illustration;
  final IconData? icon;
  final Color? color;
  final List<String>? bulletPoints;

  const OnboardingStep({
    required this.title,
    required this.description,
    this.illustration,
    this.icon,
    this.color,
    this.bulletPoints,
  });
}

/// Onboarding screen with smooth transitions
class OnboardingScreen extends StatefulWidget {
  final List<OnboardingStep> steps;
  final VoidCallback onComplete;
  final String? skipButtonText;
  final String? nextButtonText;
  final String? finishButtonText;

  const OnboardingScreen({
    super.key,
    required this.steps,
    required this.onComplete,
    this.skipButtonText = 'Skip',
    this.nextButtonText = 'Next',
    this.finishButtonText = 'Get Started',
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: AivonityAnimations.medium,
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: AivonitySpacing.paddingMD,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentIndex < widget.steps.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(widget.skipButtonText!),
                    ),
                ],
              ),
            ),

            // Page indicator
            _buildPageIndicator(),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  return _buildStepContent(widget.steps[index]);
                },
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: AivonitySpacing.paddingMD,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.steps.length,
          (index) => AnimatedContainer(
            duration: AivonityAnimations.fast,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: AivonityAnimations.easeOut,
                  ),
                ),
            child: Padding(
              padding: AivonitySpacing.paddingXL,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration or icon
                  if (step.illustration != null)
                    SizedBox(height: 200, child: step.illustration!)
                  else if (step.icon != null)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color:
                            (step.color ??
                                    Theme.of(context).colorScheme.primary)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.icon!,
                        size: 60,
                        color:
                            step.color ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),

                  AivonitySpacing.vGapXL,

                  // Title
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),

                  AivonitySpacing.vGapMD,

                  // Description
                  Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Bullet points
                  if (step.bulletPoints != null) ...[
                    AivonitySpacing.vGapLG,
                    ...step.bulletPoints!.map(
                      (point) => Padding(
                        padding: AivonitySpacing.verticalXS,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color:
                                  step.color ??
                                  Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            AivonitySpacing.hGapSM,
                            Expanded(
                              child: Text(
                                point,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: AivonitySpacing.paddingXL,
      child: Row(
        children: [
          // Previous button
          if (_currentIndex > 0)
            Expanded(
              child: AivonityButton(
                text: 'Previous',
                type: ButtonType.secondary,
                onPressed: _previousStep,
                isFullWidth: true,
              ),
            ),

          if (_currentIndex > 0) AivonitySpacing.hGapMD,

          // Next/Finish button
          Expanded(
            child: AivonityButton(
              text: _currentIndex == widget.steps.length - 1
                  ? widget.finishButtonText!
                  : widget.nextButtonText!,
              onPressed: _currentIndex == widget.steps.length - 1
                  ? _completeOnboarding
                  : _nextStep,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: AivonityAnimations.medium,
        curve: AivonityAnimations.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: AivonityAnimations.medium,
        curve: AivonityAnimations.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    widget.onComplete();
  }
}

/// Tooltip system for contextual help
class HelpTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final String? title;
  final TooltipPosition position;
  final bool showOnFirstVisit;
  final String? helpId;

  const HelpTooltip({
    super.key,
    required this.child,
    required this.message,
    this.title,
    this.position = TooltipPosition.top,
    this.showOnFirstVisit = false,
    this.helpId,
  });

  @override
  State<HelpTooltip> createState() => _HelpTooltipState();
}

class _HelpTooltipState extends State<HelpTooltip> {
  bool _shouldShowTooltip = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  void _checkShouldShow() async {
    if (widget.showOnFirstVisit && widget.helpId != null) {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('tooltip_${widget.helpId}') ?? false;

      if (!hasShown) {
        setState(() {
          _shouldShowTooltip = true;
        });

        // Mark as shown after a delay
        Future.delayed(const Duration(seconds: 3), () async {
          await prefs.setBool('tooltip_${widget.helpId}', true);
          if (mounted) {
            setState(() {
              _shouldShowTooltip = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _shouldShowTooltip
        ? Tooltip(
            message: widget.message,
            preferBelow: widget.position == TooltipPosition.bottom,
            child: widget.child,
          )
        : widget.child;
  }
}

enum TooltipPosition { top, bottom, left, right }

/// Help center with FAQ and guides
class HelpCenter extends StatelessWidget {
  const HelpCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: SingleChildScrollView(
        padding: AivonitySpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                // Implement search functionality
              },
            ),

            AivonitySpacing.vGapXL,

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AivonitySpacing.vGapMD,

            ResponsiveGrid(
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionCard(
                  context,
                  'Getting Started',
                  Icons.play_arrow,
                  () => _showOnboarding(context),
                ),
                _buildQuickActionCard(
                  context,
                  'Video Tutorials',
                  Icons.video_library,
                  () => _showVideoTutorials(context),
                ),
                _buildQuickActionCard(
                  context,
                  'Contact Support',
                  Icons.support_agent,
                  () => _contactSupport(context),
                ),
                _buildQuickActionCard(
                  context,
                  'Report Issue',
                  Icons.bug_report,
                  () => _reportIssue(context),
                ),
              ],
            ),

            AivonitySpacing.vGapXL,

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AivonitySpacing.vGapMD,

            ..._buildFAQItems(context),

            AivonitySpacing.vGapXL,

            // Guides Section
            Text(
              'User Guides',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AivonitySpacing.vGapMD,

            ..._buildGuideItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return AnimatedInteractiveContainer(
      onTap: onTap,
      child: AivonityCard(
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            AivonitySpacing.hGapMD,
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFAQItems(BuildContext context) {
    final faqItems = [
      {
        'question': 'How do I connect my vehicle?',
        'answer':
            'To connect your vehicle, go to Settings > Vehicle Setup and follow the step-by-step instructions. Make sure your vehicle is compatible and has an active data connection.',
      },
      {
        'question': 'Why am I not receiving alerts?',
        'answer':
            'Check your notification settings in the app and ensure notifications are enabled for AIVONITY in your device settings. Also verify that your vehicle is properly connected.',
      },
      {
        'question': 'How accurate is the predictive analytics?',
        'answer':
            'Our predictive analytics use advanced machine learning algorithms with 85-95% accuracy. The accuracy improves over time as the system learns your vehicle\'s patterns.',
      },
      {
        'question': 'Can I use the app offline?',
        'answer':
            'Yes, many features work offline including viewing cached data, reports, and basic vehicle information. Real-time features require an internet connection.',
      },
    ];

    return faqItems
        .map(
          (item) => _buildFAQItem(context, item['question']!, item['answer']!),
        )
        .toList();
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return AivonityCard(
      margin: AivonitySpacing.verticalSM,
      child: ExpansionTile(
        title: Text(question, style: Theme.of(context).textTheme.titleMedium),
        children: [
          Padding(
            padding: AivonitySpacing.paddingMD,
            child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGuideItems(BuildContext context) {
    final guideItems = [
      _GuideItem(
        title: 'Vehicle Setup Guide',
        description:
            'Complete guide to connecting and configuring your vehicle',
        icon: Icons.directions_car,
      ),
      _GuideItem(
        title: 'Understanding Analytics',
        description: 'Learn how to interpret your vehicle\'s performance data',
        icon: Icons.analytics,
      ),
      _GuideItem(
        title: 'Maintenance Scheduling',
        description: 'How to set up and manage maintenance reminders',
        icon: Icons.schedule,
      ),
    ];

    return guideItems
        .map(
          (guide) => AnimatedInteractiveContainer(
            onTap: () => _openGuide(context, guide.title),
            child: AivonityCard(
              margin: AivonitySpacing.verticalSM,
              child: ListTile(
                leading: Icon(
                  guide.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(guide.title),
                subtitle: Text(guide.description),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ),
          ),
        )
        .toList();
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

  void _showVideoTutorials(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Tutorials'),
        content: const Text(
          'Video tutorials will be available in a future update. For now, please refer to the user guides and FAQ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
            Text('📧 Email: support@aivonity.com'),
            Text('📞 Phone: 1-800-AIVONITY'),
            Text('💬 Live Chat: Available 24/7'),
            SizedBox(height: 16),
            Text('Average response time: 2-4 hours'),
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

  void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Issue Title',
                hintText: 'Brief description of the issue',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of what happened',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue report submitted. Thank you!'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _openGuide(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          'This guide will provide detailed instructions for $title. Full guides will be available in a future update.',
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
        title: 'Monitor & Maintain',
        description:
            'Get insights into your vehicle\'s performance and receive proactive maintenance recommendations.',
        icon: Icons.analytics,
        color: Colors.orange,
        bulletPoints: [
          'Performance tracking',
          'Maintenance scheduling',
          'Cost optimization',
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

class _GuideItem {
  final String title;
  final String description;
  final IconData icon;

  const _GuideItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
