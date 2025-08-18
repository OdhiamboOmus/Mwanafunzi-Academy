import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/quiz_model.dart';

/// Parent quiz analytics service following Flutter Lite rules (<150 lines)
class ParentQuizAnalyticsService {
  /// Get child quiz analytics from Firebase
  static Future<ChildQuizAnalytics> getChildQuizAnalytics(String childId) async {
    try {
      // Get all quiz attempts for child
      final attemptsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(childId)
          .collection('regular')
          .orderBy('completedAt', descending: true)
          .get();

      final attempts = attemptsSnapshot.docs
          .map((doc) => QuizAttempt.fromJson(doc.data()))
          .toList();

      // Calculate analytics
      return ChildQuizAnalytics(
        totalQuizzesTaken: attempts.length,
        averageScore: _calculateAverageScore(attempts),
        topicsCompleted: _getUniqueTopics(attempts),
        recentAttempts: attempts.take(10).toList(),
        subjectPerformance: _calculateSubjectPerformance(attempts),
        strongestTopics: _getStrongestTopics(attempts),
        weakestTopics: _getWeakestTopics(attempts),
      );
    } catch (e) {
      throw Exception('Failed to get quiz analytics: $e');
    }
  }

  /// Calculate average score across all attempts
  static double _calculateAverageScore(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;

    double totalScore = 0;
    for (final attempt in attempts) {
      totalScore += (attempt.score / attempt.totalQuestions);
    }

    return totalScore / attempts.length;
  }

  /// Get unique topics completed
  static List<String> _getUniqueTopics(List<QuizAttempt> attempts) {
    final topics = <String>{};
    for (final attempt in attempts) {
      topics.add(attempt.topic);
    }
    return topics.toList();
  }

  /// Calculate performance by subject
  static Map<String, double> _calculateSubjectPerformance(List<QuizAttempt> attempts) {
    final subjectScores = <String, List<double>>{};

    for (final attempt in attempts) {
      subjectScores.putIfAbsent(attempt.subject, () => []);
      subjectScores[attempt.subject]!.add(attempt.score / attempt.totalQuestions);
    }

    return subjectScores.map((subject, scores) => 
        MapEntry(subject, scores.reduce((a, b) => a + b) / scores.length));
  }

  /// Get strongest topics (highest average scores)
  static List<String> _getStrongestTopics(List<QuizAttempt> attempts) {
    final topicScores = <String, List<double>>{};

    // Group scores by topic
    for (final attempt in attempts) {
      topicScores.putIfAbsent(attempt.topic, () => []);
      topicScores[attempt.topic]!.add(attempt.score / attempt.totalQuestions);
    }

    // Calculate average scores for each topic
    final topicAverages = topicScores.map((topic, scores) {
      final average = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(topic, average);
    });

    // Sort by average score (descending) and return top 5 topics
    return topicAverages.entries
        .where((entry) => entry.value > 0.7) // Only topics with >70% average
        .map((entry) => entry.key)
        .take(5)
        .toList();
  }

  /// Get weakest topics (lowest average scores)
  static List<String> _getWeakestTopics(List<QuizAttempt> attempts) {
    final topicScores = <String, List<double>>{};

    // Group scores by topic
    for (final attempt in attempts) {
      topicScores.putIfAbsent(attempt.topic, () => []);
      topicScores[attempt.topic]!.add(attempt.score / attempt.totalQuestions);
    }

    // Calculate average scores for each topic
    final topicAverages = topicScores.map((topic, scores) {
      final average = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(topic, average);
    });

    // Sort by average score (ascending) and return bottom 5 topics
    return topicAverages.entries
        .where((entry) => entry.value < 0.6) // Only topics with <60% average
        .map((entry) => entry.key)
        .take(5)
        .toList();
  }

  /// Get recent quiz attempts with basic formatting
  static List<Map<String, dynamic>> getFormattedRecentAttempts(List<QuizAttempt> attempts) {
    return attempts.take(5).map((attempt) {
      final scorePercentage = (attempt.score / attempt.totalQuestions * 100).round();
      return {
        'topic': attempt.topic,
        'subject': attempt.subject,
        'score': '$attempt.score/$attempt.totalQuestions',
        'percentage': '$scorePercentage%',
        'date': _formatDate(attempt.completedAt),
      };
    }).toList();
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get improvement trends (simplified)
  static String getImprovementSuggestion(List<QuizAttempt> attempts) {
    if (attempts.length < 3) {
      return 'Complete more quizzes to see improvement trends';
    }

    // Get last 3 attempts
    final recentAttempts = attempts.take(3).toList();
    final firstScore = recentAttempts.last.score / recentAttempts.last.totalQuestions;
    final lastScore = recentAttempts.first.score / recentAttempts.first.totalQuestions;

    if (lastScore > firstScore + 0.1) {
      return 'Great improvement! Keep up the good work.';
    } else if (lastScore < firstScore - 0.1) {
      return 'Focus on reviewing concepts and practice more.';
    } else {
      return 'Steady performance. Try new topics for growth.';
    }
  }
}