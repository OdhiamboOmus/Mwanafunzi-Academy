import 'package:flutter/foundation.dart';

/// Content validation and URL sanitization utilities
class ContentValidator {
  /// Validate and sanitize YouTube URLs
  static String? validateAndSanitizeYouTubeUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'URL is required';
    }

    final trimmedUrl = url.trim();
    
    // Basic URL format validation
    if (!_isValidUrl(trimmedUrl)) {
      return 'Invalid URL format';
    }

    // Check if it's a YouTube URL
    if (!_isValidYouTubeDomain(trimmedUrl)) {
      return 'Only YouTube URLs are allowed';
    }

    // Extract and validate video ID
    final videoId = _extractVideoId(trimmedUrl);
    if (videoId == null) {
      return 'Invalid YouTube video URL';
    }

    return null; // Valid URL
  }

  /// Basic URL validation without external dependencies
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasAbsolutePath && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if URL has valid YouTube domain
  static bool _isValidYouTubeDomain(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') || 
           lowerUrl.contains('youtu.be') ||
           lowerUrl.contains('youtube-nocookie.com');
  }

  /// Extract YouTube video ID from URL
  static String? _extractVideoId(String url) {
    try {
      // Handle youtu.be format
      if (url.contains('youtu.be/')) {
        final pathSegments = url.split('/');
        final videoIdSegment = pathSegments.last.split('?').first;
        if (videoIdSegment.length == 11) {
          return videoIdSegment;
        }
      }
      
      // Handle youtube.com format
      if (url.contains('youtube.com/')) {
        final uri = Uri.parse(url);
        final videoId = uri.queryParameters['v'];
        if (videoId != null && videoId.length == 11) {
          return videoId;
        }
        
        // Handle /embed/ and /v/ formats
        final pathSegments = uri.pathSegments;
        final embedIndex = pathSegments.indexOf('embed');
        if (embedIndex != -1 && embedIndex + 1 < pathSegments.length) {
          return pathSegments[embedIndex + 1];
        }
        
        final vIndex = pathSegments.indexOf('v');
        if (vIndex != -1 && vIndex + 1 < pathSegments.length) {
          return pathSegments[vIndex + 1];
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error extracting video ID: $e');
      }
      return null;
    }
  }

  /// Validate video title and description
  static String? validateVideoContent({
    required String title,
    required String description,
    int maxTitleLength = 100,
    int maxDescriptionLength = 500,
  }) {
    if (title.trim().isEmpty) {
      return 'Title is required';
    }
    
    if (title.length > maxTitleLength) {
      return 'Title must be less than $maxTitleLength characters';
    }
    
    if (description.trim().isEmpty) {
      return 'Description is required';
    }
    
    if (description.length > maxDescriptionLength) {
      return 'Description must be less than $maxDescriptionLength characters';
    }
    
    // Check for inappropriate content (basic check)
    final inappropriateWords = _getInappropriateWords();
    final lowerTitle = title.toLowerCase();
    final lowerDescription = description.toLowerCase();
    
    for (final word in inappropriateWords) {
      if (lowerTitle.contains(word) || lowerDescription.contains(word)) {
        return 'Content contains inappropriate language';
      }
    }
    
    return null; // Valid content
  }

  /// Get list of inappropriate words for content filtering
  static List<String> _getInappropriateWords() {
    // In a real app, this would be loaded from a database or configuration
    return [
      'inappropriate1', 'inappropriate2', 'badword1', 'badword2'
    ];
  }

  /// Validate grade, subject, and topic structure
  static String? validateVideoStructure({
    required String grade,
    required String subject,
    required String topic,
  }) {
    if (grade.trim().isEmpty) {
      return 'Grade is required';
    }
    
    if (subject.trim().isEmpty) {
      return 'Subject is required';
    }
    
    if (topic.trim().isEmpty) {
      return 'Topic is required';
    }
    
    // Validate grade format (e.g., "Grade 1", "Grade 10")
    if (!grade.startsWith('Grade ') || grade.length < 7) {
      return 'Grade must be in format "Grade X" where X is a number';
    }
    
    // Validate subject against allowed subjects
    final allowedSubjects = [
      'Mathematics', 'Science', 'English', 'Social Studies', 'Other'
    ];
    
    if (!allowedSubjects.contains(subject)) {
      return 'Invalid subject selected';
    }
    
    // Validate topic (should not contain special characters)
    if (_containsInvalidCharacters(topic)) {
      return 'Topic contains invalid characters';
    }
    
    return null; // Valid structure
  }

  /// Check if string contains invalid characters
  static bool _containsInvalidCharacters(String input) {
    final invalidChars = ['<', '>', '"', "'", '&'];
    for (final char in invalidChars) {
      if (input.contains(char)) {
        return true;
      }
    }
    return false;
  }

  /// Check if video duration is acceptable
  static bool isAcceptableDuration(Duration duration) {
    // Accept videos between 30 seconds and 30 minutes
    const minDuration = Duration(seconds: 30);
    const maxDuration = Duration(minutes: 30);
    
    return duration >= minDuration && duration <= maxDuration;
  }

  /// Generate audit log entry for content validation
  static Map<String, dynamic> generateValidationLog({
    required String action,
    required String url,
    required String title,
    required String grade,
    required String subject,
    required String topic,
    String? validationError,
    bool isValid = true,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'url': url,
      'title': title,
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'validationError': validationError,
      'isValid': isValid,
      'validationType': 'content_validation',
    };
  }

  /// Sanitize string for safe storage
  static String sanitizeString(String input) {
    // Remove potentially dangerous characters
    String result = input;
    result = result.replaceAll('<', '');
    result = result.replaceAll('>', '');
    result = result.replaceAll('"', '');
    result = result.replaceAll("'", '');
    result = result.replaceAll('&', '');
    
    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result.trim();
  }

  /// Validate admin permissions for video operations
  static Future<bool> validateAdminPermissions(String adminId, String operation) async {
    try {
      // In a real app, this would check against Firestore admin_users collection
      // and verify specific permissions for video operations
      
      if (kDebugMode) {
        debugPrint('Validating admin $adminId for operation: $operation');
      }
      
      // For now, assume all admins have video permissions
      // In production, you would implement proper permission checks
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error validating admin permissions: $e');
      }
      return false;
    }
  }
}