import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_model.dart';
import 'quiz_model.dart';

/// Unified content model that matches both script and app structures
/// This model serves as the bridge between the Node.js scripts and Flutter app

/// Represents a lesson section (content or question)
class ContentSection {
  final String sectionId;
  final String type; // 'content' or 'question'
  final String title;
  final String content; // For content sections
  final String question; // For question sections
  final List<String> options; // For question sections (4 options)
  final int correctAnswer; // For question sections (0-3)
  final String explanation; // For question sections
  final int order;
  final List<String> media; // Media files for content sections

  ContentSection({
    required this.sectionId,
    required this.type,
    required this.title,
    this.content = '',
    this.question = '',
    this.options = const [],
    this.correctAnswer = 0,
    this.explanation = '',
    required this.order,
    this.media = const [],
  });

  /// Create from JSON (matches script format)
  factory ContentSection.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 DEBUG: Creating ContentSection from JSON: $json');
    
    try {
      return ContentSection(
        sectionId: json['sectionId'] ?? json['id'] ?? '',
        type: json['type'] ?? 'content',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctAnswer: json['correctAnswer'] ?? json['correctAnswerIndex'] ?? 0,
        explanation: json['explanation'] ?? '',
        order: json['order'] ?? 1,
        media: List<String>.from(json['media'] ?? []),
      );
    } catch (e) {
      debugPrint('❌ ERROR: Failed to create ContentSection from JSON: $e');
      rethrow;
    }
  }

  /// Convert to JSON (matches script format)
  Map<String, dynamic> toJson() {
    return {
      'sectionId': sectionId,
      'type': type,
      'title': title,
      'content': content,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'order': order,
      'media': media,
    };
  }

  /// Check if this is a content section
  bool get isContent => type == 'content';
  
  /// Check if this is a question section
  bool get isQuestion => type == 'question';
}

/// Represents a complete lesson (matches script format)
class LessonContent {
  final String lessonId;
  final String title;
  final String subject;
  final String topic;
  final String grade;
  final List<ContentSection> sections;
  final int totalSections;
  final bool hasQuestions;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int version;

  LessonContent({
    required this.lessonId,
    required this.title,
    required this.subject,
    required this.topic,
    required this.grade,
    required this.sections,
    this.totalSections = 0,
    this.hasQuestions = false,
    required this.createdAt,
    required this.lastUpdated,
    this.version = 1,
  });

  /// Create from JSON (matches script format)
  factory LessonContent.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 DEBUG: Creating LessonContent from JSON: $json');
    
    try {
      final sections = (json['sections'] as List)
          .map((s) => ContentSection.fromJson(s))
          .toList();
      
      return LessonContent(
        lessonId: json['lessonId'] ?? '',
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? json['title'] ?? '',
        grade: json['grade'] ?? '',
        sections: sections,
        totalSections: json['totalSections'] ?? sections.length,
        hasQuestions: json['hasQuestions'] ?? sections.any((s) => s.isQuestion),
        createdAt: json['createdAt'] != null 
            ? (json['createdAt'] is Timestamp 
                ? (json['createdAt'] as Timestamp).toDate()
                : DateTime.parse(json['createdAt']))
            : DateTime.now(),
        lastUpdated: json['lastUpdated'] != null 
            ? (json['lastUpdated'] is Timestamp 
                ? (json['lastUpdated'] as Timestamp).toDate()
                : DateTime.parse(json['lastUpdated']))
            : DateTime.now(),
        version: json['version'] ?? 1,
      );
    } catch (e) {
      debugPrint('❌ ERROR: Failed to create LessonContent from JSON: $e');
      rethrow;
    }
  }

  /// Convert to JSON (matches script format)
  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'title': title,
      'subject': subject,
      'topic': topic,
      'grade': grade,
      'sections': sections.map((s) => s.toJson()).toList(),
      'totalSections': totalSections,
      'hasQuestions': hasQuestions,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }

  /// Get content sections only
  List<ContentSection> get contentSections => sections.where((s) => s.isContent).toList();
  
  /// Get question sections only
  List<ContentSection> get questionSections => sections.where((s) => s.isQuestion).toList();
  
  /// Get estimated duration based on sections
  Duration get estimatedDuration {
    final contentCount = contentSections.length;
    final questionCount = questionSections.length;
    // Estimate: 5 minutes per content section, 2 minutes per question
    final totalMinutes = (contentCount * 5) + (questionCount * 2);
    return Duration(minutes: totalMinutes);
  }
}

/// Represents a quiz question (matches script format)
class UnifiedQuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String? title;
  final String? description;

  UnifiedQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.title,
    this.description,
  });

  /// Create from JSON (matches script format)
  factory UnifiedQuizQuestion.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 DEBUG: Creating UnifiedQuizQuestion from JSON: $json');
    
    try {
      return UnifiedQuizQuestion(
        id: json['id'] ?? '',
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctAnswerIndex: json['correctAnswerIndex'] ?? json['correctAnswer'] ?? 0,
        explanation: json['explanation'] ?? '',
        title: json['title'],
        description: json['description'],
      );
    } catch (e) {
      debugPrint('❌ ERROR: Failed to create UnifiedQuizQuestion from JSON: $e');
      rethrow;
    }
  }

  /// Convert to JSON (matches script format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'title': title,
      'description': description,
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

/// Represents a complete quiz (matches script format)
class QuizContent {
  final String quizId;
  final String title;
  final String subject;
  final String topic;
  final String grade;
  final String description;
  final List<UnifiedQuizQuestion> questions;
  final int totalQuestions;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int version;

  QuizContent({
    required this.quizId,
    required this.title,
    required this.subject,
    required this.topic,
    required this.grade,
    required this.description,
    required this.questions,
    this.totalQuestions = 0,
    required this.createdAt,
    required this.lastUpdated,
    this.version = 1,
  });

  /// Create from JSON (matches script format)
  factory QuizContent.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 DEBUG: Creating QuizContent from JSON: $json');
    
    try {
      final questions = (json['questions'] as List)
          .map((q) => UnifiedQuizQuestion.fromJson(q))
          .toList();
      
      return QuizContent(
        quizId: json['quizId'] ?? '',
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? '',
        grade: json['grade'] ?? '',
        description: json['description'] ?? '',
        questions: questions,
        totalQuestions: json['totalQuestions'] ?? questions.length,
        createdAt: json['createdAt'] != null 
            ? (json['createdAt'] is Timestamp 
                ? (json['createdAt'] as Timestamp).toDate()
                : DateTime.parse(json['createdAt']))
            : DateTime.now(),
        lastUpdated: json['lastUpdated'] != null 
            ? (json['lastUpdated'] is Timestamp 
                ? (json['lastUpdated'] as Timestamp).toDate()
                : DateTime.parse(json['lastUpdated']))
            : DateTime.now(),
        version: json['version'] ?? 1,
      );
    } catch (e) {
      debugPrint('❌ ERROR: Failed to create QuizContent from JSON: $e');
      rethrow;
    }
  }

  /// Convert to JSON (matches script format)
  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'title': title,
      'subject': subject,
      'topic': topic,
      'grade': grade,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'totalQuestions': totalQuestions,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }

  /// Get estimated duration based on questions
  Duration get estimatedDuration {
    // Estimate: 1 minute per question
    return Duration(minutes: totalQuestions);
  }
}

/// Converter utilities for legacy models
class ContentModelConverter {
  /// Convert legacy LessonModel to unified LessonContent
  static LessonContent convertLessonModel(LessonModel legacyModel) {
    return LessonContent(
      lessonId: legacyModel.id,
      title: 'Lesson ${legacyModel.weekNumber}', // Default title
      subject: 'Mathematics', // Default subject
      topic: 'Week ${legacyModel.weekNumber}', // Default topic
      grade: '5', // Default grade
      sections: [], // Convert sections if needed
      totalSections: 1,
      hasQuestions: false,
      createdAt: legacyModel.createdAt,
      lastUpdated: legacyModel.createdAt,
      version: 1,
    );
  }

  /// Convert legacy QuizQuestion to unified UnifiedQuizQuestion
  static UnifiedQuizQuestion convertQuizQuestion(QuizQuestion legacyQuestion) {
    return UnifiedQuizQuestion(
      id: legacyQuestion.id,
      question: legacyQuestion.question,
      options: legacyQuestion.options,
      correctAnswerIndex: legacyQuestion.correctAnswerIndex,
      explanation: legacyQuestion.explanation,
    );
  }

  /// Convert legacy QuizAttempt to unified QuizContent
  static QuizContent convertQuizAttempt(QuizAttempt legacyAttempt) {
    return QuizContent(
      quizId: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: '${legacyAttempt.subject} - ${legacyAttempt.topic} Quiz',
      subject: legacyAttempt.subject,
      topic: legacyAttempt.topic,
      grade: legacyAttempt.grade,
      description: '${legacyAttempt.subject} quiz on ${legacyAttempt.topic} for grade ${legacyAttempt.grade}',
      questions: legacyAttempt.questions.map((q) => convertQuizQuestion(q)).toList(),
      totalQuestions: legacyAttempt.questions.length,
      createdAt: legacyAttempt.completedAt,
      lastUpdated: legacyAttempt.completedAt,
      version: 1,
    );
  }
}