
import 'package:flutter/foundation.dart';

/// Represents a single quiz question
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  /// Create from JSON
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 DEBUG: Creating QuizQuestion from JSON: $json');
    
    try {
      final id = json['id'];
      final question = json['question'];
      final options = json['options'];
      final correctAnswerIndex = json['correctAnswerIndex'];
      final explanation = json['explanation'];
      
      debugPrint('🔍 DEBUG: Parsed values - id: $id, question: $question, options: $options, correctAnswerIndex: $correctAnswerIndex, explanation: $explanation');
      
      if (id == null || question == null || options == null || correctAnswerIndex == null || explanation == null) {
        debugPrint('❌ ERROR: Missing required fields in JSON: $json');
        throw Exception('Missing required fields in quiz question');
      }
      
      return QuizQuestion(
        id: id,
        question: question,
        options: List<String>.from(options),
        correctAnswerIndex: correctAnswerIndex,
        explanation: explanation,
      );
    } catch (e) {
      debugPrint('❌ ERROR: Failed to create QuizQuestion from JSON: $e');
      rethrow;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  /// Check if answer is correct
  bool isCorrect(int answerIndex) {
    return answerIndex == correctAnswerIndex;
  }

  /// Get correct answer text
  String getCorrectAnswer() {
    return options[correctAnswerIndex];
  }
}

/// Represents a quiz attempt by a student
class QuizAttempt {
  final String studentId;
  final String grade;
  final String subject;
  final String topic;
  final List<QuizQuestion> questions;
  final List<int> answers;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  QuizAttempt({
    required this.studentId,
    required this.grade,
    required this.subject,
    required this.topic,
    required this.questions,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  /// Create from JSON
  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      studentId: json['studentId'] ?? '',
      grade: json['grade'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      answers: List<int>.from(json['answers'] ?? []),
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'questions': questions.map((q) => q.toJson()).toList(),
      'answers': answers,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  /// Calculate score from answers
  static QuizAttempt calculateScore({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
    required List<int> answers,
    DateTime? completedAt,
  }) {
    if (answers.length != questions.length) {
      throw ArgumentError('Number of answers must match number of questions');
    }

    int correctCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (questions[i].isCorrect(answers[i])) {
        correctCount++;
      }
    }

    return QuizAttempt(
      studentId: studentId,
      grade: grade,
      subject: subject,
      topic: topic,
      questions: questions,
      answers: answers,
      score: correctCount,
      totalQuestions: questions.length,
      completedAt: completedAt ?? DateTime.now(),
    );
  }
}

/// Represents a student challenge competition
class StudentChallenge {
  final String id;
  final StudentInfo challenger;
  final StudentInfo challenged;
  final String topic;
  final String subject;
  final String grade;
  String status;
  final List<QuizQuestion> questions;
  final ChallengeResults? results;
  final DateTime createdAt;
  final DateTime? completedAt;

  StudentChallenge({
    required this.id,
    required this.challenger,
    required this.challenged,
    required this.topic,
    required this.subject,
    required this.grade,
    required this.status,
    required this.questions,
    this.results,
    required this.createdAt,
    this.completedAt,
  });

  /// Create from JSON
  factory StudentChallenge.fromJson(Map<String, dynamic> json) {
    return StudentChallenge(
      id: json['id'] ?? '',
      challenger: StudentInfo.fromJson(json['challenger'] ?? {}),
      challenged: StudentInfo.fromJson(json['challenged'] ?? {}),
      topic: json['topic'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
      status: json['status'] ?? 'pending',
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      results: json['results'] != null 
          ? ChallengeResults.fromJson(json['results'])
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenger': challenger.toJson(),
      'challenged': challenged.toJson(),
      'topic': topic,
      'subject': subject,
      'grade': grade,
      'status': status,
      'questions': questions.map((q) => q.toJson()).toList(),
      'results': results?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Copy with updated fields
  StudentChallenge copyWith({
    String? id,
    StudentInfo? challenger,
    StudentInfo? challenged,
    String? topic,
    String? subject,
    String? grade,
    String? status,
    List<QuizQuestion>? questions,
    ChallengeResults? results,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return StudentChallenge(
      id: id ?? this.id,
      challenger: challenger ?? this.challenger,
      challenged: challenged ?? this.challenged,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      questions: questions ?? this.questions,
      results: results ?? this.results,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if challenge is completed
  bool get isCompleted => status == 'completed';

  /// Check if challenge is pending
  bool get isPending => status == 'pending';

  /// Check if challenge is in progress
  bool get isInProgress => status == 'in_progress';
}

/// Represents student information in challenges
class StudentInfo {
  final String studentId;
  final String name;
  final String school;

  StudentInfo({
    required this.studentId,
    required this.name,
    required this.school,
  });

  /// Create from JSON
  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      studentId: json['studentId'] ?? '',
      name: json['name'] ?? '',
      school: json['school'] ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'school': school,
    };
  }
}

/// Represents challenge results
class ChallengeResults {
  final int? challengerScore;
  final int? challengedScore;
  final String? winner;
  final Map<String, dynamic> pointsAwarded;

  ChallengeResults({
    this.challengerScore,
    this.challengedScore,
    this.winner,
    required this.pointsAwarded,
  });

  /// Create from JSON
  factory ChallengeResults.fromJson(Map<String, dynamic> json) {
    return ChallengeResults(
      challengerScore: json['challengerScore'],
      challengedScore: json['challengedScore'],
      winner: json['winner'],
      pointsAwarded: Map<String, dynamic>.from(json['pointsAwarded'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'challengerScore': challengerScore,
      'challengedScore': challengedScore,
      'winner': winner,
      'pointsAwarded': pointsAwarded,
    };
  }
}

/// Represents quiz analytics for a child
class ChildQuizAnalytics {
  final int totalQuizzesTaken;
  final double averageScore;
  final List<String> topicsCompleted;
  final List<QuizAttempt> recentAttempts;
  final Map<String, double> subjectPerformance;
  final List<String> strongestTopics;
  final List<String> weakestTopics;

  ChildQuizAnalytics({
    required this.totalQuizzesTaken,
    required this.averageScore,
    required this.topicsCompleted,
    required this.recentAttempts,
    required this.subjectPerformance,
    required this.strongestTopics,
    required this.weakestTopics,
  });

  /// Create from JSON
  factory ChildQuizAnalytics.fromJson(Map<String, dynamic> json) {
    return ChildQuizAnalytics(
      totalQuizzesTaken: json['totalQuizzesTaken'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      topicsCompleted: List<String>.from(json['topicsCompleted'] ?? []),
      recentAttempts: (json['recentAttempts'] as List)
          .map((a) => QuizAttempt.fromJson(a))
          .toList(),
      subjectPerformance: Map<String, double>.from(json['subjectPerformance'] ?? {}),
      strongestTopics: List<String>.from(json['strongestTopics'] ?? []),
      weakestTopics: List<String>.from(json['weakestTopics'] ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalQuizzesTaken': totalQuizzesTaken,
      'averageScore': averageScore,
      'topicsCompleted': topicsCompleted,
      'recentAttempts': recentAttempts.map((a) => a.toJson()).toList(),
      'subjectPerformance': subjectPerformance,
      'strongestTopics': strongestTopics,
      'weakestTopics': weakestTopics,
    };
  }
}