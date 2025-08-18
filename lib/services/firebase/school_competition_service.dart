import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/quiz_model.dart';

// School competition service following Flutter Lite rules (<150 lines)
class SchoolCompetitionService {
  /// Create a new school competition
  static Future<String> createCompetition({
    required String competitionName,
    required String grade,
    required String subject,
    required String topic,
    required DateTime deadline,
    required List<QuizQuestion> questions,
  }) async {
    try {
      final competitionId = _generateCompetitionId();
      
      // Create competition document
      final competition = {
        'id': competitionId,
        'name': competitionName,
        'grade': grade,
        'subject': subject,
        'topic': topic,
        'deadline': deadline.toIso8601String(),
        'status': 'active',
        'questions': questions.map((q) => q.toJson()).toList(),
        'participantSchools': [],
        'createdAt': DateTime.now().toIso8601String(),
        'completedAt': null,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .set(competition);

      return competitionId;
    } catch (e) {
      throw Exception('Failed to create competition: $e');
    }
  }

  /// Join a school competition
  static Future<void> joinCompetition({
    required String competitionId,
    required String studentId,
    required String studentName,
    required String school,
  }) async {
    try {
      // Check if student is already participating
      final existingParticipants = await _getCompetitionParticipants(competitionId);
      if (existingParticipants.any((p) => p['studentId'] == studentId)) {
        throw Exception('Student already participating in this competition');
      }

      // Add student to participants
      await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .update({
        'participantSchools': FieldValue.arrayUnion([{
          'studentId': studentId,
          'studentName': studentName,
          'school': school,
          'completedAt': null,
          'score': null,
        }])
      });
    } catch (e) {
      throw Exception('Failed to join competition: $e');
    }
  }

  /// Submit competition results
  static Future<void> submitResults({
    required String competitionId,
    required String studentId,
    required int score,
  }) async {
    try {
      // Get competition document
      final competitionDoc = await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .get();

      if (!competitionDoc.exists) {
        throw Exception('Competition not found');
      }

      final competition = competitionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(competition['participantSchools'] ?? []);

      // Update participant score
      final updatedParticipants = participants.map((p) {
        if (p['studentId'] == studentId) {
          return {
            ...p,
            'score': score,
            'completedAt': DateTime.now().toIso8601String(),
          };
        }
        return p;
      }).toList();

      // Check if all participants have completed
      final allCompleted = updatedParticipants.every((p) => p['score'] != null);
      final status = allCompleted ? 'completed' : 'active';

      // Update competition
      await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .update({
        'participantSchools': updatedParticipants,
        'status': status,
        'completedAt': allCompleted ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      throw Exception('Failed to submit results: $e');
    }
  }

  /// Get competition with deduplicated questions for a student
  static Future<Map<String, dynamic>?> getCompetitionForStudent({
    required String competitionId,
    required String studentId,
  }) async {
    try {
      final competitionDoc = await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .get();

      if (!competitionDoc.exists) return null;

      final competition = competitionDoc.data()!;
      
      // Check if student has already completed this competition
      final participants = List<Map<String, dynamic>>.from(competition['participantSchools'] ?? []);
      final studentParticipant = participants.firstWhere(
        (p) => p['studentId'] == studentId,
        orElse: () => {},
      );

      if (studentParticipant['score'] != null) {
        return null; // Student already completed
      }

      // Get student's answered questions to deduplicate
      final answeredQuestions = await _getStudentAnsweredQuestions(studentId);
      
      // Filter out questions student has already answered
      final availableQuestions = (competition['questions'] as List)
          .where((q) => !answeredQuestions.contains(q['id']))
          .cast<Map<String, dynamic>>()
          .toList();

      return {
        ...competition,
        'availableQuestions': availableQuestions,
      };
    } catch (e) {
      throw Exception('Failed to get competition: $e');
    }
  }

  /// Calculate school scores and rankings
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
        final averageScore = scores.reduce((a, b) => a + b) / scores.length;
        
        return {
          'school': entry.key,
          'averageScore': averageScore,
          'participantCount': scores.length,
          'totalScore': scores.reduce((a, b) => a + b),
        };
      }).toList();

      // Sort by average score (descending)
      rankings.sort((a, b) => (b['averageScore'] as double).compareTo(a['averageScore'] as double));

      return rankings;
    } catch (e) {
      throw Exception('Failed to calculate rankings: $e');
    }
  }

  /// Get active competitions for a student
  static Future<List<Map<String, dynamic>>> getActiveCompetitions({
    required String grade,
    required String school,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('school_competitions')
          .where('grade', isEqualTo: grade)
          .where('status', isEqualTo: 'active')
          .get();

      final competitions = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final competition = doc.data();
        final participants = List<Map<String, dynamic>>.from(competition['participantSchools'] ?? []);
        
        // Check if student's school is already participating
        final schoolParticipating = participants.any((p) => p['school'] == school);
        
        if (!schoolParticipating) {
          competitions.add({
            ...competition,
            'id': doc.id,
          });
        }
      }

      return competitions;
    } catch (e) {
      throw Exception('Failed to get active competitions: $e');
    }
  }

  /// Get student's answered questions for deduplication
  static Future<Set<String>> _getStudentAnsweredQuestions(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(studentId)
          .collection('regular')
          .get();

      final answeredQuestions = <String>{};
      
      for (final doc in snapshot.docs) {
        final attempt = doc.data();
        final questions = List<Map<String, dynamic>>.from(attempt['questions'] ?? []);
        for (final question in questions) {
          answeredQuestions.add(question['id']);
        }
      }

      return answeredQuestions;
    } catch (e) {
      return {};
    }
  }

  /// Get competition participants
  static Future<List<Map<String, dynamic>>> _getCompetitionParticipants(String competitionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('school_competitions')
          .doc(competitionId)
          .get();

      if (!doc.exists) return [];
      
      return List<Map<String, dynamic>>.from(doc.data()?['participantSchools'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Generate unique competition ID
  static String _generateCompetitionId() {
    return 'comp_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}