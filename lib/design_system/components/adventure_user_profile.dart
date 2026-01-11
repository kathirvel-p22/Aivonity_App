import 'package:flutter/material.dart';
import '../theme.dart';

/// Modern Adventure-themed User Profile Components
/// Provides comprehensive user profile interfaces with adventure styling

/// User profile model for adventure app
class AdventureUserProfile {
  final String name;
  final String email;
  final String avatarUrl;
  final String bio;
  final List<String> achievements;
  final int totalAdventures;
  final int level;
  final int experiencePoints;
  final List<String> skills;
  final String location;
  final DateTime joinDate;

  const AdventureUserProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.bio = '',
    this.achievements = const [],
    this.totalAdventures = 0,
    this.level = 1,
    this.experiencePoints = 0,
    this.skills = const [],
    this.location = '',
    required this.joinDate,
  });
}

/// Adventure user profile header with gradient background
class AdventureProfileHeader extends StatelessWidget {
  final AdventureUserProfile profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSettings;

  const AdventureProfileHeader({
    super.key,
    required this.profile,
    this.onEditProfile,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AivonityTheme.primaryAlpineBlue,
            AivonityTheme.primaryBlueLight,
            AivonityTheme.accentSunsetCoral,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: AdventurePatternPainter()),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: onSettings,
                        icon: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Text(
                        'Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: onEditProfile,
                        icon: Icon(Icons.edit, color: Colors.white, size: 28),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Avatar with adventure border
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AivonityTheme.adventureGradient,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(profile.avatarUrl),
                      radius: 56,
                      backgroundColor: Colors.transparent,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name and level
                  Text(
                    profile.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha:0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: AivonityTheme.accentSummitOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Level ${profile.level}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adventure stats card component
class AdventureStatsCard extends StatelessWidget {
  final AdventureUserProfile profile;

  const AdventureStatsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withValues(alpha:0.9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AivonityTheme.primaryAlpineBlue.withValues(alpha:0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AivonityTheme.primaryAlpineBlue.withValues(alpha:0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adventure Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AivonityTheme.primaryAlpineBlue,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.explore,
                  profile.totalAdventures.toString(),
                  'Adventures',
                  AivonityTheme.accentPineGreen,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.star,
                  profile.experiencePoints.toString(),
                  'Experience',
                  AivonityTheme.accentSummitOrange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.emoji_events,
                  profile.achievements.length.toString(),
                  'Achievements',
                  AivonityTheme.accentSunsetCoral,
                ),
              ),
            ],
          ),

          // Experience progress bar
          if (profile.level > 1) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Level Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${profile.experiencePoints}/1000 XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AivonityTheme.primaryAlpineBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (profile.experiencePoints % 1000) / 1000,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AivonityTheme.adventureGradient.colors.first,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Adventure achievements section
class AdventureAchievementsSection extends StatelessWidget {
  final AdventureUserProfile profile;

  const AdventureAchievementsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Achievements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AivonityTheme.primaryAlpineBlue,
            ),
          ),
          const SizedBox(height: 16),

          if (profile.achievements.isEmpty)
            _buildEmptyAchievements(context)
          else
            _buildAchievementsList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyAchievements(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AivonityTheme.neutralMistGray,
            AivonityTheme.neutralMistGray.withValues(alpha:0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha:0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No achievements yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete adventures to unlock achievements!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha:0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: profile.achievements
          .take(6)
          .map((achievement) => _buildAchievementBadge(context, achievement))
          .toList(),
    );
  }

  Widget _buildAchievementBadge(BuildContext context, String achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AivonityTheme.accentSummitOrange.withValues(alpha:0.1),
            AivonityTheme.accentSunsetCoral.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AivonityTheme.accentSummitOrange.withValues(alpha:0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 16,
            color: AivonityTheme.accentSummitOrange,
          ),
          const SizedBox(width: 8),
          Text(
            achievement,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AivonityTheme.accentSummitOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Adventure skills section
class AdventureSkillsSection extends StatelessWidget {
  final AdventureUserProfile profile;

  const AdventureSkillsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adventure Skills',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AivonityTheme.primaryAlpineBlue,
            ),
          ),
          const SizedBox(height: 16),

          if (profile.skills.isEmpty)
            _buildEmptySkills(context)
          else
            _buildSkillsGrid(context),
        ],
      ),
    );
  }

  Widget _buildEmptySkills(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_esports,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha:0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No skills listed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your adventure skills to connect with other explorers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: profile.skills.length,
      itemBuilder: (context, index) {
        final skill = profile.skills[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AivonityTheme.accentPineGreen.withValues(alpha:0.1),
                AivonityTheme.accentPineGreen.withValues(alpha:0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AivonityTheme.accentPineGreen.withValues(alpha:0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AivonityTheme.accentPineGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AivonityTheme.accentPineGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for adventure pattern background
class AdventurePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha:0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw mountain peaks pattern
    final path = Path();
    final peakHeight = size.height * 0.3;

    path.moveTo(0, size.height - peakHeight * 0.5);
    path.lineTo(size.width * 0.2, size.height - peakHeight);
    path.lineTo(size.width * 0.4, size.height - peakHeight * 0.6);
    path.lineTo(size.width * 0.6, size.height - peakHeight * 0.8);
    path.lineTo(size.width * 0.8, size.height - peakHeight * 0.4);
    path.lineTo(size.width, size.height - peakHeight * 0.7);

    canvas.drawPath(path, paint);

    // Draw additional decorative elements
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha:0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.3),
      20,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      15,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

