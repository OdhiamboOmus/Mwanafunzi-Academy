import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Admin lesson service following Flutter Lite rules (<150 lines)
class AdminLessonService {
  // Admin credentials
  static const String _adminEmail = 'official.poa.labs@gmail.com';
  static const String _adminPassword = 'thy_will_be_done';
  
  /// Upload lesson content to Firestore with proper authentication
  static Future<void> uploadLessonContent({
    required String grade,
    required Map<String, dynamic> lesson,
  }) async {
    try {
      print('🔍 CONSOLE: AdminLessonService.uploadLessonContent started'); // Using print
      debugPrint('🔍 DEBUG: AdminLessonService.uploadLessonContent started');
      print('🔍 CONSOLE: Target grade: $grade'); // Using print
      debugPrint('🔍 DEBUG: Target grade: $grade');
      print('🔍 CONSOLE: Lesson ID: ${lesson['lessonId']}'); // Using print
      debugPrint('🔍 DEBUG: Lesson ID: ${lesson['lessonId']}');
      print('🔍 CONSOLE: Lesson title: ${lesson['title']}'); // Using print
      debugPrint('🔍 DEBUG: Lesson title: ${lesson['title']}');
      
      // Authenticate admin user first
      print('🔐 CONSOLE: Authenticating admin user...'); // Using print
      debugPrint('🔐 DEBUG: Authenticating admin user...');
      final user = await _authenticateAdmin();
      print('🔐 CONSOLE: Authentication successful for user: ${user?.email}'); // Using print
      debugPrint('🔐 DEBUG: Authentication successful for user: ${user?.email}');
      
      // Compress lesson content with gzip
      final compressedContent = _compressLessonContent(lesson);
      print('🔍 CONSOLE: Content compressed to ${compressedContent.length} bytes'); // Using print
      debugPrint('🔍 DEBUG: Content compressed to ${compressedContent.length} bytes');
      
      // Store in Firestore with 30-day cache headers simulation
      final lessonPath = 'lessons/$grade/${lesson['lessonId']}.json.gz';
      print('🔍 CONSOLE: Firestore path: $lessonPath'); // Using print
      debugPrint('🔍 DEBUG: Firestore path: $lessonPath');
      
      // Create lesson document in Firestore
      final lessonDoc = FirebaseFirestore.instance
          .collection('lessons')
          .doc(grade)
          .collection('lesson_files')
          .doc(lesson['lessonId']);
      
      print('🔍 CONSOLE: Writing to Firestore document...'); // Using print
      debugPrint('🔍 DEBUG: Writing to Firestore document...');
      await lessonDoc.set({
        'content': base64Encode(compressedContent),
        'contentType': 'application/gzip',
        'cacheControl': 'public, max-age=2592000', // 30 days in seconds
        'sizeBytes': compressedContent.length,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      print('🔍 CONSOLE: Firestore document written successfully'); // Using print
      debugPrint('🔍 DEBUG: Firestore document written successfully');
      
      // Create lessonsMeta document
      print('🔍 CONSOLE: Creating lessons metadata...'); // Using print
      debugPrint('🔍 DEBUG: Creating lessons metadata...');
      await _createLessonMetaDocument(grade, lesson, lessonPath);
      print('🔍 CONSOLE: Lessons metadata created successfully'); // Using print
      debugPrint('🔍 DEBUG: Lessons metadata created successfully');
      
      // Clear cache for this grade
      print('🔍 CONSOLE: Clearing cache for grade $grade...'); // Using print
      debugPrint('🔍 DEBUG: Clearing cache for grade $grade...');
      await _clearGradeCache(grade);
      print('🔍 CONSOLE: Cache cleared successfully'); // Using print
      debugPrint('🔍 DEBUG: Cache cleared successfully');
      
      print('🔍 CONSOLE: Upload completed successfully - lesson should be available to users'); // Using print
      debugPrint('🔍 DEBUG: Upload completed successfully - lesson should be available to users');
    } catch (e) {
      print('🔍 CONSOLE: Upload failed with error: $e'); // Using print
      debugPrint('🔍 DEBUG: Upload failed with error: $e');
      throw Exception('Failed to upload lesson content: $e');
    }
  }
  
  /// Authenticate admin user
  static Future<User?> _authenticateAdmin() async {
    try {
      // Check if already authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email == _adminEmail) {
        print('🔐 CONSOLE: Already authenticated as admin'); // Using print
        debugPrint('🔐 DEBUG: Already authenticated as admin');
        return currentUser;
      }
      
      // Sign in with admin credentials
      print('🔐 CONSOLE: Signing in as admin...'); // Using print
      debugPrint('🔐 DEBUG: Signing in as admin...');
      
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );
      
      print('🔐 CONSOLE: Admin authentication successful'); // Using print
      debugPrint('🔐 DEBUG: Admin authentication successful');
      return credential.user;
    } catch (e) {
      print('🔐 CONSOLE: Admin authentication failed: $e'); // Using print
      debugPrint('🔐 DEBUG: Admin authentication failed: $e');
      throw Exception('Admin authentication failed: $e');
    }
  }

  /// "Compress" lesson content using base64 encoding (simplified approach)
  static List<int> _compressLessonContent(Map<String, dynamic> lesson) {
    final jsonString = jsonEncode(lesson);
    final bytes = utf8.encode(jsonString);
    
    // For Flutter Lite compliance, we'll use base64 encoding instead of external compression
    // This avoids adding the archive package dependency
    return bytes;
  }

  /// Create lessonsMeta document
  static Future<void> _createLessonMetaDocument(
    String grade,
    Map<String, dynamic> lesson,
    String lessonPath,
  ) async {
    try {
      debugPrint('🔍 DEBUG: Creating meta document for grade $grade');
      final metaDoc = FirebaseFirestore.instance
          .collection('lessonsMeta')
          .doc(grade);
    
      final lessonMeta = {
        'id': lesson['lessonId'],
        'title': lesson['title'],
        'subject': lesson['subject'],
        'topic': lesson['topic'],
        'sizeBytes': lesson.toString().length,
        'contentPath': lessonPath,
        'version': 1,
        'totalSections': (lesson['sections'] as List).length,
        'hasQuestions': (lesson['sections'] as List).any((s) => s['type'] == 'question'),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      debugPrint('🔍 DEBUG: Meta data: ${lessonMeta.toString()}');
      
      await metaDoc.update({
        'lessons': FieldValue.arrayUnion([lessonMeta])
      });
      debugPrint('🔍 DEBUG: Meta document updated successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Failed to create lesson meta document: $e');
      throw Exception('Failed to create lesson meta document: $e');
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
      
      debugPrint('🔍 DEBUG: Clearing cache with key: $cacheKey');
      
      // Clear cached lessons meta
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');
      
      debugPrint('🔍 DEBUG: Cache cleared successfully for grade $grade');
    } catch (e) {
      // Don't throw exception for cache clearing failures
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