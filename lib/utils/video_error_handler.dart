import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive error handling for video operations
class VideoErrorHandler {
  /// Handle network errors with offline fallbacks
  static void handleNetworkError(dynamic error, StackTrace stackTrace, {String? operation}) {
    if (kDebugMode) {
      debugPrint('Network error in ${operation ?? "video operation"}: $error');
      debugPrint('Stack trace: $stackTrace');
    }
    
    // Log error for admin review
    _logErrorForAdmin('network_error', error.toString(), operation);
  }
  
  /// Handle YouTube integration errors for invalid videos
  static void handleYouTubeError(String videoId, dynamic error, {String? operation}) {
    if (kDebugMode) {
      debugPrint('YouTube error for video $videoId: $error');
      debugPrint('Operation: ${operation ?? "unknown"}');
    }
    
    // Mark video as unavailable in cache
    _markVideoAsUnavailable(videoId);
    
    // Log error for admin review
    _logErrorForAdmin('youtube_error', 'Video ID: $videoId, Error: $error', operation);
  }
  
  /// Handle Firestore errors with retry mechanisms
  static Future<T?> handleFirestoreError<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T? defaultValue,
  }) async {
    int attempt = 0;
    dynamic lastError;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempt++;
        
        if (kDebugMode) {
          debugPrint('Firestore attempt $attempt failed for $operationName: $error');
        }
        
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt); // Exponential backoff
        }
      }
    }
    
    // All retries failed
    if (kDebugMode) {
      debugPrint('Firestore operation failed after $maxRetries attempts: $lastError');
    }
    
    _logErrorForAdmin('firestore_error', 'Operation: $operationName, Error: $lastError', 'retry_failed');
    throw Exception('Failed to $operationName after $maxRetries attempts');
  }
  
  /// Handle WebView errors and recovery
  static void handleWebViewError(String videoId, dynamic error, {String? operation}) {
    if (kDebugMode) {
      debugPrint('WebView error for video $videoId: $error');
      debugPrint('Operation: ${operation ?? "unknown"}');
    }
    
    // Log error for admin review
    _logErrorForAdmin('webview_error', 'Video ID: $videoId, Error: $error', operation);
    
    // Provide alternative content suggestions
    _suggestAlternativeContent(videoId);
  }
  
  /// Handle general video loading errors
  static void handleVideoLoadError(dynamic error, StackTrace stackTrace, {String? videoId, String? operation}) {
    if (kDebugMode) {
      debugPrint('Video load error: $error');
      debugPrint('Video ID: $videoId, Operation: ${operation ?? "unknown"}');
      debugPrint('Stack trace: $stackTrace');
    }
    
    // Log error for admin review
    _logErrorForAdmin('video_load_error', 
      'Video ID: $videoId, Error: $error, Operation: $operation', 
      'video_load');
  }
  
  /// Handle cache errors
  static void handleCacheError(dynamic error, {String? operation}) {
    if (kDebugMode) {
      debugPrint('Cache error: $error');
      debugPrint('Operation: ${operation ?? "unknown"}');
    }
    
    _logErrorForAdmin('cache_error', error.toString(), operation);
  }
  
  /// Log errors for admin review
  static Future<void> _logErrorForAdmin(String errorType, String errorMessage, String? operation) async {
    try {
      // In a real implementation, this would send errors to Firestore or an error tracking service
      // For now, we'll just log with timestamp
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'errorType': errorType,
        'errorMessage': errorMessage,
        'operation': operation ?? 'unknown',
        'userId': 'current_user', // In real app, get from auth
      };
      
      if (kDebugMode) {
        debugPrint('Error logged: $logEntry');
      }
      
      // TODO: Implement actual error logging to Firestore admin collection
      // await FirebaseFirestore.instance.collection('video_errors').add(logEntry);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log error for admin: $e');
      }
    }
  }
  
  /// Mark video as unavailable in cache
  static Future<void> _markVideoAsUnavailable(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unavailableKey = 'video_unavailable_$videoId';
      await prefs.setBool(unavailableKey, true);
      
      // Set expiration time (24 hours)
      final expireKey = 'video_unavailable_expire_$videoId';
      final expireTime = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
      await prefs.setInt(expireKey, expireTime);
      
      if (kDebugMode) {
        debugPrint('Marked video $videoId as unavailable');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to mark video as unavailable: $e');
      }
    }
  }
  
  /// Check if video is marked as unavailable
  static Future<bool> isVideoUnavailable(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unavailableKey = 'video_unavailable_$videoId';
      final expireKey = 'video_unavailable_expire_$videoId';
      
      final isUnavailable = prefs.getBool(unavailableKey) ?? false;
      final expireTime = prefs.getInt(expireKey) ?? 0;
      
      // Check if expiration time has passed
      if (expireTime > 0 && DateTime.now().millisecondsSinceEpoch > expireTime) {
        // Clean up expired entry
        await prefs.remove(unavailableKey);
        await prefs.remove(expireKey);
        return false;
      }
      
      return isUnavailable;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking video availability: $e');
      }
      return false;
    }
  }
  
  /// Suggest alternative content when video fails
  static Future<void> _suggestAlternativeContent(String failedVideoId) async {
    try {
      // In a real implementation, this would fetch alternative videos from Firestore
      // For now, we'll just log the suggestion
      if (kDebugMode) {
        debugPrint('Suggesting alternative content for failed video: $failedVideoId');
      }
      
      // TODO: Implement alternative content suggestion logic
      // This could involve:
      // 1. Finding similar videos by topic/subject
      // 2. Finding videos from the same grade level
      // 3. Showing popular videos in the same subject
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to suggest alternative content: $e');
      }
    }
  }
  
  /// Get user-friendly error message
  static String getUserFriendlyErrorMessage(dynamic error, {String? operation}) {
    if (error is NetworkException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is FirestoreException) {
      return 'Unable to load videos. Please try again later.';
    } else if (error is YouTubeException) {
      return 'Unable to load video. The video may be unavailable or private.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}

/// Custom exception classes for better error handling
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class FirestoreException implements Exception {
  final String message;
  FirestoreException(this.message);
  
  @override
  String toString() => message;
}

class YouTubeException implements Exception {
  final String message;
  YouTubeException(this.message);
  
  @override
  String toString() => message;
}