import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/quiz_model.dart';
import 'incremental_sync_service.dart';
import 'performance_optimization_service.dart';
import 'retry_service.dart';

// Simplified admin quiz service following Flutter Lite rules
class AdminQuizService {
  static final IncrementalSyncService _syncService = IncrementalSyncService();
  static final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();
  
  /// Upload quiz content to Firebase with batch operations and incremental sync
  static Future<void> uploadQuizContent({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    await RetryService.executeWithSmartRetry(
      operation: () async {
        await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'upload_quiz_content_$grade/$subject/$topic',
          operation: () async {
            // Create quiz data structure
            final quizData = {
              'questions': questions.map((q) => q.toJson()).toList(),
              'metadata': {
                'totalQuestions': questions.length,
                'lastUpdated': DateTime.now().toIso8601String(),
                'grade': grade,
                'subject': subject,
                'topic': topic,
              },
            };

            // Upload to Firebase using batch operation for cost optimization
            final batch = FirebaseFirestore.instance.batch();
            
            // Create document reference
            final docRef = FirebaseFirestore.instance
                .collection('quizzes')
                .doc(grade)
                .collection(subject)
                .doc(topic);
            
            // Add to batch
            batch.set(docRef, quizData);
            
            // Commit batch operation
            await batch.commit();
            
            // Queue update for incremental sync
            await _syncService.queueQuizUpdate(
              grade: grade,
              subject: subject,
              topic: topic,
              questions: questions,
              operation: 'update',
            );
            
            debugPrint('Performance: Quiz content uploaded and queued for sync: $grade/$subject/$topic');
          },
        );
      },
      operationName: 'upload_quiz_content_$grade/$subject/$topic',
    );
  }

  /// Validate quiz JSON structure
  static List<QuizQuestion> validateQuizJson(List<dynamic> jsonData) {
    final validQuestions = <QuizQuestion>[];
    
    for (int i = 0; i < jsonData.length; i++) {
      try {
        final questionData = jsonData[i] as Map<String, dynamic>;
        
        // Validate required fields
        if (questionData['question'] == null || questionData['question'] is! String) {
          throw Exception('Invalid question text at index $i');
        }
        
        if (questionData['options'] == null || questionData['options'] is! List) {
          throw Exception('Invalid options at index $i');
        }
        
        final options = questionData['options'] as List;
        if (options.length != 4 || !options.every((opt) => opt is String)) {
          throw Exception('Each question must have exactly 4 string options at index $i');
        }
        
        if (questionData['correctAnswerIndex'] == null || 
            questionData['correctAnswerIndex'] is! int ||
            questionData['correctAnswerIndex'] < 0 || 
            questionData['correctAnswerIndex'] >= 4) {
          throw Exception('Invalid correctAnswerIndex at index $i');
        }
        
        if (questionData['explanation'] == null || questionData['explanation'] is! String) {
          throw Exception('Invalid explanation at index $i');
        }
        
        // Create valid question
        validQuestions.add(QuizQuestion.fromJson(questionData));
      } catch (e) {
        throw Exception('Error validating question at index $i: ${e.toString()}');
      }
    }
    
    return validQuestions;
  }

  /// Get existing quiz topics for a grade and subject
  static Future<List<String>> getExistingTopics(String grade, String subject) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(grade)
          .collection(subject)
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete quiz content
  static Future<void> deleteQuizContent({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    await RetryService.executeWithSmartRetry(
      operation: () async {
        await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'delete_quiz_content_$grade/$subject/$topic',
          operation: () async {
            final docRef = FirebaseFirestore.instance
                .collection('quizzes')
                .doc(grade)
                .collection(subject)
                .doc(topic);
            
            await docRef.delete();
            
            // Queue deletion for incremental sync
            await _syncService.queueQuizUpdate(
              grade: grade,
              subject: subject,
              topic: topic,
              questions: [],
              operation: 'delete',
            );
            
            debugPrint('Performance: Quiz content deleted and queued for sync: $grade/$subject/$topic');
          },
        );
      },
      operationName: 'delete_quiz_content_$grade/$subject/$topic',
    );
  }

  /// Update quiz content
  static Future<void> updateQuizContent({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    try {
      await uploadQuizContent(
        grade: grade,
        subject: subject,
        topic: topic,
        questions: questions,
      );
    } catch (e) {
      throw Exception('Failed to update quiz content: $e');
    }
  }
  
  /// Get sync statistics for admin monitoring
  static Map<String, dynamic> getSyncStats() {
    return _syncService.getSyncStats();
  }
  
  /// Force sync of pending updates
  static Future<void> forceSync() async {
    await RetryService.executeWithSmartRetry(
      operation: () async {
        await _performanceService.executeWithPerformanceMonitoring(
          operationId: 'admin_force_sync',
          operation: () async {
            await _syncService.forceSync();
          },
        );
      },
      operationName: 'admin_force_sync',
    );
  }
  
  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return _performanceService.getPerformanceStats();
  }

  /// Clear cache for a specific quiz topic
  static Future<void> clearTopicCache({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'quiz_${grade}_${subject}_$topic';
      
      // Clear cached questions
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');
      
      // Clear metadata cache
      await prefs.remove('quiz_metadata_${grade}_$subject');
    } catch (e) {
      // Don't throw exception for cache clearing failures
      if (kDebugMode) {
        print('Warning: Failed to clear cache for $topic: $e');
      }
    }
  }
}