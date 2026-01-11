import 'package:flutter/material.dart';
import '../components/adventure_notifications.dart';
import '../components/adventure_user_profile.dart';
import '../components/adventure_settings.dart';
import '../components/adventure_quick_actions.dart';
import '../theme.dart';

/// Comprehensive Adventure-themed Demo Screen
/// Demonstrates all adventure components with full functionality
class AdventureDemoScreen extends StatefulWidget {
  const AdventureDemoScreen({super.key});

  @override
  State<AdventureDemoScreen> createState() => _AdventureDemoScreenState();
}

class _AdventureDemoScreenState extends State<AdventureDemoScreen> {
  int _currentIndex = 0;
  int _notificationCount = 3;

  // Demo user profile
  final AdventureUserProfile _demoProfile = AdventureUserProfile(
    name: 'Alex Mountain',
    email: 'alex.mountain@adventure.app',
    avatarUrl: 'https://via.placeholder.com/150',
    bio: 'Passionate outdoor enthusiast seeking new adventures and challenges.',
    achievements: [
      'First Summit',
      'Mountain Explorer',
      'Trail Blazer',
      'Camping Master',
      'Weather Warrior',
    ],
    totalAdventures: 47,
    level: 8,
    experiencePoints: 2450,
    skills: [
      'Rock Climbing',
      'Mountaineering',
      'Wilderness Survival',
      'Photography',
      'GPS Navigation',
    ],
    location: 'Colorado Rockies',
    joinDate: DateTime(2023, 3, 15),
  );

  // Demo notifications
  List<AdventureNotification> _notifications = [
    AdventureNotification(
      title: 'Weather Alert',
      message:
          'Storm warning for your hiking area. Check conditions before departing.',
      type: AdventureNotificationType.weather,
      timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      isRead: false,
    ),
    AdventureNotification(
      title: 'Achievement Unlocked',
      message: 'Congratulations! You\'ve completed 50 adventures.',
      type: AdventureNotificationType.achievement,
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      isRead: false,
    ),
    AdventureNotification(
      title: 'Equipment Maintenance',
      message: 'Your climbing gear is due for inspection next week.',
      type: AdventureNotificationType.equipment,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      isRead: true,
    ),
    AdventureNotification(
      title: 'Trail Update',
      message: 'New trail conditions available for your favorite routes.',
      type: AdventureNotificationType.trail,
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildNotifications(),
          _buildProfile(),
          _buildSettings(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AivonityTheme.primaryAlpineBlue,
        unselectedItemColor: AivonityTheme.accentMountainGray,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: AdventureNotificationBell(
              notificationCount: _notificationCount,
            ),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      backgroundColor: AivonityTheme.neutralMistGray,
      body: CustomScrollView(
        slivers: [
          // Header with quick actions
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AivonityTheme.primaryAlpineBlue,
                    AivonityTheme.primaryBlueLight,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning,',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                              ),
                              Text(
                                _demoProfile.name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          AdventureNotificationBell(
                            notificationCount: _notificationCount,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ready for your next adventure?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick actions section
          SliverToBoxAdapter(
            child: AdventureSectionQuickActions(
              sectionTitle: 'Quick Actions',
              actions: AdventureQuickActionsHelper.getDashboardActions(),
              onSeeAll: () => _showQuickActionsSheet(),
            ),
          ),

          // Adventure stats
          SliverToBoxAdapter(child: AdventureStatsCard(profile: _demoProfile)),

          // Recent achievements
          SliverToBoxAdapter(
            child: AdventureAchievementsSection(profile: _demoProfile),
          ),

          // Adventure skills
          SliverToBoxAdapter(
            child: AdventureSkillsSection(profile: _demoProfile),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AdventureFloatingQuickAction(
        action: AdventureQuickAction(
          title: 'Start Adventure',
          subtitle: 'Begin new journey',
          icon: Icons.play_circle_filled,
          type: AdventureQuickActionType.hiking,
          onTap: _startNewAdventure,
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    return Scaffold(
      backgroundColor: AivonityTheme.neutralMistGray,
      body: AdventureNotificationList(
        notifications: _notifications,
        onMarkAllRead: _markAllNotificationsAsRead,
      ),
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AdventureProfileHeader(
              profile: _demoProfile,
              onEditProfile: _editProfile,
              onSettings: () => setState(() => _currentIndex = 3),
            ),
          ),
          SliverToBoxAdapter(child: AdventureStatsCard(profile: _demoProfile)),
          SliverToBoxAdapter(
            child: AdventureAchievementsSection(profile: _demoProfile),
          ),
          SliverToBoxAdapter(
            child: AdventureSkillsSection(profile: _demoProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return AdventureSettingsScreen();
  }

  // Demo functionality methods
  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdventureQuickActionSheet(
        title: 'All Quick Actions',
        actions: [
          ...AdventureQuickActionsHelper.getDashboardActions(),
          ...AdventureQuickActionsHelper.getAdventureSectionActions(),
          ...AdventureQuickActionsHelper.getEquipmentSectionActions(),
        ],
      ),
    );
  }

  void _startNewAdventure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting new adventure...'),
        backgroundColor: AivonityTheme.accentPineGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAllNotificationsAsRead() {
    setState(() {
      _notifications = _notifications.map((notification) {
        return AdventureNotification(
          title: notification.title,
          message: notification.message,
          type: notification.type,
          timestamp: notification.timestamp,
          isRead: true,
          icon: notification.icon,
          onDismiss: notification.onDismiss,
          onTap: notification.onTap,
        );
      }).toList();
      _notificationCount = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AivonityTheme.accentPineGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit profile functionality'),
        backgroundColor: AivonityTheme.primaryAlpineBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Adventure-themed demonstration app
class AdventureDemoApp extends StatelessWidget {
  const AdventureDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adventure App Demo',
      theme: AivonityTheme.lightTheme,
      darkTheme: AivonityTheme.darkTheme,
      home: const AdventureDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
