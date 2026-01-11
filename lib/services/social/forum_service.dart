import 'dart:async';
import 'package:flutter/foundation.dart';
import 'user_profile_service.dart';

/// Service for managing community forums and discussions
class ForumService extends ChangeNotifier {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;
  ForumService._internal();

  final UserProfileService _userService = UserProfileService();

  final List<ForumCategory> _categories = [];
  final Map<String, List<ForumPost>> _posts = {};
  final Map<String, List<ForumReply>> _replies = {};

  bool _isInitialized = false;

  /// Get forum categories
  List<ForumCategory> get categories => List.unmodifiable(_categories);

  /// Initialize forum service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _setupDefaultCategories();
    await _loadForumData();

    _isInitialized = true;
  }

  /// Create new forum post
  Future<ForumResult> createPost({
    required String categoryId,
    required String title,
    required String content,
    List<String>? tags,
    PostType type = PostType.discussion,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ForumResult.error('User not logged in');
      }

      final post = ForumPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: categoryId,
        authorId: currentUser.userId,
        authorName: currentUser.displayName,
        title: title,
        content: content,
        type: type,
        tags: tags ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        votes: 0,
        replyCount: 0,
        viewCount: 0,
        isPinned: false,
        isLocked: false,
      );

      _posts[categoryId] ??= [];
      _posts[categoryId]!.insert(0, post);

      await _savePost(post);

      // Update user reputation
      await _userService.updateReputation(
        userId: currentUser.userId,
        action: ReputationAction.helpfulPost,
      );

      notifyListeners();
      return ForumResult.success('Post created successfully');
    } catch (e) {
      return ForumResult.error('Failed to create post: $e');
    }
  }

  /// Reply to a forum post
  Future<ForumResult> replyToPost({
    required String postId,
    required String content,
    String? parentReplyId,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ForumResult.error('User not logged in');
      }

      final reply = ForumReply(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: postId,
        authorId: currentUser.userId,
        authorName: currentUser.displayName,
        content: content,
        parentReplyId: parentReplyId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        votes: 0,
        isBestAnswer: false,
      );

      _replies[postId] ??= [];
      _replies[postId]!.add(reply);

      // Update post reply count
      await _incrementPostReplyCount(postId);

      await _saveReply(reply);

      notifyListeners();
      return ForumResult.success('Reply posted successfully');
    } catch (e) {
      return ForumResult.error('Failed to post reply: $e');
    }
  }

  /// Vote on a post or reply
  Future<ForumResult> vote({
    required String itemId,
    required VoteType voteType,
    required bool isPost,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ForumResult.error('User not logged in');
      }

      final voteValue = voteType == VoteType.upvote ? 1 : -1;

      if (isPost) {
        await _updatePostVotes(itemId, voteValue);
      } else {
        await _updateReplyVotes(itemId, voteValue);
      }

      // Track user vote to prevent duplicate voting
      await _recordUserVote(currentUser.userId, itemId, voteType);

      notifyListeners();
      return ForumResult.success('Vote recorded');
    } catch (e) {
      return ForumResult.error('Failed to record vote: $e');
    }
  }

  /// Mark reply as best answer
  Future<ForumResult> markBestAnswer(String replyId) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ForumResult.error('User not logged in');
      }

      // Find the reply and update it
      for (final replies in _replies.values) {
        final replyIndex = replies.indexWhere((r) => r.id == replyId);
        if (replyIndex != -1) {
          final reply = replies[replyIndex];
          replies[replyIndex] = reply.copyWith(isBestAnswer: true);

          await _updateReplyBestAnswer(replyId, true);

          // Update author reputation
          await _userService.updateReputation(
            userId: reply.authorId,
            action: ReputationAction.bestAnswer,
          );

          notifyListeners();
          return ForumResult.success('Best answer marked');
        }
      }

      return ForumResult.error('Reply not found');
    } catch (e) {
      return ForumResult.error('Failed to mark best answer: $e');
    }
  }

  /// Get posts for a category
  List<ForumPost> getPostsForCategory(String categoryId) {
    return _posts[categoryId] ?? [];
  }

  /// Get replies for a post
  List<ForumReply> getRepliesForPost(String postId) {
    return _replies[postId] ?? [];
  }

  /// Search posts
  Future<List<ForumPost>> searchPosts({
    String? query,
    String? categoryId,
    List<String>? tags,
    PostType? type,
    int limit = 20,
  }) async {
    try {
      List<ForumPost> allPosts = [];

      if (categoryId != null) {
        allPosts = _posts[categoryId] ?? [];
      } else {
        for (final posts in _posts.values) {
          allPosts.addAll(posts);
        }
      }

      // Filter by query
      if (query != null && query.isNotEmpty) {
        allPosts = allPosts
            .where(
              (post) =>
                  post.title.toLowerCase().contains(query.toLowerCase()) ||
                  post.content.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }

      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        allPosts = allPosts
            .where((post) => post.tags.any((tag) => tags.contains(tag)))
            .toList();
      }

      // Filter by type
      if (type != null) {
        allPosts = allPosts.where((post) => post.type == type).toList();
      }

      // Sort by relevance/date
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allPosts.take(limit).toList();
    } catch (e) {
      debugPrint('Failed to search posts: $e');
      return [];
    }
  }

  /// Get trending posts
  List<ForumPost> getTrendingPosts({int limit = 10}) {
    List<ForumPost> allPosts = [];

    for (final posts in _posts.values) {
      allPosts.addAll(posts);
    }

    // Sort by engagement score (votes + replies + views)
    allPosts.sort((a, b) {
      final scoreA = a.votes + a.replyCount + (a.viewCount / 10).round();
      final scoreB = b.votes + b.replyCount + (b.viewCount / 10).round();
      return scoreB.compareTo(scoreA);
    });

    return allPosts.take(limit).toList();
  }

  /// Get user's posts
  Future<List<ForumPost>> getUserPosts(String userId, {int limit = 20}) async {
    List<ForumPost> userPosts = [];

    for (final posts in _posts.values) {
      userPosts.addAll(posts.where((post) => post.authorId == userId));
    }

    userPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userPosts.take(limit).toList();
  }

  /// Report content
  Future<ForumResult> reportContent({
    required String contentId,
    required ContentType contentType,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      final currentUser = _userService.currentUserProfile;
      if (currentUser == null) {
        return ForumResult.error('User not logged in');
      }

      final report = ContentReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contentId: contentId,
        contentType: contentType,
        reporterId: currentUser.userId,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
        status: ReportStatus.pending,
      );

      await _saveContentReport(report);

      return ForumResult.success('Content reported successfully');
    } catch (e) {
      return ForumResult.error('Failed to report content: $e');
    }
  }

  // Private methods

  Future<void> _setupDefaultCategories() async {
    _categories.addAll([
      ForumCategory(
        id: 'general',
        name: 'General Discussion',
        description: 'General vehicle and automotive discussions',
        icon: 'chat',
        color: 0xFF2196F3,
        postCount: 0,
        isModerated: true,
      ),
      ForumCategory(
        id: 'maintenance',
        name: 'Maintenance & Repairs',
        description: 'Questions and tips about vehicle maintenance',
        icon: 'build',
        color: 0xFFFF9800,
        postCount: 0,
        isModerated: true,
      ),
      ForumCategory(
        id: 'performance',
        name: 'Performance & Tuning',
        description: 'Discussions about vehicle performance optimization',
        icon: 'speed',
        color: 0xFFF44336,
        postCount: 0,
        isModerated: true,
      ),
      ForumCategory(
        id: 'reviews',
        name: 'Reviews & Recommendations',
        description: 'Service center reviews and product recommendations',
        icon: 'star',
        color: 0xFF4CAF50,
        postCount: 0,
        isModerated: true,
      ),
      ForumCategory(
        id: 'qa',
        name: 'Q&A',
        description: 'Questions and answers from the community',
        icon: 'help',
        color: 0xFF9C27B0,
        postCount: 0,
        isModerated: true,
      ),
    ]);
  }

  Future<void> _loadForumData() async {
    try {
      // Load forum data from database
      // This would query the posts and replies tables
    } catch (e) {
      debugPrint('Failed to load forum data: $e');
    }
  }

  Future<void> _savePost(ForumPost post) async {
    try {
      // Save post to database
    } catch (e) {
      debugPrint('Failed to save post: $e');
    }
  }

  Future<void> _saveReply(ForumReply reply) async {
    try {
      // Save reply to database
    } catch (e) {
      debugPrint('Failed to save reply: $e');
    }
  }

  Future<void> _incrementPostReplyCount(String postId) async {
    try {
      // Update post reply count in database and local cache
      for (final posts in _posts.values) {
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = posts[postIndex];
          posts[postIndex] = post.copyWith(replyCount: post.replyCount + 1);
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to increment post reply count: $e');
    }
  }

  Future<void> _updatePostVotes(String postId, int voteValue) async {
    try {
      // Update post votes in database and local cache
      for (final posts in _posts.values) {
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = posts[postIndex];
          posts[postIndex] = post.copyWith(votes: post.votes + voteValue);
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to update post votes: $e');
    }
  }

  Future<void> _updateReplyVotes(String replyId, int voteValue) async {
    try {
      // Update reply votes in database and local cache
      for (final replies in _replies.values) {
        final replyIndex = replies.indexWhere((r) => r.id == replyId);
        if (replyIndex != -1) {
          final reply = replies[replyIndex];
          replies[replyIndex] = reply.copyWith(votes: reply.votes + voteValue);
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to update reply votes: $e');
    }
  }

  Future<void> _updateReplyBestAnswer(String replyId, bool isBestAnswer) async {
    try {
      // Update reply best answer status in database
    } catch (e) {
      debugPrint('Failed to update reply best answer: $e');
    }
  }

  Future<void> _recordUserVote(
    String userId,
    String itemId,
    VoteType voteType,
  ) async {
    try {
      // Record user vote to prevent duplicate voting
    } catch (e) {
      debugPrint('Failed to record user vote: $e');
    }
  }

  Future<void> _saveContentReport(ContentReport report) async {
    try {
      // Save content report to database
    } catch (e) {
      debugPrint('Failed to save content report: $e');
    }
  }
}

/// Forum category model
class ForumCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int color;
  final int postCount;
  final bool isModerated;

  ForumCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.postCount,
    required this.isModerated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'post_count': postCount,
      'is_moderated': isModerated,
    };
  }
}

/// Forum post model
class ForumPost {
  final String id;
  final String categoryId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final PostType type;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int votes;
  final int replyCount;
  final int viewCount;
  final bool isPinned;
  final bool isLocked;

  ForumPost({
    required this.id,
    required this.categoryId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.type,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.votes,
    required this.replyCount,
    required this.viewCount,
    required this.isPinned,
    required this.isLocked,
  });

  ForumPost copyWith({
    String? id,
    String? categoryId,
    String? authorId,
    String? authorName,
    String? title,
    String? content,
    PostType? type,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? votes,
    int? replyCount,
    int? viewCount,
    bool? isPinned,
    bool? isLocked,
  }) {
    return ForumPost(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      votes: votes ?? this.votes,
      replyCount: replyCount ?? this.replyCount,
      viewCount: viewCount ?? this.viewCount,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'author_id': authorId,
      'author_name': authorName,
      'title': title,
      'content': content,
      'type': type.toString(),
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'votes': votes,
      'reply_count': replyCount,
      'view_count': viewCount,
      'is_pinned': isPinned,
      'is_locked': isLocked,
    };
  }
}

/// Forum reply model
class ForumReply {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final String? parentReplyId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int votes;
  final bool isBestAnswer;

  ForumReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.parentReplyId,
    required this.createdAt,
    required this.updatedAt,
    required this.votes,
    required this.isBestAnswer,
  });

  ForumReply copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    String? parentReplyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? votes,
    bool? isBestAnswer,
  }) {
    return ForumReply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      parentReplyId: parentReplyId ?? this.parentReplyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      votes: votes ?? this.votes,
      isBestAnswer: isBestAnswer ?? this.isBestAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'parent_reply_id': parentReplyId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'votes': votes,
      'is_best_answer': isBestAnswer,
    };
  }
}

/// Content report model
class ContentReport {
  final String id;
  final String contentId;
  final ContentType contentType;
  final String reporterId;
  final ReportReason reason;
  final String? description;
  final DateTime createdAt;
  final ReportStatus status;

  ContentReport({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.reporterId,
    required this.reason,
    this.description,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'content_type': contentType.toString(),
      'reporter_id': reporterId,
      'reason': reason.toString(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status.toString(),
    };
  }
}

/// Forum operation result
class ForumResult {
  final bool success;
  final String message;

  ForumResult({required this.success, required this.message});

  factory ForumResult.success(String message) {
    return ForumResult(success: true, message: message);
  }

  factory ForumResult.error(String message) {
    return ForumResult(success: false, message: message);
  }
}

/// Enums
enum PostType { discussion, question, announcement, tutorial }

enum VoteType { upvote, downvote }

enum ContentType { post, reply }

enum ReportReason { spam, inappropriate, harassment, misinformation, other }

enum ReportStatus { pending, reviewed, resolved, dismissed }
