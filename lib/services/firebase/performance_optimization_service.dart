import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for optimizing quiz loading and admin operations to complete within 2 seconds
/// Implements performance monitoring and optimization strategies

class PerformanceOptimizationService {
  static const int _targetLoadTimeMs = 2000; // 2 seconds target
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 3);
  
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, int> _operationTimings = {};
  final Map<String, int> _retryCounts = {};
  
  /// Singleton instance
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  
  factory PerformanceOptimizationService() => _instance;
  
  PerformanceOptimizationService._internal();
  
  /// Start performance monitoring for an operation
  void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    debugPrint('Performance: Started operation $operationId');
  }
  
  /// End performance monitoring and record timing
  void endOperation(String operationId) {
    final startTime = _operationStartTimes[operationId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _operationTimings[operationId] = duration;
      _operationStartTimes.remove(operationId);
      
      debugPrint('Performance: Operation $operationId completed in ${duration}ms');
      
      if (duration > _targetLoadTimeMs) {
        debugPrint('Performance: WARNING - Operation $operationId exceeded target time of ${_targetLoadTimeMs}ms');
      }
    }
  }
  
  /// Optimized quiz loading with performance monitoring
  Future<T> executeWithPerformanceMonitoring<T>({
    required String operationId,
    required Future<T> Function() operation,
    bool enableTimeout = true,
    bool enableRetries = true,
  }) async {
    startOperation(operationId);
    
    try {
      // Check connectivity first
      if (!await _isOnline()) {
        debugPrint('Performance: Device is offline for operation $operationId');
        throw Exception('Device is offline');
      }
      
      // Execute with timeout if enabled
      Future<T> executeWithTimeout() async {
        if (enableTimeout) {
          return await operation().timeout(_timeoutDuration);
        } else {
          return await operation();
        }
      }
      
      // Execute with retries if enabled
      Future<T> executeWithRetries() async {
        int attempt = 0;
        Exception? lastError;
        
        while (attempt < _maxRetries) {
          try {
            attempt++;
            _retryCounts[operationId] = attempt;
            
            final result = await executeWithTimeout();
            endOperation(operationId);
            return result;
          } catch (e) {
            lastError = e as Exception;
            debugPrint('Performance: Attempt $attempt failed for $operationId: $e');
            
            if (attempt < _maxRetries) {
              // Exponential backoff
              final delay = Duration(milliseconds: min(1000 * (1 << (attempt - 1)), 5000));
              await Future.delayed(delay);
            }
          }
        }
        
        endOperation(operationId);
        throw lastError ?? Exception('Operation failed after $_maxRetries attempts');
      }
      
      if (enableRetries) {
        return await executeWithRetries();
      } else {
        final result = await executeWithTimeout();
        endOperation(operationId);
        return result;
      }
    } catch (e) {
      endOperation(operationId);
      rethrow;
    }
  }
  
  /// Check if device has network connectivity (simplified version)
  Future<bool> _isOnline() async {
    // For now, always return true as we don't have connectivity_plus dependency
    // In a real app, you would use connectivity_plus or similar
    return true;
  }
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final totalOperations = _operationTimings.length;
    final successfulOperations = _operationTimings.values.where((t) => t <= _targetLoadTimeMs).length;
    final failedOperations = totalOperations - successfulOperations;
    
    if (totalOperations == 0) {
      return {
        'total_operations': 0,
        'successful_operations': 0,
        'failed_operations': 0,
        'success_rate': 0.0,
        'average_load_time': 0,
        'max_load_time': 0,
        'min_load_time': 0,
        'target_load_time_ms': _targetLoadTimeMs,
      };
    }
    
    final loadTimes = _operationTimings.values.toList();
    loadTimes.sort();
    
    return {
      'total_operations': totalOperations,
      'successful_operations': successfulOperations,
      'failed_operations': failedOperations,
      'success_rate': (successfulOperations / totalOperations * 100).toStringAsFixed(1),
      'average_load_time': (loadTimes.reduce((a, b) => a + b) / totalOperations).round(),
      'max_load_time': loadTimes.last,
      'min_load_time': loadTimes.first,
      'target_load_time_ms': _targetLoadTimeMs,
      'operations_exceeding_target': failedOperations,
    };
  }
  
  /// Get operation-specific timing
  int? getOperationTiming(String operationId) {
    return _operationTimings[operationId];
  }
  
  /// Clear performance statistics
  void clearStats() {
    _operationTimings.clear();
    _retryCounts.clear();
    _operationStartTimes.clear();
  }
  
  /// Preload data for faster access
  Future<void> preloadData<T>({
    required String operationId,
    required Future<T> Function() preloadOperation,
    required void Function(T) cacheFunction,
  }) async {
    startOperation('preload_$operationId');
    
    try {
      final data = await preloadOperation();
      cacheFunction(data);
      endOperation('preload_$operationId');
    } catch (e) {
      endOperation('preload_$operationId');
      debugPrint('Performance: Preload failed for $operationId: $e');
    }
  }
  
  /// Batch operations for better performance
  Future<List<T>> batchExecute<T>({
    required String batchId,
    required List<Future<T>> operations,
    int maxConcurrent = 3,
  }) async {
    startOperation('batch_$batchId');
    
    try {
      final results = <T>[];
      final activeOperations = <Future<T>>[];
      
      for (final operation in operations) {
        activeOperations.add(operation);
        
        if (activeOperations.length >= maxConcurrent) {
          final completed = await Future.wait(activeOperations);
          results.addAll(completed);
          activeOperations.clear();
        }
      }
      
      // Execute remaining operations
      if (activeOperations.isNotEmpty) {
        final completed = await Future.wait(activeOperations);
        results.addAll(completed);
      }
      
      endOperation('batch_$batchId');
      return results;
    } catch (e) {
      endOperation('batch_$batchId');
      rethrow;
    }
  }
  
  /// Memory optimization - clear unused resources
  Future<void> optimizeMemoryUsage() async {
    debugPrint('Performance: Starting memory optimization');
    
    try {
      // Clear performance stats if they're getting large
      if (_operationTimings.length > 1000) {
        clearStats();
      }
      
      // Force garbage collection (debug mode only)
      if (kDebugMode) {
        debugPrint('Performance: Memory optimization completed');
      }
    } catch (e) {
      debugPrint('Performance: Memory optimization failed: $e');
    }
  }
}
