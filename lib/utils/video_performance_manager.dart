import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/video_model.dart';

/// Performance optimization utilities for video operations
class VideoPerformanceManager {
  static const int _maxCacheSize = 10 * 1024 * 1024; // 10MB max cache
  static const int _maxVideoCacheEntries = 50;
  static const Duration _cacheCleanupInterval = Duration(hours: 6);
  
  static VideoPerformanceManager? _instance;
  static VideoPerformanceManager get instance => _instance ??= VideoPerformanceManager._();
  
  VideoPerformanceManager._();
  
  Timer? _cleanupTimer;
  final Map<String, DateTime> _cacheAccessTimes = {};
  final Map<String, int> _cacheSizes = {};
  
  /// Initialize performance manager
  void initialize() {
    _startCleanupTimer();
    _loadCacheStats();
  }
  
  /// Start periodic cache cleanup
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cacheCleanupInterval, (_) {
      _performCacheCleanup();
    });
  }
  
  /// Load cache statistics from SharedPreferences
  Future<void> _loadCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStatsJson = prefs.getString('video_cache_stats');
      
      if (cacheStatsJson != null) {
        final cacheStats = Map<String, dynamic>.from(jsonDecode(cacheStatsJson));
        _cacheAccessTimes.clear();
        _cacheSizes.clear();
        
        for (final entry in cacheStats.entries) {
          if (entry.value is Map) {
            final stats = entry.value as Map<String, dynamic>;
            _cacheAccessTimes[entry.key] = DateTime.parse(stats['lastAccess'] as String);
            _cacheSizes[entry.key] = stats['size'] as int;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cache stats: $e');
    }
  }
  
  /// Save cache statistics to SharedPreferences
  Future<void> _saveCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStats = <String, Map<String, dynamic>>{};
      
      for (final key in _cacheAccessTimes.keys) {
        cacheStats[key] = {
          'lastAccess': _cacheAccessTimes[key]!.toIso8601String(),
          'size': _cacheSizes[key] ?? 0,
        };
      }
      
      await prefs.setString('video_cache_stats', jsonEncode(cacheStats));
    } catch (e) {
      debugPrint('Error saving cache stats: $e');
    }
  }
  
  /// Record cache access for LRU tracking
  Future<void> recordCacheAccess(String cacheKey, int size) async {
    _cacheAccessTimes[cacheKey] = DateTime.now();
    _cacheSizes[cacheKey] = size;
    await _saveCacheStats();
  }
  
  /// Perform LRU cache cleanup
  Future<void> _performCacheCleanup() async {
    try {
      if (_cacheAccessTimes.isEmpty) return;
      
      // Sort by access time (oldest first)
      final sortedEntries = _cacheAccessTimes.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      int totalSize = _cacheSizes.values.fold(0, (sum, size) => sum + (size ?? 0));
      final keysToRemove = <String>[];
      
      // Remove oldest entries until we're under limits
      for (final entry in sortedEntries) {
        if (totalSize <= _maxCacheSize && _cacheAccessTimes.length <= _maxVideoCacheEntries) {
          break;
        }
        
        final size = _cacheSizes[entry.key] ?? 0;
        keysToRemove.add(entry.key);
        totalSize -= size;
      }
      
      // Remove old cache entries
      if (keysToRemove.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        for (final key in keysToRemove) {
          await prefs.remove(key);
          _cacheAccessTimes.remove(key);
          _cacheSizes.remove(key);
        }
        
        await _saveCacheStats();
        debugPrint('Cleaned up ${keysToRemove.length} old video cache entries');
      }
    } catch (e) {
      debugPrint('Error performing cache cleanup: $e');
    }
  }
  
  /// Optimize video list rendering with pagination
  static Widget buildOptimizedVideoList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double? itemExtent,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      key: const ValueKey('optimized_video_list'),
      itemCount: itemCount,
      itemExtent: itemExtent,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        // Add performance tracking for each item
        return _PerformanceTrackingWidget(
          index: index,
          child: itemBuilder(context, index),
        );
      },
    );
  }
  
  /// Optimize image loading with caching
  static Widget buildOptimizedThumbnail({
    required String imageUrl,
    required Widget placeholder,
    required Widget errorWidget,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }
  
  /// Dispose resources when no longer needed
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _cacheAccessTimes.clear();
    _cacheSizes.clear();
  }
  
  /// Get cache statistics for monitoring
  Map<String, dynamic> getCacheStats() {
    final totalSize = _cacheSizes.values.fold(0, (sum, size) => sum + (size ?? 0));
    final oldestAccess = _cacheAccessTimes.values.isEmpty 
        ? null 
        : _cacheAccessTimes.values.reduce((a, b) => a.isBefore(b) ? a : b);
    final newestAccess = _cacheAccessTimes.values.isEmpty
        ? null
        : _cacheAccessTimes.values.reduce((a, b) => a.isAfter(b) ? a : b);
    
    return {
      'totalCacheEntries': _cacheAccessTimes.length,
      'totalCacheSizeBytes': totalSize,
      'maxCacheSizeBytes': _maxCacheSize,
      'maxCacheEntries': _maxVideoCacheEntries,
      'oldestAccess': oldestAccess?.toIso8601String(),
      'newestAccess': newestAccess?.toIso8601String(),
      'cacheUtilizationPercent': (totalSize / _maxCacheSize * 100).round(),
    };
  }
}

/// Widget to track performance metrics for list items
class _PerformanceTrackingWidget extends StatefulWidget {
  final int index;
  final Widget child;
  
  const _PerformanceTrackingWidget({
    required this.index,
    required this.child,
  });
  
  @override
  State<_PerformanceTrackingWidget> createState() => _PerformanceTrackingWidgetState();
}

class _PerformanceTrackingWidgetState extends State<_PerformanceTrackingWidget> {
  DateTime? _buildTime;
  
  @override
  Widget build(BuildContext context) {
    _buildTime = DateTime.now();
    return widget.child;
  }
  
  @override
  void didUpdateWidget(_PerformanceTrackingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      // Track rebuilds for performance analysis
      final rebuildTime = DateTime.now().difference(_buildTime ?? DateTime.now());
      if (rebuildTime.inMilliseconds > 16) { // > 1 frame at 60fps
        debugPrint('Slow widget rebuild at index ${widget.index}: ${rebuildTime.inMilliseconds}ms');
      }
    }
  }
}

/// Extension for performance optimization on VideoModel
extension VideoModelPerformance on VideoModel {
  /// Get optimized thumbnail URL based on available quality
  String get optimizedThumbnailUrl {
    // Use lower quality thumbnails for better performance
    return 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';
  }
  
  /// Check if video should be cached based on size and importance
  bool get shouldCache {
    // Cache videos under 10 minutes and active
    return duration.inMinutes < 10 && isActive;
  }
}

/// Batch operation utilities for Firestore
class VideoBatchOperations {
  /// Execute multiple Firestore operations in a batch
  static Future<void> executeBatchOperations(
    List<Future<void> Function()> operations, {
    int batchSize = 10,
    Duration delayBetweenBatches = const Duration(milliseconds: 100),
  }) async {
    try {
      final batches = <List<Future<void> Function()>>[];
      var currentBatch = <Future<void> Function()>[];
      
      // Group operations into batches
      for (final operation in operations) {
        currentBatch.add(operation);
        if (currentBatch.length >= batchSize) {
          batches.add(currentBatch);
          currentBatch = [];
        }
      }
      
      if (currentBatch.isNotEmpty) {
        batches.add(currentBatch);
      }
      
      // Execute batches with delays
      for (final batch in batches) {
        await Future.wait(batch.map((operation) => operation()));
        if (delayBetweenBatches.inMilliseconds > 0) {
          await Future.delayed(delayBetweenBatches);
        }
      }
    } catch (e) {
      debugPrint('Error in batch operations: $e');
      rethrow;
    }
  }
}