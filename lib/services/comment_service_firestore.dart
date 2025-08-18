import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/storage_service.dart';
import '../data/models/comment_model.dart';

/// Firestore operations for comment service
class CommentServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService;
  
  static const String _commentsCollection = 'comments';
  static const String _commentsCachePrefix = 'comments_';

  // Expose firestore for connectivity checks
  FirebaseFirestore get firestore => _firestore;

  CommentServiceFirestore({
    required StorageService storageService,
  }) : _storageService = storageService;

  /// Fetch comments from Firestore for a specific section
  Future<List<Comment>> fetchCommentsFromFirestore(String lessonId, String sectionId) async {
    try {
      final sectionKey = '${lessonId}_$sectionId';
      final docRef = _firestore.collection(_commentsCollection).doc(sectionKey);
      
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final comments = (data['comments'] as List)
            .map((commentJson) => Comment.fromJson(commentJson))
            .toList();
        
        return comments;
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching comments from Firestore: $e');
      rethrow;
    }
  }

  /// Add new comment to Firestore
  Future<void> addCommentToFirestore(String lessonId, String sectionId, Comment comment) async {
    try {
      final sectionKey = '${lessonId}_$sectionId';
      final docRef = _firestore.collection(_commentsCollection).doc(sectionKey);
      
      // Get current document or create new one
      final doc = await docRef.get();
      final List<Map<String, dynamic>> comments = [];
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        comments.addAll((data['comments'] as List)
            .map((commentJson) => commentJson as Map<String, dynamic>)
            .toList());
      }
      
      // Add new comment
      comments.add(comment.toJson());
      
      // Update document
      await docRef.set({
        'comments': comments,
        'lastUpdated': DateTime.now().toIso8601String(),
        'totalComments': comments.length,
      });
      
      debugPrint('✅ Comment added to Firestore: ${comment.commentId}');
    } catch (e) {
      debugPrint('❌ Error adding comment to Firestore: $e');
      rethrow;
    }
  }

  /// Update comment in Firestore
  Future<void> updateCommentInFirestore(String commentId, Map<String, dynamic> updateData) async {
    try {
      // Find the comment in cache to get the correct document
      final commentInfo = await findCommentInCache(commentId);
      if (commentInfo == null) {
        throw Exception('Comment not found in cache for update');
      }
      
      final lessonId = commentInfo['lessonId'] as String;
      final sectionId = commentInfo['sectionId'] as String;
      final sectionKey = '${lessonId}_$sectionId';
      
      // Update the comment in Firestore
      await _firestore.collection(_commentsCollection).doc(sectionKey).update({
        'comments.${commentInfo['commentIndex']}': updateData,
      });
      
      debugPrint('✅ Comment updated in Firestore: $commentId');
    } catch (e) {
      debugPrint('❌ Error updating comment in Firestore: $e');
      rethrow;
    }
  }

  /// Delete comment from Firestore
  Future<void> deleteCommentFromFirestore(String commentId) async {
    try {
      // Find the comment in cache to get the correct document
      final commentInfo = await findCommentInCache(commentId);
      if (commentInfo == null) {
        throw Exception('Comment not found in cache for deletion');
      }
      
      final lessonId = commentInfo['lessonId'] as String;
      final sectionId = commentInfo['sectionId'] as String;
      final sectionKey = '${lessonId}_$sectionId';
      
      // Remove the comment from Firestore
      await _firestore.collection(_commentsCollection).doc(sectionKey).update({
        'comments.${commentInfo['commentIndex']}': FieldValue.delete(),
      });
      
      debugPrint('✅ Comment deleted from Firestore: $commentId');
    } catch (e) {
      debugPrint('❌ Error deleting comment from Firestore: $e');
      rethrow;
    }
  }

  /// Find comment in cache for Firestore update
  Future<Map<String, dynamic>?> findCommentInCache(String commentId) async {
    try {
      // Get all keys from SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith(_commentsCachePrefix)) {
          final cachedJson = await _storageService.getValue(key);
          if (cachedJson != null) {
            final data = jsonDecode(cachedJson) as Map<String, dynamic>;
            final comments = (data['comments'] as List)
                .map((commentJson) => Comment.fromJson(commentJson))
                .toList();
            
            final commentIndex = comments.indexWhere((c) => c.commentId == commentId);
            if (commentIndex != -1) {
              return {
                'key': key,
                'lessonId': key.substring(_commentsCachePrefix.length).split('_')[0],
                'sectionId': key.substring(_commentsCachePrefix.length).split('_').sublist(1).join('_'),
                'commentIndex': commentIndex,
              };
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error finding comment in cache: $e');
      return null;
    }
  }

  /// Process batch of comment actions
  Future<void> processActionBatch(List<Map<String, dynamic>> actions) async {
    try {
      // Group actions by type and process efficiently
      for (final action in actions) {
        final actionType = action['action'] as String;
        final commentId = action['commentId'] as String;
        
        switch (actionType) {
          case 'post':
            if (action['data'] != null) {
              final commentData = jsonDecode(action['data'] as String) as Map<String, dynamic>;
              final comment = Comment.fromJson(commentData);
              await addCommentToFirestore(
                action['lessonId'] as String,
                action['sectionId'] as String,
                comment,
              );
            }
            break;
            
          case 'like':
            await updateCommentInFirestore(commentId, {
              'likes': FieldValue.increment(1),
              'isLiked': true,
              'isDisliked': false,
            });
            break;
            
          case 'dislike':
            await updateCommentInFirestore(commentId, {
              'dislikes': FieldValue.increment(1),
              'isDisliked': true,
              'isLiked': false,
            });
            break;
            
          case 'delete':
            await deleteCommentFromFirestore(commentId);
            break;
            
          default:
            debugPrint('⚠️ Unknown action type: $actionType');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error processing action batch: $e');
      // Don't rethrow for network errors - allow offline operation
      if (e.toString().contains('Network') || e.toString().contains('connection')) {
        debugPrint('📡 Network error during batch processing - will retry later');
      } else {
        rethrow;
      }
    }
  }
}