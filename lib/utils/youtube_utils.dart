/// YouTube URL parsing and validation utilities
class YouTubeUtils {
  /// Regular expression patterns for YouTube URLs
  static final RegExp _youtubeUrlPattern = RegExp(
    r'^(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
  );

  static final RegExp _videoIdPattern = RegExp(
    r'^[a-zA-Z0-9_-]{11}$',
  );

  /// Check if a string is a valid YouTube URL
  static bool isValidYouTubeUrl(String url) {
    if (url.isEmpty) return false;
    
    final trimmedUrl = url.trim();
    return _youtubeUrlPattern.hasMatch(trimmedUrl);
  }

  /// Extract video ID from YouTube URL
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    final trimmedUrl = url.trim();

    // Check if it's already a video ID
    if (_videoIdPattern.hasMatch(trimmedUrl)) {
      return trimmedUrl;
    }

    // Extract from URL
    final match = _youtubeUrlPattern.firstMatch(trimmedUrl);
    if (match != null && match.groupCount >= 4) {
      return match.group(4);
    }

    return null;
  }

  /// Normalize YouTube URL to standard watch URL
  static String normalizeUrl(String url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return url;

    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Get YouTube thumbnail URL with specified quality
  static String getThumbnailUrl(String videoId, {String quality = 'maxresdefault'}) {
    // Available qualities: default, mqdefault, hqdefault, sddefault, maxresdefault
    final validQualities = ['default', 'mqdefault', 'hqdefault', 'sddefault', 'maxresdefault'];
    final actualQuality = validQualities.contains(quality) ? quality : 'default';

    return 'https://img.youtube.com/vi/$videoId/$actualQuality.jpg';
  }

  /// Get YouTube embed URL
  static String getEmbedUrl(String videoId) {
    return 'https://www.youtube.com/embed/$videoId';
  }

  /// Get YouTube watch URL
  static String getWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Check if video ID is valid format
  static bool isValidVideoId(String videoId) {
    return _videoIdPattern.hasMatch(videoId);
  }

  /// Extract video ID from various YouTube URL formats
  static String? extractVideoIdFromUrl(String url) {
    if (url.isEmpty) return null;

    final trimmedUrl = url.trim();

    // Handle youtu.be format
    if (trimmedUrl.contains('youtu.be/')) {
      final parts = trimmedUrl.split('youtu.be/');
      if (parts.length > 1) {
        final videoId = parts[1].split('?')[0].split('&')[0];
        if (isValidVideoId(videoId)) {
          return videoId;
        }
      }
    }

    // Handle youtube.com/watch?v= format
    if (trimmedUrl.contains('youtube.com/watch?v=')) {
      final parts = trimmedUrl.split('v=');
      if (parts.length > 1) {
        final videoId = parts[1].split('&')[0];
        if (isValidVideoId(videoId)) {
          return videoId;
        }
      }
    }

    // Handle youtube.com/embed/ format
    if (trimmedUrl.contains('youtube.com/embed/')) {
      final parts = trimmedUrl.split('embed/');
      if (parts.length > 1) {
        final videoId = parts[1].split('?')[0].split('&')[0];
        if (isValidVideoId(videoId)) {
          return videoId;
        }
      }
    }

    // Check if it's already a valid video ID
    if (isValidVideoId(trimmedUrl)) {
      return trimmedUrl;
    }

    return null;
  }

  /// Get all available thumbnail URLs for a video
  static Map<String, String> getAllThumbnailUrls(String videoId) {
    return {
      'default': getThumbnailUrl(videoId, quality: 'default'),
      'medium': getThumbnailUrl(videoId, quality: 'mqdefault'),
      'high': getThumbnailUrl(videoId, quality: 'hqdefault'),
      'standard': getThumbnailUrl(videoId, quality: 'sddefault'),
      'max': getThumbnailUrl(videoId, quality: 'maxresdefault'),
    };
  }

  /// Validate YouTube URL and return video ID if valid
  static String? validateAndGetVideoId(String url) {
    if (!isValidYouTubeUrl(url)) {
      return null;
    }
    return extractVideoId(url);
  }

  /// Check if URL is a YouTube embed URL
  static bool isEmbedUrl(String url) {
    return url.contains('youtube.com/embed/');
  }

  /// Check if URL is a YouTube short URL (youtu.be)
  static bool isShortUrl(String url) {
    return url.contains('youtu.be/');
  }

  /// Check if URL is a standard YouTube watch URL
  static bool isWatchUrl(String url) {
    return url.contains('youtube.com/watch?v=');
  }
}

/// Extension methods for String to add YouTube utilities
extension YouTubeStringExtension on String {
  /// Check if this string is a valid YouTube URL
  bool get isValidYouTubeUrl => YouTubeUtils.isValidYouTubeUrl(this);

  /// Extract video ID from this YouTube URL
  String? get extractVideoId => YouTubeUtils.extractVideoId(this);

  /// Normalize this YouTube URL to standard format
  String get normalizeYouTubeUrl => YouTubeUtils.normalizeUrl(this);

  /// Get video ID if this is a valid YouTube URL
  String? get validateAndGetVideoId => YouTubeUtils.validateAndGetVideoId(this);

  /// Check if this is a YouTube embed URL
  bool get isYouTubeEmbedUrl => YouTubeUtils.isEmbedUrl(this);

  /// Check if this is a YouTube short URL
  bool get isYouTubeShortUrl => YouTubeUtils.isShortUrl(this);

  /// Check if this is a YouTube watch URL
  bool get isYouTubeWatchUrl => YouTubeUtils.isWatchUrl(this);
}