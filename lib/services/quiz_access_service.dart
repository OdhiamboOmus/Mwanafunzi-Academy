import 'package:flutter/foundation.dart';
import '../services/lesson_quiz_progress_service.dart';

/// Quiz access service to ensure unrestricted quiz access
/// Following Flutter Lite rules - under 150 lines
class QuizAccessService {
  final LessonQuizProgressService _progressService;

  QuizAccessService({
    required LessonQuizProgressService progressService,
  }) : _progressService = progressService;

  /// Check if student can access quiz (always returns true for unrestricted access)
  Future<bool> canAccessQuiz({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      // Always return true to ensure unrestricted access
      // This requirement ensures ALL quizzes are available without any locking
      return true;
    } catch (e) {
      debugPrint('❌ Error checking quiz access: $e');
      // In case of error, default to allowing access
      return true;
    }
  }

  /// Get quiz access status (always shows as available)
  Future<Map<String, dynamic>> getQuizAccessStatus({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      // Check if student has completed any lesson or quiz for this topic
      final hasCompleted = await _progressService.hasCompletedLessonOrQuiz(
        studentId: studentId,
        grade: grade,
        subject: subject,
        topic: topic,
      );

      return {
        'canAccess': true, // Always true for unrestricted access
        'hasCompletedLessonOrQuiz': hasCompleted,
        'accessReason': 'All quizzes are available without prerequisites',
        'grade': grade,
        'subject': subject,
        'topic': topic,
      };
    } catch (e) {
      debugPrint('❌ Error getting quiz access status: $e');
      return {
        'canAccess': true, // Default to allowing access
        'hasCompletedLessonOrQuiz': false,
        'accessReason': 'All quizzes are available without prerequisites',
        'grade': grade,
        'subject': subject,
        'topic': topic,
      };
    }
  }

  /// Get all available topics for a grade and subject (no restrictions)
  Future<List<String>> getAvailableTopics({
    required String grade,
    required String subject,
  }) async {
    try {
      // This would normally fetch from quizzes collection
      // For now, return a list of common topics
      // In a real implementation, this would query the quizzes collection
      return [
        'Introduction',
        'Basic Concepts',
        'Practice Problems',
        'Advanced Topics',
        'Review',
        'Assessment',
      ];
    } catch (e) {
      debugPrint('❌ Error getting available topics: $e');
      return [];
    }
  }

  /// Ensure quiz access by removing any existing locking mechanisms
  Future<void> ensureUnrestrictedAccess({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      // This method ensures that any existing quiz locking mechanisms are removed
      // In practice, this means we always return true from canAccessQuiz
      // and don't enforce any prerequisites
      
      debugPrint('✅ Ensuring unrestricted access to quiz: $grade/$subject/$topic');
      
      // Log the access attempt for analytics (optional)
      // This helps track quiz usage patterns without restricting access
    } catch (e) {
      debugPrint('❌ Error ensuring unrestricted access: $e');
    }
  }

  /// Get quiz recommendations based on student progress (no access restrictions)
  Future<List<Map<String, dynamic>>> getQuizRecommendations({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      // Get completed topics to provide recommendations
      final completedTopics = await _progressService.getCompletedTopics(
        studentId: studentId,
        grade: grade,
        subject: subject,
      );

      // Get all available topics
      final availableTopics = await getAvailableTopics(grade: grade, subject: subject);

      // Recommend topics that haven't been completed yet
      final recommendations = availableTopics
          .where((topic) => !completedTopics.contains(topic))
          .map((topic) => {
                'topic': topic,
                'recommended': true,
                'reason': 'Continue your learning journey',
              })
          .toList();

      // If all topics are completed, recommend review
      if (recommendations.isEmpty) {
        recommendations.addAll(availableTopics.map((topic) => {
          'topic': topic,
          'recommended': true,
          'reason': 'Review and reinforce your knowledge',
        }));
      }

      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting quiz recommendations: $e');
      return [];
    }
  }
}