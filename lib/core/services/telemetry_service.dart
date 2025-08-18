import 'dart:async';
import 'package:flutter/foundation.dart';

/// Telemetry service for performance monitoring and optimization
/// Collects cache hit/miss ratios, read/write counts, and download frequencies
class TelemetryService {
  final TelemetryCollector _collector = TelemetryCollector();
  Timer? _reportTimer;

  /// Initialize telemetry monitoring
  void initialize() {
    // Start periodic telemetry reports
    _reportTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _generateTelemetryReport();
    });
  }

  /// Record cache hit for performance monitoring
  void recordCacheHit(String cacheKey) {
    _collector.recordCacheHit(cacheKey);
  }

  /// Record cache miss for performance monitoring
  void recordCacheMiss(String cacheKey) {
    _collector.recordCacheMiss(cacheKey);
  }

  /// Record cache read operation
  void recordCacheRead(String cacheKey, int durationMs) {
    _collector.recordCacheRead(cacheKey, durationMs);
  }

  /// Record cache write operation
  void recordCacheWrite(String cacheKey, int durationMs) {
    _collector.recordCacheWrite(cacheKey, durationMs);
  }

  /// Record download frequency for cache management
  void recordDownloadFrequency(String contentType) {
    _collector.recordDownloadFrequency(contentType);
  }

  /// Record read count for optimization decisions
  void recordReadCount(String dataType) {
    _collector.recordReadCount(dataType);
  }

  /// Record write count for optimization decisions
  void recordWriteCount(String dataType) {
    _collector.recordWriteCount(dataType);
  }

  /// Get cache performance metrics
  CacheMetrics getCacheMetrics() {
    return _collector.getCacheMetrics();
  }

  /// Get download frequency analysis
  DownloadFrequencyAnalysis getDownloadFrequencyAnalysis() {
    return DownloadFrequencyAnalysis.fromCounts(
      _collector._downloadFrequencies,
    );
  }

  /// Get performance recommendations based on telemetry
  List<String> getPerformanceRecommendations() {
    final metrics = getCacheMetrics();
    final recommendations = <String>[];

    // Cache hit rate recommendations
    if (metrics.hitRate < 0.5) {
      recommendations.add(
        'Low cache hit rate (${(metrics.hitRate * 100).toStringAsFixed(1)}%). Consider increasing TTL values for frequently accessed content.',
      );
    } else if (metrics.hitRate > 0.9) {
      recommendations.add(
        'Excellent cache hit rate (${(metrics.hitRate * 100).toStringAsFixed(1)}%). Current caching strategy is working well.',
      );
    }

    // Read time recommendations
    if (metrics.averageReadTime > 100) {
      recommendations.add(
        'High average read time (${metrics.averageReadTime.toStringAsFixed(1)}ms). Consider optimizing data structures or storage access patterns.',
      );
    }

    // Write time recommendations
    if (metrics.averageWriteTime > 200) {
      recommendations.add(
        'High average write time (${metrics.averageWriteTime.toStringAsFixed(1)}ms). Consider batching writes or optimizing serialization.',
      );
    }

    // Download frequency recommendations
    final downloadAnalysis = getDownloadFrequencyAnalysis();
    if (downloadAnalysis.totalDownloads > 100) {
      recommendations.add(
        'High download frequency (${downloadAnalysis.totalDownloads} downloads). Consider implementing more aggressive caching.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance metrics are within acceptable ranges.');
    }

    return recommendations;
  }

  /// Generate telemetry report for debugging
  void _generateTelemetryReport() {
    if (kDebugMode) {
      final metrics = getCacheMetrics();
      final downloadAnalysis = getDownloadFrequencyAnalysis();

      debugPrint('📊 Telemetry Report:');
      debugPrint(
        '  Cache Hit Rate: ${(metrics.hitRate * 100).toStringAsFixed(1)}%',
      );
      debugPrint('  Total Reads: ${metrics.totalReads}');
      debugPrint('  Total Writes: ${metrics.totalWrites}');
      debugPrint(
        '  Average Read Time: ${metrics.averageReadTime.toStringAsFixed(1)}ms',
      );
      debugPrint(
        '  Average Write Time: ${metrics.averageWriteTime.toStringAsFixed(1)}ms',
      );
      debugPrint('  Total Downloads: ${downloadAnalysis.totalDownloads}');
      debugPrint('  Most Downloaded: ${downloadAnalysis.mostDownloadedType}');

      final recommendations = getPerformanceRecommendations();
      debugPrint('  Recommendations: ${recommendations.join('; ')}');
    }
  }

  /// Dispose monitoring resources
  void dispose() {
    _reportTimer?.cancel();
  }
}

/// Cache metrics for performance monitoring
class CacheMetrics {
  final int totalReads;
  final int totalWrites;
  final int cacheHits;
  final int cacheMisses;
  final List<int> readTimes;
  final List<int> writeTimes;

  CacheMetrics({
    required this.totalReads,
    required this.totalWrites,
    required this.cacheHits,
    required this.cacheMisses,
    required this.readTimes,
    required this.writeTimes,
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
}

/// Download frequency analysis
class DownloadFrequencyAnalysis {
  final int totalDownloads;
  final Map<String, int> downloadCounts;
  final String mostDownloadedType;

  DownloadFrequencyAnalysis({
    required this.totalDownloads,
    required this.downloadCounts,
    required this.mostDownloadedType,
  });

  factory DownloadFrequencyAnalysis.fromCounts(Map<String, int> counts) {
    String mostDownloaded = 'unknown';
    int maxCount = 0;

    counts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostDownloaded = type;
      }
    });

    return DownloadFrequencyAnalysis(
      totalDownloads: counts.values.fold(0, (sum, count) => sum + count),
      downloadCounts: Map.from(counts),
      mostDownloadedType: mostDownloaded,
    );
  }
}

/// Telemetry data collector
class TelemetryCollector {
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};
  final Map<String, List<int>> _readTimes = {};
  final Map<String, List<int>> _writeTimes = {};
  final Map<String, int> _downloadFrequencies = {};
  final Map<String, int> _readCounts = {};
  final Map<String, int> _writeCounts = {};

  void recordCacheHit(String cacheKey) {
    _cacheHits[cacheKey] = (_cacheHits[cacheKey] ?? 0) + 1;
  }

  void recordCacheMiss(String cacheKey) {
    _cacheMisses[cacheKey] = (_cacheMisses[cacheKey] ?? 0) + 1;
  }

  void recordCacheRead(String cacheKey, int durationMs) {
    _readTimes[cacheKey] = (_readTimes[cacheKey] ?? [])..add(durationMs);
    _readCounts[cacheKey] = (_readCounts[cacheKey] ?? 0) + 1;
  }

  void recordCacheWrite(String cacheKey, int durationMs) {
    _writeTimes[cacheKey] = (_writeTimes[cacheKey] ?? [])..add(durationMs);
    _writeCounts[cacheKey] = (_writeCounts[cacheKey] ?? 0) + 1;
  }

  void recordDownloadFrequency(String contentType) {
    _downloadFrequencies[contentType] =
        (_downloadFrequencies[contentType] ?? 0) + 1;
  }

  void recordReadCount(String dataType) {
    _readCounts[dataType] = (_readCounts[dataType] ?? 0) + 1;
  }

  void recordWriteCount(String dataType) {
    _writeCounts[dataType] = (_writeCounts[dataType] ?? 0) + 1;
  }

  CacheMetrics getCacheMetrics() {
    final allReadTimes = _readTimes.values.expand((times) => times).toList();
    final allWriteTimes = _writeTimes.values.expand((times) => times).toList();

    return CacheMetrics(
      totalReads: _readCounts.values.fold(0, (sum, count) => sum + count),
      totalWrites: _writeCounts.values.fold(0, (sum, count) => sum + count),
      cacheHits: _cacheHits.values.fold(0, (sum, count) => sum + count),
      cacheMisses: _cacheMisses.values.fold(0, (sum, count) => sum + count),
      readTimes: allReadTimes,
      writeTimes: allWriteTimes,
    );
  }

  DownloadFrequencyAnalysis getDownloadFrequencyAnalysis() {
    return DownloadFrequencyAnalysis.fromCounts(Map.from(_downloadFrequencies));
  }

  /// Clear collected telemetry data
  void clear() {
    _cacheHits.clear();
    _cacheMisses.clear();
    _readTimes.clear();
    _writeTimes.clear();
    _downloadFrequencies.clear();
    _readCounts.clear();
    _writeCounts.clear();
  }
}
