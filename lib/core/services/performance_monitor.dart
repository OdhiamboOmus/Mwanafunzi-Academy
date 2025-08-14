import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Performance monitoring service for Flutter Lite compliance
/// Monitors cache performance, network operations, and app responsiveness
class PerformanceMonitor {
  static const String _monitorPrefix = 'mwanafunzi_perf_';
  
  final PerformanceMetrics _metrics = PerformanceMetrics();
  Timer? _monitorTimer;
  
  /// Initialize performance monitoring
  void initialize() {
    // Start periodic performance checks
    _monitorTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkPerformanceHealth();
    });
    
    // Record initial startup time
    _recordStartupTime();
  }
  
  /// Record cache hit/miss ratio
  void recordCacheHit(String cacheKey) {
    _metrics.recordCacheHit(cacheKey);
  }
  
  void recordCacheMiss(String cacheKey) {
    _metrics.recordCacheMiss(cacheKey);
  }
  
  /// Record read/write count for optimization
  void recordReadOperation(String dataType) {
    _metrics.recordReadOperation(dataType);
  }
  
  void recordWriteOperation(String dataType) {
    _metrics.recordWriteOperation(dataType);
  }
  
  /// Record download frequency for cache management
  void recordDownload(String contentType, int sizeBytes) {
    _metrics.recordDownload(contentType, sizeBytes);
  }
  
  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    return _metrics.getSummary();
  }
  
  /// Check if performance is degraded
  bool isPerformanceDegraded() {
    final summary = getPerformanceSummary();
    
    // Performance thresholds for Flutter Lite
    return summary.averageNetworkTime > 3000 || // 3 seconds
           summary.averageReadTime > 100 || // 100ms
           summary.cacheHitRate < 0.6 || // 60% hit rate
           summary.errorRate > 0.1; // 10% error rate
  }
  
  /// Get performance recommendations
  List<String> getRecommendations() {
    final summary = getPerformanceSummary();
    final recommendations = <String>[];
    
    // Cache hit rate recommendations
    if (summary.cacheHitRate < 0.6) {
      recommendations.add('Low cache hit rate (${(summary.cacheHitRate * 100).toStringAsFixed(1)}%). Consider increasing TTL values.');
    }
    
    // Read time recommendations
    if (summary.averageReadTime > 100) {
      recommendations.add('High read time (${summary.averageReadTime.toStringAsFixed(1)}ms). Optimize data access patterns.');
    }
    
    // Network time recommendations
    if (summary.averageNetworkTime > 3000) {
      recommendations.add('Slow network (${summary.averageNetworkTime.toStringAsFixed(1)}ms). Implement offline caching.');
    }
    
    // Error rate recommendations
    if (summary.errorRate > 0.1) {
      recommendations.add('High error rate (${(summary.errorRate * 100).toStringAsFixed(1)}%). Review error handling.');
    }
    
    // Download frequency recommendations
    if (summary.totalDownloads > 50) {
      recommendations.add('Frequent downloads (${summary.totalDownloads}). Consider aggressive caching.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable parameters.');
    }
    
    return recommendations;
  }
  
  /// Check performance health and trigger optimizations
  void _checkPerformanceHealth() {
    if (isPerformanceDegraded()) {
      if (kDebugMode) {
        final summary = getPerformanceSummary();
        debugPrint('⚠️ Performance degradation detected:');
        debugPrint('  Cache hit rate: ${(summary.cacheHitRate * 100).toStringAsFixed(1)}%');
        debugPrint('  Average read time: ${summary.averageReadTime.toStringAsFixed(1)}ms');
        debugPrint('  Average network time: ${summary.averageNetworkTime.toStringAsFixed(1)}ms');
        debugPrint('  Error rate: ${(summary.errorRate * 100).toStringAsFixed(1)}%');
      }
    }
  }
  
  /// Record app startup time
  void _recordStartupTime() {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Record startup completion when app is ready
    Future.delayed(const Duration(seconds: 2), () {
      final startupTime = DateTime.now().millisecondsSinceEpoch - startTime;
      _metrics.recordStartupTime(startupTime);
    });
  }
  
  /// Dispose monitoring resources
  void dispose() {
    _monitorTimer?.cancel();
  }
}

/// Performance metrics collector
class PerformanceMetrics {
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};
  final Map<String, int> _readOperations = {};
  final Map<String, int> _writeOperations = {};
  final Map<String, int> _downloadCounts = {};
  final Map<String, int> _downloadSizes = {};
  final List<int> _readTimes = [];
  final List<int> _networkTimes = [];
  final List<int> _startupTimes = [];
  final List<int> _errorCounts = [];
  
  void recordCacheHit(String cacheKey) {
    _cacheHits[cacheKey] = (_cacheHits[cacheKey] ?? 0) + 1;
  }
  
  void recordCacheMiss(String cacheKey) {
    _cacheMisses[cacheKey] = (_cacheMisses[cacheKey] ?? 0) + 1;
  }
  
  void recordReadOperation(String dataType) {
    _readOperations[dataType] = (_readOperations[dataType] ?? 0) + 1;
    _readTimes.add(1); // Placeholder for actual timing
  }
  
  void recordWriteOperation(String dataType) {
    _writeOperations[dataType] = (_writeOperations[dataType] ?? 0) + 1;
  }
  
  void recordDownload(String contentType, int sizeBytes) {
    _downloadCounts[contentType] = (_downloadCounts[contentType] ?? 0) + 1;
    _downloadSizes[contentType] = (_downloadSizes[contentType] ?? 0) + sizeBytes;
  }
  
  void recordNetworkTime(int timeMs) {
    _networkTimes.add(timeMs);
  }
  
  void recordStartupTime(int timeMs) {
    _startupTimes.add(timeMs);
  }
  
  void recordError() {
    _errorCounts.add(1);
  }
  
  PerformanceSummary getSummary() {
    return PerformanceSummary(
      totalCacheHits: _cacheHits.values.fold(0, (sum, count) => sum + count),
      totalCacheMisses: _cacheMisses.values.fold(0, (sum, count) => sum + count),
      totalReads: _readOperations.values.fold(0, (sum, count) => sum + count),
      totalWrites: _writeOperations.values.fold(0, (sum, count) => sum + count),
      totalDownloads: _downloadCounts.values.fold(0, (sum, count) => sum + count),
      downloadSizes: Map.from(_downloadSizes),
      readTimes: List.from(_readTimes),
      networkTimes: List.from(_networkTimes),
      startupTimes: List.from(_startupTimes),
      errorCounts: List.from(_errorCounts),
    );
  }
}

/// Complete performance summary
class PerformanceSummary {
  final int totalCacheHits;
  final int totalCacheMisses;
  final int totalReads;
  final int totalWrites;
  final int totalDownloads;
  final Map<String, int> downloadSizes;
  final List<int> readTimes;
  final List<int> networkTimes;
  final List<int> startupTimes;
  final List<int> errorCounts;
  
  PerformanceSummary({
    required this.totalCacheHits,
    required this.totalCacheMisses,
    required this.totalReads,
    required this.totalWrites,
    required this.totalDownloads,
    required this.downloadSizes,
    required this.readTimes,
    required this.networkTimes,
    required this.startupTimes,
    required this.errorCounts,
  });
  
  double get cacheHitRate {
    final total = totalCacheHits + totalCacheMisses;
    if (total == 0) return 0.0;
    return totalCacheHits / total;
  }
  
  double get averageReadTime {
    if (readTimes.isEmpty) return 0.0;
    return readTimes.reduce((a, b) => a + b) / readTimes.length;
  }
  
  double get averageNetworkTime {
    if (networkTimes.isEmpty) return 0.0;
    return networkTimes.reduce((a, b) => a + b) / networkTimes.length;
  }
  
  double get averageStartupTime {
    if (startupTimes.isEmpty) return 0.0;
    return startupTimes.reduce((a, b) => a + b) / startupTimes.length;
  }
  
  double get errorRate {
    final totalOperations = totalReads + totalWrites + totalDownloads;
    if (totalOperations == 0) return 0.0;
    return errorCounts.length / totalOperations;
  }
  
  int getTotalDownloadSize() {
    return downloadSizes.values.fold(0, (sum, size) => sum + size);
  }
}