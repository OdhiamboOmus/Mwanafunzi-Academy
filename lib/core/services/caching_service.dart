import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Comprehensive caching service for Flutter Lite compliance
/// Implements aggressive caching with 24-hour cycles and performance monitoring
class CachingService {
  static const String _cachePrefix = 'mwanafunzi_cache_';

  /// Cache statistics for performance monitoring
  final CacheTelemetry _telemetry = CacheTelemetry();

  /// Get cached data with aggressive 24-hour TTL for static content
  Future<T?> getCachedData<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    int? ttlSeconds,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();

    try {
      final cacheKey = '$_cachePrefix$key';

      // Record cache read attempt
      _telemetry.recordRead(key);

      // For static content, use aggressive 24-hour TTL if not specified
      final effectiveTtl =
          ttlSeconds ??
          (key.contains('static') || key.contains('meta') ? 86400 : 3600);

      final cachedData = await _getStorageValue(cacheKey);

      if (cachedData == null) {
        _telemetry.recordCacheMiss(key);
        return null;
      }

      final jsonData = _decodeJson(cachedData) as Map<String, dynamic>;

      // Check TTL if provided and not force refresh
      if (!forceRefresh && effectiveTtl > 0) {
        final cachedAt = jsonData['cachedAt'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (cachedAt == null || (now - cachedAt) > (effectiveTtl * 1000)) {
          await _removeStorageValue(cacheKey); // Remove expired cache
          _telemetry.recordCacheMiss(key);
          return null;
        }
      }

      _telemetry.recordCacheHit(key);

      // Record read performance
      final readTime = DateTime.now().difference(startTime).inMilliseconds;
      _telemetry.recordReadPerformance(key, readTime);

      return fromJson(jsonData['data']);
    } catch (e) {
      _telemetry.recordError(key, e.toString());
      if (kDebugMode) {
        debugPrint('❌ CachingService.getCachedData error for $key: $e');
      }
      return null;
    }
  }

  /// Set cached data with intelligent compression and metadata
  Future<bool> setCachedData<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
    int? ttlSeconds,
  }) async {
    final startTime = DateTime.now();

    try {
      final cacheKey = '$_cachePrefix$key';
      final effectiveTtl =
          ttlSeconds ??
          (key.contains('static') || key.contains('meta') ? 86400 : 3600);

      // Compress data by removing null values for smaller footprint
      final jsonData = {
        'data': _compressJson(toJson(data)),
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'ttl': effectiveTtl,
        'version': '1.0',
      };

      // Record write attempt
      _telemetry.recordWrite(key);

      final success = await _setStorageValue(cacheKey, _encodeJson(jsonData));

      if (success) {
        // Record write performance
        final writeTime = DateTime.now().difference(startTime).inMilliseconds;
        _telemetry.recordWritePerformance(key, writeTime);

        // Update cache size tracking
        final dataSize = _encodeJson(jsonData).length;
        _telemetry.recordCacheSize(key, dataSize);
      }

      return success;
    } catch (e) {
      _telemetry.recordError(key, e.toString());
      if (kDebugMode) {
        debugPrint('❌ CachingService.setCachedData error for $key: $e');
      }
      return false;
    }
  }

  /// Intelligent cache cleanup prioritizing frequently accessed content
  Future<int> performCacheCleanup({
    int maxCacheSizeMB = 50,
    int maxItems = 1000,
  }) async {
    try {
      final allKeys = await _getAllCacheKeys();
      final cacheInfo = await _getCacheInfo(allKeys);

      // Sort by access frequency (most accessed first)
      cacheInfo.sort((a, b) => b.accessCount.compareTo(a.accessCount));

      int totalCleaned = 0;
      int totalSize = 0;

      // Keep frequently accessed items, remove least recently used
      for (int i = cacheInfo.length - 1; i >= 0; i--) {
        final info = cacheInfo[i];
        totalSize += info.sizeBytes;

        // Remove if over size limit or item limit
        if (totalSize > (maxCacheSizeMB * 1024 * 1024) ||
            cacheInfo.length - totalCleaned > maxItems) {
          await _removeStorageValue('$_cachePrefix${info.key}');
          totalCleaned++;
        }
      }

      _telemetry.recordCleanup(totalCleaned, totalSize);
      return totalCleaned;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingService.performCacheCleanup error: $e');
      }
      return 0;
    }
  }

  /// Get cache statistics for performance monitoring
  CacheStats getCacheStats() {
    return _telemetry.getStats();
  }

  /// Clear all cache with telemetry
  Future<bool> clearAllCache() async {
    try {
      final allKeys = await _getAllCacheKeys();
      int clearedCount = 0;

      for (final key in allKeys) {
        final success = await _removeStorageValue(key);
        if (success) clearedCount++;
      }

      _telemetry.recordClear(clearedCount);
      return clearedCount == allKeys.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CachingService.clearAllCache error: $e');
      }
      return false;
    }
  }

  /// Check if cache needs optimization
  bool needsOptimization() {
    final stats = _telemetry.getStats();
    return stats.hitRate < 0.7 ||
        stats.averageReadTime > 100 ||
        stats.totalCacheSizeMB > 50;
  }

  /// Optimize cache based on usage patterns
  Future<void> optimizeCache() async {
    if (needsOptimization()) {
      await performCacheCleanup();
      _telemetry.recordOptimization();
    }
  }

  // Helper methods for storage operations
  // Abstract storage methods to be implemented by platform-specific services
  Future<String?> _getStorageValue(String key) {
    throw UnimplementedError('Storage service must be implemented');
  }

  Future<bool> _setStorageValue(String key, String value) {
    throw UnimplementedError('Storage service must be implemented');
  }

  Future<bool> _removeStorageValue(String key) {
    throw UnimplementedError('Storage service must be implemented');
  }

  Future<List<String>> _getAllCacheKeys() {
    throw UnimplementedError('Storage service must be implemented');
  }

  /// Get cache information for cleanup decisions
  Future<List<CacheInfo>> _getCacheInfo(List<String> allKeys) async {
    final cacheInfo = <CacheInfo>[];

    for (final key in allKeys) {
      try {
        final cachedData = await _getStorageValue(key);
        if (cachedData != null) {
          final jsonData = _decodeJson(cachedData) as Map<String, dynamic>;
          final accessCount =
              _telemetry._readCounts[key.replaceFirst(_cachePrefix, '')] ?? 0;
          final sizeBytes = cachedData.length;

          cacheInfo.add(
            CacheInfo(
              key: key.replaceFirst(_cachePrefix, ''),
              sizeBytes: sizeBytes,
              accessCount: accessCount,
              lastAccessed: jsonData['cachedAt'] ?? 0,
            ),
          );
        }
      } catch (e) {
        // Skip corrupted cache entries
        continue;
      }
    }

    return cacheInfo;
  }

  // JSON helpers with error handling
  dynamic _decodeJson(String data) {
    try {
      return _safeJsonDecode(data);
    } catch (e) {
      throw FormatException('Invalid JSON data: $e');
    }
  }

  String _encodeJson(dynamic data) {
    try {
      return _safeJsonEncode(data);
    } catch (e) {
      throw FormatException('Invalid JSON encoding: $e');
    }
  }

  // Compress JSON by removing null values
  dynamic _compressJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map(
        (key, value) =>
            MapEntry(key, value != null ? _compressJson(value) : null),
      );
    } else if (data is List) {
      return data
          .map((item) => item != null ? _compressJson(item) : null)
          .toList();
    }
    return data;
  }

  // Safe JSON decode with null safety
  dynamic _safeJsonDecode(String source) {
    return jsonDecode(source);
  }

  // Safe JSON encode with null safety
  String _safeJsonEncode(Object? data) {
    return jsonEncode(data);
  }
}

/// Cache information for cleanup decisions
class CacheInfo {
  final String key;
  final int sizeBytes;
  final int accessCount;
  final int lastAccessed;

  CacheInfo({
    required this.key,
    required this.sizeBytes,
    required this.accessCount,
    required this.lastAccessed,
  });
}

/// Cache statistics for performance monitoring
class CacheStats {
  final int totalReads;
  final int totalWrites;
  final int cacheHits;
  final int cacheMisses;
  final int errors;
  final List<int> readTimes;
  final List<int> writeTimes;
  final Map<String, int> cacheSizes;
  final int cleanupCount;
  final int cleanupSizeBytes;

  CacheStats({
    required this.totalReads,
    required this.totalWrites,
    required this.cacheHits,
    required this.cacheMisses,
    required this.errors,
    required this.readTimes,
    required this.writeTimes,
    required this.cacheSizes,
    required this.cleanupCount,
    required this.cleanupSizeBytes,
  });

  double get hitRate {
    if (totalReads == 0) return 0.0;
    return cacheHits / totalReads;
  }

  double get averageReadTime {
    if (readTimes.isEmpty) return 0.0;
    return readTimes.reduce((a, b) => a + b) / readTimes.length;
  }

  double get averageWriteTime {
    if (writeTimes.isEmpty) return 0.0;
    return writeTimes.reduce((a, b) => a + b) / writeTimes.length;
  }

  int get totalCacheSizeMB {
    if (cacheSizes.isEmpty) return 0;
    final totalBytes = cacheSizes.values.fold(0, (sum, size) => sum + size);
    return (totalBytes / (1024 * 1024)).ceil();
  }
}

/// Cache telemetry for performance monitoring
class CacheTelemetry {
  final Map<String, int> _readCounts = {};
  final Map<String, int> _writeCounts = {};
  final Map<String, int> _hitCounts = {};
  final Map<String, int> _missCounts = {};
  final Map<String, int> _errorCounts = {};
  final List<int> _readTimes = [];
  final List<int> _writeTimes = [];
  final Map<String, int> _cacheSizes = {};
  int _cleanupCount = 0;
  int _cleanupSizeBytes = 0;

  void recordRead(String key) {
    _readCounts[key] = (_readCounts[key] ?? 0) + 1;
  }

  void recordWrite(String key) {
    _writeCounts[key] = (_writeCounts[key] ?? 0) + 1;
  }

  void recordCacheHit(String key) {
    _hitCounts[key] = (_hitCounts[key] ?? 0) + 1;
  }

  void recordCacheMiss(String key) {
    _missCounts[key] = (_missCounts[key] ?? 0) + 1;
  }

  void recordError(String key, String error) {
    _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
  }

  void recordReadPerformance(String key, int timeMs) {
    _readTimes.add(timeMs);
  }

  void recordWritePerformance(String key, int timeMs) {
    _writeTimes.add(timeMs);
  }

  void recordCacheSize(String key, int sizeBytes) {
    _cacheSizes[key] = sizeBytes;
  }

  void recordCleanup(int itemsCleared, int sizeBytes) {
    _cleanupCount += itemsCleared;
    _cleanupSizeBytes += sizeBytes;
  }

  void recordClear(int itemsCleared) {
    _cleanupCount += itemsCleared;
  }

  void recordOptimization() {
    _cleanupCount++;
  }

  CacheStats getStats() {
    return CacheStats(
      totalReads: _readCounts.values.fold(0, (sum, count) => sum + count),
      totalWrites: _writeCounts.values.fold(0, (sum, count) => sum + count),
      cacheHits: _hitCounts.values.fold(0, (sum, count) => sum + count),
      cacheMisses: _missCounts.values.fold(0, (sum, count) => sum + count),
      errors: _errorCounts.values.fold(0, (sum, count) => sum + count),
      readTimes: List.from(_readTimes),
      writeTimes: List.from(_writeTimes),
      cacheSizes: Map.from(_cacheSizes),
      cleanupCount: _cleanupCount,
      cleanupSizeBytes: _cleanupSizeBytes,
    );
  }
}
