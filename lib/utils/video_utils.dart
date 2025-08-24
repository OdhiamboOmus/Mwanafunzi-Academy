import 'package:flutter/material.dart' show debugPrint;

/// Unified video utilities for Mwanafunzi Academy
/// Consolidates VideoPerformanceManager, VideoErrorHandler, and YouTubeUtils
class VideoUtils {
  
  /// Get optimized YouTube thumbnail URL
  static String getOptimizedThumbnail(String videoId, {String quality = 'mqdefault'}) {
    // Use medium quality by default for faster loading
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }
  
  /// Validate YouTube URL format
  static bool isValidYouTubeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('youtube') || uri.host.contains('youtu.be');
    } catch (e) {
      debugPrint('Error validating YouTube URL: $e');
      return false;
    }
  }
  
  /// Extract video ID from YouTube URL
  static String? extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Handle youtu.be format
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
      
      // Handle youtube.com format
      if (uri.host.contains('youtube')) {
        return uri.queryParameters['v'];
      }
      
      return null;
    } catch (e) {
      debugPrint('Error extracting video ID: $e');
      return null;
    }
  }
  
  /// Create video player configuration (placeholder for actual implementation)
  static Map<String, dynamic> createVideoPlayerConfig(String videoUrl) {
    final videoId = extractVideoId(videoUrl);
    
    if (videoId == null) {
      throw Exception('Invalid YouTube URL: $videoUrl');
    }
    
    return {
      'videoId': videoId,
      'showControls': true,
      'showFullscreenButton': true,
      'autoPlay': false,
      'mute': false,
      'enableCaption': true,
      'showVideoAnnotations': false,
    };
  }
  
  /// Format video duration from seconds to readable format
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return remainingSeconds > 0 
          ? '$minutes min $remainingSeconds sec'
          : '$minutes min';
    } else {
      return '$remainingSeconds sec';
    }
  }
  
  /// Get video quality options for optimization
  static List<String> getQualityOptions() {
    return [
      'default',      // Default quality
      'mqdefault',    // Medium quality (320x180)
      'hqdefault',    // High quality (480x360)
      'sddefault',    // Standard definition (640x480)
      'maxresdefault' // Maximum resolution
    ];
  }
  
  /// Log video performance metrics
  static void logPerformanceMetrics({
    required String videoId,
    required String action,
    required int duration,
    String? error,
  }) {
    debugPrint('📊 Video Performance Metrics:');
    debugPrint('  Video ID: $videoId');
    debugPrint('  Action: $action');
    debugPrint('  Duration: ${formatDuration(duration)}');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    debugPrint('  Timestamp: ${DateTime.now().toIso8601String()}');
  }
  
  /// Handle common video errors
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      return 'Video error: ${error.toString()}';
    }
    
    if (error is String) {
      return 'Video error: $error';
    }
    
    return 'Unknown video error: $error';
  }
  
  /// Validate video URL for performance optimization
  static Map<String, dynamic> validateVideoUrl(String url) {
    final isValid = isValidYouTubeUrl(url);
    final videoId = extractVideoId(url);
    
    return {
      'is_valid': isValid,
      'video_id': videoId,
      'error': isValid ? null : 'Invalid YouTube URL format',
      'can_optimize': isValid && videoId != null,
    };
  }
  
  /// Get optimized video URL for better performance
  static String getOptimizedUrl(String url) {
    final validation = validateVideoUrl(url);
    
    if (!validation['is_valid'] || !validation['can_optimize']) {
      return url; // Return original URL if invalid
    }
    
    final videoId = validation['videoId'] as String?;
    if (videoId == null) {
      return url;
    }
    
    // Return embed URL for better performance
    return 'https://www.youtube.com/embed/$videoId';
  }
  
  /// Cache video metadata for performance
  static Future<void> cacheVideoMetadata({
    required String videoId,
    required String title,
    required String thumbnailUrl,
    required int duration,
  }) async {
    // In production, this would use shared_preferences or hive
    debugPrint('📝 Caching video metadata for: $videoId');
    debugPrint('  Title: $title');
    debugPrint('  Thumbnail: $thumbnailUrl');
    debugPrint('  Duration: ${formatDuration(duration)}');
  }
  
  /// Clear video cache when needed
  static Future<void> clearVideoCache() async {
    debugPrint('🧹 Clearing video cache...');
    // In production, this would clear shared_preferences or hive entries
    debugPrint('✅ Video cache cleared');
  }
}