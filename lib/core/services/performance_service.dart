import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Performance monitoring service for Flutter Lite compliance
/// Tracks cache performance, network operations, and app responsiveness
class PerformanceService {
  static const String _telemetryPrefix = 'mwanafunzi_perf_';
  
  final PerformanceTelemetry _telemetry = PerformanceTelemetry();
  Timer? _optimizationTimer;
  
  /// Initialize performance monitoring
  void initialize() {
    // Start periodic optimization checks
    _optimizationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkPerformanceHealth();
    });
    
    // Record app startup time
    _recordAppStartup();
  }
  
  /// Record network operation performance
  void recordNetworkOperation({
    required String operation,
    required int durationMs,
    required bool success,
    int? bytesTransferred,
  }) {
    _telemetry.recordNetworkOperation(
      operation: operation,
      durationMs: durationMs,
      success: success,
      bytesTransferred: bytesTransferred,
    );
  }
  
  /// Record UI rendering performance
  void recordUiRender({
    required String component,
    required int frameTimeMs,
    required int droppedFrames,
  }) {
    _telemetry.recordUiRender(
      component: component,
      frameTimeMs: frameTimeMs,
      droppedFrames: droppedFrames,
    );
  }
  
  /// Record memory usage
  void recordMemoryUsage({
    required int usedMemoryMB,
    required int maxMemoryMB,
    required int gcCount,
  }) {
    _telemetry.recordMemoryUsage(
      usedMemoryMB: usedMemoryMB,
      maxMemoryMB: maxMemoryMB,
      gcCount: gcCount,
    );
  }
  
  /// Record download frequency for cache management
  void recordDownloadFrequency(String contentType) {
    _telemetry.recordDownloadFrequency(contentType);
  }
  
  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    return _telemetry.getSummary();
  }
  
  /// Check if performance is degraded
  bool isPerformanceDegraded() {
    final summary = getPerformanceSummary();
    
    // Check various performance indicators
    return summary.averageNetworkTime > 3000 || // 3 seconds
           summary.averageFrameTime > 16 || // 60fps = 16.67ms per frame
           summary.memoryUsagePercent > 80 || // 80% memory usage
           summary.errorRate > 0.1 || // 10% error rate
           summary.cacheHitRate < 0.6; // 60% cache hit rate
  }
  
  /// Get performance recommendations
  List<String> getPerformanceRecommendations() {
    final summary = getPerformanceSummary();
    final recommendations = <String>[];
    
    if (summary.averageNetworkTime > 3000) {
      recommendations.add('Network performance is slow. Consider implementing offline caching.');
    }
    
    if (summary.averageFrameTime > 16) {
      recommendations.add('UI rendering is slow. Optimize widget rebuilds and use ListView.builder.');
    }
    
    if (summary.memoryUsagePercent > 80) {
      recommendations.add('High memory usage detected. Implement proper cleanup and dispose resources.');
    }
    
    if (summary.errorRate > 0.1) {
      recommendations.add('High error rate detected. Review error handling and network resilience.');
    }
    
    if (summary.cacheHitRate < 0.6) {
      recommendations.add('Low cache hit rate. Optimize caching strategy and TTL values.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable parameters.');
    }
    
    return recommendations;
  }
  
  /// Check performance health and trigger optimizations
  void _checkPerformanceHealth() {
    if (isPerformanceDegraded()) {
      _telemetry.recordPerformanceDegradation();
      
      // Log performance issues for debugging
      if (kDebugMode) {
        final summary = getPerformanceSummary();
        debugPrint('⚠️ Performance degradation detected:');
        debugPrint('  Network time: ${summary.averageNetworkTime}ms');
        debugPrint('  Frame time: ${summary.averageFrameTime}ms');
        debugPrint('  Memory usage: ${summary.memoryUsagePercent}%');
        debugPrint('  Error rate: ${summary.errorRate}');
        debugPrint('  Cache hit rate: ${summary.cacheHitRate}');
      }
    }
  }
  
  /// Record app startup time
  void _recordAppStartup() {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Record startup completion when app is ready
    Future.delayed(const Duration(seconds: 2), () {
      final startupTime = DateTime.now().millisecondsSinceEpoch - startTime;
      _telemetry.recordAppStartup(startupTime);
    });
  }
  
  /// Dispose monitoring resources
  void dispose() {
    _optimizationTimer?.cancel();
  }
}

/// Performance telemetry data collector
class PerformanceTelemetry {
  final List<NetworkOperation> _networkOperations = [];
  final List<UiRenderEvent> _uiRenderEvents = [];
  final List<MemoryUsage> _memoryUsages = [];
  final Map<String, int> _downloadFrequencies = {};
  final List<int> _appStartups = [];
  int _performanceDegradations = 0;
  
  void recordNetworkOperation({
    required String operation,
    required int durationMs,
    required bool success,
    int? bytesTransferred,
  }) {
    _networkOperations.add(NetworkOperation(
      operation: operation,
      durationMs: durationMs,
      success: success,
      bytesTransferred: bytesTransferred,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    
    // Keep only last 100 operations
    if (_networkOperations.length > 100) {
      _networkOperations.removeAt(0);
    }
  }
  
  void recordUiRender({
    required String component,
    required int frameTimeMs,
    required int droppedFrames,
  }) {
    _uiRenderEvents.add(UiRenderEvent(
      component: component,
      frameTimeMs: frameTimeMs,
      droppedFrames: droppedFrames,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    
    // Keep only last 50 render events
    if (_uiRenderEvents.length > 50) {
      _uiRenderEvents.removeAt(0);
    }
  }
  
  void recordMemoryUsage({
    required int usedMemoryMB,
    required int maxMemoryMB,
    required int gcCount,
  }) {
    _memoryUsages.add(MemoryUsage(
      usedMemoryMB: usedMemoryMB,
      maxMemoryMB: maxMemoryMB,
      gcCount: gcCount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    
    // Keep only last 10 memory readings
    if (_memoryUsages.length > 10) {
      _memoryUsages.removeAt(0);
    }
  }
  
  void recordDownloadFrequency(String contentType) {
    _downloadFrequencies[contentType] = (_downloadFrequencies[contentType] ?? 0) + 1;
  }
  
  void recordAppStartup(int startupTimeMs) {
    _appStartups.add(startupTimeMs);
    
    // Keep only last 5 startups
    if (_appStartups.length > 5) {
      _appStartups.removeAt(0);
    }
  }
  
  void recordPerformanceDegradation() {
    _performanceDegradations++;
  }
  
  PerformanceSummary getSummary() {
    return PerformanceSummary(
      networkOperations: List.from(_networkOperations),
      uiRenderEvents: List.from(_uiRenderEvents),
      memoryUsages: List.from(_memoryUsages),
      downloadFrequencies: Map.from(_downloadFrequencies),
      appStartups: List.from(_appStartups),
      performanceDegradations: _performanceDegradations,
    );
  }
}

/// Network operation tracking
class NetworkOperation {
  final String operation;
  final int durationMs;
  final bool success;
  final int? bytesTransferred;
  final int timestamp;
  
  NetworkOperation({
    required this.operation,
    required this.durationMs,
    required this.success,
    this.bytesTransferred,
    required this.timestamp,
  });
}

/// UI render event tracking
class UiRenderEvent {
  final String component;
  final int frameTimeMs;
  final int droppedFrames;
  final int timestamp;
  
  UiRenderEvent({
    required this.component,
    required this.frameTimeMs,
    required this.droppedFrames,
    required this.timestamp,
  });
}

/// Memory usage tracking
class MemoryUsage {
  final int usedMemoryMB;
  final int maxMemoryMB;
  final int gcCount;
  final int timestamp;
  
  MemoryUsage({
    required this.usedMemoryMB,
    required this.maxMemoryMB,
    required this.gcCount,
    required this.timestamp,
  });
  
  double get usagePercent {
    if (maxMemoryMB == 0) return 0.0;
    return (usedMemoryMB / maxMemoryMB) * 100;
  }
}

/// Complete performance summary
class PerformanceSummary {
  final List<NetworkOperation> networkOperations;
  final List<UiRenderEvent> uiRenderEvents;
  final List<MemoryUsage> memoryUsages;
  final Map<String, int> downloadFrequencies;
  final List<int> appStartups;
  final int performanceDegradations;
  
  PerformanceSummary({
    required this.networkOperations,
    required this.uiRenderEvents,
    required this.memoryUsages,
    required this.downloadFrequencies,
    required this.appStartups,
    required this.performanceDegradations,
  });
  
  double get averageNetworkTime {
    if (networkOperations.isEmpty) return 0.0;
    final totalTime = networkOperations.fold(0, (sum, op) => sum + op.durationMs);
    return totalTime / networkOperations.length;
  }
  
  double get averageFrameTime {
    if (uiRenderEvents.isEmpty) return 0.0;
    final totalTime = uiRenderEvents.fold(0, (sum, event) => sum + event.frameTimeMs);
    return totalTime / uiRenderEvents.length;
  }
  
  double get memoryUsagePercent {
    if (memoryUsages.isEmpty) return 0.0;
    final latest = memoryUsages.last;
    return latest.usagePercent;
  }
  
  double get errorRate {
    if (networkOperations.isEmpty) return 0.0;
    final errorCount = networkOperations.where((op) => !op.success).length;
    return errorCount / networkOperations.length;
  }
  
  double get cacheHitRate {
    // This would be connected to cache service statistics
    // For now, return a placeholder
    return 0.8;
  }
  
  int get totalDownloads {
    return downloadFrequencies.values.fold(0, (sum, count) => sum + count);
  }
  
  double get averageStartupTime {
    if (appStartups.isEmpty) return 0.0;
    return appStartups.reduce((a, b) => a + b) / appStartups.length;
  }
}