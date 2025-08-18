import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint;
import '../../data/models/quiz_model.dart' as quiz;
import 'quiz_service.dart';
import 'challenge_models.dart';
import 'challenge_utils.dart';
import 'challenge_database.dart';

class StudentChallengeService {
  static const String _challengesCollection = 'student_challenges';
  static const String _attemptsCollection = 'quiz_attempts';
  static const String _competitionAttemptsCollection = 'competition';
  static const int _maxCacheSize = 50;

  /// Create a random challenge with another student
  Future<String> createRandomChallenge({
    required String challengerId,
    required String challengerName,
    required String challengerSchool,
    required String topic,
    required String subject,
    required String grade,
  }) async {
    try {
      // Find random opponent (exclude challenger)
      final randomOpponent = await _findRandomOpponent(challengerId, grade);
      
      if (randomOpponent == null) {
        throw Exception('No opponents available for challenge');
      }
      
      // Generate unique challenge ID
      final challengeId = ChallengeUtils.generateChallengeId();
      
      // Get questions for the challenge
      final questions = await _getRandomQuestionsForTopic(topic, subject, grade);
      
      // Create challenge document
      final challenge = StudentChallenge(
        id: challengeId,
        challenger: {
          'studentId': challengerId,
          'name': challengerName,
          'school': challengerSchool,
        },
        challenged: randomOpponent,
        topic: topic,
        subject: subject,
        grade: grade,
        status: 'pending',
        questions: questions.map((q) => q.toJson()).toList(),
        createdAt: DateTime.now(),
      );
      
      await ChallengeDatabase.createChallenge(challenge);
      
      debugPrint('Challenge created: $challengeId');
      
      // Send notification (placeholder - will be implemented with settings notifications)
      await _sendChallengeNotification(
        randomOpponent['studentId'],
        challengeId,
        challengerName,
        topic,
        subject,
      );
      
      return challengeId;
    } catch (e) {
      debugPrint('Error creating random challenge: $e');
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// Complete a challenge with answers
  Future<void> completeChallenge({
    required String challengeId,
    required String studentId,
    required List<int> answers,
  }) async {
    try {
      final challenge = await ChallengeDatabase.getChallenge(challengeId);
      
      if (challenge == null) {
        throw Exception('Challenge not found');
      }
      
      // Calculate score
      final score = ChallengeUtils.calculateScore(answers, challenge.questions);
      
      // Update challenge with results
      final updatedChallenge = ChallengeUtils.updateChallengeWithResults(
        challenge,
        studentId,
        score
      );
      
      await ChallengeDatabase.updateChallenge(challengeId, updatedChallenge);
      
      debugPrint('Challenge completed: $challengeId by $studentId with score: $score');
      
      // Record competition attempt
      await _recordCompetitionAttempt(
        challengeId,
        studentId,
        answers,
        score,
        challenge.questions.length,
      );
      
    } catch (e) {
      debugPrint('Error completing challenge: $e');
      throw Exception('Failed to complete challenge: $e');
    }
  }

  /// Get active challenges for a student
  Future<List<quiz.StudentChallenge>> getActiveChallenges(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('challenger.studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => quiz.StudentChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting active challenges: $e');
      return [];
    }
  }

  /// Get challenges where student is challenged
  Future<List<quiz.StudentChallenge>> getIncomingChallenges(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('challenged.studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => quiz.StudentChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting incoming challenges: $e');
      return [];
    }
  }

  /// Get completed challenges for a student
  Future<List<quiz.StudentChallenge>> getCompletedChallenges(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('status', isEqualTo: 'completed')
          .where('challenger.studentId', isEqualTo: studentId)
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) => quiz.StudentChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting completed challenges: $e');
      return [];
    }
  }

  /// Accept a challenge
  Future<void> acceptChallenge(String challengeId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .update({
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Challenge accepted: $challengeId');
    } catch (e) {
      debugPrint('Error accepting challenge: $e');
      throw Exception('Failed to accept challenge: $e');
    }
  }

  /// Reject a challenge
  Future<void> rejectChallenge(String challengeId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Challenge rejected: $challengeId');
    } catch (e) {
      debugPrint('Error rejecting challenge: $e');
      throw Exception('Failed to reject challenge: $e');
    }
  }

  /// Validate challenge data
  static bool validateChallengeData(Map<String, dynamic> challengeData) {
    try {
      // Check required fields
      if (challengeData['challenger'] == null || challengeData['challenged'] == null) {
        return false;
      }
      
      if (challengeData['topic'] == null || challengeData['topic'] is! String) {
        return false;
      }
      
      if (challengeData['subject'] == null || challengeData['subject'] is! String) {
        return false;
      }
      
      if (challengeData['grade'] == null || challengeData['grade'] is! String) {
        return false;
      }
      
      if (challengeData['questions'] == null || challengeData['questions'] is! List) {
        return false;
      }
      
      // Validate questions
      final questions = challengeData['questions'] as List;
      if (questions.isEmpty || questions.length > 10) {
        return false;
      }
      
      for (final question in questions) {
        if (!QuizService.validateQuizQuestion(question)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating challenge data: $e');
      return false;
    }
  }

  /// Helper methods
  Future<Map<String, dynamic>?> _findRandomOpponent(String challengerId, String grade) async {
    try {
      // Get all students from same grade
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc('students')
          .collection('users')
          .where('grade', isEqualTo: grade)
          .get();
      
      // Filter out challenger and students without complete profiles
      final availableOpponents = studentsSnapshot.docs.where((doc) {
        final data = doc.data();
        return doc.id != challengerId &&
               data['profileCompleted'] == true &&
               data['fullName'] != null &&
               data['schoolName'] != null;
      }).toList();
      
      if (availableOpponents.isEmpty) {
        return null;
      }
      
      // Select random opponent
      final randomIndex = DateTime.now().millisecondsSinceEpoch % availableOpponents.length;
      final opponentDoc = availableOpponents[randomIndex];
      final opponentData = opponentDoc.data();
      
      return {
        'studentId': opponentDoc.id,
        'name': opponentData['fullName'] ?? 'Unknown Student',
        'school': opponentData['schoolName'] ?? 'Unknown School',
      };
    } catch (e) {
      debugPrint('Error finding random opponent: $e');
      return null;
    }
  }

  Future<List<quiz.QuizQuestion>> _getRandomQuestionsForTopic(
    String topic,
    String subject,
    String grade,
  ) async {
    try {
      // Use existing QuizService to get questions
      final quizService = QuizService();
      final allQuestions = await quizService.getQuizQuestions(
        grade: grade,
        subject: subject,
        topic: topic,
      );
      
      if (allQuestions.isEmpty) {
        throw Exception('No questions found for topic: $topic');
      }
      
      // Select random questions (limit to 10 for competitions)
      final selectedQuestions = ChallengeUtils.selectRandomQuestions(
        allQuestions.map((q) => q.toJson()).toList(),
        maxQuestions: 10,
      );
      
      return selectedQuestions.map((q) => quiz.QuizQuestion.fromJson(q)).toList();
    } catch (e) {
      debugPrint('Error getting random questions: $e');
      throw Exception('Failed to get questions for challenge: $e');
    }
  }

  Future<void> _recordCompetitionAttempt(
    String challengeId,
    String studentId,
    List<int> answers,
    int score,
    int totalQuestions,
  ) async {
    try {
      await ChallengeDatabase.recordCompetitionAttempt(
        challengeId: challengeId,
        studentId: studentId,
        answers: answers,
        score: score,
        totalQuestions: totalQuestions,
      );
      
      debugPrint('Competition attempt recorded for $studentId');
    } catch (e) {
      debugPrint('Error recording competition attempt: $e');
    }
  }

  Future<void> _sendChallengeNotification(
    String challengedId,
    String challengeId,
    String challengerName,
    String topic,
    String subject,
  ) async {
    // Placeholder for notification system
    // This will be implemented when settings notifications are available
    debugPrint('Notification sent to $challengedId for challenge $challengeId from $challengerName');
  }
}