import 'package:flutter/foundation.dart';
import 'lesson_retrieval_service.dart';

/// Service for lesson section navigation operations
class LessonNavigationService {
  final LessonRetrievalService _lessonRetrievalService;

  LessonNavigationService({required LessonRetrievalService lessonRetrievalService})
      : _lessonRetrievalService = lessonRetrievalService;

  /// Get specific lesson section
  Future<Map<String, dynamic>> getLessonSection(String lessonId, String sectionId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      final sections = lessonContent['sections'] as List?;
      
      if (sections == null) {
        throw Exception('No sections found in lesson: $lessonId');
      }
      
      final section = sections.firstWhere(
        (s) => (s as Map<String, dynamic>)['sectionId'] == sectionId,
        orElse: () => null,
      );
      
      if (section == null) {
        throw Exception('Section not found: $sectionId');
      }
      
      return section as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getLessonSection: $e');
      rethrow;
    }
  }

  /// Get lesson sections in order
  Future<List<Map<String, dynamic>>> getLessonSections(String lessonId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      final sections = lessonContent['sections'] as List?;
      return sections?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getLessonSections: $e');
      rethrow;
    }
  }

  /// Get next section in lesson
  Future<Map<String, dynamic>?> getNextSection(String lessonId, String currentSectionId) async {
    try {
      final sections = await getLessonSections(lessonId);
      final currentIndex = sections.indexWhere((s) => (s as Map<String, dynamic>)?['sectionId'] == currentSectionId);
      
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
  Future<Map<String, dynamic>?> getPreviousSection(String lessonId, String currentSectionId) async {
    try {
      final sections = await getLessonSections(lessonId);
      final currentIndex = sections.indexWhere((s) => (s as Map<String, dynamic>)?['sectionId'] == currentSectionId);
      
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
      final sections = lessonContent['sections'] as List?;
      return sections?.any((section) => (section as Map<String, dynamic>)['type'] == 'question') ?? false;
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in lessonHasQuestions: $e');
      return false;
    }
  }

  /// Get all question sections from a lesson
  Future<List<Map<String, dynamic>>> getQuestionSections(String lessonId) async {
    try {
      final lessonContent = await _lessonRetrievalService.getLessonContent(lessonId);
      final sections = lessonContent['sections'] as List?;
      return sections?.where((section) => (section as Map<String, dynamic>)['type'] == 'question').cast<Map<String, dynamic>>().toList() ?? [];
    } catch (e) {
      debugPrint('❌ LessonNavigationService error in getQuestionSections: $e');
      return [];
    }
  }
}