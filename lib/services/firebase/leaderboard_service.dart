import 'package:cloud_firestore/cloud_firestore.dart';

// Leaderboard service following Flutter Lite rules (<150 lines)
class LeaderboardService {
  /// Calculate individual leaderboard with comprehensive point aggregation
  static Future<List<Map<String, dynamic>>> calculateIndividualRankings({
    required String studentId,
    required String grade,
  }) async {
    try {
      final rankings = <Map<String, dynamic>>[];
      
      // Get all students from same grade
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc('students')
          .collection('users')
          .where('grade', isEqualTo: grade)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final currentStudentId = studentDoc.id;
        
        // Calculate total points from all sources
        final totalPoints = await _calculateTotalPoints(currentStudentId);
        
        rankings.add({
          'studentId': currentStudentId,
          'name': studentData['fullName'] ?? 'Unknown Student',
          'school': studentData['schoolName'] ?? 'Unknown School',
          'grade': grade,
          'totalPoints': totalPoints,
          'rank': 0, // Will be calculated after sorting
        });
      }

      // Sort by total points (descending)
      rankings.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
      
      // Assign ranks
      for (int i = 0; i < rankings.length; i++) {
        rankings[i]['rank'] = i + 1;
      }

      return rankings;
    } catch (e) {
      throw Exception('Failed to calculate individual rankings: $e');
    }
  }

  /// Calculate school rankings from competitions only
  static Future<List<Map<String, dynamic>>> calculateSchoolRankings({
    required String competitionId,
  }) async {
    try {
      final competitionDoc = await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .get();

      if (!competitionDoc.exists) return [];

      final competition = competitionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(competition['participantSchools'] ?? []);

      // Group participants by school
      final schoolScores = <String, List<int>>{};
      for (final participant in participants) {
        if (participant['score'] != null) {
          final school = participant['school'];
          schoolScores.putIfAbsent(school, () => []);
          schoolScores[school]!.add(participant['score']);
        }
      }

      // Calculate average scores for each school
      final rankings = schoolScores.entries.map((entry) {
        final scores = entry.value;
        final averageScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
        
        return {
          'school': entry.key,
          'averageScore': averageScore,
          'participantCount': scores.length,
          'totalScore': scores.reduce((a, b) => a + b),
          'rank': 0, // Will be calculated after sorting
        };
      }).toList();

      // Sort by average score (descending)
      rankings.sort((a, b) => (b['averageScore'] as double).compareTo(a['averageScore'] as double));
      
      // Assign ranks
      for (int i = 0; i < rankings.length; i++) {
        rankings[i]['rank'] = i + 1;
      }

      return rankings;
    } catch (e) {
      throw Exception('Failed to calculate school rankings: $e');
    }
  }

  /// Get top contributors from a specific school
  static Future<List<Map<String, dynamic>>> getSchoolContributors({
    required String school,
    required String competitionId,
  }) async {
    try {
      final competitionDoc = await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .get();

      if (!competitionDoc.exists) return [];

      final competition = competitionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(competition['participantSchools'] ?? []);

      // Filter participants from the specified school
      final schoolParticipants = participants
          .where((p) => p['school'] == school && p['score'] != null)
          .map((p) => {
                'studentId': p['studentId'],
                'name': p['studentName'] ?? 'Unknown Student',
                'score': p['score'],
                'rank': 0,
              })
          .toList();

      // Sort by score (descending)
      schoolParticipants.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      // Assign ranks
      for (int i = 0; i < schoolParticipants.length; i++) {
        schoolParticipants[i]['rank'] = i + 1;
      }

      return schoolParticipants.take(5).toList(); // Return top 5 contributors
    } catch (e) {
      throw Exception('Failed to get school contributors: $e');
    }
  }

  /// Calculate total points for a student from all sources
  static Future<int> _calculateTotalPoints(String studentId) async {
    try {
      int totalPoints = 0;

      // 1. Lesson completion points (1 point per lesson)
      final lessonPoints = await _getLessonCompletionPoints(studentId);
      totalPoints += lessonPoints;

      // 2. Personal quiz points (1 point per correct answer)
      final quizPoints = await _getPersonalQuizPoints(studentId);
      totalPoints += quizPoints;

      // 3. Student vs student challenge points
      final challengePoints = await _getChallengePoints(studentId);
      totalPoints += challengePoints;

      // 4. School competition points
      final competitionPoints = await _getCompetitionPoints(studentId);
      totalPoints += competitionPoints;

      return totalPoints;
    } catch (e) {
      return 0; // Return 0 if calculation fails
    }
  }

  /// Get lesson completion points for a student
  static Future<int> _getLessonCompletionPoints(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lesson_progress')
          .doc(studentId)
          .get();

      if (!snapshot.exists) return 0;

      final progress = snapshot.data()!;
      final completedLessons = (progress['completedLessons'] as List?)?.length ?? 0;
      
      return completedLessons; // 1 point per completed lesson
    } catch (e) {
      return 0;
    }
  }

  /// Get personal quiz points for a student
  static Future<int> _getPersonalQuizPoints(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(studentId)
          .collection('regular')
          .get();

      int totalCorrect = 0;
      
      for (final doc in snapshot.docs) {
        final attempt = doc.data();
        final answers = List<int>.from(attempt['answers'] ?? []);
        final questions = List<Map<String, dynamic>>.from(attempt['questions'] ?? []);
        
        // Count correct answers
        for (int i = 0; i < answers.length && i < questions.length; i++) {
          if (answers[i] == questions[i]['correctAnswerIndex']) {
            totalCorrect++;
          }
        }
      }

      return totalCorrect; // 1 point per correct answer
    } catch (e) {
      return 0;
    }
  }

  /// Get student challenge points for a student
  static Future<int> _getChallengePoints(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('student_challenges')
          .get();

      int totalPoints = 0;
      
      for (final doc in snapshot.docs) {
        final challenge = doc.data();
        
        // Check if student participated in this challenge
        final challengerId = challenge['challenger']['studentId'];
        final challengedId = challenge['challenged']['studentId'];
        
        if (challengerId == studentId || challengedId == studentId) {
          final results = challenge['results'];
          if (results != null) {
            final pointsAwarded = Map<String, dynamic>.from(results['pointsAwarded'] ?? {});
            
            // Add points awarded to this student
            if (challengerId == studentId) {
              totalPoints += (pointsAwarded['challenger'] as num? ?? 0).toInt();
            } else {
              totalPoints += (pointsAwarded['challenged'] as num? ?? 0).toInt();
            }
          }
        }
      }

      return totalPoints;
    } catch (e) {
      return 0;
    }
  }

  /// Get school competition points for a student
  static Future<int> _getCompetitionPoints(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('school_competitions')
          .get();

      int totalPoints = 0;
      
      for (final doc in snapshot.docs) {
        final competition = doc.data();
        final participants = List<Map<String, dynamic>>.from(competition['participantSchools'] ?? []);
        
        // Find this student's participation
        final studentParticipation = participants.firstWhere(
          (p) => p['studentId'] == studentId,
          orElse: () => {},
        );
        
        if (studentParticipation.isNotEmpty) {
          final score = studentParticipation['score'] ?? 0;
          // School competitions contribute points equal to the score
          totalPoints += (score as num? ?? 0).toInt();
        }
      }

      return totalPoints;
    } catch (e) {
      return 0;
    }
  }
}