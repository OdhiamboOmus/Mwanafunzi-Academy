import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/lesson_quiz_progress_service.dart';
import '../data/models/quiz_model.dart' as quiz;

/// Lesson-quiz correlation analytics service
/// Following Flutter Lite rules - under 150 lines
class LessonQuizCorrelationService {
  final LessonQuizProgressService _progressService;

  LessonQuizCorrelationService({
    required LessonQuizProgressService progressService,
  }) : _progressService = progressService;

  /// Get comprehensive correlation analytics for a student
  Future<Map<String, dynamic>> getCorrelationAnalytics({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      // Get lesson-quiz correlation data
      final correlationData = await _progressService.getLessonQuizCorrelation(
        studentId: studentId,
        grade: grade,
        subject: subject,
      );

      // Get quiz attempts for detailed analysis
      final quizAttempts = await _getQuizAttempts(studentId, grade, subject);

      // Calculate additional insights
      final insights = _calculateInsights(quizAttempts, correlationData);

      return {
        'correlationData': correlationData,
        'insights': insights,
        'quizAttempts': quizAttempts,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting correlation analytics: $e');
      return {
        'correlationData': {},
        'insights': {},
        'quizAttempts': [],
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get improvement suggestions based on correlation data
  Future<List<Map<String, dynamic>>> getImprovementSuggestions({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      final analytics = await getCorrelationAnalytics(
        studentId: studentId,
        grade: grade,
        subject: subject,
      );

      final correlationData = analytics['correlationData'] as Map<String, dynamic>;
      final weakestTopics = correlationData['weakestTopics'] as List? ?? [];

      final suggestions = <Map<String, dynamic>>[];

      // Add suggestions based on correlation strength
      final correlation = correlationData['lessonQuizCorrelation'] as double? ?? 0.0;
      
      if (correlation < 0.3) {
        suggestions.add({
          'type': 'focus',
          'title': 'Focus on Lesson Completion',
          'description': 'Complete more lessons before taking quizzes to improve your performance',
          'priority': 'high',
        });
      }

      if (correlation > 0.7) {
        suggestions.add({
          'type': 'continue',
          'title': 'Great Progress!',
          'description': 'Your lesson completion is strongly correlated with quiz success',
          'priority': 'medium',
        });
      }

      // Add suggestions for weakest topics
      for (final topic in weakestTopics.take(3)) {
        suggestions.add({
          'type': 'topic',
          'title': 'Improve $topic',
          'description': 'Focus on this topic with additional lessons and practice',
          'priority': 'high',
          'topic': topic,
        });
      }

      // Add general suggestions based on quiz performance
      final averageScore = correlationData['averageQuizScore'] as double? ?? 0.0;
      if (averageScore < 60) {
        suggestions.add({
          'type': 'practice',
          'title': 'More Practice Needed',
          'description': 'Consider taking more quizzes to improve your understanding',
          'priority': 'high',
        });
      }

      return suggestions;
    } catch (e) {
      debugPrint('❌ Error getting improvement suggestions: $e');
      return [];
    }
  }

  /// Get learning progress summary
  Future<Map<String, dynamic>> getLearningProgressSummary({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      final analytics = await getCorrelationAnalytics(
        studentId: studentId,
        grade: grade,
        subject: subject,
      );

      final correlationData = analytics['correlationData'] as Map<String, dynamic>;
      final insights = analytics['insights'] as Map<String, dynamic>;

      return {
        'overallProgress': {
          'lessonsCompleted': correlationData['totalLessonsCompleted'] as int? ?? 0,
          'quizzesTaken': correlationData['totalQuizzesTaken'] as int? ?? 0,
          'averageScore': correlationData['averageQuizScore'] as double? ?? 0.0,
          'correlationStrength': correlationData['lessonQuizCorrelation'] as double? ?? 0.0,
        },
        'insights': insights,
        'recommendations': await getImprovementSuggestions(
          studentId: studentId,
          grade: grade,
          subject: subject,
        ),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting learning progress summary: $e');
      return {
        'overallProgress': {},
        'insights': {},
        'recommendations': [],
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get quiz attempts for a student in a specific grade and subject
  Future<List<quiz.QuizAttempt>> _getQuizAttempts(
    String studentId,
    String grade,
    String subject,
  ) async {
    try {
      // This would normally query the quiz_attempts collection
      // For now, return an empty list
      // In a real implementation, this would fetch from Firestore
      return [];
    } catch (e) {
      debugPrint('❌ Error getting quiz attempts: $e');
      return [];
    }
  }

  /// Calculate additional insights from quiz attempts
  Map<String, dynamic> _calculateInsights(
    List<quiz.QuizAttempt> quizAttempts,
    Map<String, dynamic> correlationData,
  ) {
    final insights = <String, dynamic>{};

    // Calculate improvement trend
    if (quizAttempts.length >= 2) {
      final sortedAttempts = List<quiz.QuizAttempt>.from(quizAttempts)
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      
      final recentAttempts = sortedAttempts.take(3).toList();
      final olderAttempts = sortedAttempts.skip(sortedAttempts.length - 3).toList();
      
      if (recentAttempts.isNotEmpty && olderAttempts.isNotEmpty) {
        final recentAverage = recentAttempts
            .map((a) => a.score / a.totalQuestions)
            .reduce((a, b) => a + b) / recentAttempts.length;
        
        final olderAverage = olderAttempts
            .map((a) => a.score / a.totalQuestions)
            .reduce((a, b) => a + b) / olderAttempts.length;
        
        insights['improvementTrend'] = recentAverage > olderAverage ? 'improving' : 'declining';
        insights['improvementPercentage'] = ((recentAverage - olderAverage) / olderAverage * 100).round();
      }
    }

    // Calculate consistency
    if (quizAttempts.isNotEmpty) {
      final scores = quizAttempts.map((a) => a.score / a.totalQuestions).toList();
      final average = scores.reduce((a, b) => a + b) / scores.length;
      final variance = scores.map((s) => (s - average) * (s - average)).reduce((a, b) => a + b) / scores.length;
      final standardDeviation = sqrt(variance);
      
      insights['consistency'] = standardDeviation < 0.2 ? 'high' : standardDeviation < 0.4 ? 'medium' : 'low';
      insights['consistencyScore'] = (1 - standardDeviation).clamp(0.0, 1.0);
    }

    return insights;
  }
}