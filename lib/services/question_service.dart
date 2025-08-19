import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../data/models/lesson_model.dart';
import 'lesson_service_core.dart';

/// Enhanced Question service for handling embedded questions within lesson sections
/// Implements immediate feedback without points awarded (Duolingo-style)
class QuestionService {
  final StorageService _storageService;
  
  static const String _answersKey = 'question_answers';
  static const String _feedbackKey = 'question_feedback';

  final LessonService _lessonService;
  
  QuestionService({
    required StorageService storageService,
    required LessonService lessonService,
  }) : _storageService = storageService,
       _lessonService = lessonService;

  /// Get question for a specific section
  Future<Map<String, dynamic>?> getQuestionForSection(String lessonId, String sectionId) async {
    try {
      final section = await _lessonService.getLessonSection(lessonId, sectionId);
      
      if (section['type'] == 'question' && section['question'] != null) {
        return section['question'];
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ QuestionService error in getQuestionForSection: $e');
      return null;
    }
  }

  /// Record student answer for a question with immediate feedback
  Future<Map<String, dynamic>?> recordAnswerWithFeedback(
    String lessonId,
    String sectionId,
    int selectedOption,
  ) async {
    try {
      final question = await getQuestionForSection(lessonId, sectionId);
      if (question == null) {
        throw Exception('Question not found for section: $sectionId');
      }

      // Record the answer
      await recordAnswer(question['questionId'], selectedOption, lessonId: lessonId);
      
      // Check if answer is correct
      final isCorrect = isAnswerCorrect(question['questionId'], selectedOption);
      
      // Get explanation
      final explanation = getExplanation(question['questionId']);
      
      // Record feedback for immediate display
      final feedback = {
        'questionId': question['questionId'],
        'selectedOption': selectedOption,
        'isCorrect': isCorrect,
        'explanation': explanation,
        'answeredAt': DateTime.now().toIso8601String(),
        'lessonId': lessonId,
        'sectionId': sectionId,
      };
      
      // Store feedback for immediate display
      await _storeFeedback(feedback);
      
      debugPrint('✅ Answer recorded with feedback for question: ${question['questionId']}, correct: $isCorrect');
      
      return feedback;
    } catch (e) {
      debugPrint('❌ QuestionService error in recordAnswerWithFeedback: $e');
      return null;
    }
  }

  /// Record student answer for a question
  Future<void> recordAnswer(String questionId, int selectedOption, {String? lessonId}) async {
    try {
      final answers = await getRecordedAnswers();
      
      // Add or update the answer
      answers[questionId] = {
        'selectedOption': selectedOption,
        'answeredAt': DateTime.now().toIso8601String(),
        'lessonId': lessonId,
      };
      
      await _storageService.setCachedData(
        key: _answersKey,
        data: answers,
        toJson: (answers) => answers,
      );
      
      debugPrint('✅ Answer recorded for question: $questionId, option: $selectedOption');
    } catch (e) {
      debugPrint('❌ QuestionService error in recordAnswer: $e');
    }
  }

  /// Check if answer is correct
  bool isAnswerCorrect(String questionId, int selectedOption) {
    try {
      final question = _getQuestionById(questionId);
      return question?['correctAnswer'] == selectedOption;
    } catch (e) {
      debugPrint('❌ QuestionService error in isAnswerCorrect: $e');
      return false;
    }
  }

  /// Get explanation for a question
  String? getExplanation(String questionId) {
    try {
      final question = _getQuestionById(questionId);
      return question?['explanation'];
    } catch (e) {
      debugPrint('❌ QuestionService error in getExplanation: $e');
      return null;
    }
  }

  /// Check if question has been answered
  Future<bool> isQuestionAnswered(String questionId) async {
    try {
      final answers = await getRecordedAnswers();
      return answers.containsKey(questionId);
    } catch (e) {
      debugPrint('❌ QuestionService error in isQuestionAnswered: $e');
      return false;
    }
  }

  /// Get answer details for a question
  Future<Map<String, dynamic>?> getAnswerDetails(String questionId) async {
    try {
      final answers = await getRecordedAnswers();
      return answers[questionId] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ QuestionService error in getAnswerDetails: $e');
      return null;
    }
  }

  /// Get all answered questions for a lesson
  Future<List<Map<String, dynamic>>> getAnsweredQuestionsForLesson(String lessonId) async {
    try {
      final answers = await getRecordedAnswers();
      return answers.entries
          .where((entry) => entry.value['lessonId'] == lessonId)
          .map((entry) => {
                'questionId': entry.key,
                'selectedOption': entry.value['selectedOption'],
                'answeredAt': entry.value['answeredAt'],
              })
          .toList();
    } catch (e) {
      debugPrint('❌ QuestionService error in getAnsweredQuestionsForLesson: $e');
      return [];
    }
  }

  /// Clear recorded answers
  Future<bool> clearAnswers() async {
    try {
      // Clear both answers and feedback
      await _storageService.removeValue(_answersKey);
      await _storageService.removeValue(_feedbackKey);
      return true;
    } catch (e) {
      debugPrint('❌ QuestionService error in clearAnswers: $e');
      return false;
    }
  }

  /// Get recorded answers for parent dashboard
  Future<Map<String, dynamic>> getRecordedAnswers() async {
    try {
      final answers = await _storageService.getCachedData<Map<String, dynamic>>(
        key: _answersKey,
        fromJson: (json) => Map<String, dynamic>.from(json),
        ttlSeconds: null,
      );
      
      return answers ?? {};
    } catch (e) {
      debugPrint('❌ QuestionService error in getRecordedAnswers: $e');
      return {};
    }
  }

  /// Get immediate feedback for a question
  Future<Map<String, dynamic>?> getQuestionFeedback(String questionId) async {
    try {
      final feedback = await _storageService.getCachedData<Map<String, dynamic>>(
        key: '$_feedbackKey$questionId',
        fromJson: (json) => json,
        ttlSeconds: 300, // 5 minutes cache for feedback
      );
      
      return feedback;
    } catch (e) {
      debugPrint('❌ QuestionService error in getQuestionFeedback: $e');
      return null;
    }
  }

  /// Store feedback for immediate display
  Future<void> _storeFeedback(Map<String, dynamic> feedback) async {
    try {
      final questionId = feedback['questionId'] as String;
      await _storageService.setCachedData(
        key: '$_feedbackKey$questionId',
        data: feedback,
        toJson: (feedback) => feedback,
      );
    } catch (e) {
      debugPrint('❌ QuestionService error in _storeFeedback: $e');
    }
  }


  /// Get sample lesson content as fallback
  Map<String, dynamic> _getSampleLessonContent(String lessonId) {
    final sampleContent = '''
    {
      "lessonId": "$lessonId",
      "title": "Sample Lesson",
      "sections": [
        {
          "sectionId": "section_1",
          "type": "content",
          "title": "Introduction",
          "content": "Welcome to this lesson!",
          "media": [],
          "order": 1
        },
        {
          "sectionId": "section_2",
          "type": "question",
          "title": "Check Your Understanding",
          "content": "What did you learn?",
          "media": [],
          "order": 2,
          "question": {
            "questionId": "q1",
            "question": "What is the capital of Kenya?",
            "options": ["Nairobi", "Mombasa", "Kisumu", "Eldoret"],
            "correctAnswer": 0,
            "explanation": "Nairobi is the capital city of Kenya."
          }
        }
      ]
    }
    ''';
    
    return jsonDecode(sampleContent) as Map<String, dynamic>;
  }

  /// Get question by ID from lesson content
  Map<String, dynamic>? _getQuestionById(String questionId) {
    try {
      // In real implementation, this would fetch from lesson content
      // For now, return sample question
      return {
        'questionId': questionId,
        'question': 'What is the capital of Kenya?',
        'options': ['Nairobi', 'Mombasa', 'Kisumu', 'Eldoret'],
        'correctAnswer': 0,
        'explanation': 'Nairobi is the capital city of Kenya.',
      };
    } catch (e) {
      debugPrint('❌ QuestionService error in _getQuestionById: $e');
      return null;
    }
  }
}