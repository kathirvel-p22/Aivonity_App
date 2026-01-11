import 'package:flutter/material.dart';
import '../theme.dart';

/// Adventure-themed Quick Action Components
/// Provides modern, interactive quick action buttons for different app sections

/// Quick action types for different adventure categories
enum AdventureQuickActionType {
  hiking,
  climbing,
  camping,
  cycling,
  waterSports,
  winterSports,
  photography,
  navigation,
  weather,
  equipment,
  emergency,
  social,
}

/// Quick action model
class AdventureQuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final AdventureQuickActionType type;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final bool isEnabled;
  final String? badgeText;
  final int? notificationCount;

  const AdventureQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.onTap,
    this.backgroundColor,
    this.isEnabled = true,
    this.badgeText,
    this.notificationCount,
  });
}

/// Adventure quick action button
class AdventureQuickActionButton extends StatelessWidget {
  final AdventureQuickAction action;
  final double size;

  const AdventureQuickActionButton({
    super.key,
    required this.action,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color buttonColor;
    Color iconColor;

    switch (action.type) {
      case AdventureQuickActionType.hiking:
        buttonColor = AivonityTheme.accentPineGreen;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.climbing:
        buttonColor = AivonityTheme.primaryAlpineBlue;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.camping:
        buttonColor = AivonityTheme.accentSummitOrange;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.cycling:
        buttonColor = AivonityTheme.accentSunsetCoral;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.waterSports:
        buttonColor = AivonityTheme.accentSkyBlue;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.winterSports:
        buttonColor = AivonityTheme.accentMountainGray;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.photography:
        buttonColor = AivonityTheme.accentPurple;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.navigation:
        buttonColor = AivonityTheme.accentRed;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.weather:
        buttonColor = AivonityTheme.accentYellow;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.equipment:
        buttonColor = AivonityTheme.neutralStoneGray;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.emergency:
        buttonColor = AivonityTheme.accentRed;
        iconColor = Colors.white;
        break;
      case AdventureQuickActionType.social:
        buttonColor = AivonityTheme.accentPink;
        iconColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: action.isEnabled ? action.onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: iconColor, size: size * 0.35),
                  const SizedBox(height: 4),
                  Text(
                    action.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Badge
            if (action.badgeText != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AivonityTheme.accentSummitOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    action.badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Notification count
            if (action.notificationCount != null &&
                action.notificationCount! > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AivonityTheme.accentSummitOrange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    action.notificationCount! > 99
                        ? '99+'
                        : action.notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Adventure quick actions grid
class AdventureQuickActionsGrid extends StatelessWidget {
  final List<AdventureQuickAction> actions;
  final int columns;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const AdventureQuickActionsGrid({
    super.key,
    required this.actions,
    this.columns = 3,
    this.spacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return AdventureQuickActionButton(action: actions[index]);
        },
      ),
    );
  }
}

/// Adventure floating quick action button
class AdventureFloatingQuickAction extends StatelessWidget {
  final AdventureQuickAction action;

  const AdventureFloatingQuickAction({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: action.isEnabled ? action.onTap : null,
      backgroundColor: _getActionColor(action.type),
      foregroundColor: Colors.white,
      elevation: 8,
      icon: Icon(action.icon),
      label: Text(action.title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Color _getActionColor(AdventureQuickActionType type) {
    switch (type) {
      case AdventureQuickActionType.emergency:
        return AivonityTheme.accentRed;
      case AdventureQuickActionType.navigation:
        return AivonityTheme.primaryAlpineBlue;
      case AdventureQuickActionType.weather:
        return AivonityTheme.accentSunsetCoral;
      case AdventureQuickActionType.equipment:
        return AivonityTheme.accentMountainGray;
      default:
        return AivonityTheme.accentPineGreen;
    }
  }
}

/// Adventure section quick actions
class AdventureSectionQuickActions extends StatelessWidget {
  final String sectionTitle;
  final List<AdventureQuickAction> actions;
  final VoidCallback? onSeeAll;

  const AdventureSectionQuickActions({
    super.key,
    required this.sectionTitle,
    required this.actions,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AivonityTheme.primaryAlpineBlue,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See All',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AivonityTheme.primaryAlpineBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.take(4).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AdventureQuickActionButton(action: action, size: 70),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Adventure quick action sheet
class AdventureQuickActionSheet extends StatelessWidget {
  final List<AdventureQuickAction> actions;
  final String title;

  const AdventureQuickActionSheet({
    super.key,
    required this.actions,
    this.title = 'Quick Actions',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AivonityTheme.neutralMistGray, Colors.white],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AivonityTheme.accentMountainGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AivonityTheme.primaryAlpineBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Actions grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                return AdventureQuickActionButton(
                  action: actions[index],
                  size: 80,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action helper for different sections
class AdventureQuickActionsHelper {
  /// Get quick actions for main dashboard
  static List<AdventureQuickAction> getDashboardActions() {
    return [
      AdventureQuickAction(
        title: 'Start Adventure',
        subtitle: 'Begin new journey',
        icon: Icons.play_circle_filled,
        type: AdventureQuickActionType.hiking,
        onTap: () {
          /* Navigate to start adventure */
        },
      ),
      AdventureQuickAction(
        title: 'Weather',
        subtitle: 'Check conditions',
        icon: Icons.wb_sunny,
        type: AdventureQuickActionType.weather,
        onTap: () {
          /* Navigate to weather */
        },
        notificationCount: 1,
      ),
      AdventureQuickAction(
        title: 'Navigation',
        subtitle: 'Find your way',
        icon: Icons.navigation,
        type: AdventureQuickActionType.navigation,
        onTap: () {
          /* Navigate to navigation */
        },
      ),
      AdventureQuickAction(
        title: 'Emergency',
        subtitle: 'SOS & safety',
        icon: Icons.emergency,
        type: AdventureQuickActionType.emergency,
        onTap: () {
          /* Navigate to emergency */
        },
        backgroundColor: AivonityTheme.accentRed,
      ),
      AdventureQuickAction(
        title: 'Equipment',
        subtitle: 'Gear & tools',
        icon: Icons.backpack,
        type: AdventureQuickActionType.equipment,
        onTap: () {
          /* Navigate to equipment */
        },
      ),
      AdventureQuickAction(
        title: 'Social',
        subtitle: 'Share & connect',
        icon: Icons.people,
        type: AdventureQuickActionType.social,
        onTap: () {
          /* Navigate to social */
        },
        badgeText: '3',
      ),
    ];
  }

  /// Get quick actions for adventure section
  static List<AdventureQuickAction> getAdventureSectionActions() {
    return [
      AdventureQuickAction(
        title: 'Hiking',
        subtitle: 'Mountain trails',
        icon: Icons.hiking,
        type: AdventureQuickActionType.hiking,
        onTap: () {
          /* Navigate to hiking */
        },
      ),
      AdventureQuickAction(
        title: 'Climbing',
        subtitle: 'Rock climbing',
        icon: Icons.terrain,
        type: AdventureQuickActionType.climbing,
        onTap: () {
          /* Navigate to climbing */
        },
      ),
      AdventureQuickAction(
        title: 'Camping',
        subtitle: 'Outdoor stay',
        icon: Icons.terrain,
        type: AdventureQuickActionType.camping,
        onTap: () {
          /* Navigate to camping */
        },
      ),
      AdventureQuickAction(
        title: 'Cycling',
        subtitle: 'Bike adventures',
        icon: Icons.directions_bike,
        type: AdventureQuickActionType.cycling,
        onTap: () {
          /* Navigate to cycling */
        },
      ),
      AdventureQuickAction(
        title: 'Water Sports',
        subtitle: 'Aquatic activities',
        icon: Icons.water,
        type: AdventureQuickActionType.waterSports,
        onTap: () {
          /* Navigate to water sports */
        },
      ),
      AdventureQuickAction(
        title: 'Photography',
        subtitle: 'Capture moments',
        icon: Icons.camera_alt,
        type: AdventureQuickActionType.photography,
        onTap: () {
          /* Navigate to photography */
        },
      ),
    ];
  }

  /// Get quick actions for equipment section
  static List<AdventureQuickAction> getEquipmentSectionActions() {
    return [
      AdventureQuickAction(
        title: 'Add Gear',
        subtitle: 'New equipment',
        icon: Icons.add_box,
        type: AdventureQuickActionType.equipment,
        onTap: () {
          /* Add new equipment */
        },
      ),
      AdventureQuickAction(
        title: 'Maintenance',
        subtitle: 'Check & service',
        icon: Icons.build,
        type: AdventureQuickActionType.equipment,
        onTap: () {
          /* Navigate to maintenance */
        },
        notificationCount: 2,
      ),
      AdventureQuickAction(
        title: 'Recommendations',
        subtitle: 'AI suggestions',
        icon: Icons.lightbulb,
        type: AdventureQuickActionType.equipment,
        onTap: () {
          /* Navigate to recommendations */
        },
      ),
      AdventureQuickAction(
        title: 'Inventory',
        subtitle: 'Gear list',
        icon: Icons.inventory,
        type: AdventureQuickActionType.equipment,
        onTap: () {
          /* Navigate to inventory */
        },
      ),
    ];
  }
}

