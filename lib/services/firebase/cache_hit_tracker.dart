import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple cache hit rate tracker for performance monitoring
class CacheHitTracker {
  static const String _cacheHitKey = 'cache_hits';
  static const String _cacheMissKey = 'cache_misses';
  
  /// Record cache hit
  static Future<void> recordHit() async {
    await _incrementCounter(_cacheHitKey);
  }
  
  /// Record cache miss
  static Future<void> recordMiss() async {
    await _incrementCounter(_cacheMissKey);
  }
  
  /// Increment counter in SharedPreferences
  static Future<void> _incrementCounter(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, currentCount + 1);
    } catch (e) {
      debugPrint('Error incrementing counter: $e');
    }
  }
  
  /// Get cache hit rate
  static Future<double> getHitRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hits = prefs.getInt(_cacheHitKey) ?? 0;
      final misses = prefs.getInt(_cacheMissKey) ?? 0;
      final total = hits + misses;
      
      if (total == 0) return 0.0;
      return hits / total;
    } catch (e) {
      debugPrint('Error calculating cache hit rate: $e');
      return 0.0;
    }
  }
  
  /// Validate cache hit rate meets target (>90%)
  static Future<bool> validateHitRate() async {
    final hitRate = await getHitRate();
    return hitRate >= 0.90; // 90% target
  }
  
  /// Reset all counters
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheHitKey);
      await prefs.remove(_cacheMissKey);
    } catch (e) {
      debugPrint('Error resetting counters: $e');
    }
  }
}