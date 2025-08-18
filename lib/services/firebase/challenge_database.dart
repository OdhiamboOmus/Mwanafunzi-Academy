import 'package:cloud_firestore/cloud_firestore.dart';
import 'challenge_models.dart';

class ChallengeDatabase {
  static const String _challengesCollection = 'student_challenges';
  static const String _attemptsCollection = 'quiz_attempts';
  static const String _competitionAttemptsCollection = 'competition';

  /// Create a new challenge in Firestore
  static Future<void> createChallenge(StudentChallenge challenge) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challenge.id)
          .set(challenge.toJson());
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// Update an existing challenge
  static Future<void> updateChallenge(String challengeId, StudentChallenge challenge) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .update(challenge.toJson());
    } catch (e) {
      throw Exception('Failed to update challenge: $e');
    }
  }

  /// Get a challenge by ID
  static Future<StudentChallenge?> getChallenge(String challengeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .get();
      
      if (doc.exists) {
        return StudentChallenge.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get challenge: $e');
    }
  }

  /// Get active challenges for a student (as challenger)
  static Future<List<StudentChallenge>> getActiveChallenges(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('challenger.studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => StudentChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get active challenges: $e');
    }
  }

  /// Get incoming challenges for a student (as challenged)
  static Future<List<StudentChallenge>> getIncomingChallenges(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('challenged.studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => StudentChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get incoming challenges: $e');
    }
  }

  /// Get completed challenges for a student
  static Future<List<StudentChallenge>> getCompletedChallenges(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('status', isEqualTo: 'completed')
          .where('challenger.studentId', isEqualTo: studentId)
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) => StudentChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get completed challenges: $e');
    }
  }

  /// Accept a challenge
  static Future<void> acceptChallenge(String challengeId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .update({
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to accept challenge: $e');
    }
  }

  /// Reject a challenge
  static Future<void> rejectChallenge(String challengeId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject challenge: $e');
    }
  }

  /// Record a competition attempt
  static Future<void> recordCompetitionAttempt({
    required String challengeId,
    required String studentId,
    required List<int> answers,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final attempt = {
        'challengeId': challengeId,
        'studentId': studentId,
        'answers': answers,
        'score': score,
        'totalQuestions': totalQuestions,
        'completedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection(_attemptsCollection)
          .doc(studentId)
          .collection(_competitionAttemptsCollection)
          .doc()
          .set(attempt);
    } catch (e) {
      throw Exception('Failed to record competition attempt: $e');
    }
  }

  /// Get competition attempts for a student
  static Future<List<Map<String, dynamic>>> getCompetitionAttempts(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_attemptsCollection)
          .doc(studentId)
          .collection(_competitionAttemptsCollection)
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get competition attempts: $e');
    }
  }

  /// Delete a challenge
  static Future<void> deleteChallenge(String challengeId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .doc(challengeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete challenge: $e');
    }
  }

  /// Get challenge statistics for a student
  static Future<Map<String, dynamic>> getChallengeStats(String studentId) async {
    try {
      // Get all challenges where student is challenger
      final challengerChallenges = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('challenger.studentId', isEqualTo: studentId)
          .get();
      
      // Get all challenges where student is challenged
      final challengedChallenges = await FirebaseFirestore.instance
          .collection(_challengesCollection)
          .where('challenged.studentId', isEqualTo: studentId)
          .get();
      
      // Calculate statistics
      int totalChallenges = challengerChallenges.docs.length + challengedChallenges.docs.length;
      int completedChallenges = 0;
      int wonChallenges = 0;
      int lostChallenges = 0;
      int drawChallenges = 0;
      int totalScore = 0;
      int totalQuestions = 0;
      
      // Process challenger challenges
      for (final doc in challengerChallenges.docs) {
        final challenge = StudentChallenge.fromJson(doc.data());
        if (challenge.status == 'completed') {
          completedChallenges++;
          if (challenge.results != null) {
            totalScore += challenge.results!.challengerScore;
            totalQuestions += challenge.questions.length;
            if (challenge.results!.winner == 'draw') {
              drawChallenges++;
            } else if (challenge.results!.winner == challenge.challenger['studentId']) {
              wonChallenges++;
            } else {
              lostChallenges++;
            }
          }
        }
      }
      
      // Process challenged challenges
      for (final doc in challengedChallenges.docs) {
        final challenge = StudentChallenge.fromJson(doc.data());
        if (challenge.status == 'completed') {
          completedChallenges++;
          if (challenge.results != null) {
            totalScore += challenge.results!.challengedScore;
            totalQuestions += challenge.questions.length;
            if (challenge.results!.winner == 'draw') {
              drawChallenges++;
            } else if (challenge.results!.winner == challenge.challenged['studentId']) {
              wonChallenges++;
            } else {
              lostChallenges++;
            }
          }
        }
      }
      
      return {
        'totalChallenges': totalChallenges,
        'completedChallenges': completedChallenges,
        'wonChallenges': wonChallenges,
        'lostChallenges': lostChallenges,
        'drawChallenges': drawChallenges,
        'averageScore': totalQuestions > 0 ? (totalScore / totalQuestions * 100).round() : 0,
        'winRate': completedChallenges > 0 ? (wonChallenges / completedChallenges * 100).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to get challenge stats: $e');
    }
  }
}