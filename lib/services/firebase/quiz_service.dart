import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/models/quiz_model.dart' as quiz;
import 'cost_optimized_cache_service.dart';
import 'batch_operation_service.dart';
import 'lru_cache_service.dart';
import 'incremental_sync_service.dart';
import 'offline_quiz_service.dart';
import 'performance_optimization_service.dart';
import 'retry_service.dart';

class QuizService {
  
  final CostOptimizedCacheService _cacheService = CostOptimizedCacheService();
  final BatchOperationService _batchService = BatchOperationService();
  final LRUCacheService _lruCacheService = LRUCacheService();
  final IncrementalSyncService _syncService = IncrementalSyncService();
  final OfflineQuizService _offlineService = OfflineQuizService();
  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();

  /// Get quiz questions with 30-day caching strategy using LRU cache and incremental sync
  Future<List<quiz.QuizQuestion>> getQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    return await RetryService.executeWithSmartRetry(
      operation: () async {
        return await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'get_quiz_questions_$grade/$subject/$topic',
          operation: () async {
            // Try LRU cache first for better performance
            final cached = await _lruCacheService.getCachedQuizQuestions(
              grade: grade,
              subject: subject,
              topic: topic,
            );
            
            if (cached != null) {
              debugPrint('Performance: LRU cache hit for $grade/$subject/$topic');
              return cached;
            }
            
            debugPrint('Performance: LRU cache miss for $grade/$subject/$topic, checking incremental sync');
            
            // Check if we need to sync before fetching
            final needsSync = await _syncService.needsSync(
              grade: grade,
              subject: subject,
              topic: topic,
            );
            
            if (needsSync) {
              debugPrint('Performance: Incremental sync needed for $grade/$subject/$topic');
              await _syncService.forceSync();
            }
            
            // Try cost optimized cache as fallback
            final fallbackCached = await _cacheService.getCachedQuizQuestions(
              grade: grade,
              subject: subject,
              topic: topic,
            );
            
            if (fallbackCached != null) {
              debugPrint('Performance: Fallback cache hit for $grade/$subject/$topic');
              // Cache in LRU for future requests
              await _lruCacheService.cacheQuizQuestions(
                grade: grade,
                subject: subject,
                topic: topic,
                questions: fallbackCached,
              );
              return fallbackCached;
            }
            
            // Fetch from Firebase
            final questions = await _fetchQuestionsFromFirebase(grade, subject, topic);
            
            // Cache in all services for optimal performance
            await _lruCacheService.cacheQuizQuestions(
              grade: grade,
              subject: subject,
              topic: topic,
              questions: questions,
            );
            
            await _cacheService.cacheQuizQuestions(
              grade: grade,
              subject: subject,
              topic: topic,
              questions: questions,
            );
            
            // Cache for offline use
            await _offlineService.cacheQuizQuestions(
              grade: grade,
              subject: subject,
              topic: topic,
              questions: questions,
            );
            
            return questions;
          },
        );
      },
      operationName: 'get_quiz_questions_$grade/$subject/$topic',
    );
  }

  /// Fetch questions from Firestore
  Future<List<quiz.QuizQuestion>> _fetchQuestionsFromFirebase(
    String grade,
    String subject,
    String topic,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('quizzes')
          .doc(grade)
          .collection(subject)
          .doc(topic);
      
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('No quiz found for $grade/$subject/$topic');
      }
      
      final data = doc.data()!;
      final questionsData = data['questions'] as List;
      
      return questionsData.map((q) => quiz.QuizQuestion.fromJson(q)).toList();
    } catch (e) {
      debugPrint('Error fetching quiz questions: $e');
      throw Exception('Failed to load quiz questions: $e');
    }
  }



  /// Clear cache for a specific topic using both cache services
  Future<void> clearTopicCache(String grade, String subject, String topic) async {
    try {
      await _lruCacheService.clearTopicCache(
        grade: grade,
        subject: subject,
        topic: topic,
      );
      
      await _cacheService.clearTopicCache(
        grade: grade,
        subject: subject,
        topic: topic,
      );
      
      debugPrint('Both LRU and fallback cache cleared for $grade/$subject/$topic');
    } catch (e) {
      debugPrint('Error clearing topic cache: $e');
    }
  }
  
  /// Clear cache for a specific topic when admin uploads occur
  Future<void> invalidateTopicCacheOnAdminUpdate({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      // Clear the topic cache
      await clearTopicCache(grade, subject, topic);
      
      // Update last sync timestamp for incremental sync
      await _cacheService.updateLastSyncTimestamp(
        grade: grade,
        subject: subject,
        topic: topic,
      );
      
      // Force LRU cache cleanup to remove any expired items
      await _lruCacheService.forceCacheCleanup();
      
      debugPrint('Cache invalidated for admin update: $grade/$subject/$topic');
    } catch (e) {
      debugPrint('Error invalidating topic cache: $e');
    }
  }

  /// Record quiz attempts using BatchOperationService for cost optimization
  Future<void> recordQuizAttempt(quiz.QuizAttempt attempt) async {
    await RetryService.executeWithSmartRetry(
      operation: () async {
        await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'record_quiz_attempt_${attempt.studentId}',
          operation: () async {
            // Use BatchOperationService for background queuing and batching
            await _batchService.queueQuizAttempt(attempt);
            debugPrint('Performance: Quiz attempt queued for batch processing: ${attempt.studentId}');
          },
        );
      },
      operationName: 'record_quiz_attempt_${attempt.studentId}',
    );
  }
  
  /// Queue quiz update for incremental sync (used by admin operations)
  Future<void> queueQuizUpdate({
    required String grade,
    required String subject,
    required String topic,
    required List<quiz.QuizQuestion> questions,
    required String operation, // 'create', 'update', 'delete'
  }) async {
    try {
      await _syncService.queueQuizUpdate(
        grade: grade,
        subject: subject,
        topic: topic,
        questions: questions,
        operation: operation,
      );
      debugPrint('Quiz update queued for incremental sync: $operation for $grade/$subject/$topic');
    } catch (e) {
      debugPrint('Error queuing quiz update: $e');
      throw Exception('Failed to queue quiz update: $e');
    }
  }
  
  /// Batch record quiz attempts for cost optimization (legacy method)
  Future<void> batchRecordAttempts(List<quiz.QuizAttempt> attempts) async {
    if (attempts.isEmpty) return;
    
    try {
      // Use BatchOperationService for background queuing and batching
      for (final attempt in attempts) {
        await _batchService.queueQuizAttempt(attempt);
      }
      
      debugPrint('Quiz attempts queued for batch processing: ${attempts.length}');
    } catch (e) {
      debugPrint('Error queuing quiz attempts: $e');
      throw Exception('Failed to record quiz attempts: $e');
    }
  }
  
  /// Force immediate sync of pending quiz attempts
  Future<void> forceSyncPendingAttempts() async {
    try {
      await _batchService.forceSync();
      debugPrint('Pending quiz attempts synced');
    } catch (e) {
      debugPrint('Error syncing pending quiz attempts: $e');
      throw Exception('Failed to sync quiz attempts: $e');
    }
  }

  /// Validate quiz question structure
  static bool validateQuizQuestion(Map<String, dynamic> questionData) {
    try {
      // Check required fields
      if (questionData['question'] == null || questionData['question'] is! String) {
        return false;
      }
      
      if (questionData['options'] == null || questionData['options'] is! List) {
        return false;
      }
      
      final options = questionData['options'] as List;
      if (options.length != 4 || !options.every((opt) => opt is String)) {
        return false;
      }
      
      if (questionData['correctAnswerIndex'] == null || 
          questionData['correctAnswerIndex'] is! int ||
          questionData['correctAnswerIndex'] < 0 || 
          questionData['correctAnswerIndex'] >= 4) {
        return false;
      }
      
      if (questionData['explanation'] == null || questionData['explanation'] is! String) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating quiz question: $e');
      return false;
    }
  }

  /// Get all available quiz topics for a grade and subject
  Future<List<String>> getAvailableTopics(String grade, String subject) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(grade)
          .collection(subject)
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching available topics: $e');
      return [];
    }
  }

  /// Get all available subjects for a grade
  Future<List<String>> getAvailableSubjects(String grade) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(grade)
          .collection('subjects')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching available subjects: $e');
      return [];
    }
  }

  /// Clear all quiz cache (useful for admin updates)
  Future<void> clearAllQuizCache() async {
    try {
      // Clear LRU cache
      await _lruCacheService.clearAllQuizCaches();
      
      // Clear cost optimized cache
      await _cacheService.clearAllQuizCaches();
      
      debugPrint('All quiz cache cleared');
    } catch (e) {
      debugPrint('Error clearing all quiz cache: $e');
    }
  }
  
  /// Get cache statistics for performance monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final lruStats = await _lruCacheService.getCacheStats();
      final syncStats = _syncService.getSyncStats();
      final offlineStats = await _offlineService.getOfflineStats();
      final performanceStats = _performanceService.getPerformanceStats();
      
      return {
        'lru_cache': lruStats,
        'cache_service': 'CostOptimizedCacheService',
        'total_cache_layers': 2,
        'incremental_sync': syncStats,
        'offline_service': offlineStats,
        'performance_monitoring': performanceStats,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }
  
  /// Initialize incremental sync service
  Future<void> initializeIncrementalSync() async {
    try {
      await _syncService.initialize();
      debugPrint('Incremental sync service initialized');
    } catch (e) {
      debugPrint('Error initializing incremental sync: $e');
    }
  }
  
  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return _syncService.getSyncStats();
  }
  
  /// Force sync of pending updates
  Future<void> forceSync() async {
    await RetryService.executeWithSmartRetry(
      operation: () async {
        await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'force_sync',
          operation: () async {
            await _syncService.forceSync();
            debugPrint('Performance: Force sync completed');
          },
        );
      },
      operationName: 'force_sync',
    );
  }
  
  /// Sync pending offline attempts
  Future<int> syncPendingOfflineAttempts() async {
    try {
      return await _offlineService.syncPendingOfflineAttempts();
    } catch (e) {
      debugPrint('Error syncing offline attempts: $e');
      return 0;
    }
  }
  
  /// Get offline quiz statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      return await _offlineService.getOfflineStats();
    } catch (e) {
      debugPrint('Error getting offline stats: $e');
      return {};
    }
  }
  
  /// Preload quiz for offline use
  Future<bool> preloadQuizForOffline({
    required String grade,
    required String subject,
    required String topic,
    required List<quiz.QuizQuestion> questions,
  }) async {
    return await RetryService.executeWithSmartRetry(
      operation: () async {
        return await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'preload_quiz_offline_$grade/$subject/$topic',
          operation: () async {
            return await _offlineService.preloadQuizForOffline(
              grade: grade,
              subject: subject,
              topic: topic,
              questions: questions,
            );
          },
        );
      },
      operationName: 'preload_quiz_offline_$grade/$subject/$topic',
    );
  }
  
  /// Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    return _performanceService.getPerformanceStats();
  }
  
  /// Optimize memory usage
  Future<void> optimizeMemoryUsage() async {
    await _performanceService.optimizeMemoryUsage();
  }
}