import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

/// Service for managing user profiles and social connections
class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  UserProfile? _currentUserProfile;
  final Map<String, UserProfile> _profileCache = {};
  final List<SocialConnection> _connections = [];

  bool _isInitialized = false;

  /// Get current user profile
  UserProfile? get currentUserProfile => _currentUserProfile;

  /// Get user connections
  List<SocialConnection> get connections => List.unmodifiable(_connections);

  /// Initialize user profile service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadCurrentUserProfile();
    await _loadConnections();

    _isInitialized = true;
  }

  /// Create or update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String displayName,
    String? bio,
    String? location,
    String? profileImageUrl,
    List<String>? interests,
    Map<String, dynamic>? vehicleShowcase,
    PrivacySettings? privacySettings,
  }) async {
    final profile = UserProfile(
      userId: userId,
      displayName: displayName,
      bio: bio,
      location: location,
      profileImageUrl: profileImageUrl,
      interests: interests ?? [],
      vehicleShowcase: vehicleShowcase ?? {},
      privacySettings: privacySettings ?? PrivacySettings.defaultSettings(),
      reputation: _currentUserProfile?.reputation ?? UserReputation.newUser(),
      joinedAt: _currentUserProfile?.joinedAt ?? DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    _currentUserProfile = profile;
    _profileCache[userId] = profile;

    await _saveUserProfile(profile);
    notifyListeners();
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    // Check cache first
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }

    // Load from database
    final profile = await _loadUserProfileFromDb(userId);
    if (profile != null) {
      _profileCache[userId] = profile;
    }

    return profile;
  }

  /// Send friend request
  Future<ConnectionResult> sendFriendRequest(String targetUserId) async {
    try {
      if (_currentUserProfile == null) {
        return ConnectionResult.error('User not logged in');
      }

      final connection = SocialConnection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserProfile!.userId,
        targetUserId: targetUserId,
        type: ConnectionType.friend,
        status: ConnectionStatus.pending,
        createdAt: DateTime.now(),
      );

      _connections.add(connection);
      await _saveConnection(connection);

      notifyListeners();
      return ConnectionResult.success('Friend request sent');
    } catch (e) {
      return ConnectionResult.error('Failed to send friend request: $e');
    }
  }

  /// Accept friend request
  Future<ConnectionResult> acceptFriendRequest(String connectionId) async {
    try {
      final connectionIndex = _connections.indexWhere(
        (c) => c.id == connectionId,
      );
      if (connectionIndex == -1) {
        return ConnectionResult.error('Connection not found');
      }

      final connection = _connections[connectionIndex];
      _connections[connectionIndex] = connection.copyWith(
        status: ConnectionStatus.accepted,
        acceptedAt: DateTime.now(),
      );

      await _updateConnectionStatus(connectionId, ConnectionStatus.accepted);

      notifyListeners();
      return ConnectionResult.success('Friend request accepted');
    } catch (e) {
      return ConnectionResult.error('Failed to accept friend request: $e');
    }
  }

  /// Get user's friends
  List<SocialConnection> getFriends() {
    return _connections
        .where(
          (c) =>
              c.type == ConnectionType.friend &&
              c.status == ConnectionStatus.accepted,
        )
        .toList();
  }

  /// Get pending friend requests
  List<SocialConnection> getPendingRequests() {
    return _connections
        .where(
          (c) =>
              c.type == ConnectionType.friend &&
              c.status == ConnectionStatus.pending,
        )
        .toList();
  }

  /// Update user reputation
  Future<void> updateReputation({
    required String userId,
    required ReputationAction action,
  }) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return;

      final currentReputation = profile.reputation;
      late UserReputation updatedReputation;

      switch (action) {
        case ReputationAction.socialConnection:
          updatedReputation = currentReputation.copyWith(
            totalPoints: currentReputation.totalPoints + 5,
          );
          break;
        case ReputationAction.helpfulPost:
          updatedReputation = currentReputation.copyWith(
            totalPoints: currentReputation.totalPoints + 10,
            postsShared: currentReputation.postsShared + 1,
          );
          break;
        case ReputationAction.bestAnswer:
          updatedReputation = currentReputation.copyWith(
            totalPoints: currentReputation.totalPoints + 25,
            bestAnswers: currentReputation.bestAnswers + 1,
          );
          break;
        case ReputationAction.contentShared:
          updatedReputation = currentReputation.copyWith(
            totalPoints: currentReputation.totalPoints + 5,
          );
          break;
        case ReputationAction.reviewPosted:
          updatedReputation = currentReputation.copyWith(
            totalPoints: currentReputation.totalPoints + 15,
            reviewsPosted: currentReputation.reviewsPosted + 1,
          );
          break;
      }

      // Update level based on total points
      final newLevel = (updatedReputation.totalPoints / 100).floor() + 1;
      updatedReputation = updatedReputation.copyWith(level: newLevel);

      final updatedProfile = profile.copyWith(reputation: updatedReputation);
      _profileCache[userId] = updatedProfile;

      if (userId == _currentUserProfile?.userId) {
        _currentUserProfile = updatedProfile;
      }

      await _saveUserProfile(updatedProfile);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update reputation: $e');
    }
  }

  // Private methods

  Future<void> _loadCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId != null) {
        _currentUserProfile = await _loadUserProfileFromDb(userId);
      }
    } catch (e) {
      debugPrint('Failed to load current user profile: $e');
    }
  }

  Future<void> _loadConnections() async {
    try {
      if (_currentUserProfile == null) return;
      // Load connections from database
    } catch (e) {
      debugPrint('Failed to load connections: $e');
    }
  }

  Future<UserProfile?> _loadUserProfileFromDb(String userId) async {
    try {
      // This would query the user_profiles table
      return null;
    } catch (e) {
      debugPrint('Failed to load user profile from database: $e');
      return null;
    }
  }

  Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      // Save to database
    } catch (e) {
      debugPrint('Failed to save user profile: $e');
    }
  }

  Future<void> _saveConnection(SocialConnection connection) async {
    try {
      // Save to database
    } catch (e) {
      debugPrint('Failed to save connection: $e');
    }
  }

  Future<void> _updateConnectionStatus(
    String connectionId,
    ConnectionStatus status,
  ) async {
    try {
      // Update connection status in database
    } catch (e) {
      debugPrint('Failed to update connection status: $e');
    }
  }
}

/// User profile model
class UserProfile {
  final String userId;
  final String displayName;
  final String? bio;
  final String? location;
  final String? profileImageUrl;
  final List<String> interests;
  final Map<String, dynamic> vehicleShowcase;
  final PrivacySettings privacySettings;
  final UserReputation reputation;
  final DateTime joinedAt;
  final DateTime lastActiveAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.bio,
    this.location,
    this.profileImageUrl,
    required this.interests,
    required this.vehicleShowcase,
    required this.privacySettings,
    required this.reputation,
    required this.joinedAt,
    required this.lastActiveAt,
  });

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? bio,
    String? location,
    String? profileImageUrl,
    List<String>? interests,
    Map<String, dynamic>? vehicleShowcase,
    PrivacySettings? privacySettings,
    UserReputation? reputation,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      interests: interests ?? this.interests,
      vehicleShowcase: vehicleShowcase ?? this.vehicleShowcase,
      privacySettings: privacySettings ?? this.privacySettings,
      reputation: reputation ?? this.reputation,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'location': location,
      'profile_image_url': profileImageUrl,
      'interests': interests,
      'vehicle_showcase': vehicleShowcase,
      'privacy_settings': privacySettings.toJson(),
      'reputation': reputation.toJson(),
      'joined_at': joinedAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }
}

/// Social connection model
class SocialConnection {
  final String id;
  final String userId;
  final String targetUserId;
  final ConnectionType type;
  final ConnectionStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  SocialConnection({
    required this.id,
    required this.userId,
    required this.targetUserId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  SocialConnection copyWith({
    String? id,
    String? userId,
    String? targetUserId,
    ConnectionType? type,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return SocialConnection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetUserId: targetUserId ?? this.targetUserId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

/// Privacy settings
class PrivacySettings {
  final bool profileVisible;
  final bool vehicleShowcaseVisible;
  final bool locationVisible;
  final bool allowFriendRequests;
  final bool allowFollowers;
  final bool showOnlineStatus;

  PrivacySettings({
    required this.profileVisible,
    required this.vehicleShowcaseVisible,
    required this.locationVisible,
    required this.allowFriendRequests,
    required this.allowFollowers,
    required this.showOnlineStatus,
  });

  factory PrivacySettings.defaultSettings() {
    return PrivacySettings(
      profileVisible: true,
      vehicleShowcaseVisible: true,
      locationVisible: false,
      allowFriendRequests: true,
      allowFollowers: true,
      showOnlineStatus: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_visible': profileVisible,
      'vehicle_showcase_visible': vehicleShowcaseVisible,
      'location_visible': locationVisible,
      'allow_friend_requests': allowFriendRequests,
      'allow_followers': allowFollowers,
      'show_online_status': showOnlineStatus,
    };
  }
}

/// User reputation and scoring
class UserReputation {
  final int totalPoints;
  final int level;
  final int helpfulAnswers;
  final int bestAnswers;
  final int postsShared;
  final int reviewsPosted;

  UserReputation({
    required this.totalPoints,
    required this.level,
    required this.helpfulAnswers,
    required this.bestAnswers,
    required this.postsShared,
    required this.reviewsPosted,
  });

  factory UserReputation.newUser() {
    return UserReputation(
      totalPoints: 0,
      level: 1,
      helpfulAnswers: 0,
      bestAnswers: 0,
      postsShared: 0,
      reviewsPosted: 0,
    );
  }

  UserReputation copyWith({
    int? totalPoints,
    int? level,
    int? helpfulAnswers,
    int? bestAnswers,
    int? postsShared,
    int? reviewsPosted,
  }) {
    return UserReputation(
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      helpfulAnswers: helpfulAnswers ?? this.helpfulAnswers,
      bestAnswers: bestAnswers ?? this.bestAnswers,
      postsShared: postsShared ?? this.postsShared,
      reviewsPosted: reviewsPosted ?? this.reviewsPosted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_points': totalPoints,
      'level': level,
      'helpful_answers': helpfulAnswers,
      'best_answers': bestAnswers,
      'posts_shared': postsShared,
      'reviews_posted': reviewsPosted,
    };
  }
}

/// Connection result
class ConnectionResult {
  final bool success;
  final String message;

  ConnectionResult({required this.success, required this.message});

  factory ConnectionResult.success(String message) {
    return ConnectionResult(success: true, message: message);
  }

  factory ConnectionResult.error(String message) {
    return ConnectionResult(success: false, message: message);
  }
}

/// Connection types
enum ConnectionType { friend, follower }

/// Connection status
enum ConnectionStatus { none, pending, accepted, declined }

/// Reputation actions
enum ReputationAction {
  socialConnection,
  helpfulPost,
  bestAnswer,
  contentShared,
  reviewPosted,
}
