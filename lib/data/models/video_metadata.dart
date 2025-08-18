import '../../utils/youtube_utils.dart';

/// Represents extracted video metadata from YouTube
class VideoMetadata {
  final String title;
  final Duration duration;
  final String thumbnailUrl;
  final String description;
  final bool isValid;
  final String? videoId;
  final String? author;
  final DateTime? publishedAt;
  final int? viewCount;
  final String? categoryId;
  final List<String>? tags;

  const VideoMetadata({
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.description,
    required this.isValid,
    this.videoId,
    this.author,
    this.publishedAt,
    this.viewCount,
    this.categoryId,
    this.tags,
  });

  /// Create from JSON
  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      title: json['title'] ?? '',
      duration: Duration(seconds: json['duration'] ?? 0),
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      description: json['description'] ?? '',
      isValid: json['isValid'] ?? false,
      videoId: json['videoId'],
      author: json['author'],
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt'])
          : null,
      viewCount: json['viewCount'],
      categoryId: json['categoryId'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration.inSeconds,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'isValid': isValid,
      'videoId': videoId,
      'author': author,
      'publishedAt': publishedAt?.toIso8601String(),
      'viewCount': viewCount,
      'categoryId': categoryId,
      'tags': tags,
    };
  }

  /// Create from YouTube URL (placeholder for actual API integration)
  static Future<VideoMetadata> fromYouTubeUrl(String url) async {
    // This is a placeholder implementation
    // In a real implementation, this would call YouTube's oEmbed API or Data API
    final videoId = YouTubeUtils.extractVideoId(url);
    
    if (videoId == null) {
      return const VideoMetadata(
        title: '',
        duration: Duration(seconds: 0),
        thumbnailUrl: '',
        description: '',
        isValid: false,
      );
    }

    // Simulate API call with mock data
    await Future.delayed(const Duration(milliseconds: 500));

    return VideoMetadata(
      title: 'Sample Video Title',
      duration: const Duration(minutes: 5, seconds: 30),
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
      description: 'This is a sample video description for educational purposes.',
      isValid: true,
      videoId: videoId,
      author: 'Sample Channel',
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
      viewCount: 12345,
      categoryId: '22',
      tags: ['education', 'tutorial', 'learning'],
    );
  }

  /// Create minimal metadata from video ID
  static VideoMetadata fromVideoId(String videoId) {
    return VideoMetadata(
      title: '',
      duration: const Duration(seconds: 0),
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/default.jpg',
      description: '',
      isValid: true,
      videoId: videoId,
    );
  }

  /// Copy with updated fields
  VideoMetadata copyWith({
    String? title,
    Duration? duration,
    String? thumbnailUrl,
    String? description,
    bool? isValid,
    String? videoId,
    String? author,
    DateTime? publishedAt,
    int? viewCount,
    String? categoryId,
    List<String>? tags,
  }) {
    return VideoMetadata(
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      isValid: isValid ?? this.isValid,
      videoId: videoId ?? this.videoId,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
    );
  }

  /// Get formatted duration (MM:SS)
  String get formattedDuration {
    if (!isValid) return '00:00';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get display title with fallback
  String get displayTitle => title.isNotEmpty ? title : 'Untitled Video';

  /// Get display author with fallback
  String get displayAuthor => author?.isNotEmpty == true ? author! : 'Unknown Author';

  /// Get formatted view count
  String get formattedViewCount {
    if (viewCount == null) return '';
    
    final count = viewCount!;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Get short description
  String get shortDescription {
    if (description.isEmpty) return '';
    
    if (description.length <= 100) {
      return description;
    }
    return '${description.substring(0, 100)}...';
  }

  /// Check if metadata is complete
  bool get isComplete => isValid && title.isNotEmpty && videoId != null;

  /// Get all thumbnail URLs
  Map<String, String> get allThumbnails {
    if (videoId == null) return {};
    
    return {
      'default': 'https://img.youtube.com/vi/${videoId!}/default.jpg',
      'medium': 'https://img.youtube.com/vi/${videoId!}/mqdefault.jpg',
      'high': 'https://img.youtube.com/vi/${videoId!}/hqdefault.jpg',
      'standard': 'https://img.youtube.com/vi/${videoId!}/sddefault.jpg',
      'max': 'https://img.youtube.com/vi/${videoId!}/maxresdefault.jpg',
    };
  }
}