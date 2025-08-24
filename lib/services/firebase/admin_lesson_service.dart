import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Admin lesson service following Flutter Lite rules (<150 lines)
class AdminLessonService {
  /// Upload lesson content to Firestore with proper authentication
  static Future<void> uploadLessonContent({
    required String grade,
    required Map<String, dynamic> lesson,
  }) async {
    try {
      debugPrint('🔍 DEBUG: AdminLessonService.uploadLessonContent started');
      debugPrint('🔍 DEBUG: Target grade: $grade');
      debugPrint('🔍 DEBUG: Lesson ID: ${lesson['lessonId']}');
      debugPrint('🔍 DEBUG: Lesson title: ${lesson['title']}');
      
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please sign in first.');
      }
      
      debugPrint('🔐 DEBUG: User authenticated: ${user.email}');
      
      // Store lesson directly in Firestore (matching script structure)
      final lessonDoc = FirebaseFirestore.instance
          .collection('lessons')
          .doc(lesson['lessonId']);
      
      debugPrint('🔍 DEBUG: Writing lesson to Firestore...');
      
      await lessonDoc.set({
        'lessonId': lesson['lessonId'],
        'title': lesson['title'],
        'subject': lesson['subject'],
        'topic': lesson['topic'] ?? lesson['title'],
        'grade': grade,
        'sections': lesson['sections'],
        'totalSections': lesson['sections'].length,
        'hasQuestions': (lesson['sections'] as List).any((s) => s['type'] == 'question'),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': 1,
        'uploadedBy': user.email,
      });
      
      debugPrint('🔍 DEBUG: Lesson document written successfully');
      
      // Update lessonsMeta document
      await _updateLessonsMeta(grade, lesson);
      
      // Clear cache for this grade
      await _clearGradeCache(grade);
      
      debugPrint('🔍 DEBUG: Upload completed successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Upload failed: $e');
      throw Exception('Failed to upload lesson content: $e');
    }
  }
  
  /// Update lessons metadata
  static Future<void> _updateLessonsMeta(String grade, Map<String, dynamic> lesson) async {
    try {
      debugPrint('🔍 DEBUG: Updating lessons metadata for grade $grade');
      
      final metaDoc = FirebaseFirestore.instance
          .collection('lessonsMeta')
          .doc(grade);
      
      // Get existing lessons
      final snapshot = await metaDoc.get();
      List<Map<String, dynamic>> existingLessons = [];
      
      if (snapshot.exists && snapshot.data()?['lessons'] != null) {
        existingLessons = List<Map<String, dynamic>>.from(snapshot.data()!['lessons']);
      }
      
      // Remove existing lesson with same ID
      existingLessons.removeWhere((l) => l['id'] == lesson['lessonId']);
      
      // Add new lesson metadata
      final lessonMeta = {
        'id': lesson['lessonId'],
        'title': lesson['title'],
        'subject': lesson['subject'],
        'topic': lesson['topic'] ?? lesson['title'],
        'totalSections': lesson['sections'].length,
        'hasQuestions': (lesson['sections'] as List).any((s) => s['type'] == 'question'),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      existingLessons.add(lessonMeta);
      
      await metaDoc.set({
        'grade': grade,
        'lessons': existingLessons,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('🔍 DEBUG: Lessons metadata updated successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Failed to update lessons metadata: $e');
      throw Exception('Failed to update lessons metadata: $e');
    }
  }


  /// Validate lesson JSON structure
  static Map<String, dynamic> validateLessonJson(Map<String, dynamic> jsonData) {
    try {
      // Validate required fields
      if (jsonData['lessonId'] == null || jsonData['lessonId'] is! String) {
        throw Exception('Invalid or missing lessonId');
      }
      
      if (jsonData['title'] == null || jsonData['title'] is! String) {
        throw Exception('Invalid or missing title');
      }
      
      if (jsonData['subject'] == null || jsonData['subject'] is! String) {
        throw Exception('Invalid or missing subject');
      }
      
      // Make topic optional (use title as fallback)
      final topic = jsonData['topic'] ?? jsonData['title'];
      
      if (jsonData['sections'] == null || jsonData['sections'] is! List) {
        throw Exception('Invalid or missing sections');
      }
      
      final sections = jsonData['sections'] as List;
      if (sections.isEmpty) {
        throw Exception('Lesson must have at least one section');
      }
      
      // Validate each section
      for (int i = 0; i < sections.length; i++) {
        final section = sections[i];
        if (section['sectionId'] == null || section['sectionId'] is! String) {
          throw Exception('Invalid sectionId at index $i');
        }
        
        if (section['type'] == null || section['type'] is! String) {
          throw Exception('Invalid section type at index $i');
        }
        
        if (section['order'] == null || section['order'] is! int) {
          throw Exception('Invalid section order at index $i');
        }
        
        // Validate content based on type
        if (section['type'] == 'content') {
          if (section['content'] == null || section['content'] is! String) {
            throw Exception('Content section at index $i must have content');
          }
        } else if (section['type'] == 'question') {
          if (section['question'] == null || section['question'] is! String) {
            throw Exception('Question section at index $i must have question text');
          }
          
          if (section['options'] == null || section['options'] is! List) {
            throw Exception('Question must have options at index $i');
          }
          
          final options = section['options'] as List;
          if (options.length != 4 || !options.every((opt) => opt is String)) {
            throw Exception('Question must have exactly 4 string options at index $i');
          }
          
          if (section['correctAnswer'] == null ||
              section['correctAnswer'] is! int ||
              section['correctAnswer'] < 0 ||
              section['correctAnswer'] >= 4) {
            throw Exception('Question must have correctAnswer (0-3) at index $i');
          }
          
          if (section['explanation'] == null || section['explanation'] is! String) {
            throw Exception('Question must have explanation at index $i');
          }
        } else {
          throw Exception('Invalid section type at index $i. Must be "content" or "question"');
        }
        
        // Validate media array if present
        if (section['media'] != null) {
          final media = section['media'] as List;
          if (!media.every((item) => item is String)) {
            throw Exception('Media array must contain only strings at index $i');
          }
        }
      }
      
      // Add topic if missing
      if (jsonData['topic'] == null) {
        jsonData['topic'] = jsonData['title'];
      }
      
      return jsonData;
    } catch (e) {
      throw Exception('Error validating lesson JSON: ${e.toString()}');
    }
  }

  /// Get existing lessons for a grade
  static Future<List<Map<String, dynamic>>> getExistingLessons(String grade) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessonsMeta')
          .doc(grade)
          .get();
      
      if (snapshot.exists && snapshot.data()?['lessons'] != null) {
        return List<Map<String, dynamic>>.from(snapshot.data()!['lessons']);
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Delete lesson content
  static Future<void> deleteLessonContent({
    required String grade,
    required String lessonId,
  }) async {
    try {
      // Delete from Firestore
      final lessonDoc = FirebaseFirestore.instance
          .collection('lessons')
          .doc(grade)
          .collection('lesson_files')
          .doc(lessonId);
      await lessonDoc.delete();
      
      // Remove from lessonsMeta
      final metaDoc = FirebaseFirestore.instance
          .collection('lessonsMeta')
          .doc(grade);
      
      final snapshot = await metaDoc.get();
      if (snapshot.exists && snapshot.data()?['lessons'] != null) {
        final lessons = List<Map<String, dynamic>>.from(snapshot.data()!['lessons']);
        lessons.removeWhere((lesson) => lesson['id'] == lessonId);
        
        await metaDoc.update({
          'lessons': lessons
        });
      }
      
      // Clear cache for this grade
      await _clearGradeCache(grade);
    } catch (e) {
      throw Exception('Failed to delete lesson content: $e');
    }
  }

  /// Clear cache for a specific grade
  static Future<void> _clearGradeCache(String grade) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'lessons_meta_$grade';
      
      debugPrint('🔍 DEBUG: Clearing cache for grade $grade');
      
      // Clear cached lessons meta
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');
      
      // Clear lesson content cache
      final lessonCacheKey = 'lesson_content_$grade';
      await prefs.remove(lessonCacheKey);
      await prefs.remove('${lessonCacheKey}_timestamp');
      
      debugPrint('🔍 DEBUG: Cache cleared successfully for grade $grade');
    } catch (e) {
      debugPrint('🔍 DEBUG: Warning: Failed to clear cache for grade $grade: $e');
    }
  }

  /// Update lesson content
  static Future<void> updateLessonContent({
    required String grade,
    required Map<String, dynamic> lesson,
  }) async {
    try {
      await uploadLessonContent(
        grade: grade,
        lesson: lesson,
      );
    } catch (e) {
      throw Exception('Failed to update lesson content: $e');
    }
  }
}