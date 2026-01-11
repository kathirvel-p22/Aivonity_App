import 'dart:async';
import 'package:flutter/foundation.dart';
import 'user_profile_service.dart';

/// Service for managing content sharing and reviews
class ContentService extends ChangeNotifier {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  final UserProfileService _userService = UserProfileService();

  final List<ServiceCenterReview> _reviews = [];
  final List<SharedContent> _sharedContent = [];
  final List<MaintenanceTip> _maintenanceTips = [];

  bool _isInitialized = false;

  /// Get service center reviews
  List<ServiceCenterReview> get reviews => List.unmodifiable(_reviews);

  /// Get shared content
  List<SharedContent> get sharedContent => List.unmodifiable(_sharedContent);

  /// Get maintenance tips
  List<MaintenanceTip> get maintenanceTips =>
      List.unmodifiable(_maintenanceTips);

  /// Initialize content service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadContent();
    _isInitialized = true;
  }

  /// Submit service center review
  Future<ContentResult> submitServiceCenterReview({
    required String serviceCenterId,
    required String serviceCenterName,
    required double rating,
    required String reviewText,
    List<String>? photoUrls,
    List<String>? serviceTypes,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ContentResult.error('User not logged in');
      }

      // Check if user already reviewed this service center
      final existingReview = _reviews.firstWhere(
        (r) =>
            r.serviceCenterId == serviceCenterId &&
            r.authorId == currentUser.userId,
        orElse: () => ServiceCenterReview(
          id: '',
          serviceCenterId: '',
          serviceCenterName: '',
          authorId: '',
          authorName: '',
          rating: 0,
          reviewText: '',
          photoUrls: [],
          serviceTypes: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          helpfulVotes: 0,
          isVerified: false,
        ),
      );

      if (existingReview.id.isNotEmpty) {
        return ContentResult.error(
          'You have already reviewed this service center',
        );
      }

      final review = ServiceCenterReview(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        serviceCenterId: serviceCenterId,
        serviceCenterName: serviceCenterName,
        authorId: currentUser.userId,
        authorName: currentUser.displayName,
        rating: rating,
        reviewText: reviewText,
        photoUrls: photoUrls ?? [],
        serviceTypes: serviceTypes ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        helpfulVotes: 0,
        isVerified: false,
      );

      _reviews.insert(0, review);
      await _saveReview(review);

      // Update user reputation
      await _userService.updateReputation(
        userId: currentUser.userId,
        action: ReputationAction.reviewPosted,
      );

      notifyListeners();
      return ContentResult.success('Review submitted successfully');
    } catch (e) {
      return ContentResult.error('Failed to submit review: $e');
    }
  }

  /// Share maintenance content
  Future<ContentResult> shareMaintenanceContent({
    required String title,
    required String description,
    required ContentType contentType,
    List<String>? mediaUrls,
    List<String>? tags,
    String? vehicleModel,
    DifficultyLevel? difficulty,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ContentResult.error('User not logged in');
      }

      final content = SharedContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: currentUser.userId,
        authorName: currentUser.displayName,
        title: title,
        description: description,
        contentType: contentType,
        mediaUrls: mediaUrls ?? [],
        tags: tags ?? [],
        vehicleModel: vehicleModel,
        difficulty: difficulty,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likes: 0,
        views: 0,
        shares: 0,
        isFeatured: false,
      );

      _sharedContent.insert(0, content);
      await _saveSharedContent(content);

      // Update user reputation
      await _userService.updateReputation(
        userId: currentUser.userId,
        action: ReputationAction.contentShared,
      );

      notifyListeners();
      return ContentResult.success('Content shared successfully');
    } catch (e) {
      return ContentResult.error('Failed to share content: $e');
    }
  }

  /// Submit maintenance tip
  Future<ContentResult> submitMaintenanceTip({
    required String title,
    required String description,
    required List<String> steps,
    List<String>? mediaUrls,
    List<String>? tags,
    String? vehicleModel,
    DifficultyLevel? difficulty,
    Duration? estimatedTime,
    List<String>? requiredTools,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ContentResult.error('User not logged in');
      }

      final tip = MaintenanceTip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: currentUser.userId,
        authorName: currentUser.displayName,
        title: title,
        description: description,
        steps: steps,
        mediaUrls: mediaUrls ?? [],
        tags: tags ?? [],
        vehicleModel: vehicleModel,
        difficulty: difficulty ?? DifficultyLevel.beginner,
        estimatedTime: estimatedTime,
        requiredTools: requiredTools ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likes: 0,
        views: 0,
        saves: 0,
        isVerified: false,
      );

      _maintenanceTips.insert(0, tip);
      await _saveMaintenanceTip(tip);

      // Update user reputation
      await _userService.updateReputation(
        userId: currentUser.userId,
        action: ReputationAction.helpfulPost,
      );

      notifyListeners();
      return ContentResult.success('Maintenance tip submitted successfully');
    } catch (e) {
      return ContentResult.error('Failed to submit maintenance tip: $e');
    }
  }

  /// Like content
  Future<ContentResult> likeContent({
    required String contentId,
    required ContentCategory category,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ContentResult.error('User not logged in');
      }

      switch (category) {
        case ContentCategory.sharedContent:
          await _likeSharedContent(contentId);
          break;
        case ContentCategory.maintenanceTip:
          await _likeMaintenanceTip(contentId);
          break;
        case ContentCategory.review:
          await _likeReview(contentId);
          break;
      }

      notifyListeners();
      return ContentResult.success('Content liked');
    } catch (e) {
      return ContentResult.error('Failed to like content: $e');
    }
  }

  /// Get reviews for service center
  List<ServiceCenterReview> getServiceCenterReviews(String serviceCenterId) {
    return _reviews.where((r) => r.serviceCenterId == serviceCenterId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get average rating for service center
  double getServiceCenterAverageRating(String serviceCenterId) {
    final centerReviews = getServiceCenterReviews(serviceCenterId);
    if (centerReviews.isEmpty) return 0.0;

    final totalRating = centerReviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    return totalRating / centerReviews.length;
  }

  /// Search content
  Future<List<dynamic>> searchContent({
    String? query,
    List<String>? tags,
    ContentCategory? category,
    String? vehicleModel,
    DifficultyLevel? difficulty,
    int limit = 20,
  }) async {
    try {
      List<dynamic> allContent = [];

      if (category == null || category == ContentCategory.sharedContent) {
        allContent.addAll(_sharedContent);
      }
      if (category == null || category == ContentCategory.maintenanceTip) {
        allContent.addAll(_maintenanceTips);
      }
      if (category == null || category == ContentCategory.review) {
        allContent.addAll(_reviews);
      }

      // Filter by query
      if (query != null && query.isNotEmpty) {
        allContent = allContent.where((content) {
          final title = _getContentTitle(content);
          final description = _getContentDescription(content);
          return title.toLowerCase().contains(query.toLowerCase()) ||
              description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        allContent = allContent.where((content) {
          final contentTags = _getContentTags(content);
          return contentTags.any((tag) => tags.contains(tag));
        }).toList();
      }

      // Filter by vehicle model
      if (vehicleModel != null) {
        allContent = allContent.where((content) {
          final model = _getContentVehicleModel(content);
          return model != null &&
              model.toLowerCase().contains(vehicleModel.toLowerCase());
        }).toList();
      }

      // Filter by difficulty
      if (difficulty != null) {
        allContent = allContent.where((content) {
          final contentDifficulty = _getContentDifficulty(content);
          return contentDifficulty == difficulty;
        }).toList();
      }

      // Sort by relevance/date
      allContent.sort((a, b) {
        final dateA = _getContentDate(a);
        final dateB = _getContentDate(b);
        return dateB.compareTo(dateA);
      });

      return allContent.take(limit).toList();
    } catch (e) {
      debugPrint('Failed to search content: $e');
      return [];
    }
  }

  /// Get trending content
  List<dynamic> getTrendingContent({int limit = 10}) {
    List<dynamic> allContent = [];
    allContent.addAll(_sharedContent);
    allContent.addAll(_maintenanceTips);

    // Sort by engagement score (likes + views + shares)
    allContent.sort((a, b) {
      final scoreA = _calculateEngagementScore(a);
      final scoreB = _calculateEngagementScore(b);
      return scoreB.compareTo(scoreA);
    });

    return allContent.take(limit).toList();
  }

  /// Get user's content
  Future<List<dynamic>> getUserContent(String userId, {int limit = 20}) async {
    List<dynamic> userContent = [];

    userContent.addAll(_sharedContent.where((c) => c.authorId == userId));
    userContent.addAll(_maintenanceTips.where((t) => t.authorId == userId));
    userContent.addAll(_reviews.where((r) => r.authorId == userId));

    userContent.sort((a, b) {
      final dateA = _getContentDate(a);
      final dateB = _getContentDate(b);
      return dateB.compareTo(dateA);
    });

    return userContent.take(limit).toList();
  }

  // Private methods

  Future<void> _loadContent() async {
    try {
      // Load content from database
      // This would query the reviews, shared_content, and maintenance_tips tables
    } catch (e) {
      debugPrint('Failed to load content: $e');
    }
  }

  Future<void> _saveReview(ServiceCenterReview review) async {
    try {
      // Save review to database
    } catch (e) {
      debugPrint('Failed to save review: $e');
    }
  }

  Future<void> _saveSharedContent(SharedContent content) async {
    try {
      // Save shared content to database
    } catch (e) {
      debugPrint('Failed to save shared content: $e');
    }
  }

  Future<void> _saveMaintenanceTip(MaintenanceTip tip) async {
    try {
      // Save maintenance tip to database
    } catch (e) {
      debugPrint('Failed to save maintenance tip: $e');
    }
  }

  Future<void> _likeSharedContent(String contentId) async {
    final index = _sharedContent.indexWhere((c) => c.id == contentId);
    if (index != -1) {
      _sharedContent[index] = _sharedContent[index].copyWith(
        likes: _sharedContent[index].likes + 1,
      );
    }
  }

  Future<void> _likeMaintenanceTip(String tipId) async {
    final index = _maintenanceTips.indexWhere((t) => t.id == tipId);
    if (index != -1) {
      _maintenanceTips[index] = _maintenanceTips[index].copyWith(
        likes: _maintenanceTips[index].likes + 1,
      );
    }
  }

  Future<void> _likeReview(String reviewId) async {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _reviews[index] = _reviews[index].copyWith(
        helpfulVotes: _reviews[index].helpfulVotes + 1,
      );
    }
  }

  String _getContentTitle(dynamic content) {
    if (content is SharedContent) return content.title;
    if (content is MaintenanceTip) return content.title;
    if (content is ServiceCenterReview) return content.serviceCenterName;
    return '';
  }

  String _getContentDescription(dynamic content) {
    if (content is SharedContent) return content.description;
    if (content is MaintenanceTip) return content.description;
    if (content is ServiceCenterReview) return content.reviewText;
    return '';
  }

  List<String> _getContentTags(dynamic content) {
    if (content is SharedContent) return content.tags;
    if (content is MaintenanceTip) return content.tags;
    if (content is ServiceCenterReview) return content.serviceTypes;
    return [];
  }

  String? _getContentVehicleModel(dynamic content) {
    if (content is SharedContent) return content.vehicleModel;
    if (content is MaintenanceTip) return content.vehicleModel;
    return null;
  }

  DifficultyLevel? _getContentDifficulty(dynamic content) {
    if (content is SharedContent) return content.difficulty;
    if (content is MaintenanceTip) return content.difficulty;
    return null;
  }

  DateTime _getContentDate(dynamic content) {
    if (content is SharedContent) return content.createdAt;
    if (content is MaintenanceTip) return content.createdAt;
    if (content is ServiceCenterReview) return content.createdAt;
    return DateTime.now();
  }

  int _calculateEngagementScore(dynamic content) {
    if (content is SharedContent) {
      return content.likes + content.views + content.shares;
    }
    if (content is MaintenanceTip) {
      return content.likes + content.views + content.saves;
    }
    return 0;
  }
}

/// Service center review model
class ServiceCenterReview {
  final String id;
  final String serviceCenterId;
  final String serviceCenterName;
  final String authorId;
  final String authorName;
  final double rating;
  final String reviewText;
  final List<String> photoUrls;
  final List<String> serviceTypes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int helpfulVotes;
  final bool isVerified;

  ServiceCenterReview({
    required this.id,
    required this.serviceCenterId,
    required this.serviceCenterName,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.reviewText,
    required this.photoUrls,
    required this.serviceTypes,
    required this.createdAt,
    required this.updatedAt,
    required this.helpfulVotes,
    required this.isVerified,
  });

  ServiceCenterReview copyWith({
    String? id,
    String? serviceCenterId,
    String? serviceCenterName,
    String? authorId,
    String? authorName,
    double? rating,
    String? reviewText,
    List<String>? photoUrls,
    List<String>? serviceTypes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? helpfulVotes,
    bool? isVerified,
  }) {
    return ServiceCenterReview(
      id: id ?? this.id,
      serviceCenterId: serviceCenterId ?? this.serviceCenterId,
      serviceCenterName: serviceCenterName ?? this.serviceCenterName,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      photoUrls: photoUrls ?? this.photoUrls,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Shared content model
class SharedContent {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String description;
  final ContentType contentType;
  final List<String> mediaUrls;
  final List<String> tags;
  final String? vehicleModel;
  final DifficultyLevel? difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final int views;
  final int shares;
  final bool isFeatured;

  SharedContent({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.contentType,
    required this.mediaUrls,
    required this.tags,
    this.vehicleModel,
    this.difficulty,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.views,
    required this.shares,
    required this.isFeatured,
  });

  SharedContent copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? description,
    ContentType? contentType,
    List<String>? mediaUrls,
    List<String>? tags,
    String? vehicleModel,
    DifficultyLevel? difficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? views,
    int? shares,
    bool? isFeatured,
  }) {
    return SharedContent(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

/// Maintenance tip model
class MaintenanceTip {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String description;
  final List<String> steps;
  final List<String> mediaUrls;
  final List<String> tags;
  final String? vehicleModel;
  final DifficultyLevel difficulty;
  final Duration? estimatedTime;
  final List<String> requiredTools;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final int views;
  final int saves;
  final bool isVerified;

  MaintenanceTip({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.steps,
    required this.mediaUrls,
    required this.tags,
    this.vehicleModel,
    required this.difficulty,
    this.estimatedTime,
    required this.requiredTools,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.views,
    required this.saves,
    required this.isVerified,
  });

  MaintenanceTip copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? description,
    List<String>? steps,
    List<String>? mediaUrls,
    List<String>? tags,
    String? vehicleModel,
    DifficultyLevel? difficulty,
    Duration? estimatedTime,
    List<String>? requiredTools,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? views,
    int? saves,
    bool? isVerified,
  }) {
    return MaintenanceTip(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      requiredTools: requiredTools ?? this.requiredTools,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      saves: saves ?? this.saves,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Content operation result
class ContentResult {
  final bool success;
  final String message;

  ContentResult({required this.success, required this.message});

  factory ContentResult.success(String message) {
    return ContentResult(success: true, message: message);
  }

  factory ContentResult.error(String message) {
    return ContentResult(success: false, message: message);
  }
}

/// Enums
enum ContentType { photo, video, tutorial, repair, modification }

enum DifficultyLevel { beginner, intermediate, advanced, expert }

enum ContentCategory { sharedContent, maintenanceTip, review }
