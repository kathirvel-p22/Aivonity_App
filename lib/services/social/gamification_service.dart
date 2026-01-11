import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import 'user_profile_service.dart';

/// Service for managing gamification, achievements, and community challenges
class GamificationService extends ChangeNotifier {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final UserProfileService _userService = UserProfileService();

  final Map<String, Achievement> _achievements = {};
  final Map<String, UserAchievement> _userAchievements = {};
  final List<Leaderboard> _leaderboards = [];
  final List<CommunityChallenge> _challenges = [];
  final Map<String, Badge> _badges = {};

  bool _isInitialized = false;

  /// Get all achievements
  Map<String, Achievement> get achievements => Map.unmodifiable(_achievements);

  /// Get leaderboards
  List<Leaderboard> get leaderboards => List.unmodifiable(_leaderboards);

  /// Get active challenges
  List<CommunityChallenge> get activeChallenges =>
      _challenges.where((c) => c.isActive).toList();

  /// Initialize gamification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _setupAchievements();
    await _setupBadges();
    await _setupLeaderboards();

    _isInitialized = true;
  }

  /// Check and unlock achievements for user action
  Future<List<Achievement>> checkAchievements({
    required String userId,
    required AchievementTrigger trigger,
    Map<String, dynamic>? data,
  }) async {
    final unlockedAchievements = <Achievement>[];

    try {
      for (final achievement in _achievements.values) {
        if (achievement.trigger == trigger) {
          final isUnlocked = await _checkAchievementCondition(
            userId: userId,
            achievement: achievement,
            data: data,
          );

          if (isUnlocked && !_hasUserAchievement(userId, achievement.id)) {
            await _unlockAchievement(userId, achievement);
            unlockedAchievements.add(achievement);
          }
        }
      }

      if (unlockedAchievements.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to check achievements: $e');
    }

    return unlockedAchievements;
  }

  /// Award badge to user
  Future<BadgeResult> awardBadge({
    required String userId,
    required String badgeId,
    String? reason,
  }) async {
    try {
      final badge = _badges[badgeId];
      if (badge == null) {
        return BadgeResult.error('Badge not found');
      }

      final userBadge = UserBadge(
        id: '${userId}_$badgeId',
        userId: userId,
        badgeId: badgeId,
        awardedAt: DateTime.now(),
        reason: reason,
      );

      await _saveUserBadge(userBadge);

      notifyListeners();
      return BadgeResult.success('Badge awarded successfully');
    } catch (e) {
      return BadgeResult.error('Failed to award badge: $e');
    }
  }

  /// Get user's achievements
  List<UserAchievement> getUserAchievements(String userId) {
    return _userAchievements.values.where((ua) => ua.userId == userId).toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }

  // Private methods

  Future<void> _setupAchievements() async {
    final achievementsList = [
      Achievement(
        id: 'first_maintenance',
        title: 'First Maintenance',
        description: 'Complete your first maintenance record',
        icon: 'build',
        points: 10,
        rarity: AchievementRarity.common,
        trigger: AchievementTrigger.maintenanceCompleted,
        condition: {'count': 1},
      ),
      Achievement(
        id: 'first_friend',
        title: 'Social Butterfly',
        description: 'Make your first friend in the community',
        icon: 'people',
        points: 15,
        rarity: AchievementRarity.common,
        trigger: AchievementTrigger.friendAdded,
        condition: {'count': 1},
      ),
    ];

    for (final achievement in achievementsList) {
      _achievements[achievement.id] = achievement;
    }
  }

  Future<void> _setupBadges() async {
    final badgesList = [
      Badge(
        id: 'expert_mechanic',
        title: 'Expert Mechanic',
        description: 'Recognized for exceptional mechanical knowledge',
        icon: 'engineering',
        color: 0xFFFFD700,
        points: 100,
        rarity: BadgeRarity.legendary,
      ),
    ];

    for (final badge in badgesList) {
      _badges[badge.id] = badge;
    }
  }

  Future<void> _setupLeaderboards() async {
    _leaderboards.addAll([
      Leaderboard(
        id: 'reputation_points',
        title: 'Reputation Leaders',
        description: 'Top users by reputation points',
        type: LeaderboardType.reputation,
        period: LeaderboardPeriod.allTime,
        maxEntries: 100,
      ),
    ]);
  }

  Future<bool> _checkAchievementCondition({
    required String userId,
    required Achievement achievement,
    Map<String, dynamic>? data,
  }) async {
    // Simplified condition checking
    return false;
  }

  bool _hasUserAchievement(String userId, String achievementId) {
    return _userAchievements.values.any(
      (ua) => ua.userId == userId && ua.achievementId == achievementId,
    );
  }

  Future<void> _unlockAchievement(
    String userId,
    Achievement achievement,
  ) async {
    final userAchievement = UserAchievement(
      id: '${userId}_${achievement.id}',
      userId: userId,
      achievementId: achievement.id,
      unlockedAt: DateTime.now(),
    );

    _userAchievements[userAchievement.id] = userAchievement;
    await _saveUserAchievement(userAchievement);
  }

  Future<void> _saveUserAchievement(UserAchievement userAchievement) async {
    // Save to database
  }

  Future<void> _saveUserBadge(UserBadge userBadge) async {
    // Save to database
  }
}

/// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final AchievementRarity rarity;
  final AchievementTrigger trigger;
  final Map<String, dynamic> condition;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.rarity,
    required this.trigger,
    required this.condition,
  });
}

/// User achievement model
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });
}

/// Badge model
class Badge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int color;
  final int points;
  final BadgeRarity rarity;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    required this.rarity,
  });
}

/// User badge model
class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime awardedAt;
  final String? reason;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.awardedAt,
    this.reason,
  });
}

/// Community challenge model
class CommunityChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

/// Leaderboard model
class Leaderboard {
  final String id;
  final String title;
  final String description;
  final LeaderboardType type;
  final LeaderboardPeriod period;
  final int maxEntries;

  Leaderboard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.maxEntries,
  });
}

/// Result classes
class BadgeResult {
  final bool success;
  final String message;

  BadgeResult({required this.success, required this.message});

  factory BadgeResult.success(String message) {
    return BadgeResult(success: true, message: message);
  }

  factory BadgeResult.error(String message) {
    return BadgeResult(success: false, message: message);
  }
}

/// Enums
enum AchievementRarity { common, uncommon, rare, epic, legendary }

enum AchievementTrigger {
  maintenanceCompleted,
  friendAdded,
  upvotesReceived,
  fuelEfficiency,
  contentShared,
}

enum BadgeRarity { common, uncommon, rare, epic, legendary }

enum ChallengeType { maintenance, social, performance, content }

enum LeaderboardType { reputation, contributions, fuelEfficiency }

enum LeaderboardPeriod { weekly, monthly, quarterly, allTime }

