/// Represents a YouTube video with educational metadata
class VideoModel {
  final String id;
  final String youtubeId;
  final String title;
  final String description;
  final String grade;
  final String subject;
  final String topic;
  final Duration duration;
  final DateTime uploadedAt;
  final String uploadedBy;
  final bool isActive;
  
  const VideoModel({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.description,
    required this.grade,
    required this.subject,
    required this.topic,
    required this.duration,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.isActive,
  });

  /// Create from JSON
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      youtubeId: json['youtubeId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      grade: json['grade'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      duration: Duration(seconds: json['duration'] ?? 0),
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
      uploadedBy: json['uploadedBy'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'youtubeId': youtubeId,
      'title': title,
      'description': description,
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'duration': duration.inSeconds,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
      'isActive': isActive,
    };
  }

  /// Get YouTube thumbnail URL
  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';
  
  /// Get optimized thumbnail URL for better performance
  String get optimizedThumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';

  /// Get YouTube watch URL
  String get watchUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  /// Get YouTube embed URL
  String get embedUrl => 'https://www.youtube.com/embed/$youtubeId';

  /// Copy with updated fields
  VideoModel copyWith({
    String? id,
    String? youtubeId,
    String? title,
    String? description,
    String? grade,
    String? subject,
    String? topic,
    Duration? duration,
    DateTime? uploadedAt,
    String? uploadedBy,
    bool? isActive,
  }) {
    return VideoModel(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      description: description ?? this.description,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      duration: duration ?? this.duration,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if video is available for viewing
  bool get isAvailable => isActive && youtubeId.isNotEmpty;

  /// Get formatted duration (MM:SS)
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get display title with fallback
  String get displayTitle => title.isNotEmpty ? title : 'Untitled Video';

  /// Get display subject with fallback
  String get displaySubject => subject.isNotEmpty ? subject : 'Other';

  /// Get display topic with fallback
  String get displayTopic => topic.isNotEmpty ? topic : 'General';
}