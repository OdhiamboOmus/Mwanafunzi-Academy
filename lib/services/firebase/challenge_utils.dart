import 'dart:math' as math;
import 'challenge_models.dart';

class ChallengeUtils {
  /// Generate a unique challenge ID
  static String generateChallengeId() {
    return 'challenge_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().second}';
  }

  /// Calculate challenge score based on answers
  static int calculateScore(List<int> answers, List<Map<String, dynamic>> questions) {
    if (answers.length != questions.length) {
      throw ArgumentError('Number of answers must match number of questions');
    }

    int correctCount = 0;
    for (int i = 0; i < questions.length; i++) {
      final correctAnswerIndex = questions[i]['correctAnswerIndex'] as int;
      if (answers[i] == correctAnswerIndex) {
        correctCount++;
      }
    }

    return correctCount;
  }

  /// Calculate challenge results and points
  static ChallengeResults calculateChallengeResults(
    StudentChallenge challenge,
    String completingStudentId,
    int score,
  ) {
    final challengerScore = challenge.results?.challengerScore ?? 0;
    final challengedScore = challenge.results?.challengedScore ?? 0;
    
    // Scoring: 1 point per correct answer + 3 bonus for winner + 1 each for draw
    Map<String, dynamic> pointsAwarded = {};
    String? winner;
    
    if (challengerScore > challengedScore) {
      winner = challenge.challenger['studentId'];
      pointsAwarded = {
        'challenger': challengerScore + 3, // Winner bonus
        'challenged': challengedScore,     // No bonus
      };
    } else if (challengedScore > challengerScore) {
      winner = challenge.challenged['studentId'];
      pointsAwarded = {
        'challenger': challengerScore,     // No bonus
        'challenged': challengedScore + 3, // Winner bonus
      };
    } else {
      // Draw
      winner = 'draw';
      pointsAwarded = {
        'challenger': challengerScore + 1, // Draw bonus
        'challenged': challengedScore + 1, // Draw bonus
      };
    }
    
    return ChallengeResults(
      challengerScore: challengerScore,
      challengedScore: challengedScore,
      winner: winner,
      pointsAwarded: pointsAwarded,
    );
  }

  /// Update challenge with completion results
  static StudentChallenge updateChallengeWithResults(
    StudentChallenge challenge,
    String completingStudentId,
    int score,
  ) {
    // Check if this is the first completion or second
    final challengerCompleted = challenge.results?.challengerScore != null;
    final challengedCompleted = challenge.results?.challengedScore != null;
    
    // Determine which student completed this attempt
    bool isFirstCompletion = true;
    if (completingStudentId == challenge.challenger['studentId']) {
      if (challengedCompleted) {
        isFirstCompletion = false; // Challenger is second to complete
      }
    } else {
      if (challengerCompleted) {
        isFirstCompletion = false; // Challenged is second to complete
      }
    }
    
    // Calculate challenge results
    ChallengeResults? results;
    String status = 'in_progress';
    
    if (!isFirstCompletion) {
      // Both students completed, determine winner
      status = 'completed';
      results = calculateChallengeResults(challenge, completingStudentId, score);
    } else {
      // First completion, just record score
      results = ChallengeResults(
        challengerScore: completingStudentId == challenge.challenger['studentId'] ? score : 0,
        challengedScore: completingStudentId == challenge.challenged['studentId'] ? score : 0,
        winner: null,
        pointsAwarded: {},
      );
    }
    
    return challenge.copyWith(
      status: status,
      results: results,
      completedAt: status == 'completed' ? DateTime.now() : null,
    );
  }

  /// Validate challenge data structure
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
        if (!validateQuizQuestion(question)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate individual quiz question
  static bool validateQuizQuestion(Map<String, dynamic> question) {
    try {
      // Check required fields
      if (question['question'] == null || question['question'] is! String) {
        return false;
      }
      
      if (question['options'] == null || question['options'] is! List) {
        return false;
      }
      
      if (question['correctAnswerIndex'] == null || question['correctAnswerIndex'] is! int) {
        return false;
      }
      
      if (question['explanation'] == null || question['explanation'] is! String) {
        return false;
      }
      
      // Validate options
      final options = question['options'] as List;
      if (options.length != 4) {
        return false;
      }
      
      for (final option in options) {
        if (option is! String || option.trim().isEmpty) {
          return false;
        }
      }
      
      // Validate correct answer index
      final correctIndex = question['correctAnswerIndex'] as int;
      if (correctIndex < 0 || correctIndex >= 4) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Select random questions from a list
  static List<Map<String, dynamic>> selectRandomQuestions(
    List<Map<String, dynamic>> allQuestions, {
    int maxQuestions = 10,
  }) {
    if (allQuestions.isEmpty) {
      return [];
    }
    
    // Limit to maxQuestions
    final questionCount = allQuestions.length > maxQuestions ? maxQuestions : allQuestions.length;
    final selectedQuestions = <Map<String, dynamic>>[];
    final usedIndices = <int>{};
    
    final random = math.Random(DateTime.now().millisecondsSinceEpoch);
    for (int i = 0; i < questionCount; i++) {
      int index;
      do {
        index = random.nextInt(allQuestions.length);
      } while (usedIndices.contains(index));
      
      usedIndices.add(index);
      selectedQuestions.add(allQuestions[index]);
    }
    
    return selectedQuestions;
  }
}