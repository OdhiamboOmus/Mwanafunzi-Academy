import 'package:flutter/foundation.dart';

/// Centralized error handling and logging service
/// Provides consistent error handling across the application
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  /// Log informational message
  void logInfo(String message, {dynamic error, StackTrace? stackTrace}) {
    _logMessage('INFO', message, error: error, stackTrace: stackTrace);
  }

  /// Log debug message
  void logDebug(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logMessage('DEBUG', message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning message
  void logWarning(String message, {dynamic error, StackTrace? stackTrace}) {
    _logMessage('WARNING', message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    _logMessage('ERROR', message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error message
  void logFatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _logMessage('FATAL', message, error: error, stackTrace: stackTrace);
  }

  /// Internal logging method
  void _logMessage(String level, String message, {dynamic error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$level] $message';
    
    if (kDebugMode) {
      debugPrint(logEntry);
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack Trace: $stackTrace');
      }
    }
    
    // In production, you might want to send logs to a logging service
    if (!kDebugMode && level == 'ERROR') {
      // TODO: Implement production logging service
    }
  }

  /// Handle Firebase/Firestore errors with user-friendly messages
  String handleFirebaseError(dynamic error) {
    logError('Firebase error occurred: $error');
    
    if (error.toString().contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    } else if (error.toString().contains('unauthenticated')) {
      return 'Please sign in to continue.';
    } else if (error.toString().contains('not-found')) {
      return 'The requested resource was not found.';
    } else if (error.toString().contains('already-exists')) {
      return 'This resource already exists.';
    } else if (error.toString().contains('invalid-argument')) {
      return 'Invalid data provided. Please check your input.';
    } else if (error.toString().contains('deadline-exceeded')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('unavailable')) {
      return 'Service is currently unavailable. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle network errors with user-friendly messages
  String handleNetworkError(dynamic error) {
    logError('Network error occurred: $error');
    
    if (error.toString().contains('Connection refused')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (error.toString().contains('Timeout')) {
      return 'Request timed out. Please check your internet connection and try again.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network settings.';
    } else {
      return 'Network error occurred. Please try again.';
    }
  }

  /// Handle parsing errors with user-friendly messages
  String handleParsingError(dynamic error, String context) {
    logError('Parsing error in $context: $error');
    return 'Unable to process the data. Please try again.';
  }

  /// Handle validation errors with user-friendly messages
  String handleValidationError(String field, String? message) {
    logError('Validation error for field $field: $message');
    return message ?? 'Invalid input for $field.';
  }

  /// Wrap async operations with error handling
  Future<T> executeWithHandling<T>(
    Future<T> Function() operation, {
    String operationName = 'Operation',
    T Function()? fallback,
  }) async {
    try {
      logDebug('Starting $operationName');
      final result = await operation();
      logDebug('Successfully completed $operationName');
      return result;
    } catch (error, stackTrace) {
      logError('Error in $operationName: $error', stackTrace: stackTrace);
      
      if (fallback != null) {
        logDebug('Using fallback for $operationName');
        return fallback();
      }
      
      rethrow;
    }
  }

  /// Wrap async operations with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'Operation',
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt <= maxRetries) {
      try {
        logDebug('Attempt ${attempt + 1} for $operationName');
        final result = await operation();
        logDebug('Successfully completed $operationName on attempt ${attempt + 1}');
        return result;
      } catch (error, stackTrace) {
        attempt++;
        logError('Attempt $attempt failed for $operationName: $error', stackTrace: stackTrace);
        
        if (attempt > maxRetries) {
          logError('Max retries exceeded for $operationName');
          rethrow;
        }
        
        logDebug('Retrying $operationName in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay = delay < maxDelay ? delay * 2 : maxDelay;
      }
    }
    
    throw Exception('Max retries exceeded for $operationName');
  }

  /// Create a standardized error response
  Map<String, dynamic> createErrorResponse({
    required String code,
    required String message,
    dynamic details,
    StackTrace? stackTrace,
  }) {
    logError('Error response - Code: $code, Message: $message', stackTrace: stackTrace);
    
    return {
      'success': false,
      'error': {
        'code': code,
        'message': message,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Create a standardized success response
  Map<String, dynamic> createSuccessResponse({
    required String message,
    dynamic data,
  }) {
    logDebug('Success response - Message: $message');
    
    return {
      'success': true,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get formatted error message for UI display
  String getFormattedErrorMessage(dynamic error, {String context = ''}) {
    String message;
    
    if (error is String) {
      message = error;
    } else if (error is Exception) {
      message = error.toString();
    } else {
      message = 'An unknown error occurred';
    }
    
    // Remove technical details for user-friendly display
    message = message.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    message = message.replaceAll(RegExp(r'Exception:'), '').trim();
    message = message.replaceAll(RegExp(r'Error:'), '').trim();
    
    if (context.isNotEmpty) {
      message = '$context: $message';
    }
    
    return message.isNotEmpty ? message : 'An unexpected error occurred';
  }

  /// Log performance metrics
  void logPerformanceMetrics({
    required String operation,
    required Duration duration,
    int? itemCount,
    Map<String, dynamic>? additionalMetrics,
  }) {
    final metrics = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'item_count': itemCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (additionalMetrics != null) {
      metrics.addAll(additionalMetrics);
    }
    
    logDebug('Performance metrics: $metrics');
  }

  /// Log analytics event
  void logAnalyticsEvent({
    required String eventName,
    required Map<String, dynamic> parameters,
    bool isCritical = false,
  }) {
    final event = {
      'event_name': eventName,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
      'is_critical': isCritical,
    };
    
    if (isCritical) {
      logInfo('Analytics event: $event');
    } else {
      logDebug('Analytics event: $event');
    }
  }
}

/// Extension for easy error handling on Future operations
extension FutureErrorHandling<T> on Future<T> {
  /// Execute with error handling
  Future<T> withErrorHandling({
    String operationName = 'Operation',
    T Function()? fallback,
    ErrorHandlingService? errorHandler,
  }) async {
    errorHandler ??= ErrorHandlingService();
    return errorHandler.executeWithHandling(
      () => this,
      operationName: operationName,
      fallback: fallback,
    );
  }

  /// Execute with retry logic
  Future<T> withRetry({
    String operationName = 'Operation',
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    ErrorHandlingService? errorHandler,
  }) async {
    errorHandler ??= ErrorHandlingService();
    return errorHandler.executeWithRetry(
      () => this,
      operationName: operationName,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
    );
  }
}

/// Extension for easy error handling on async operations
extension AsyncErrorHandling<T> on Future<T> Function() {
  /// Execute with error handling
  Future<T> withErrorHandling({
    String operationName = 'Operation',
    T Function()? fallback,
    ErrorHandlingService? errorHandler,
  }) async {
    errorHandler ??= ErrorHandlingService();
    return errorHandler.executeWithHandling(
      this,
      operationName: operationName,
      fallback: fallback,
    );
  }

  /// Execute with retry logic
  Future<T> withRetry({
    String operationName = 'Operation',
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    ErrorHandlingService? errorHandler,
  }) async {
    errorHandler ??= ErrorHandlingService();
    return errorHandler.executeWithRetry(
      this,
      operationName: operationName,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
    );
  }
}