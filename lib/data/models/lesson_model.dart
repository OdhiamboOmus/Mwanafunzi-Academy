/// Lesson section model for Duolingo-style learning
class LessonSection {
  final String sectionId;
  final String type; // 'content' or 'question'
  final String title;
  final String content;
  final List<String> media; // Image/audio file paths
  final int order;
  final QuestionModel? question; // Only if type == 'question'

  LessonSection({
    required this.sectionId,
    required this.type,
    required this.title,
    required this.content,
    required this.media,
    required this.order,
    this.question,
  });

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      sectionId: json['sectionId'] ?? '',
      type: json['type'] ?? 'content',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      media: List<String>.from(json['media'] ?? []),
      order: json['order'] ?? 0,
      question: json['question'] != null 
          ? QuestionModel.fromJson(json['question']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionId': sectionId,
      'type': type,
      'title': title,
      'content': content,
      'media': media,
      'order': order,
      'question': question?.toJson(),
    };
  }
}

/// Question model for embedded assessments
class QuestionModel {
  final String questionId;
  final String question;
  final List<String> options;
  final int correctAnswer; // Index of correct option (0-3)
  final String explanation;

  QuestionModel({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['questionId'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  /// Check if answer is correct
  bool isAnswerCorrect(int selectedOption) {
    return selectedOption == correctAnswer;
  }
}

/// Lesson metadata model
class LessonMeta {
  final String id;
  final String title;
  final String subject;
  final String grade;
  final String version;
  final int sizeBytes;
  final String contentPath;
  final int mediaCount;
  final int totalSections;
  final bool hasQuestions;
  final DateTime lastUpdated;

  LessonMeta({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.version,
    required this.sizeBytes,
    required this.contentPath,
    required this.mediaCount,
    required this.totalSections,
    required this.hasQuestions,
    required this.lastUpdated,
  });

  factory LessonMeta.fromJson(Map<String, dynamic> json) {
    return LessonMeta(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
      version: json['version'] ?? '1.0.0',
      sizeBytes: json['sizeBytes'] ?? 0,
      contentPath: json['contentPath'] ?? '',
      mediaCount: json['mediaCount'] ?? 0,
      totalSections: json['totalSections'] ?? 0,
      hasQuestions: json['hasQuestions'] ?? false,
      lastUpdated: json['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'grade': grade,
      'version': version,
      'sizeBytes': sizeBytes,
      'contentPath': contentPath,
      'mediaCount': mediaCount,
      'totalSections': totalSections,
      'hasQuestions': hasQuestions,
      'lastUpdated': lastUpdated,
    };
  }
}

/// Complete lesson content model
class LessonContent {
  final String lessonId;
  final String title;
  final List<LessonSection> sections;

  LessonContent({
    required this.lessonId,
    required this.title,
    required this.sections,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List?;
    final sections = sectionsJson?.map((section) => 
        LessonSection.fromJson(section)).toList() ?? [];

    return LessonContent(
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'title': title,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }

  /// Get section by ID
  LessonSection? getSection(String sectionId) {
    try {
      return sections.firstWhere((section) => section.sectionId == sectionId);
    } catch (e) {
      return null;
    }
  }

  /// Get questions from lesson
  List<QuestionModel> getQuestions() {
    return sections
        .where((section) => section.type == 'question' && section.question != null)
        .map((section) => section.question!)
        .toList();
  }
}