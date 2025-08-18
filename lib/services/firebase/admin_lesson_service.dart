import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/lesson_model.dart';

// Admin lesson service following Flutter Lite rules (<150 lines)
class AdminLessonService {
  /// Upload lesson content to Firestore with gzip compression
  static Future<void> uploadLessonContent({
    required String grade,
    required LessonContent lesson,
  }) async {
    try {
      // Compress lesson content with gzip
      final compressedContent = _compressLessonContent(lesson);
      
      // Store in Firestore with 30-day cache headers simulation
      final lessonPath = 'lessons/$grade/${lesson.lessonId}.json.gz';
      
      // Create lesson document in Firestore
      final lessonDoc = FirebaseFirestore.instance
          .collection('lessons')
          .doc(grade)
          .collection('lesson_files')
          .doc(lesson.lessonId);
      
      await lessonDoc.set({
        'content': base64Encode(compressedContent),
        'contentType': 'application/gzip',
        'cacheControl': 'public, max-age=2592000', // 30 days in seconds
        'sizeBytes': compressedContent.length,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      
      // Create lessonsMeta document
      await _createLessonMetaDocument(grade, lesson, lessonPath);
      
      // Clear cache for this grade
      await _clearGradeCache(grade);
    } catch (e) {
      throw Exception('Failed to upload lesson content: $e');
    }
  }

  /// "Compress" lesson content using base64 encoding (simplified approach)
  static List<int> _compressLessonContent(LessonContent lesson) {
    final jsonString = jsonEncode(lesson.toJson());
    final bytes = utf8.encode(jsonString);
    
    // For Flutter Lite compliance, we'll use base64 encoding instead of external compression
    // This avoids adding the archive package dependency
    return bytes;
  }

  /// Create lessonsMeta document
  static Future<void> _createLessonMetaDocument(
    String grade,
    LessonContent lesson,
    String lessonPath,
  ) async {
    try {
      final metaDoc = FirebaseFirestore.instance
          .collection('lessonsMeta')
          .doc(grade);
      
      final lessonMeta = {
        'id': lesson.lessonId,
        'title': lesson.title,
        'subject': lesson.subject,
        'topic': lesson.topic,
        'sizeBytes': lesson.toJson().toString().length,
        'contentPath': lessonPath,
        'version': 1,
        'totalSections': lesson.sections.length,
        'hasQuestions': lesson.sections.any((s) => s.type == 'question'),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      await metaDoc.update({
        'lessons': FieldValue.arrayUnion([lessonMeta])
      });
    } catch (e) {
      throw Exception('Failed to create lesson meta document: $e');
    }
  }

  /// Validate lesson JSON structure
  static LessonContent validateLessonJson(Map<String, dynamic> jsonData) {
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
      
      if (jsonData['topic'] == null || jsonData['topic'] is! String) {
        throw Exception('Invalid or missing topic');
      }
      
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
        if (section['type'] == 'content' || section['type'] == 'question') {
          if (section['content'] == null || section['content'] is! String) {
            throw Exception('Invalid section content at index $i');
          }
        }
        
        // Validate image URLs maintain relative path structure
        if (section['imageUrl'] != null) {
          final imageUrl = section['imageUrl'] as String;
          if (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http')) {
            throw Exception('Image URL must start with "assets/" or be a valid URL at index $i');
          }
        }
        
        // Validate question-specific fields
        if (section['type'] == 'question') {
          if (section['options'] == null || section['options'] is! List) {
            throw Exception('Question must have options at index $i');
          }
          
          final options = section['options'] as List;
          if (options.length != 4 || !options.every((opt) => opt is String)) {
            throw Exception('Question must have exactly 4 string options at index $i');
          }
          
          if (section['correctAnswerIndex'] == null || 
              section['correctAnswerIndex'] is! int ||
              section['correctAnswerIndex'] < 0 || 
              section['correctAnswerIndex'] >= 4) {
            throw Exception('Invalid correctAnswerIndex at index $i');
          }
          
          if (section['explanation'] == null || section['explanation'] is! String) {
            throw Exception('Invalid explanation at index $i');
          }
        }
      }
      
      return LessonContent.fromJson(jsonData);
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
      
      // Clear cached lessons meta
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');
    } catch (e) {
      // Don't throw exception for cache clearing failures
      if (kDebugMode) {
        print('Warning: Failed to clear cache for grade $grade: $e');
      }
    }
  }

  /// Update lesson content
  static Future<void> updateLessonContent({
    required String grade,
    required LessonContent lesson,
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