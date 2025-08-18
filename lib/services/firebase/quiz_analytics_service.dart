import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/quiz_model.dart';

/// Service for local aggregation of quiz analytics to minimize Firebase costs
class QuizAnalyticsService {
  static const String _analyticsPrefix = 'quiz_analytics_';
  static const String _summaryPrefix = 'quiz_summary_';
  
  /// Get quiz analytics for a child with local caching
  Future<ChildQuizAnalytics> getChildQuizAnalytics(String childId) async {
    // Try to get cached analytics first
    final cachedAnalytics = await _getCachedAnalytics(childId);
    if (cachedAnalytics != null) {
      return cachedAnalytics;
    }
    
    // Fetch from Firebase and cache locally
    final analytics = await _fetchAnalyticsFromFirebase(childId);
    await _cacheAnalytics(childId, analytics);
    
    return analytics;
  }
  
  /// Get cached quiz analytics
  Future<ChildQuizAnalytics?> _getCachedAnalytics(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_analyticsPrefix$childId');
      
      if (cachedJson != null) {
        return ChildQuizAnalytics.fromJson(jsonDecode(cachedJson));
      }
    } catch (e) {
      debugPrint('Error reading cached analytics: $e');
    }
    
    return null;
  }
  
  /// Cache quiz analytics locally
  Future<void> _cacheAnalytics(String childId, ChildQuizAnalytics analytics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = jsonEncode(analytics.toJson());
      await prefs.setString('$_analyticsPrefix$childId', analyticsJson);
    } catch (e) {
      debugPrint('Error caching analytics: $e');
    }
  }
  
  /// Fetch analytics from Firebase
  Future<ChildQuizAnalytics> _fetchAnalyticsFromFirebase(String childId) async {
    // Get all quiz attempts for the child
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
  }
  
  /// Calculate average score
  double _calculateAverageScore(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;
    
    double totalScore = 0;
    for (final attempt in attempts) {
      totalScore += (attempt.score / attempt.totalQuestions);
    }
    
    return totalScore / attempts.length;
  }
  
  /// Get unique topics completed
  List<String> _getUniqueTopics(List<QuizAttempt> attempts) {
    return attempts.map((a) => a.topic).toSet().toList();
  }
  
  /// Calculate subject performance
  Map<String, double> _calculateSubjectPerformance(List<QuizAttempt> attempts) {
    final subjectScores = <String, List<double>>{};
    
    for (final attempt in attempts) {
      subjectScores.putIfAbsent(attempt.subject, () => []);
      subjectScores[attempt.subject]!.add(attempt.score / attempt.totalQuestions);
    }
    
    return subjectScores.map((subject, scores) => 
        MapEntry(subject, scores.reduce((a, b) => a + b) / scores.length));
  }
  
  /// Get strongest topics
  List<String> _getStrongestTopics(List<QuizAttempt> attempts) {
    final topicScores = <String, double>{};
    
    for (final attempt in attempts) {
      final key = '${attempt.subject}_${attempt.topic}';
      topicScores[key] = (topicScores[key] ?? 0) + (attempt.score / attempt.totalQuestions);
    }
    
    // Sort by score and return top 5
    return topicScores.entries
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => (topicScores[b] ?? 0).compareTo(topicScores[a] ?? 0))
      ..take(5)
      .toList();
  }
  
  /// Get weakest topics
  List<String> _getWeakestTopics(List<QuizAttempt> attempts) {
    final topicScores = <String, double>{};
    
    for (final attempt in attempts) {
      final key = '${attempt.subject}_${attempt.topic}';
      topicScores[key] = (topicScores[key] ?? 0) + (attempt.score / attempt.totalQuestions);
    }
    
    // Sort by score and return bottom 5
    return topicScores.entries
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => (topicScores[a] ?? 0).compareTo(topicScores[b] ?? 0))
      ..take(5)
      .toList();
  }
  
  /// Get aggregated summary statistics for a school
  Future<Map<String, dynamic>> getSchoolSummaryAnalytics(String schoolId) async {
    // Try to get cached summary first
    final cachedSummary = await _getCachedSchoolSummary(schoolId);
    if (cachedSummary != null) {
      return cachedSummary;
    }
    
    // Fetch from Firebase and cache locally
    final summary = await _fetchSchoolSummaryFromFirebase(schoolId);
    await _cacheSchoolSummary(schoolId, summary);
    
    return summary;
  }
  
  /// Get cached school summary
  Future<Map<String, dynamic>?> _getCachedSchoolSummary(String schoolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_summaryPrefix$schoolId');
      
      if (cachedJson != null) {
        return jsonDecode(cachedJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached school summary: $e');
    }
    
    return null;
  }
  
  /// Cache school summary locally
  Future<void> _cacheSchoolSummary(String schoolId, Map<String, dynamic> summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summaryJson = jsonEncode(summary);
      await prefs.setString('$_summaryPrefix$schoolId', summaryJson);
    } catch (e) {
      debugPrint('Error caching school summary: $e');
    }
  }
  
  /// Fetch school summary from Firebase
  Future<Map<String, dynamic>> _fetchSchoolSummaryFromFirebase(String schoolId) async {
    // Get all students from the school
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('school', isEqualTo: schoolId)
        .where('role', isEqualTo: 'student')
        .get();
    
    if (studentsSnapshot.docs.isEmpty) {
      return {
        'totalStudents': 0,
        'averageScore': 0.0,
        'totalQuizzes': 0,
        'topPerformers': [],
        'improvementTrends': [],
      };
    }
    
    // Aggregate quiz data for all students
    int totalQuizzes = 0;
    double totalScore = 0;
    final List<Map<String, dynamic>> topPerformers = [];
    
    for (final studentDoc in studentsSnapshot.docs) {
      final studentId = studentDoc.id;
      final studentName = studentDoc.data()['name'] ?? 'Unknown';
      
      // Get quiz attempts for this student
      final attemptsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(studentId)
          .collection('regular')
          .get();
      
      final attempts = attemptsSnapshot.docs
          .map((doc) => QuizAttempt.fromJson(doc.data()))
          .toList();
      
      totalQuizzes += attempts.length;
      
      if (attempts.isNotEmpty) {
        final studentAverage = _calculateAverageScore(attempts);
        totalScore += studentAverage;
        
        topPerformers.add({
          'name': studentName,
          'averageScore': studentAverage,
          'totalQuizzes': attempts.length,
        });
      }
    }
    
    // Sort top performers
    topPerformers.sort((a, b) => (b['averageScore'] as double).compareTo(a['averageScore'] as double));
    topPerformers.take(5).toList();
    
    return {
      'totalStudents': studentsSnapshot.docs.length,
      'averageScore': totalQuizzes > 0 ? totalScore / studentsSnapshot.docs.length : 0.0,
      'totalQuizzes': totalQuizzes,
      'topPerformers': topPerformers,
      'improvementTrends': [], // Placeholder for improvement trend calculation
    };
  }
  
  /// Clear cached analytics for a specific child
  Future<void> clearChildAnalytics(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_analyticsPrefix$childId');
    } catch (e) {
      debugPrint('Error clearing child analytics: $e');
    }
  }
  
  /// Clear cached analytics for a school
  Future<void> clearSchoolSummary(String schoolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_summaryPrefix$schoolId');
    } catch (e) {
      debugPrint('Error clearing school summary: $e');
    }
  }
  
  /// Get analytics hit rate
  double getAnalyticsCacheHitRate() {
    // This is a simplified implementation
    // In production, you would track actual hit/miss counts
    return 0.0; // Placeholder - implement actual tracking
  }
}