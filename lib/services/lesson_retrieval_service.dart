import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/services/storage_service.dart';
import '../data/models/lesson_model.dart';
import '../services/firebase/firestore_service.dart';

/// Service for core lesson retrieval operations
class LessonRetrievalService {
  final StorageService _storageService;
  
  static const String _lessonsMetaPrefix = 'lessons_meta_';
  static const String _lessonVersionsKey = 'lesson_versions';
  static const String _cacheKeyPrefix = 'lesson_content_';

  final FirestoreService _firestoreService;
  
  LessonRetrievalService({
    required StorageService storageService,
    required FirestoreService firestoreService,
  }) : _storageService = storageService,
       _firestoreService = firestoreService;

  /// Get lessons metadata for a grade with single Firestore query
  Future<List<LessonMeta>> getLessonsForGrade(String grade) async {
    try {
      // Try to get from cache first
      final cachedLessons = await _getCachedLessonsMeta(grade);
      if (cachedLessons != null) {
        return cachedLessons;
      }

      // Get lessons from Firestore
      final querySnapshot = await _firestoreService.getLessonsForGrade(grade);
      
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Parse lessons from Firestore data
      final lessons = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return LessonMeta(
          id: doc.id,
          title: data['title'] ?? '',
          subject: data['subject'] ?? '',
          grade: data['grade'] ?? grade,
          version: data['version'] ?? '1.0.0',
          sizeBytes: data['sizeBytes'] ?? 0,
          contentPath: data['contentPath'] ?? '',
          mediaCount: data['mediaCount'] ?? 0,
          totalSections: data['totalSections'] ?? 0,
          hasQuestions: data['hasQuestions'] ?? false,
          lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Cache indefinitely with version-based validation
      await _cacheLessonsMeta(grade, lessons);
      
      return lessons;
    } catch (e) {
      debugPrint('❌ LessonRetrievalService error in getLessonsForGrade: $e');
      return [];
    }
  }

  /// Get lesson content with automatic download and caching
  Future<LessonContent> getLessonContent(String lessonId) async {
    try {
      // First check if lesson exists in local storage
      if (await _isLessonInLocalStorage(lessonId)) {
        return await _loadLessonFromFile(lessonId);
      }

      // Check if lesson is cached in SharedPreferences
      if (await _isLessonCached(lessonId)) {
        return await _getCachedLessonContent(lessonId);
      }

      // Download lesson content with automatic background download
      // This would be handled by the download service
      await _downloadLessonContentWithProgress(lessonId, null);
      
      // Try to load from local storage first (faster)
      if (await _isLessonInLocalStorage(lessonId)) {
        return await _loadLessonFromFile(lessonId);
      }
      
      // Fallback to SharedPreferences cache
      return await _getCachedLessonContent(lessonId);
    } catch (e) {
      debugPrint('❌ LessonRetrievalService error in getLessonContent: $e');
      throw Exception('Failed to get lesson content. Please check your connection and try again.');
    }
  }

  /// Get cached lessons metadata
  Future<List<LessonMeta>?> _getCachedLessonsMeta(String grade) async {
    try {
      final cached = await _storageService.getCachedData<List<LessonMeta>>(
        key: '$_lessonsMetaPrefix$grade',
        fromJson: (json) {
          final lessons = json['lessons'] as List?;
          return lessons?.map((lesson) => LessonMeta.fromJson(lesson)).toList() ?? [];
        },
        // No TTL for indefinite caching
      );
      
      return cached;
    } catch (e) {
      debugPrint('❌ Get cached lessons meta error: $e');
      return null;
    }
  }

  /// Cache lessons metadata
  Future<void> _cacheLessonsMeta(String grade, List<LessonMeta> lessons) async {
    try {
      await _storageService.setCachedData(
        key: '$_lessonsMetaPrefix$grade',
        data: lessons,
        toJson: (lessons) => {
          'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ Cache lessons meta error: $e');
    }
  }

  /// Check if lesson is cached
  Future<bool> _isLessonCached(String lessonId) async {
    try {
      final cacheInfo = await _getCacheInfo();
      return (cacheInfo['entries'] as List?)?.any((entry) => (entry as Map)['lessonId'] == lessonId) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get cached lesson content
  Future<LessonContent> _getCachedLessonContent(String lessonId) async {
    try {
      final cached = await _storageService.getCachedData<LessonContent>(
        key: '$_cacheKeyPrefix$lessonId',
        fromJson: (json) => LessonContent.fromJson(json),
        ttlSeconds: null, // No TTL, use version validation
      );

      if (cached != null) {
        // Update last accessed time
        await _updateLessonAccessTime(lessonId);
        return cached;
      }

      throw Exception('Lesson content not cached');
    } catch (e) {
      debugPrint('❌ Get cached lesson content error: $e');
      rethrow;
    }
  }



  /// Update lesson access time
  Future<void> _updateLessonAccessTime(String lessonId) async {
    try {
      final cacheInfo = await _getCacheInfo();
      final entries = (cacheInfo['entries'] as List?) ?? [];
      final entryIndex = entries.indexWhere((e) => (e as Map)['lessonId'] == lessonId);
      
      Map<String, dynamic> entry;
      if (entryIndex != -1) {
        entry = entries[entryIndex] as Map<String, dynamic>;
      } else {
        entry = {'lessonId': lessonId, 'lastAccessed': 0, 'size': 0};
        entries.add(entry);
      }
      
      entry['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
      cacheInfo['entries'] = entries;
      
      await _storageService.setCachedData(
        key: 'lesson_cache_info',
        data: cacheInfo,
        toJson: (info) => info,
      );
    } catch (e) {
      debugPrint('❌ Update lesson access time error: $e');
    }
  }

  /// Get cache information
  Future<Map<String, dynamic>> _getCacheInfo() async {
    try {
      final cached = await _storageService.getCachedData<Map<String, dynamic>>(
        key: 'lesson_cache_info',
        fromJson: (json) => json,
        ttlSeconds: null,
      );
      
      if (cached == null) {
        return {
          'entries': [],
          'totalSize': 0,
        };
      }
      
      return cached;
    } catch (e) {
      return {
        'entries': [],
        'totalSize': 0,
      };
    }
  }

  /// Check if lesson exists in local storage
  Future<bool> _isLessonInLocalStorage(String lessonId) async {
    try {
      final lessonFile = await _getLessonFile(lessonId);
      return await lessonFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get lesson file from local storage
  Future<File> _getLessonFile(String lessonId) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final lessonFile = File('${appDocDir.path}/mwanafunzi/lessons/$lessonId.json');
      
      if (!await lessonFile.exists()) {
        throw Exception('Lesson file not found: $lessonId');
      }
      
      return lessonFile;
    } catch (e) {
      debugPrint('❌ Error getting lesson file: $e');
      rethrow;
    }
  }

  /// Load lesson content from local file
  Future<LessonContent> _loadLessonFromFile(String lessonId) async {
    try {
      final lessonFile = await _getLessonFile(lessonId);
      final content = await lessonFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return LessonContent.fromJson(json);
    } catch (e) {
      debugPrint('❌ Error loading lesson from file: $e');
      throw Exception('Failed to load lesson content from storage');
    }
  }

  /// Download lesson content with progress tracking (placeholder)
  Future<void> _downloadLessonContentWithProgress(String lessonId, Function(double progress)? onProgress) async {
    // This will be implemented in the download service
    throw UnimplementedError('Download service not implemented');
  }
}