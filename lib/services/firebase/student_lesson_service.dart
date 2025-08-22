import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Student lesson service following Flutter Lite rules (<150 lines)
class StudentLessonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get lessons for a specific grade from Firestore
  Future<List<Map<String, dynamic>>> getLessonsForGrade(String grade) async {
    try {
      debugPrint('🔍 DEBUG: Fetching lessons for grade: $grade');
      
      // Validate grade input
      if (grade.isEmpty) {
        debugPrint('❌ ERROR: Grade cannot be empty');
        return [];
      }
      
      // Try to get cached lessons first
      try {
        final cachedLessons = await _getCachedLessons(grade);
        if (cachedLessons.isNotEmpty) {
          debugPrint('🔍 DEBUG: Using cached lessons for grade: $grade');
          return cachedLessons;
        }
      } catch (e) {
        debugPrint('❌ WARNING: Failed to get cached lessons, fetching from Firestore: $e');
      }
      
      // Fetch from Firestore if cache is empty or invalid
      final metaDoc = _firestore.collection('lessonsMeta').doc(grade);
      final snapshot = await metaDoc.get();
      
      if (snapshot.exists && snapshot.data()?['lessons'] != null) {
        final lessons = List<Map<String, dynamic>>.from(snapshot.data()!['lessons']);
        
        // Filter out any invalid lesson entries
        final validLessons = lessons.where((lesson) {
          return lesson['id'] != null &&
                 lesson['title'] != null &&
                 lesson['subject'] != null;
        }).toList();
        
        debugPrint('🔍 DEBUG: Found ${validLessons.length} valid lessons for grade: $grade');
        
        // Cache the lessons for offline access
        await _cacheLessons(grade, validLessons);
        
        return validLessons;
      }
      
      debugPrint('🔍 DEBUG: No lessons found for grade: $grade');
      return [];
    } catch (e) {
      debugPrint('❌ ERROR: Failed to fetch lessons for grade $grade: $e');
      return [];
    }
  }
  
  /// Get lesson content by grade and lesson ID
  Future<Map<String, dynamic>?> getLessonContent(String grade, String lessonId) async {
    try {
      debugPrint('🔍 DEBUG: Fetching lesson content for: $lessonId in grade: $grade');
      
      // Validate inputs
      if (grade.isEmpty || lessonId.isEmpty) {
        debugPrint('❌ ERROR: Grade or lessonId cannot be empty');
        return null;
      }
      
      // Fetch lesson content directly from lessons collection
      final lessonDoc = _firestore.collection('lessons').doc(lessonId);
      final snapshot = await lessonDoc.get();
      
      if (snapshot.exists) {
        final lessonData = snapshot.data()!;
        
        // Verify the lesson belongs to the requested grade (handle both "5" and "grade5" formats)
        final lessonGrade = lessonData['grade']?.toString();
        if (lessonGrade == grade || lessonGrade == 'grade$grade') {
          debugPrint('🔍 DEBUG: Successfully fetched lesson content for: $lessonId');
          return lessonData;
        } else {
          debugPrint('❌ WARNING: Lesson $lessonId does not belong to grade $grade (lesson grade: $lessonGrade)');
          return null;
        }
      }
      
      debugPrint('🔍 DEBUG: Lesson content not found for: $lessonId');
      return null;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to fetch lesson content for $lessonId: $e');
      return null;
    }
  }
  
  /// Cache lessons for offline access with improved error handling
  Future<void> _cacheLessons(String grade, List<Map<String, dynamic>> lessons) async {
    try {
      // Validate inputs
      if (grade.isEmpty || lessons.isEmpty) {
        debugPrint('❌ WARNING: Cannot cache lessons with empty grade or empty lessons list');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'lessons_meta_$grade';
      final timestampKey = '${cacheKey}_timestamp';
      
      // Use try-catch for each SharedPreferences operation
      try {
        await prefs.setString(cacheKey, jsonEncode(lessons));
        await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
        debugPrint('🔍 DEBUG: Successfully cached ${lessons.length} lessons for grade: $grade');
      } on Exception catch (e) {
        debugPrint('❌ WARNING: SharedPreferences operation failed for grade $grade: $e');
        // Don't throw - continue without caching
      }
    } catch (e) {
      debugPrint('❌ WARNING: Failed to cache lessons for grade $grade: $e');
    }
  }
  
  /// Get cached lessons with improved error handling
  Future<List<Map<String, dynamic>>> _getCachedLessons(String grade) async {
    try {
      // Validate input
      if (grade.isEmpty) {
        debugPrint('❌ WARNING: Cannot get cached lessons with empty grade');
        return [];
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'lessons_meta_$grade';
      final timestampKey = '${cacheKey}_timestamp';
      
      try {
        final cachedData = prefs.getString(cacheKey);
        final cachedTimestamp = prefs.getInt(timestampKey) ?? 0;
        
        // Check if cache is still valid (24 hours)
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        if (cachedData != null && cacheAge < 24 * 60 * 60 * 1000) {
          final decodedLessons = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
          debugPrint('🔍 DEBUG: Retrieved ${decodedLessons.length} cached lessons for grade: $grade');
          return decodedLessons;
        }
        
        debugPrint('🔍 DEBUG: No valid cache found for grade: $grade');
        return [];
      } on Exception catch (e) {
        debugPrint('❌ WARNING: SharedPreferences operation failed for grade $grade: $e');
        return [];
      }
    } catch (e) {
      debugPrint('❌ WARNING: Failed to get cached lessons for grade $grade: $e');
      return [];
    }
  }
  
  /// Get quizzes for a specific grade from Firestore
  Future<List<Map<String, dynamic>>> getQuizzesForGrade(String grade) async {
    try {
      debugPrint('🔍 DEBUG: Fetching quizzes for grade: $grade');
      
      // Validate grade input
      if (grade.isEmpty) {
        debugPrint('❌ ERROR: Grade cannot be empty');
        return [];
      }
      
      // Try to get cached quizzes first
      try {
        final cachedQuizzes = await _getCachedQuizzes(grade);
        if (cachedQuizzes.isNotEmpty) {
          debugPrint('🔍 DEBUG: Using cached quizzes for grade: $grade');
          return cachedQuizzes;
        }
      } catch (e) {
        debugPrint('❌ WARNING: Failed to get cached quizzes, fetching from Firestore: $e');
      }
      
      // Fetch from Firestore if cache is empty or invalid
      final metaDoc = _firestore.collection('quizMeta').doc(grade);
      final snapshot = await metaDoc.get();
      
      if (snapshot.exists && snapshot.data()?['quizzes'] != null) {
        final quizzes = List<Map<String, dynamic>>.from(snapshot.data()!['quizzes']);
        
        // Filter out any invalid quiz entries
        final validQuizzes = quizzes.where((quiz) {
          return quiz['id'] != null &&
                 quiz['title'] != null &&
                 quiz['subject'] != null;
        }).toList();
        
        debugPrint('🔍 DEBUG: Found ${validQuizzes.length} valid quizzes for grade: $grade');
        
        // Cache the quizzes for offline access
        await _cacheQuizzes(grade, validQuizzes);
        
        return validQuizzes;
      }
      
      debugPrint('🔍 DEBUG: No quizzes found for grade: $grade');
      return [];
    } catch (e) {
      debugPrint('❌ ERROR: Failed to fetch quizzes for grade $grade: $e');
      return [];
    }
  }
  
  /// Get quiz content by grade and quiz ID
  Future<Map<String, dynamic>?> getQuizContent(String grade, String quizId) async {
    try {
      debugPrint('🔍 DEBUG: Fetching quiz content for: $quizId in grade: $grade');
      
      // Validate inputs
      if (grade.isEmpty || quizId.isEmpty) {
        debugPrint('❌ ERROR: Grade or quizId cannot be empty');
        return null;
      }
      
      // Fetch quiz content directly from quizzes collection
      final quizDoc = _firestore.collection('quizzes').doc(quizId);
      final snapshot = await quizDoc.get();
      
      if (snapshot.exists) {
        final quizData = snapshot.data()!;
        
        // Verify the quiz belongs to the requested grade
        if (quizData['grade']?.toString() == grade) {
          debugPrint('🔍 DEBUG: Successfully fetched quiz content for: $quizId');
          return quizData;
        } else {
          debugPrint('❌ WARNING: Quiz $quizId does not belong to grade $grade');
          return null;
        }
      }
      
      debugPrint('🔍 DEBUG: Quiz content not found for: $quizId');
      return null;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to fetch quiz content for $quizId: $e');
      return null;
    }
  }
  
  
  /// Cache quizzes for offline access with improved error handling
  Future<void> _cacheQuizzes(String grade, List<Map<String, dynamic>> quizzes) async {
    try {
      // Validate inputs
      if (grade.isEmpty || quizzes.isEmpty) {
        debugPrint('❌ WARNING: Cannot cache quizzes with empty grade or empty quizzes list');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'quizzes_meta_$grade';
      final timestampKey = '${cacheKey}_timestamp';
      
      // Use try-catch for each SharedPreferences operation
      try {
        await prefs.setString(cacheKey, jsonEncode(quizzes));
        await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
        debugPrint('🔍 DEBUG: Successfully cached ${quizzes.length} quizzes for grade: $grade');
      } on Exception catch (e) {
        debugPrint('❌ WARNING: SharedPreferences operation failed for grade $grade: $e');
        // Don't throw - continue without caching
      }
    } catch (e) {
      debugPrint('❌ WARNING: Failed to cache quizzes for grade $grade: $e');
    }
  }
  
  /// Get cached quizzes with improved error handling
  Future<List<Map<String, dynamic>>> _getCachedQuizzes(String grade) async {
    try {
      // Validate input
      if (grade.isEmpty) {
        debugPrint('❌ WARNING: Cannot get cached quizzes with empty grade');
        return [];
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'quizzes_meta_$grade';
      final timestampKey = '${cacheKey}_timestamp';
      
      try {
        final cachedData = prefs.getString(cacheKey);
        final cachedTimestamp = prefs.getInt(timestampKey) ?? 0;
        
        // Check if cache is still valid (24 hours)
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        if (cachedData != null && cacheAge < 24 * 60 * 60 * 1000) {
          final decodedQuizzes = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
          debugPrint('🔍 DEBUG: Retrieved ${decodedQuizzes.length} cached quizzes for grade: $grade');
          return decodedQuizzes;
        }
        
        debugPrint('🔍 DEBUG: No valid cache found for grade: $grade');
        return [];
      } on Exception catch (e) {
        debugPrint('❌ WARNING: SharedPreferences operation failed for grade $grade: $e');
        return [];
      }
    } catch (e) {
      debugPrint('❌ WARNING: Failed to get cached quizzes for grade $grade: $e');
      return [];
    }
  }
  
  /// Clear cache for a specific grade with improved error handling
  Future<void> clearCacheForGrade(String grade) async {
    try {
      // Validate input
      if (grade.isEmpty) {
        debugPrint('❌ WARNING: Cannot clear cache with empty grade');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final lessonsCacheKey = 'lessons_meta_$grade';
      final quizzesCacheKey = 'quizzes_meta_$grade';
      final lessonsTimestampKey = '${lessonsCacheKey}_timestamp';
      final quizzesTimestampKey = '${quizzesCacheKey}_timestamp';
      
      // Use try-catch for each SharedPreferences operation
      try {
        await prefs.remove(lessonsCacheKey);
        await prefs.remove(quizzesCacheKey);
        await prefs.remove(lessonsTimestampKey);
        await prefs.remove(quizzesTimestampKey);
        
        debugPrint('🔍 DEBUG: Successfully cleared cache for grade: $grade');
      } on Exception catch (e) {
        debugPrint('❌ WARNING: SharedPreferences operation failed for grade $grade: $e');
        // Don't throw - continue without clearing cache
      }
    } catch (e) {
      debugPrint('❌ WARNING: Failed to clear cache for grade $grade: $e');
    }
  }
  
  /// Listen to real-time updates for lessons
  Stream<List<Map<String, dynamic>>> listenToLessons(String grade) {
    return _firestore
        .collection('lessonsMeta')
        .doc(grade)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data()?['lessons'] != null) {
            return List<Map<String, dynamic>>.from(snapshot.data()!['lessons']);
          }
          return [];
        });
  }
  
  /// Listen to real-time updates for quizzes
  Stream<List<Map<String, dynamic>>> listenToQuizzes(String grade) {
    return _firestore
        .collection('quizMeta')
        .doc(grade)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data()?['quizzes'] != null) {
            return List<Map<String, dynamic>>.from(snapshot.data()!['quizzes']);
          }
          return [];
        });
  }
}