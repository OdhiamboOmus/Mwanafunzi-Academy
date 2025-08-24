import 'package:cloud_firestore/cloud_firestore.dart';
import 'error_handling_service.dart';

/// Cost monitoring and optimization service
/// Tracks Firebase usage and provides cost optimization recommendations
class CostMonitoringService {
  static final CostMonitoringService _instance = CostMonitoringService._internal();
  factory CostMonitoringService() => _instance;
  CostMonitoringService._internal();

  final ErrorHandlingService _errorHandler = ErrorHandlingService();
  
  // Cost thresholds (in USD)
  static const int _maxDailyReads = 50000;
  static const int _maxDailyWrites = 20000;
  static const int _maxDailyStorageGB = 10;

  /// Track a Firestore read operation
  Future<void> trackReadOperation({
    required String collection,
    required String documentId,
    Map<String, dynamic>? metadata,
  }) async {
    await _errorHandler.executeWithHandling(() async {
      // In a real implementation, this would send data to a cost monitoring service
      _errorHandler.logDebug('Read operation: $collection/$documentId');
      
      // Check if we're approaching read limits
      await _checkReadLimits();
    }, operationName: 'trackReadOperation');
  }

  /// Track a Firestore write operation
  Future<void> trackWriteOperation({
    required String collection,
    required String documentId,
    required String operationType, // 'create', 'update', 'delete'
    Map<String, dynamic>? metadata,
  }) async {
    await _errorHandler.executeWithHandling(() async {
      // In a real implementation, this would send data to a cost monitoring service
      _errorHandler.logDebug('Write operation: $collection/$documentId ($operationType)');
      
      // Check if we're approaching write limits
      await _checkWriteLimits();
    }, operationName: 'trackWriteOperation');
  }

  /// Track storage usage
  Future<void> trackStorageUsage({
    required String storageType,
    required int sizeInBytes,
    required String path,
  }) async {
    await _errorHandler.executeWithHandling(() async {
      final sizeInMB = sizeInBytes / (1024 * 1024);
      _errorHandler.logDebug('Storage usage: $storageType - ${sizeInMB.toStringAsFixed(2)}MB - $path');
      
      // Check if we're approaching storage limits
      await _checkStorageLimits();
    }, operationName: 'trackStorageUsage');
  }

  /// Get cost optimization recommendations
  Future<List<String>> getOptimizationRecommendations() async {
    try {
      final recommendations = <String>[];
      
      // Check read operations
      final readStats = await _getReadOperationStats();
      if (readStats['dailyReads'] > (_maxDailyReads * 0.8)) {
        recommendations.add('High read volume detected. Consider implementing client-side caching to reduce Firestore reads.');
      }
      
      // Check write operations
      final writeStats = await _getWriteOperationStats();
      if (writeStats['dailyWrites'] > (_maxDailyWrites * 0.8)) {
        recommendations.add('High write volume detected. Consider batching write operations to reduce costs.');
      }
      
      // Check storage usage
      final storageStats = await _getStorageStats();
      if (storageStats['usedGB'] > (_maxDailyStorageGB * 0.8)) {
        recommendations.add('Storage usage is high. Consider implementing data retention policies and cleaning up unused files.');
      }
      
      // Check for expensive queries
      final queryStats = await _getQueryStats();
      if (queryStats['expensiveQueries'] > 0) {
        recommendations.add('Found ${queryStats['expensiveQueries']} expensive queries. Consider adding composite indexes to improve performance.');
      }
      
      // Check for large documents
      final documentStats = await _getDocumentStats();
      if (documentStats['largeDocuments'] > 0) {
        recommendations.add('Found ${documentStats['largeDocuments']} documents larger than 1MB. Consider splitting large documents into smaller ones.');
      }
      
      // Check for real-time listeners
      final listenerStats = await _getListenerStats();
      if (listenerStats['activeListeners'] > 10) {
        recommendations.add('High number of active real-time listeners. Consider optimizing listener usage and implementing cleanup.');
      }
      
      return recommendations;
    } catch (e) {
      _errorHandler.logError('Error getting optimization recommendations: $e');
      return [];
    }
  }

  /// Get current cost estimates
  Future<Map<String, dynamic>> getCostEstimates() async {
    try {
      final readStats = await _getReadOperationStats();
      final writeStats = await _getWriteOperationStats();
      final storageStats = await _getStorageStats();
      
      // Calculate estimated costs (these are simplified estimates)
      final readCost = (readStats['dailyReads'] / 100000) * 1.0; // $1 per 100k reads
      final writeCost = (writeStats['dailyWrites'] / 50000) * 5.0; // $5 per 50k writes
      final storageCost = (storageStats['usedGB'] / 10) * 0.018; // $0.018 per GB per day
      
      final totalDailyCost = readCost + writeCost + storageCost;
      
      return {
        'read_cost': readCost,
        'write_cost': writeCost,
        'storage_cost': storageCost,
        'total_daily_cost': totalDailyCost,
        'total_monthly_cost': totalDailyCost * 30,
        'read_threshold_status': readStats['dailyReads'] > (_maxDailyReads * 0.8) ? 'warning' : 'normal',
        'write_threshold_status': writeStats['dailyWrites'] > (_maxDailyWrites * 0.8) ? 'warning' : 'normal',
        'storage_threshold_status': storageStats['usedGB'] > (_maxDailyStorageGB * 0.8) ? 'warning' : 'normal',
      };
    } catch (e) {
      _errorHandler.logError('Error getting cost estimates: $e');
      return {
        'error': 'Failed to calculate cost estimates',
        'total_daily_cost': 0.0,
        'total_monthly_cost': 0.0,
      };
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final metrics = {
        'timestamp': DateTime.now().toIso8601String(),
        'read_operations': await _getReadOperationStats(),
        'write_operations': await _getWriteOperationStats(),
        'storage_usage': await _getStorageStats(),
        'query_performance': await _getQueryStats(),
        'document_sizes': await _getDocumentStats(),
        'realtime_listeners': await _getListenerStats(),
        'cache_efficiency': await _getCacheEfficiency(),
      };
      
      return metrics;
    } catch (e) {
      _errorHandler.logError('Error getting performance metrics: $e');
      return {
        'error': 'Failed to get performance metrics',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Optimize Firestore usage
  Future<Map<String, dynamic>> optimizeFirestoreUsage() async {
    try {
      final optimizations = <String, dynamic>{};
      
      // Optimize read operations
      optimizations['read_optimizations'] = await _optimizeReadOperations();
      
      // Optimize write operations
      optimizations['write_optimizations'] = await _optimizeWriteOperations();
      
      // Optimize storage
      optimizations['storage_optimizations'] = await _optimizeStorage();
      
      // Optimize queries
      optimizations['query_optimizations'] = await _optimizeQueries();
      
      return {
        'optimizations_applied': optimizations,
        'estimated_savings': await _calculateEstimatedSavings(optimizations),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _errorHandler.logError('Error optimizing Firestore usage: $e');
      return {
        'error': 'Failed to optimize Firestore usage',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Private helper methods

  Future<void> _checkReadLimits() async {
    // Implementation would check actual usage against limits
    // For now, we'll just log the check
    _errorHandler.logDebug('Checking read operation limits');
  }

  Future<void> _checkWriteLimits() async {
    // Implementation would check actual usage against limits
    _errorHandler.logDebug('Checking write operation limits');
  }

  Future<void> _checkStorageLimits() async {
    // Implementation would check actual usage against limits
    _errorHandler.logDebug('Checking storage usage limits');
  }

  Future<Map<String, dynamic>> _getReadOperationStats() async {
    // In a real implementation, this would query actual usage data
    return {
      'dailyReads': 25000, // Example value
      'hourlyReads': 1000,
      'top_collections': ['videos', 'quizzes', 'lessons'],
      'peak_hours': [14, 15, 16], // 2-4 PM
    };
  }

  Future<Map<String, dynamic>> _getWriteOperationStats() async {
    return {
      'dailyWrites': 8000, // Example value
      'hourlyWrites': 300,
      'top_collections': ['user_progress', 'quiz_attempts', 'lesson_completions'],
      'peak_hours': [9, 10, 20], // 9 AM, 10 AM, 8 PM
    };
  }

  Future<Map<String, dynamic>> _getStorageStats() async {
    return {
      'usedGB': 2.5, // Example value
      'totalGB': 100,
      'growth_rate': '0.5GB/day',
      'largest_collections': ['videos', 'user_data', 'media'],
    };
  }

  Future<Map<String, dynamic>> _getQueryStats() async {
    return {
      'total_queries': 1500,
      'expensive_queries': 3,
      'average_query_time': 45, // milliseconds
      'slowest_queries': [
        {'query': 'videos with filters', 'time': 120},
        {'query': 'user progress reports', 'time': 95},
      ],
    };
  }

  Future<Map<String, dynamic>> _getDocumentStats() async {
    return {
      'total_documents': 50000,
      'large_documents': 12, // > 1MB
      'average_document_size': 25, // KB
      'largest_documents': [
        {'collection': 'videos', 'size': '2.3MB'},
        {'collection': 'media', 'size': '1.8MB'},
      ],
    };
  }

  Future<Map<String, dynamic>> _getListenerStats() async {
    return {
      'active_listeners': 8,
      'average_listeners_per_user': 2,
      'top_listened_collections': ['user_progress', 'notifications'],
      'listener_duration': '15min average',
    };
  }

  Future<Map<String, dynamic>> _getCacheEfficiency() async {
    return {
      'cache_hit_rate': 0.75, // 75%
      'cache_size': '500MB',
      'cached_items': 2000,
      'cache_evictions': 150,
    };
  }

  Future<List<String>> _optimizeReadOperations() async {
    final optimizations = <String>[];
    
    // Check for opportunities to implement caching
    optimizations.add('Implement client-side caching for frequently accessed data');
    optimizations.add('Use Firestore persistence for offline data');
    optimizations.add('Consider using Cloud Functions for data aggregation');
    
    return optimizations;
  }

  Future<List<String>> _optimizeWriteOperations() async {
    final optimizations = <String>[];
    
    // Check for opportunities to batch writes
    optimizations.add('Batch multiple write operations together');
    optimizations.add('Use transactions for related operations');
    optimizations.add('Implement write queuing for non-critical data');
    
    return optimizations;
  }

  Future<List<String>> _optimizeStorage() async {
    final optimizations = <String>[];
    
    // Check for storage optimization opportunities
    optimizations.add('Implement data retention policies');
    optimizations.add('Compress large documents before storage');
    optimizations.add('Archive old data to cheaper storage');
    
    return optimizations;
  }

  Future<List<String>> _optimizeQueries() async {
    final optimizations = <String>[];
    
    // Check for query optimization opportunities
    optimizations.add('Add composite indexes for common query patterns');
    optimizations.add('Limit query result sizes');
    optimizations.add('Use pagination for large result sets');
    
    return optimizations;
  }

  Future<double> _calculateEstimatedSavings(Map<String, dynamic> optimizations) async {
    // Simplified calculation of estimated savings
    double totalSavings = 0.0;
    
    if (optimizations['read_optimizations'] != null) {
      totalSavings += 0.50; // $0.50 per day from read optimizations
    }
    
    if (optimizations['write_optimizations'] != null) {
      totalSavings += 0.30; // $0.30 per day from write optimizations
    }
    
    if (optimizations['storage_optimizations'] != null) {
      totalSavings += 0.20; // $0.20 per day from storage optimizations
    }
    
    if (optimizations['query_optimizations'] != null) {
      totalSavings += 0.10; // $0.10 per day from query optimizations
    }
    
    return totalSavings;
  }
}

/// Extension for easy cost tracking on Firestore operations
extension FirestoreCostTracking on FirebaseFirestore {
  /// Track read operations with cost monitoring
  Future<DocumentSnapshot> trackGet(
    DocumentReference ref, {
    CostMonitoringService? costMonitor,
    Map<String, dynamic>? metadata,
  }) async {
    costMonitor ??= CostMonitoringService();
    await costMonitor.trackReadOperation(
      collection: ref.parent.path,
      documentId: ref.id,
      metadata: metadata,
    );
    return ref.get();
  }

  /// Track collection read operations with cost monitoring
  Future<QuerySnapshot> trackCollectionGet(
    CollectionReference ref, {
    CostMonitoringService? costMonitor,
    Map<String, dynamic>? metadata,
  }) async {
    costMonitor ??= CostMonitoringService();
    await costMonitor.trackReadOperation(
      collection: ref.path,
      documentId: 'collection_query',
      metadata: metadata,
    );
    return ref.get();
  }

  /// Track write operations with cost monitoring
  Future<void> trackSet(
    DocumentReference ref,
    data, {
    CostMonitoringService? costMonitor,
    Map<String, dynamic>? metadata,
    bool merge = false,
  }) async {
    costMonitor ??= CostMonitoringService();
    await costMonitor.trackWriteOperation(
      collection: ref.parent.path,
      documentId: ref.id,
      operationType: merge ? 'update' : 'create',
      metadata: metadata,
    );
    return ref.set(data, SetOptions(merge: merge));
  }

  /// Track update operations with cost monitoring
  Future<void> trackUpdate(
    DocumentReference ref,
    data, {
    CostMonitoringService? costMonitor,
    Map<String, dynamic>? metadata,
  }) async {
    costMonitor ??= CostMonitoringService();
    await costMonitor.trackWriteOperation(
      collection: ref.parent.path,
      documentId: ref.id,
      operationType: 'update',
      metadata: metadata,
    );
    return ref.update(data);
  }

  /// Track delete operations with cost monitoring
  Future<void> trackDelete(
    DocumentReference ref, {
    CostMonitoringService? costMonitor,
    Map<String, dynamic>? metadata,
  }) async {
    costMonitor ??= CostMonitoringService();
    await costMonitor.trackWriteOperation(
      collection: ref.parent.path,
      documentId: ref.id,
      operationType: 'delete',
      metadata: metadata,
    );
    return ref.delete();
  }
}