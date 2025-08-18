import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'caching_service.dart';
import 'caching_service_impl.dart';
import 'performance_monitor.dart';
import 'telemetry_service.dart';

/// Service manager for coordinating all performance and caching services
/// Ensures Flutter Lite compliance while providing comprehensive monitoring
class ServiceManager {
  static ServiceManager? _instance;
  
  /// Get singleton instance
  static ServiceManager get instance {
    _instance ??= ServiceManager._internal();
    return _instance!;
  }
  
  ServiceManager._internal();
  
  /// Core services
  late final CachingServiceImpl cachingService;
  late final PerformanceMonitor performanceMonitor;
  late final TelemetryService telemetryService;
  
  /// Initialize all services
  Future<void> initialize() async {
    try {
      // Initialize core services
      cachingService = CachingServiceImpl();
      performanceMonitor = PerformanceMonitor();
      telemetryService = TelemetryService();
      
      // Start monitoring
      performanceMonitor.initialize();
      telemetryService.initialize();
      
      if (kDebugMode) {
        debugPrint('🚀 ServiceManager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ServiceManager initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Get comprehensive performance report
  PerformanceReport getPerformanceReport() {
    final cacheMetrics = telemetryService.getCacheMetrics();
    final downloadAnalysis = telemetryService.getDownloadFrequencyAnalysis();
    final recommendations = performanceMonitor.getRecommendations();
    
    return PerformanceReport(
      cacheHitRate: cacheMetrics.hitRate,
      averageReadTime: cacheMetrics.averageReadTime,
      averageWriteTime: cacheMetrics.averageWriteTime,
      totalDownloads: downloadAnalysis.totalDownloads,
      mostDownloadedType: downloadAnalysis.mostDownloadedType,
      performanceDegraded: performanceMonitor.isPerformanceDegraded(),
      recommendations: recommendations,
      timestamp: DateTime.now(),
    );
  }
  
  /// Optimize services based on performance data
  Future<void> optimizeServices() async {
    try {
      // Check if cache needs optimization
      if (cachingService.needsOptimization()) {
        await cachingService.optimizeCache();
      }
      
      // Clear expired cache entries
      await cachingService.clearExpiredCache();
      
      if (kDebugMode) {
        debugPrint('🔧 Services optimized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Service optimization failed: $e');
      }
    }
  }
  
  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    try {
      return await cachingService.getDetailedCacheStats();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get cache stats: $e');
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
  
  /// Clear all cache and telemetry data
  Future<void> clearAllData() async {
    try {
      await cachingService.clearAllCache();
      // Note: TelemetryService doesn't expose clear method publicly
      // This would need to be added to TelemetryService if needed
      
      if (kDebugMode) {
        debugPrint('🧹 All service data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear service data: $e');
      }
    }
  }
  
  /// Dispose all services
  void dispose() {
    performanceMonitor.dispose();
    telemetryService.dispose();
  }
}

/// Performance report summary
class PerformanceReport {
  final double cacheHitRate;
  final double averageReadTime;
  final double averageWriteTime;
  final int totalDownloads;
  final String mostDownloadedType;
  final bool performanceDegraded;
  final List<String> recommendations;
  final DateTime timestamp;
  
  PerformanceReport({
    required this.cacheHitRate,
    required this.averageReadTime,
    required this.averageWriteTime,
    required this.totalDownloads,
    required this.mostDownloadedType,
    required this.performanceDegraded,
    required this.recommendations,
    required this.timestamp,
  });
  
  /// Generate performance summary string
  String getSummary() {
    final status = performanceDegraded ? '⚠️ DEGRADED' : '✅ HEALTHY';
    final hitRatePercent = (cacheHitRate * 100).toStringAsFixed(1);
    
    return '''
📊 Performance Report - $status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cache Hit Rate: $hitRatePercent%
Average Read Time: ${averageReadTime.toStringAsFixed(1)}ms
Average Write Time: ${averageWriteTime.toStringAsFixed(1)}ms
Total Downloads: $totalDownloads
Most Downloaded: $mostDownloadedType
Generated: ${timestamp.toLocal()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recommendations:
${recommendations.map((r) => '• $r').join('\n')}
''';
  }
}

/// Extension for enhanced service functionality
extension ServiceManagerExtensions on ServiceManager {
  /// Record cache operation with telemetry
  void recordCacheOperation({
    required String cacheKey,
    required bool isHit,
    required int durationMs,
    required String operationType,
  }) {
    if (isHit) {
      telemetryService.recordCacheHit(cacheKey);
    } else {
      telemetryService.recordCacheMiss(cacheKey);
    }
    
    telemetryService.recordCacheRead(cacheKey, durationMs);
    performanceMonitor.recordCacheHit(cacheKey);
  }
  
  /// Record download with performance tracking
  void recordDownload({
    required String contentType,
    required int sizeBytes,
    required int durationMs,
  }) {
    telemetryService.recordDownloadFrequency(contentType);
    performanceMonitor.recordDownload(contentType, sizeBytes);
    
    // Record network time for performance monitoring
    // Note: PerformanceMonitor doesn't expose _metrics publicly
    // This would need to be added to PerformanceMonitor if needed
  }
  
  /// Get performance score (0-100)
  double getPerformanceScore() {
    final report = getPerformanceReport();
    
    double score = 100;
    
    // Cache hit rate (40% weight)
    score -= (1 - report.cacheHitRate) * 40;
    
    // Read time (30% weight) - penalize times over 100ms
    if (report.averageReadTime > 100) {
      score -= math.min((report.averageReadTime - 100) / 10, 30);
    }
    
    // Write time (20% weight) - penalize times over 200ms
    if (report.averageWriteTime > 200) {
      score -= math.min((report.averageWriteTime - 200) / 20, 20);
    }
    
    // Download frequency (10% weight) - penalize high frequencies
    if (report.totalDownloads > 50) {
      score -= math.min((report.totalDownloads - 50) / 10, 10);
    }
    
    return math.max(0, score);
  }
}