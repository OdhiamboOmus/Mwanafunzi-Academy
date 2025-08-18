import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for implementing retry logic with exponential backoff for network operations
/// Ensures robust network communication with automatic recovery

class RetryService {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 1000);
  static const Duration _maxDelay = Duration(seconds: 30);
  static const double _backoffMultiplier = 2.0;
  static const double _jitterFactor = 0.1; // 10% jitter to prevent thundering herd
  
  /// Execute an operation with retry logic and exponential backoff
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    bool Function(Exception)? shouldRetry,
    int maxRetries = _maxRetries,
    Duration initialDelay = _initialDelay,
    Duration maxDelay = _maxDelay,
    double backoffMultiplier = _backoffMultiplier,
    double jitterFactor = _jitterFactor,
  }) async {
    int attempt = 0;
    Exception? lastError;
    
    while (attempt < maxRetries) {
      attempt++;
      
      try {
        debugPrint('RetryService: Attempt $attempt for $operationName');
        final result = await operation();
        
        if (attempt > 1) {
          debugPrint('RetryService: Success on attempt $attempt for $operationName');
        }
        
        return result;
      } catch (e) {
        lastError = e as Exception;
        debugPrint('RetryService: Attempt $attempt failed for $operationName: $e');
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(lastError)) {
          debugPrint('RetryService: Not retrying $operationName due to error type: $e');
          break;
        }
        
        if (attempt < maxRetries) {
          // Calculate delay with exponential backoff and jitter
          final delay = _calculateDelay(
            attempt: attempt,
            initialDelay: initialDelay,
            maxDelay: maxDelay,
            multiplier: backoffMultiplier,
            jitterFactor: jitterFactor,
          );
          
          debugPrint('RetryService: Waiting $delay before retry $operationName');
          await Future.delayed(delay);
        }
      }
    }
    
    debugPrint('RetryService: All $maxRetries attempts failed for $operationName');
    throw lastError ?? Exception('Operation failed after $maxRetries attempts');
  }
  
  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay({
    required int attempt,
    required Duration initialDelay,
    required Duration maxDelay,
    required double multiplier,
    required double jitterFactor,
  }) {
    // Exponential backoff: initialDelay * (multiplier ^ (attempt - 1))
    double delayMs = initialDelay.inMilliseconds.toDouble() * pow(multiplier, attempt - 1);
    
    // Apply jitter (random variation)
    if (jitterFactor > 0) {
      final jitterRange = delayMs * jitterFactor;
      final jitter = (Random().nextDouble() * 2 - 1) * jitterRange;
      delayMs += jitter;
    }
    
    // Cap at maxDelay
    delayMs = min(delayMs, maxDelay.inMilliseconds.toDouble());
    
    return Duration(milliseconds: delayMs.round());
  }
  
  /// Common retry predicates for different error types
  static bool isNetworkError(Exception e) {
    return e.toString().contains('Network') ||
           e.toString().contains('Connection') ||
           e.toString().contains('Timeout') ||
           e.toString().contains('Socket') ||
           e.toString().contains('Failed host lookup');
  }
  
  static bool isServerError(Exception e) {
    return e.toString().contains('500') ||
           e.toString().contains('502') ||
           e.toString().contains('503') ||
           e.toString().contains('504');
  }
  
  static bool isRateLimitError(Exception e) {
    return e.toString().contains('429') ||
           e.toString().contains('Too Many Requests') ||
           e.toString().contains('Rate limit');
  }
  
  /// Retry with specific error handling
  static Future<T> executeWithSmartRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = _maxRetries,
  }) async {
    return executeWithRetry(
      operation: operation,
      operationName: operationName,
      maxRetries: maxRetries,
      shouldRetry: (e) {
        // Retry network errors and server errors, but not rate limit errors
        return isNetworkError(e) || isServerError(e);
      },
    );
  }
  
  /// Retry with progressive backoff for rate limiting
  static Future<T> executeWithRateLimitRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = _maxRetries,
  }) async {
    return executeWithRetry(
      operation: operation,
      operationName: operationName,
      maxRetries: maxRetries,
      initialDelay: Duration(seconds: 2), // Start with 2 seconds for rate limits
      shouldRetry: (e) {
        // Retry rate limit errors and network errors
        return isRateLimitError(e) || isNetworkError(e);
      },
    );
  }
  
  /// Execute with circuit breaker pattern
  static Future<T> executeWithCircuitBreaker<T>({
    required Future<T> Function() operation,
    required String operationName,
    int failureThreshold = 5,
    Duration recoveryTimeout = const Duration(minutes: 1),
  }) async {
    // This is a simplified circuit breaker implementation
    // In a production app, you'd want a more sophisticated implementation
    return executeWithRetry(
      operation: operation,
      operationName: operationName,
      maxRetries: 1, // Only try once after circuit breaker opens
      initialDelay: recoveryTimeout,
    );
  }
}
