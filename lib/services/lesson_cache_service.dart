import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/services/storage_service.dart';

/// Service for lesson cache management operations
class LessonCacheService {
  final StorageService _storageService;
  
  static const String _cacheKeyPrefix = 'lesson_content_';
  static const String _lessonsDir = 'mwanafunzi/lessons';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxCachedLessons = 20; // LRU cache size

  LessonCacheService({required StorageService storageService})
      : _storageService = storageService;

  /// Clear old cache with LRU eviction
  Future<void> clearOldCache() async {
    try {
      // Clear SharedPreferences cache
      final cacheInfo = await _getCacheInfo();
      
      if ((cacheInfo['totalSize'] as int? ?? 0) > _maxCacheSize) {
        // Sort by last accessed time and remove oldest
        final sortedCache = List<Map<String, dynamic>>.from((cacheInfo['entries'] as List?) ?? [])
          ..sort((a, b) => (a['lastAccessed'] as int).compareTo(b['lastAccessed'] as int));
        
        int spaceFreed = 0;
        final targetSize = _maxCacheSize ~/ 2; // Clear down to 50% of max
        
        for (final entry in sortedCache) {
          if ((cacheInfo['totalSize'] as int? ?? 0) - spaceFreed <= targetSize) break;
          
          final lessonId = entry['lessonId'] as String;
          final size = entry['size'] as int;
          
          await _removeCachedLessonContent(lessonId);
          spaceFreed += size;
        }
      }

      // Clear local storage files
      await _cleanupOldLessonFiles();
      
    } catch (e) {
      debugPrint('❌ LessonCacheService error in clearOldCache: $e');
    }
  }

  /// Verify cache integrity and handle corruption
  Future<bool> verifyCacheIntegrity(String lessonId) async {
    try {
      // Check if lesson exists in local storage
      if (await _isLessonInLocalStorage(lessonId)) {
        try {
          final lessonFile = await _getLessonFile(lessonId);
          final content = await lessonFile.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          
          // Verify basic structure
          if (json['lessonId'] != null && json['sections'] != null) {
            // Additional validation: check sections structure
            final sections = json['sections'] as List?;
            if (sections != null && sections.isNotEmpty) {
              return true;
            }
          }
        } catch (e) {
          debugPrint('❌ Cache integrity check failed for local file: $lessonId, error: $e');
          // File is corrupted, remove it
          await _removeCorruptedLessonFile(lessonId);
          return false;
        }
      }

      // Check SharedPreferences cache
      try {
        final cached = await _storageService.getCachedData<Map<String, dynamic>>(
          key: '$_cacheKeyPrefix$lessonId',
          fromJson: (json) => json,
          ttlSeconds: null,
        );
        
        if (cached != null) {
          // Additional validation for cached content
          if (cached['lessonId']?.isNotEmpty == true && (cached['sections'] as List?)?.isNotEmpty == true) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('❌ Cache integrity check failed for SharedPreferences: $lessonId, error: $e');
        // Remove corrupted cache
        await _storageService.removeCachedData('$_cacheKeyPrefix$lessonId');
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Cache integrity verification error: $e');
      return false;
    }
  }

  /// Verify lesson version and update if needed
  Future<bool> verifyLessonVersion(String lessonId, String expectedVersion) async {
    try {
      final currentVersion = await _getLessonVersion(lessonId);
      
      if (currentVersion != expectedVersion) {
        debugPrint('🔄 Version mismatch for lesson $lessonId: current=$currentVersion, expected=$expectedVersion');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying lesson version: $e');
      return false;
    }
  }

  /// Get lesson version
  Future<String> _getLessonVersion(String lessonId) async {
    try {
      final versions = await _getLessonVersions();
      return versions[lessonId] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get all lesson versions
  Future<Map<String, String>> _getLessonVersions() async {
    try {
      final cached = await _storageService.getCachedData<Map<String, String>>(
        key: 'lesson_versions',
        fromJson: (json) => Map<String, String>.from(json),
        ttlSeconds: null,
      );
      
      return cached ?? {};
    } catch (e) {
      return {};
    }
  }


  /// Remove corrupted lesson file
  Future<void> _removeCorruptedLessonFile(String lessonId) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final lessonFile = File('${appDocDir.path}/$_lessonsDir/$lessonId.json');
      
      if (await lessonFile.exists()) {
        await lessonFile.delete();
        debugPrint('🗑️ Removed corrupted lesson file: $lessonId');
      }
    } catch (e) {
      debugPrint('❌ Error removing corrupted lesson file: $e');
    }
  }

  /// Get total cache size (local + SharedPreferences)
  Future<int> getTotalCacheSize() async {
    try {
      int totalSize = 0;
      
      // Add local storage size
      final appDocDir = await getApplicationDocumentsDirectory();
      final lessonsDir = Directory('${appDocDir.path}/$_lessonsDir');
      
      if (await lessonsDir.exists()) {
        final files = await lessonsDir.list().where((entity) =>
          entity is File && entity.path.endsWith('.json')).cast<File>().toList();
        
        for (final file in files) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      // Add SharedPreferences cache size
      final cacheInfo = await _getCacheInfo();
      totalSize += (cacheInfo['totalSize'] as int? ?? 0);
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Error getting total cache size: $e');
      return 0;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final localFiles = await _getLocalLessonFiles();
      final cacheInfo = await _getCacheInfo();
      
      return {
        'totalSize': await getTotalCacheSize(),
        'localFileCount': localFiles.length,
        'cachedLessonsCount': (cacheInfo['entries'] as List?)?.length ?? 0,
        'maxCacheSize': _maxCacheSize,
        'maxCachedLessons': _maxCachedLessons,
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {};
    }
  }

  /// Get local lesson files
  Future<List<Map<String, dynamic>>> _getLocalLessonFiles() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final lessonsDir = Directory('${appDocDir.path}/$_lessonsDir');
      
      if (!await lessonsDir.exists()) {
        return [];
      }

      final files = await lessonsDir.list().where((entity) =>
        entity is File && entity.path.endsWith('.json')).cast<File>().toList();
      
      return await Future.wait(files.map((file) async {
        final stat = await file.stat();
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        
        return {
          'path': file.path,
          'size': stat.size,
          'lastModified': stat.modified.millisecondsSinceEpoch,
          'lessonId': json['lessonId'] ?? 'unknown',
          'title': json['title'] ?? 'Unknown Lesson',
        };
      }));
    } catch (e) {
      debugPrint('❌ Error getting local lesson files: $e');
      return [];
    }
  }

  /// Remove cached lesson content
  Future<void> _removeCachedLessonContent(String lessonId) async {
    try {
      await _storageService.removeCachedData('$_cacheKeyPrefix$lessonId');
      await _removeFromCacheInfo(lessonId);
    } catch (e) {
      debugPrint('❌ Remove cached lesson content error: $e');
    }
  }


  /// Remove from cache info
  Future<void> _removeFromCacheInfo(String lessonId) async {
    try {
      final cacheInfo = await _getCacheInfo();
      
      final entry = (cacheInfo['entries'] as List)
          .firstWhere((e) => e['lessonId'] == lessonId, orElse: () => null);
      
      if (entry != null) {
        (cacheInfo['entries'] as List).remove(entry);
        cacheInfo['totalSize'] = (cacheInfo['totalSize'] as int) - (entry['size'] as int);
        
        await _storageService.setCachedData(
          key: 'lesson_cache_info',
          data: cacheInfo,
          toJson: (info) => info,
        );
      }
    } catch (e) {
      debugPrint('❌ Remove from cache info error: $e');
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
      final lessonFile = File('${appDocDir.path}/$_lessonsDir/$lessonId.json');
      
      if (!await lessonFile.exists()) {
        throw Exception('Lesson file not found: $lessonId');
      }
      
      return lessonFile;
    } catch (e) {
      debugPrint('❌ Error getting lesson file: $e');
      rethrow;
    }
  }

  /// Clean up old lesson files
  Future<void> _cleanupOldLessonFiles() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final lessonsDir = Directory('${appDocDir.path}/$_lessonsDir');
      
      if (!await lessonsDir.exists()) {
        return;
      }

      final files = await lessonsDir.list().where((entity) =>
        entity is File && entity.path.endsWith('.json')).cast<File>().toList();
      
      if (files.length > _maxCachedLessons) {
        // Sort by last modified time and remove oldest
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        final filesToRemove = files.sublist(0, files.length - _maxCachedLessons);
        for (final file in filesToRemove) {
          await file.delete();
          debugPrint('🗑️ Removed old lesson file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up lesson files: $e');
    }
  }
}