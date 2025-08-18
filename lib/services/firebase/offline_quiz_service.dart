import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quiz_model.dart';

/// Service for ensuring offline quiz functionality
/// Provides fallback mechanisms when network is unavailable
class OfflineQuizService {
  static const String _offlinePrefix = 'offline_quiz_';
  static const String _offlineAttemptsPrefix = 'offline_attempt_';
  static const int _maxOfflineAttempts = 100; // Max attempts to store
  
  
  /// Check if device has network connectivity (simplified version)
  Future<bool> isOnline() async {
    // For now, always return true as we don't have connectivity_plus dependency
    // In a real app, you would use connectivity_plus or similar
    return true;
  }
  
  /// Get cached quiz questions for offline use
  Future<List<QuizQuestion>?> getCachedQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final cacheKey = '$_offlinePrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson != null) {
        final List<dynamic> jsonList = jsonDecode(cachedJson);
        return jsonList.map((json) => QuizQuestion.fromJson(json)).toList();
      }
      
      return null;
    } catch (e) {
      debugPrint('Error reading cached quiz questions: $e');
      return null;
    }
  }
  
  /// Cache quiz questions for offline use
  Future<bool> cacheQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    final cacheKey = '$_offlinePrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = jsonEncode(questions.map((q) => q.toJson()).toList());
      
      return await prefs.setString(cacheKey, questionsJson);
    } catch (e) {
      debugPrint('Error caching quiz questions: $e');
      return false;
    }
  }
  
  /// Record offline quiz attempt
  Future<bool> recordOfflineQuizAttempt({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
    required List<int> answers,
    required int score,
    required int totalQuestions,
  }) async {
    final attemptKey = '$_offlineAttemptsPrefix${studentId}_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptData = {
        'studentId': studentId,
        'grade': grade,
        'subject': subject,
        'topic': topic,
        'answers': answers,
        'score': score,
        'totalQuestions': totalQuestions,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'synced': false,
      };
      
      // Store the attempt
      await prefs.setString(attemptKey, jsonEncode(attemptData));
      
      // Clean up old attempts if we're over the limit
      await _cleanupOldOfflineAttempts();
      
      return true;
    } catch (e) {
      debugPrint('Error recording offline quiz attempt: $e');
      return false;
    }
  }
  
  /// Get pending offline quiz attempts
  Future<List<Map<String, dynamic>>> getPendingOfflineAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final offlineKeys = allKeys.where((key) => key.startsWith(_offlineAttemptsPrefix)).toList();
      
      final pendingAttempts = <Map<String, dynamic>>[];
      
      for (final key in offlineKeys) {
        final attemptJson = prefs.getString(key);
        if (attemptJson != null) {
          final attemptData = jsonDecode(attemptJson) as Map<String, dynamic>;
          if (attemptData['synced'] == false) {
            pendingAttempts.add(attemptData);
          }
        }
      }
      
      return pendingAttempts;
    } catch (e) {
      debugPrint('Error getting pending offline attempts: $e');
      return [];
    }
  }
  
  /// Mark offline attempt as synced
  Future<bool> markOfflineAttemptAsSynced(String attemptKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptJson = prefs.getString(attemptKey);
      
      if (attemptJson != null) {
        final attemptData = jsonDecode(attemptJson) as Map<String, dynamic>;
        attemptData['synced'] = true;
        
        await prefs.setString(attemptKey, jsonEncode(attemptData));
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error marking offline attempt as synced: $e');
      return false;
    }
  }
  
  /// Sync pending offline attempts when online
  Future<int> syncPendingOfflineAttempts() async {
    if (!await isOnline()) {
      debugPrint('Cannot sync offline attempts - device is offline');
      return 0;
    }
    
    try {
      final pendingAttempts = await getPendingOfflineAttempts();
      int syncedCount = 0;
      
      for (final attempt in pendingAttempts) {
        try {
          // Here you would normally send the attempt to your backend
          // For now, we'll just mark it as synced
          final attemptKey = '$_offlineAttemptsPrefix${attempt['studentId']}_${attempt['timestamp']}';
          await markOfflineAttemptAsSynced(attemptKey);
          syncedCount++;
        } catch (e) {
          debugPrint('Error syncing offline attempt: $e');
        }
      }
      
      return syncedCount;
    } catch (e) {
      debugPrint('Error syncing pending offline attempts: $e');
      return 0;
    }
  }
  
  /// Clean up old offline attempts
  Future<void> _cleanupOldOfflineAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final offlineKeys = allKeys.where((key) => key.startsWith(_offlineAttemptsPrefix)).toList();
      
      if (offlineKeys.length > _maxOfflineAttempts) {
        // Sort by timestamp (oldest first)
        offlineKeys.sort((a, b) {
          final timestampA = int.parse(a.split('_').last);
          final timestampB = int.parse(b.split('_').last);
          return timestampA.compareTo(timestampB);
        });
        
        // Remove oldest entries
        final keysToRemove = offlineKeys.sublist(0, offlineKeys.length - _maxOfflineAttempts);
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old offline attempts: $e');
    }
  }
  
  /// Clear all offline quiz data
  Future<bool> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith(_offlinePrefix) || key.startsWith(_offlineAttemptsPrefix)) {
          await prefs.remove(key);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error clearing all offline data: $e');
      return false;
    }
  }
  
  /// Get offline quiz statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final cachedQuizzes = allKeys.where((key) => key.startsWith(_offlinePrefix)).length;
      final offlineAttempts = allKeys.where((key) => key.startsWith(_offlineAttemptsPrefix)).length;
      
      final pendingAttempts = await getPendingOfflineAttempts();
      
      return {
        'cached_quizzes': cachedQuizzes,
        'offline_attempts': offlineAttempts,
        'pending_sync': pendingAttempts.length,
        'is_online': await isOnline(),
        'max_offline_attempts': _maxOfflineAttempts,
      };
    } catch (e) {
      debugPrint('Error getting offline stats: $e');
      return {};
    }
  }
  
  /// Preload quiz questions for offline use
  Future<bool> preloadQuizForOffline({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    try {
      // Check if we're online first
      if (!await isOnline()) {
        debugPrint('Cannot preload - device is offline');
        return false;
      }
      
      // Cache the questions for offline use
      final success = await cacheQuizQuestions(
        grade: grade,
        subject: subject,
        topic: topic,
        questions: questions,
      );
      
      if (success) {
        debugPrint('Quiz preloaded for offline use: $grade/$subject/$topic');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error preloading quiz for offline: $e');
      return false;
    }
  }
}

/// Extension to add offline capabilities to QuizService