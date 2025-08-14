import 'package:flutter/foundation.dart';
import '../data/models/lesson_model.dart';
import 'lesson_retrieval_service.dart';

/// Service for lesson section navigation operations
class LessonNavigationService {
  final LessonRetrievalService _lessonRetrievalService;

  LessonNavigationService({required LessonRetrievalService lessonRetrievalService})
      : _lessonRetrievalService = lessonRetrievalService;

  /// Get specific lesson section
  Future<LessonSection> getLessonSection(String lessonId, String sectionId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      final section = lessonContent.getSection(sectionId);
      
      if (section == null) {
        throw Exception('Section not found: $sectionId');
      }
      
      return section;
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getLessonSection: $e');
      rethrow;
    }
  }

  /// Get lesson sections in order
  Future<List<LessonSection>> getLessonSections(String lessonId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      return lessonContent.sections;
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getLessonSections: $e');
      rethrow;
    }
  }

  /// Get next section in lesson
  Future<LessonSection?> getNextSection(String lessonId, String currentSectionId) async {
    try {
      final sections = await getLessonSections(lessonId);
      final currentIndex = sections.indexWhere((s) => s.sectionId == currentSectionId);
      
      if (currentIndex == -1 || currentIndex >= sections.length - 1) {
        return null;
      }
      
      return sections[currentIndex + 1];
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getNextSection: $e');
      return null;
    }
  }

  /// Get previous section in lesson
  Future<LessonSection?> getPreviousSection(String lessonId, String currentSectionId) async {
    try {
      final sections = await getLessonSections(lessonId);
      final currentIndex = sections.indexWhere((s) => s.sectionId == currentSectionId);
      
      if (currentIndex <= 0) {
        return null;
      }
      
      return sections[currentIndex - 1];
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getPreviousSection: $e');
      return null;
    }
  }

  /// Check if lesson has questions
  Future<bool> lessonHasQuestions(String lessonId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      return lessonContent.sections.any((section) => section.type == 'question');
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in lessonHasQuestions: $e');
      return false;
    }
  }

  /// Get all question sections from a lesson
  Future<List<LessonSection>> getQuestionSections(String lessonId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      return lessonContent.sections.where((section) => section.type == 'question').toList();
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getQuestionSections: $e');
      return [];
    }
  }
}