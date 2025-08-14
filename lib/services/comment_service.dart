import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/storage_service.dart';
import '../data/models/comment_model.dart';
import '../data/repositories/user_repository.dart';
import 'comment_service_core.dart';
import 'comment_service_firestore.dart';

/// Comment service for managing section-based comments with 24-hour caching strategy
class CommentService implements CommentServiceCore {
  final StorageService _storageService;
  final UserRepository _userRepository;
  
  static const String _commentsCachePrefix = 'comments_';
  static const String _commentActionsQueueKey = 'comment_actions_queue';
  static const int _cacheTtlHours = 24; // 24-hour caching strategy

  late final CommentServiceFirestore _firestoreService;

  CommentService({
    required StorageService storageService,
    required UserRepository userRepository,
  }) : _storageService = storageService,
       _userRepository = userRepository {
    _firestoreService = CommentServiceFirestore(
      storageService: storageService,
      commentService: this,
    );
  }

  @override
  Future<List<Comment>> getCommentsForSection(String lessonId, String sectionId) async {
    try {
      final cachedComments = await _getCachedComments(lessonId, sectionId);
      if (cachedComments != null) return cachedComments;

      final comments = await _firestoreService.fetchCommentsFromFirestore(lessonId, sectionId);
      await _cacheComments(lessonId, sectionId, comments);
      return comments;
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      rethrow;
    }
  }

  @override
  Future<void> postComment(String lessonId, String sectionId, String text) async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user == null) throw Exception('No user logged in');

      final comment = Comment(
        commentId: Comment.generateCommentId(),
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Anonymous',
        lessonId: lessonId,
        sectionId: sectionId,
        content: text,
        createdAt: DateTime.now(),
        likes: 0,
        dislikes: 0,
        isOwner: true,
      );

      await _addToLocalCache(lessonId, sectionId, comment);
      await _queueCommentAction(
        lessonId: lessonId,
        sectionId: sectionId,
        action: 'post',
        commentId: comment.commentId,
        data: comment.toJson(),
      );
      
      debugPrint('✅ Comment posted locally');
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      rethrow;
    }
  }

  @override
  Future<void> likeComment(String commentId) async {
    await _queueCommentAction(commentId: commentId, action: 'like');
    debugPrint('✅ Comment like queued');
  }

  @override
  Future<void> dislikeComment(String commentId) async {
    await _queueCommentAction(commentId: commentId, action: 'dislike');
    debugPrint('✅ Comment dislike queued');
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _queueCommentAction(commentId: commentId, action: 'delete');
    debugPrint('✅ Comment deletion queued');
  }

  @override
  Future<void> syncQueuedActions() async {
    try {
      final queuedActions = await _getQueuedActions();
      if (queuedActions.isEmpty) {
        debugPrint('📝 No comment actions to sync');
        return;
      }

      final batchSize = 50;
      for (int i = 0; i < queuedActions.length; i += batchSize) {
        final batch = queuedActions.skip(i).take(batchSize).toList();
        await _firestoreService.processActionBatch(batch);
      }

      await _clearQueuedActions();
      debugPrint('✅ Comment actions synced successfully');
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      if (!e.toString().contains('Network')) rethrow;
    }
  }

  @override
  Future<int> getCommentCount(String lessonId, String sectionId) async {
    try {
      final comments = await getCommentsForSection(lessonId, sectionId);
      return comments.length;
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      return 0;
    }
  }

  @override
  Future<bool> isCacheExpired(String lessonId, String sectionId) async {
    try {
      final cacheKey = '$_commentsCachePrefix${lessonId}_$sectionId';
      final cachedJson = await _storageService.getValue('${cacheKey}_metadata');
      
      if (cachedJson != null) {
        final metadata = jsonDecode(cachedJson) as Map<String, dynamic>;
        final cachedAt = DateTime.parse(metadata['cachedAt'] as String);
        final expiration = cachedAt.add(const Duration(hours: _cacheTtlHours));
        return DateTime.now().isAfter(expiration);
      }
      return true;
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      return true;
    }
  }

  @override
  Future<void> clearSectionCache(String lessonId, String sectionId) async {
    try {
      final cacheKey = '$_commentsCachePrefix${lessonId}_$sectionId';
      await _storageService.removeValue(cacheKey);
      await _storageService.removeValue('${cacheKey}_metadata');
      debugPrint('✅ Cache cleared');
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final queuedActions = await _getQueuedActions();
      final isOnline = await _isOnline();
      final cacheStats = await getCacheStats();
      
      return {
        'isOnline': isOnline,
        'queuedActions': queuedActions.length,
        'lastSync': await _getLastSyncTime(),
        'cacheStats': cacheStats,
      };
    } catch (e) {
      debugPrint('❌ Error getting sync status: $e');
      return {
        'isOnline': false,
        'queuedActions': 0,
        'lastSync': null,
        'cacheStats': {},
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      int totalCachedSections = 0;
      int expiredSections = 0;
      
      for (final key in allKeys) {
        if (key.startsWith(_commentsCachePrefix) && key.endsWith('_metadata')) {
          totalCachedSections++;
          final metadataJson = await _storageService.getValue(key);
          if (metadataJson != null) {
            final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
            final cachedAt = DateTime.parse(metadata['cachedAt'] as String);
            final expiration = cachedAt.add(const Duration(hours: _cacheTtlHours));
            if (DateTime.now().isAfter(expiration)) expiredSections++;
          }
        }
      }
      
      return {
        'totalCachedSections': totalCachedSections,
        'expiredSections': expiredSections,
        'cacheHitRate': totalCachedSections > 0 ? (totalCachedSections - expiredSections) / totalCachedSections : 0.0,
      };
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      return {'totalCachedSections': 0, 'expiredSections': 0, 'cacheHitRate': 0.0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChildCommentActivity(String childId) async {
    return []; // Placeholder for parent dashboard
  }

  // Private helper methods
  Future<List<Comment>?> _getCachedComments(String lessonId, String sectionId) async {
    try {
      final cacheKey = '$_commentsCachePrefix${lessonId}_$sectionId';
      final cachedJson = await _storageService.getValue(cacheKey);
      
      if (cachedJson != null) {
        final data = jsonDecode(cachedJson) as Map<String, dynamic>;
        return (data['comments'] as List)
            .map((commentJson) => Comment.fromJson(commentJson))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      return null;
    }
  }

  Future<void> _cacheComments(String lessonId, String sectionId, List<Comment> comments) async {
    try {
      final cacheKey = '$_commentsCachePrefix${lessonId}_$sectionId';
      final metadataKey = '${cacheKey}_metadata';
      
      await _storageService.setValue(
        cacheKey,
        jsonEncode({
          'comments': comments.map((comment) => comment.toJson()).toList(),
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );
      
      await _storageService.setValue(
        metadataKey,
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'lessonId': lessonId,
          'sectionId': sectionId,
          'commentCount': comments.length,
        }),
      );
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
    }
  }

  Future<void> _addToLocalCache(String lessonId, String sectionId, Comment comment) async {
    try {
      final cachedComments = await _getCachedComments(lessonId, sectionId) ?? [];
      cachedComments.add(comment);
      await _cacheComments(lessonId, sectionId, cachedComments);
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
    }
  }

  Future<void> _queueCommentAction({
    required String action,
    String? lessonId,
    String? sectionId,
    String? commentId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final actionData = {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _userRepository.getCurrentUser()?.uid ?? '',
      };

      if (lessonId != null) actionData['lessonId'] = lessonId;
      if (sectionId != null) actionData['sectionId'] = sectionId;
      if (commentId != null) actionData['commentId'] = commentId;
      if (data != null) actionData['data'] = jsonEncode(data);

      final existingQueue = await _getQueuedActions();
      existingQueue.add(actionData);
      await _storageService.setValue(_commentActionsQueueKey, jsonEncode(existingQueue));
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getQueuedActions() async {
    try {
      final queueJson = await _storageService.getValue(_commentActionsQueueKey);
      if (queueJson != null) {
        return (jsonDecode(queueJson) as List)
            .map((action) => action as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
      return [];
    }
  }

  Future<void> _clearQueuedActions() async {
    try {
      await _storageService.removeValue(_commentActionsQueueKey);
    } catch (e) {
      debugPrint('❌ CommentService error: $e');
    }
  }

  Future<bool> _isOnline() async {
    try {
      await _firestoreService.firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    try {
      final lastSyncJson = await _storageService.getValue('comment_last_sync');
      if (lastSyncJson != null) {
        return DateTime.parse(lastSyncJson);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting last sync time: $e');
      return null;
    }
  }
}