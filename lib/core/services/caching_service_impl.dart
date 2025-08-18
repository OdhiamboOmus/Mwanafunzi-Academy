import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'caching_service.dart';

/// Concrete implementation of CachingService using SharedPreferences
/// This provides the actual storage operations for Flutter Lite compliance
class CachingServiceImpl extends CachingService {
  static const String _cachePrefix = 'mwanafunzi_cache_';
  
  Future<String?> _getStorageValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl._getStorageValue error for $key: $e');
      }
      return null;
    }
  }
  
  Future<bool> _removeStorageValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl._removeStorageValue error for $key: $e');
      }
      return false;
    }
  }
  
  Future<List<String>> _getAllCacheKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl._getAllCacheKeys error: $e');
      }
      return [];
    }
  }
  
  /// Get detailed cache statistics for performance monitoring
  Future<CacheStats> getDetailedCacheStats() async {
    try {
      final allKeys = await _getAllCacheKeys();
      int hitCount = 0;
      int missCount = 0;
      
      for (final key in allKeys) {
        final cachedData = await _getStorageValue(key);
        if (cachedData != null) {
          // Check if cache entry is valid (not expired)
          try {
            final jsonData = json.decode(cachedData) as Map<String, dynamic>;
            final cachedAt = jsonData['cachedAt'] as int?;
            final ttl = jsonData['ttl'] as int? ?? 3600;
            
            if (cachedAt != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if ((now - cachedAt) <= (ttl * 1000)) {
                hitCount++;
              } else {
                missCount++;
              }
            }
          } catch (e) {
            missCount++;
          }
        }
      }
      
      return CacheStats(
        totalReads: hitCount + missCount,
        totalWrites: allKeys.length,
        cacheHits: hitCount,
        cacheMisses: missCount,
        errors: 0,
        readTimes: [],
        writeTimes: [],
        cacheSizes: {},
        cleanupCount: 0,
        cleanupSizeBytes: 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl.getCacheStats error: $e');
      }
      return CacheStats(
        totalReads: 0,
        totalWrites: 0,
        cacheHits: 0,
        cacheMisses: 0,
        errors: 1,
        readTimes: [],
        writeTimes: [],
        cacheSizes: {},
        cleanupCount: 0,
        cleanupSizeBytes: 0,
      );
    }
  }
  
  /// Get total cache size in bytes
  Future<int> getTotalCacheSize() async {
    try {
      final allKeys = await _getAllCacheKeys();
      int totalSize = 0;
      
      for (final key in allKeys) {
        final cachedData = await _getStorageValue(key);
        if (cachedData != null) {
          totalSize += cachedData.length;
        }
      }
      
      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl.getTotalCacheSize error: $e');
      }
      return 0;
    }
  }
  
  /// Get number of cached items
  Future<int> getCachedItemCount() async {
    try {
      final allKeys = await _getAllCacheKeys();
      return allKeys.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl.getCachedItemCount error: $e');
      }
      return 0;
    }
  }
  
  /// Clear expired cache entries
  Future<int> clearExpiredCache() async {
    try {
      final allKeys = await _getAllCacheKeys();
      int clearedCount = 0;
      
      for (final key in allKeys) {
        final cachedData = await _getStorageValue(key);
        if (cachedData != null) {
          try {
            final jsonData = json.decode(cachedData) as Map<String, dynamic>;
            final cachedAt = jsonData['cachedAt'] as int?;
            final ttl = jsonData['ttl'] as int? ?? 3600;
            
            if (cachedAt != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if ((now - cachedAt) > (ttl * 1000)) {
                await _removeStorageValue(key);
                clearedCount++;
              }
            }
          } catch (e) {
            // Remove corrupted cache entries
            await _removeStorageValue(key);
            clearedCount++;
          }
        }
      }
      
      return clearedCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingServiceImpl.clearExpiredCache error: $e');
      }
      return 0;
    }
  }
}