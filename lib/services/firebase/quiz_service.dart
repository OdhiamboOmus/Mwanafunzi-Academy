import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/models/quiz_model.dart' as quiz;
import '../../core/services/cost_monitoring_service.dart';
import 'cost_optimized_cache_service.dart';
import 'batch_operation_service.dart';
import 'retry_service.dart';

class QuizService {
  
  final CostOptimizedCacheService _cacheService = CostOptimizedCacheService();
  final BatchOperationService _batchService = BatchOperationService();
  final CostMonitoringService _costMonitor = CostMonitoringService();

  /// Get quiz questions from Firestore with caching
  Future<List<quiz.QuizQuestion>> getQuizQuestions({
    required String grade,
    required String quizId,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Fetching quiz questions for grade: $grade, quizId: $quizId');
      
      // Try to get from cache first
      final cachedQuestions = await _cacheService.getCachedQuizQuestions(
        grade: grade,
        subject: 'quiz', // Default subject for quizzes
        topic: quizId, // Use quizId as topic
      );
      
      if (cachedQuestions != null) {
        debugPrint('🔍 DEBUG: Using cached quiz questions for grade: $grade, quizId: $quizId');
        return cachedQuestions;
      }
      
      // Fetch from Firebase if cache is empty
      final questions = await _fetchQuestionsFromFirebase(grade, quizId);
      
      // Cache the questions for future use
      await _cacheService.cacheQuizQuestions(
        grade: grade,
        subject: 'quiz',
        topic: quizId,
        questions: questions,
      );
      
      debugPrint('🔍 DEBUG: Successfully loaded and cached ${questions.length} questions');
      return questions;
    } catch (e) {
      debugPrint('❌ ERROR: Error fetching quiz questions: $e');
      throw Exception('Failed to load quiz questions: $e');
    }
  }

  /// Fetch questions from Firestore
  Future<List<quiz.QuizQuestion>> _fetchQuestionsFromFirebase(
    String grade,
    String quizId,
  ) async {
    try {
      debugPrint('🔍 DEBUG: Fetching quiz from Firestore: $grade/$quizId');
      
      // Access quiz using the correct Firestore path: quizzes/{quizId} (matches uploader)
      final docRef = FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId);
      
      // Track the read operation for cost monitoring
      await _costMonitor.trackReadOperation(
        collection: 'quizzes',
        documentId: quizId,
        metadata: {'grade': grade, 'operation': 'get_quiz_questions'},
      );
      
      final doc = await docRef.get();
      
      if (!doc.exists) {
        debugPrint('❌ ERROR: No quiz document found for $grade/$quizId');
        throw Exception('No quiz found for $grade/$quizId');
      }
      
      final data = doc.data();
      if (data == null) {
        debugPrint('❌ ERROR: Quiz document data is null for $grade/$quizId');
        throw Exception('Quiz document data is null');
      }
      
      debugPrint('🔍 DEBUG: Quiz document data: $data');
      
      if (!data.containsKey('questions')) {
        debugPrint('❌ ERROR: Quiz document missing "questions" field for $grade/$quizId');
        throw Exception('Quiz document missing "questions" field');
      }
      
      final questionsData = data['questions'] as List?;
      if (questionsData == null) {
        debugPrint('❌ ERROR: Questions data is null for $grade/$quizId');
        throw Exception('Questions data is null');
      }
      
      debugPrint('🔍 DEBUG: Found ${questionsData.length} questions for $grade/$quizId');
      
      return questionsData.map((q) {
        debugPrint('🔍 DEBUG: Processing question: $q');
        return quiz.QuizQuestion.fromJson(q);
      }).toList();
    } catch (e) {
      debugPrint('❌ ERROR: Error fetching quiz questions: $e');
      throw Exception('Failed to load quiz questions: $e');
    }
  }



  /// Clear cache for a specific topic
  Future<void> clearTopicCache(String grade, String subject, String topic) async {
    try {
      await _cacheService.clearTopicCache(
        grade: grade,
        subject: subject,
        topic: topic,
      );
      
      debugPrint('Cache cleared for $grade/$subject/$topic');
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
      
      debugPrint('Cache invalidated for admin update: $grade/$subject/$topic');
    } catch (e) {
      debugPrint('Error invalidating topic cache: $e');
    }
  }

  /// Record quiz attempts using BatchOperationService for cost optimization
  Future<void> recordQuizAttempt(quiz.QuizAttempt attempt) async {
    await RetryService.executeWithSmartRetry(
      operation: () async {
        // Track the write operation for cost monitoring
        await _costMonitor.trackWriteOperation(
          collection: 'quiz_attempts',
          documentId: '${attempt.studentId}_${attempt.completedAt.millisecondsSinceEpoch}',
          operationType: 'create',
          metadata: {'studentId': attempt.studentId, 'grade': attempt.grade, 'subject': attempt.subject, 'topic': attempt.topic},
        );
        
        // Use BatchOperationService for background queuing and batching
        await _batchService.queueQuizAttempt(attempt);
        debugPrint('Quiz attempt queued for batch processing: ${attempt.studentId}');
      },
      operationName: 'record_quiz_attempt_${attempt.studentId}',
    );
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
      // Get all quizzes for this grade and subject from quizMeta
      final metaSnapshot = await FirebaseFirestore.instance
          .collection('quizMeta')
          .doc(grade)
          .get();
      
      if (!metaSnapshot.exists) {
        return [];
      }
      
      final data = metaSnapshot.data();
      if (data == null || !data.containsKey('quizzes')) {
        return [];
      }
      
      final quizzes = data['quizzes'] as List?;
      if (quizzes == null) {
        return [];
      }
      
      // Extract unique topics from quizzes
      final topics = <String>{};
      for (final quiz in quizzes) {
        if (quiz is Map && quiz.containsKey('topic')) {
          topics.add(quiz['topic']);
        }
      }
      
      return topics.toList();
    } catch (e) {
      debugPrint('Error fetching available topics: $e');
      return [];
    }
  }

  /// Get all available subjects for a grade
  Future<List<String>> getAvailableSubjects(String grade) async {
    try {
      // Get all quizzes for this grade from quizMeta
      final metaSnapshot = await FirebaseFirestore.instance
          .collection('quizMeta')
          .doc(grade)
          .get();
      
      if (!metaSnapshot.exists) {
        return [];
      }
      
      final data = metaSnapshot.data();
      if (data == null || !data.containsKey('quizzes')) {
        return [];
      }
      
      final quizzes = data['quizzes'] as List?;
      if (quizzes == null) {
        return [];
      }
      
      // Extract unique subjects from quizzes
      final subjects = <String>{};
      for (final quiz in quizzes) {
        if (quiz is Map && quiz.containsKey('subject')) {
          subjects.add(quiz['subject']);
        }
      }
      
      return subjects.toList();
    } catch (e) {
      debugPrint('Error fetching available subjects: $e');
      return [];
    }
  }

  /// Clear all quiz cache (useful for admin updates)
  Future<void> clearAllQuizCache() async {
    try {
      // Clear cost optimized cache
      await _cacheService.clearAllQuizCaches();
      
      debugPrint('All quiz cache cleared');
    } catch (e) {
      debugPrint('Error clearing all quiz cache: $e');
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final hitRate = _cacheService.getCacheHitRate();
      
      return {
        'cache_service': 'CostOptimizedCacheService',
        'cache_hit_rate': hitRate,
        'cache_status': 'active',
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {
        'cache_service': 'CostOptimizedCacheService',
        'cache_hit_rate': 0.0,
        'cache_status': 'error',
      };
    }
  }
}