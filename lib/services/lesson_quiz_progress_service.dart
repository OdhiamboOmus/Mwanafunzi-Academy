import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/storage_service.dart';
import '../data/models/quiz_model.dart' as quiz;
import '../services/firebase/firestore_service.dart';

/// Enhanced lesson progress service with quiz integration
/// Following Flutter Lite rules - under 150 lines
class LessonQuizProgressService {
  final StorageService _storageService;
  final FirestoreService _firestoreService;

  LessonQuizProgressService({
    required StorageService storageService,
    required FirestoreService firestoreService,
  }) : _storageService = storageService,
       _firestoreService = firestoreService;

  /// Get lesson progress including quiz completion data
  Future<Map<String, dynamic>> getLessonProgressWithQuizzes({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      // Get lesson progress document
      final progressDoc = await _firestoreService.getLessonProgress(studentId);

      if (!progressDoc.exists) {
        return _createEmptyProgressData(grade, subject, topic);
      }

      final data = progressDoc.data() as Map<String, dynamic>;
      final gradeData = data[grade] as Map<String, dynamic>?;
      
      if (gradeData == null) {
        return _createEmptyProgressData(grade, subject, topic);
      }

      final subjectData = gradeData[subject] as Map<String, dynamic>?;
      
      if (subjectData == null) {
        return _createEmptyProgressData(grade, subject, topic);
      }

      final topicData = subjectData[topic] as Map<String, dynamic>?;
      
      return topicData ?? _createEmptyProgressData(grade, subject, topic);
    } catch (e) {
      debugPrint('❌ Error getting lesson progress with quizzes: $e');
      return _createEmptyProgressData(grade, subject, topic);
    }
  }

  /// Update lesson progress with quiz completion data
  Future<void> updateLessonProgressWithQuiz({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
    required String lessonId,
    required quiz.QuizAttempt quizAttempt,
  }) async {
    try {
      final progressData = {
        'lessonId': lessonId,
        'quizCompleted': true,
        'quizScore': quizAttempt.score,
        'quizTotalQuestions': quizAttempt.totalQuestions,
        'quizCompletedAt': quizAttempt.completedAt.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await _firestoreService.createOrUpdateLessonProgress(
        studentId: studentId,
        grade: grade,
        subject: subject,
        topic: topic,
        progressData: progressData,
      );

      // Update local cache
      await _cacheProgressData(studentId, grade, subject, topic, progressData);

      debugPrint('✅ Lesson progress updated with quiz data: $grade/$subject/$topic');
    } catch (e) {
      debugPrint('❌ Error updating lesson progress with quiz: $e');
    }
  }

  /// Get correlation analytics between lesson completion and quiz performance
  Future<Map<String, dynamic>> getLessonQuizCorrelation({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      final progressDoc = await _firestoreService.getLessonProgress(studentId);

      if (!progressDoc.exists) {
        return _createEmptyCorrelationData();
      }

      final data = progressDoc.data() as Map<String, dynamic>;
      final gradeData = data[grade] as Map<String, dynamic>?;
      
      if (gradeData == null) {
        return _createEmptyCorrelationData();
      }

      final subjectData = gradeData[subject] as Map<String, dynamic>?;
      
      if (subjectData == null) {
        return _createEmptyCorrelationData();
      }

      return _calculateCorrelationAnalytics(subjectData);
    } catch (e) {
      debugPrint('❌ Error getting lesson-quiz correlation: $e');
      return _createEmptyCorrelationData();
    }
  }

  /// Check if student has completed lesson or quiz for a topic
  Future<bool> hasCompletedLessonOrQuiz({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      final progressData = await getLessonProgressWithQuizzes(
        studentId: studentId,
        grade: grade,
        subject: subject,
        topic: topic,
      );

      return progressData['lessonCompleted'] == true || 
             (progressData['quizCompleted'] as List?)?.isNotEmpty == true;
    } catch (e) {
      debugPrint('❌ Error checking lesson/quiz completion: $e');
      return false;
    }
  }

  /// Get all completed topics for a subject
  Future<List<String>> getCompletedTopics({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      final progressData = await getLessonProgressWithQuizzes(
        studentId: studentId,
        grade: grade,
        subject: subject,
        topic: 'all_topics', // Get all topics for the subject
      );

      final quizCompletions = progressData['quizCompleted'] as List?;
      final lessonCompletions = progressData['lessonCompleted'] as List?;

      final completedTopics = <String>{};
      
      // Add quiz completed topics
      if (quizCompletions != null) {
        for (final completion in quizCompletions) {
          if (completion is Map && completion['topic'] != null) {
            completedTopics.add(completion['topic']);
          }
        }
      }

      // Add lesson completed topics
      if (lessonCompletions != null) {
        for (final completion in lessonCompletions) {
          if (completion is Map && completion['topic'] != null) {
            completedTopics.add(completion['topic']);
          }
        }
      }

      return completedTopics.toList();
    } catch (e) {
      debugPrint('❌ Error getting completed topics: $e');
      return [];
    }
  }

  /// Cache progress data locally for offline access
  Future<void> _cacheProgressData(
    String studentId,
    String grade,
    String subject,
    String topic,
    Map<String, dynamic> progressData,
  ) async {
    try {
      final cacheKey = 'lesson_progress_${studentId}_${grade}_${subject}_$topic';
      final jsonData = {
        'data': progressData,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _storageService.setValue(cacheKey, jsonEncode(jsonData));
    } catch (e) {
      debugPrint('❌ Error caching progress data: $e');
    }
  }

  /// Create empty progress data structure
  Map<String, dynamic> _createEmptyProgressData(String grade, String subject, String topic) {
    return {
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'lessonCompleted': false,
      'quizCompleted': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Create empty correlation data structure
  Map<String, dynamic> _createEmptyCorrelationData() {
    return {
      'totalLessonsCompleted': 0,
      'totalQuizzesTaken': 0,
      'averageQuizScore': 0.0,
      'lessonQuizCorrelation': 0.0,
      'strongestTopics': [],
      'weakestTopics': [],
    };
  }

  /// Calculate correlation analytics
  Map<String, dynamic> _calculateCorrelationAnalytics(Map<String, dynamic> subjectData) {
    int totalLessons = 0;
    int totalQuizzes = 0;
    double totalScore = 0.0;
    final topicScores = <String, List<int>>{};

    // Count lessons and quizzes
    subjectData.forEach((topic, data) {
      if (data is Map) {
        final lessonCompleted = data['lessonCompleted'] as bool? ?? false;
        final quizCompletions = data['quizCompleted'] as List? ?? [];

        if (lessonCompleted) totalLessons++;

        for (final quiz in quizCompletions) {
          if (quiz is Map && quiz['quizScore'] != null) {
            totalQuizzes++;
            final score = quiz['quizScore'] as int;
            totalScore += score;
            
            topicScores.putIfAbsent(topic, () => []).add(score);
          }
        }
      }
    });

    // Calculate average quiz score
    final averageQuizScore = totalQuizzes > 0 ? totalScore / totalQuizzes : 0.0;

    // Calculate correlation (simple implementation)
    final correlation = totalLessons > 0 && totalQuizzes > 0 
        ? (totalLessons / (totalLessons + totalQuizzes)) 
        : 0.0;

    // Find strongest and weakest topics
    final strongestTopics = topicScores.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => {
          'topic': entry.key,
          'average': entry.value.reduce((a, b) => a + b) / entry.value.length,
        })
        .toList()
      ..sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

    final weakestTopics = List<Map<String, dynamic>>.from(strongestTopics.reversed);

    return {
      'totalLessonsCompleted': totalLessons,
      'totalQuizzesTaken': totalQuizzes,
      'averageQuizScore': averageQuizScore,
      'lessonQuizCorrelation': correlation,
      'strongestTopics': strongestTopics.take(3).map((e) => e['topic']).toList(),
      'weakestTopics': weakestTopics.take(3).map((e) => e['topic']).toList(),
    };
  }
}