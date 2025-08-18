import 'package:equatable/equatable.dart';

class StudentChallenge extends Equatable {
  final String id;
  final Map<String, dynamic> challenger;
  final Map<String, dynamic> challenged;
  final String topic;
  final String subject;
  final String grade;
  final String status;
  final List<Map<String, dynamic>> questions;
  final ChallengeResults? results;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const StudentChallenge({
    required this.id,
    required this.challenger,
    required this.challenged,
    required this.topic,
    required this.subject,
    required this.grade,
    required this.status,
    required this.questions,
    this.results,
    this.createdAt,
    this.completedAt,
  });

  factory StudentChallenge.fromJson(Map<String, dynamic> json) {
    return StudentChallenge(
      id: json['id'] ?? '',
      challenger: json['challenger'] ?? {},
      challenged: json['challenged'] ?? {},
      topic: json['topic'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
      status: json['status'] ?? 'pending',
      questions: (json['questions'] as List? ?? []).cast<Map<String, dynamic>>(),
      results: json['results'] != null ? ChallengeResults.fromJson(json['results']) : null,
      createdAt: json['createdAt']?.toDate(),
      completedAt: json['completedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenger': challenger,
      'challenged': challenged,
      'topic': topic,
      'subject': subject,
      'grade': grade,
      'status': status,
      'questions': questions,
      'results': results?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  StudentChallenge copyWith({
    String? id,
    Map<String, dynamic>? challenger,
    Map<String, dynamic>? challenged,
    String? topic,
    String? subject,
    String? grade,
    String? status,
    List<Map<String, dynamic>>? questions,
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

  @override
  List<Object?> get props => [
    id,
    challenger,
    challenged,
    topic,
    subject,
    grade,
    status,
    questions,
    results,
    createdAt,
    completedAt,
  ];
}

class ChallengeResults extends Equatable {
  final int challengerScore;
  final int challengedScore;
  final String? winner;
  final Map<String, dynamic> pointsAwarded;

  const ChallengeResults({
    required this.challengerScore,
    required this.challengedScore,
    this.winner,
    required this.pointsAwarded,
  });

  factory ChallengeResults.fromJson(Map<String, dynamic> json) {
    return ChallengeResults(
      challengerScore: json['challengerScore'] ?? 0,
      challengedScore: json['challengedScore'] ?? 0,
      winner: json['winner'],
      pointsAwarded: Map<String, dynamic>.from(json['pointsAwarded'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengerScore': challengerScore,
      'challengedScore': challengedScore,
      'winner': winner,
      'pointsAwarded': pointsAwarded,
    };
  }

  @override
  List<Object?> get props => [
    challengerScore,
    challengedScore,
    winner,
    pointsAwarded,
  ];
}