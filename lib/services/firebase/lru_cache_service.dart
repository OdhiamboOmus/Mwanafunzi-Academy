import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quiz_model.dart';

/// LRU Cache service for quiz questions with size-based eviction
/// Implements least recently used eviction to prevent excessive storage usage
class LRUCacheService {
  static const String _cachePrefix = 'quiz_lru_';
  static const String _timestampPrefix = 'quiz_lru_ts_';
  static const String _sizePrefix = 'quiz_lru_sz_';
  static const int _maxCacheSizeMB = 10; // 10MB max cache size
  static const int _maxCacheItems = 200; // Maximum number of cached items
  static const int _cacheTTLSeconds = 30 * 24 * 60 * 60; // 30 days TTL
  
  /// Get cached quiz questions with LRU eviction
  Future<List<QuizQuestion>?> getCachedQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final cacheKey = '$_cachePrefix${grade}_${subject}_$topic';
    final timestampKey = '$_timestampPrefix$cacheKey';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      final cacheTimestamp = prefs.getInt(timestampKey) ?? 0;
      
      // Check TTL
      if (cachedJson != null && _isCacheValid(cacheTimestamp)) {
        // Update access timestamp for LRU tracking
        await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);
        
        // Record access for LRU tracking
        _recordAccess(cacheKey);
        
        return _parseQuizQuestions(cachedJson);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error reading cached quiz questions: $e');
      return null;
    }
  }
  
  /// Cache quiz questions with LRU eviction
  Future<bool> cacheQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    final cacheKey = '$_cachePrefix${grade}_${subject}_$topic';
    final timestampKey = '$_timestampPrefix$cacheKey';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = jsonEncode(questions.map((q) => q.toJson()).toList());
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final sizeBytes = questionsJson.length;
      
      // Check if we need to evict items before adding new ones
      await _ensureCacheSpace(sizeBytes);
      
      // Store the cache
      await prefs.setString(cacheKey, questionsJson);
      await prefs.setInt(timestampKey, now);
      await prefs.setInt('$_sizePrefix$cacheKey', sizeBytes);
      
      // Record access for LRU tracking
      _recordAccess(cacheKey);
      
      return true;
    } catch (e) {
      debugPrint('Error caching quiz questions: $e');
      return false;
    }
  }
  
  /// Check if cache is valid based on TTL
  bool _isCacheValid(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - timestamp) < _cacheTTLSeconds;
  }
  
  /// Parse quiz questions from JSON
  List<QuizQuestion> _parseQuizQuestions(String json) {
    final List<dynamic> jsonList = jsonDecode(json);
    return jsonList.map((json) => QuizQuestion.fromJson(json)).toList();
  }
  
  /// Record access for LRU tracking
  void _recordAccess(String cacheKey) {
    // Simple access tracking - in production, you might want to use a more sophisticated approach
    // For now, we'll just update the timestamp which serves as LRU marker
  }
  
  /// Ensure cache space is available before adding new items
  Future<void> _ensureCacheSpace(int newSizeBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_cachePrefix)).toList();
      
      // Calculate current total size
      int totalSize = 0;
      final List<Map<String, dynamic>> cacheInfo = [];
      
      for (final key in cacheKeys) {
        final timestamp = prefs.getInt('$_timestampPrefix$key') ?? 0;
        final size = prefs.getInt('$_sizePrefix$key') ?? 0;
        
        if (timestamp > 0 && size > 0) {
          totalSize += size;
          cacheInfo.add({
            'key': key,
            'timestamp': timestamp,
            'size': size,
          });
        }
      }
      
      // Sort by timestamp (oldest first) for LRU eviction
      cacheInfo.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      
      // Evict items if we're over limits
      while ((totalSize + newSizeBytes > _maxCacheSizeMB * 1024 * 1024 || 
              cacheInfo.length >= _maxCacheItems) && 
              cacheInfo.isNotEmpty) {
        final itemToRemove = cacheInfo.removeAt(0);
        final key = itemToRemove['key'];
        
        // Remove cache entry
        await prefs.remove(key);
        await prefs.remove('$_timestampPrefix$key');
        await prefs.remove('$_sizePrefix$key');
        
        totalSize -= (itemToRemove['size'] as int);
      }
      
    } catch (e) {
      debugPrint('Error ensuring cache space: $e');
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_cachePrefix)).toList();
      
      int totalSize = 0;
      int itemCount = 0;
      int validItems = 0;
      
      for (final key in cacheKeys) {
        final timestamp = prefs.getInt('$_timestampPrefix$key') ?? 0;
        final size = prefs.getInt('$_sizePrefix$key') ?? 0;
        
        if (timestamp > 0 && size > 0) {
          totalSize += size;
          itemCount++;
          
          if (_isCacheValid(timestamp)) {
            validItems++;
          }
        }
      }
      
      return {
        'totalItems': itemCount,
        'validItems': validItems,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'maxCacheSizeMB': _maxCacheSizeMB,
        'maxCacheItems': _maxCacheItems,
        'cacheUtilization': ((totalSize / (_maxCacheSizeMB * 1024 * 1024)) * 100).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }
  
  /// Clear cache for specific quiz topic
  Future<void> clearTopicCache({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final cacheKey = '$_cachePrefix${grade}_${subject}_$topic';
    final timestampKey = '$_timestampPrefix$cacheKey';
    final sizeKey = '$_sizePrefix$cacheKey';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      await prefs.remove(sizeKey);
    } catch (e) {
      debugPrint('Error clearing topic cache: $e');
    }
  }
  
  /// Clear all quiz caches
  Future<void> clearAllQuizCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith(_cachePrefix) || 
            key.startsWith(_timestampPrefix) || 
            key.startsWith(_sizePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing all quiz caches: $e');
    }
  }
  
  /// Force cache cleanup (evict expired items)
  Future<int> forceCacheCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_cachePrefix)).toList();
      
      int cleanedCount = 0;
      
      for (final key in cacheKeys) {
        final timestamp = prefs.getInt('$_timestampPrefix$key') ?? 0;
        
        // Remove expired items
        if (timestamp > 0 && !_isCacheValid(timestamp)) {
          await prefs.remove(key);
          await prefs.remove('$_timestampPrefix$key');
          await prefs.remove('$_sizePrefix$key');
          cleanedCount++;
        }
      }
      
      return cleanedCount;
    } catch (e) {
      debugPrint('Error forcing cache cleanup: $e');
      return 0;
    }
  }
}