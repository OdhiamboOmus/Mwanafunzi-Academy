import 'dart:convert';
import 'package:flutter/material.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quiz_model.dart';

/// Service for aggressive caching with 30-day TTL to minimize Firebase costs
class CostOptimizedCacheService {
  static const String _cachePrefix = 'quiz_cache_';
  static const String _metadataPrefix = 'quiz_meta_';
  static const String _timestampPrefix = 'quiz_timestamp_';
  static const int _cacheTTLSeconds = 30 * 24 * 60 * 60; // 30 days
  static const int _metadataTTLSeconds = 365 * 24 * 60 * 60; // 1 year (indefinite until admin updates)
  
  /// Cache hit rate tracking
  static const String _hitCountKey = 'cache_hits';
  static const String _missCountKey = 'cache_misses';
  
  /// Get cached quiz questions with 30-day TTL
  Future<List<QuizQuestion>?> getCachedQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final cacheKey = '$_cachePrefix${grade}_${subject}_$topic';
    final timestampKey = '$_timestampPrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      final cacheTimestamp = prefs.getInt(timestampKey) ?? 0;
      
      if (cachedJson != null && _isCacheValid(cacheTimestamp, _cacheTTLSeconds)) {
        _recordCacheHit();
        return _parseQuizQuestions(cachedJson);
      }
    } catch (e) {
      debugPrint('Error reading cached quiz questions: $e');
    }
    
    _recordCacheMiss();
    return null;
  }
  
  /// Cache quiz questions with 30-day TTL
  Future<void> cacheQuizQuestions({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    final cacheKey = '$_cachePrefix${grade}_${subject}_$topic';
    final timestampKey = '$_timestampPrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = jsonEncode(questions.map((q) => q.toJson()).toList());
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await prefs.setString(cacheKey, questionsJson);
      await prefs.setInt(timestampKey, now);
    } catch (e) {
     debugPrint('Error caching quiz questions: $e');
    }
  }
  
  /// Get cached quiz metadata with indefinite TTL until admin updates
  Future<Map<String, dynamic>?> getCachedQuizMetadata({
    required String grade,
    required String subject,
  }) async {
    final metadataKey = '$_metadataPrefix${grade}_$subject';
    final timestampKey = '${_timestampPrefix}meta_${grade}_$subject';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(metadataKey);
      final cacheTimestamp = prefs.getInt(timestampKey) ?? 0;
      
      if (cachedJson != null && _isCacheValid(cacheTimestamp, _metadataTTLSeconds)) {
        _recordCacheHit();
        return jsonDecode(cachedJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached quiz metadata: $e');
    }
    
    _recordCacheMiss();
    return null;
  }
  
  /// Cache quiz metadata with indefinite TTL
  Future<void> cacheQuizMetadata({
    required String grade,
    required String subject,
    required Map<String, dynamic> metadata,
  }) async {
    final metadataKey = '$_metadataPrefix${grade}_$subject';
    final timestampKey = '${_timestampPrefix}meta_${grade}_$subject';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = jsonEncode(metadata);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await prefs.setString(metadataKey, metadataJson);
      await prefs.setInt(timestampKey, now);
    } catch (e) {
      debugPrint('Error caching quiz metadata: $e');
    }
  }
  
  /// Check if cache is valid based on TTL
  bool _isCacheValid(int timestamp, int ttlSeconds) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - timestamp) < ttlSeconds;
  }
  
  /// Parse quiz questions from JSON
  List<QuizQuestion> _parseQuizQuestions(String json) {
    final List<dynamic> jsonList = jsonDecode(json);
    return jsonList.map((json) => QuizQuestion.fromJson(json)).toList();
  }
  
  /// Record cache hit for hit rate monitoring
  void _recordCacheHit() {
    _recordCacheEvent(_hitCountKey);
  }
  
  /// Record cache miss for hit rate monitoring
  void _recordCacheMiss() {
    _recordCacheEvent(_missCountKey);
  }
  
  /// Record cache event
  void _recordCacheEvent(String key) {
    // Simple implementation - in production, you might want to use a more sophisticated approach
    debugPrint('Cache event: $key');
  }
  
  /// Get cache hit rate
  double getCacheHitRate() {
    // This is a simplified implementation
    // In production, you would track actual hit/miss counts
    return 0.0; // Placeholder - implement actual tracking
  }
  
  /// Clear cache for specific quiz topic (when admin updates occur)
  Future<void> clearTopicCache({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final cacheKey = '$_cachePrefix${grade}_${subject}_$topic';
    final timestampKey = '$_timestampPrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
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
            key.startsWith(_metadataPrefix) || 
            key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing all quiz caches: $e');
    }
  }
  
  /// Get last sync timestamp for incremental sync
  Future<int?> getLastSyncTimestamp({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final timestampKey = '${_timestampPrefix}sync_${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(timestampKey);
    } catch (e) {
      debugPrint('Error reading sync timestamp: $e');
      return null;
    }
  }
  
  /// Update last sync timestamp
  Future<void> updateLastSyncTimestamp({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final timestampKey = '${_timestampPrefix}sync_${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(timestampKey, now);
    } catch (e) {
      debugPrint('Error updating sync timestamp: $e');
    }
  }
}