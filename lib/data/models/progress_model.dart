/// Progress record for lesson completion tracking
class ProgressRecord {
  final String progressRecordId;
  final String userId;
  final String lessonId;
  final String sectionId;
  final DateTime completedAt;
  final int pointsEarned;
  final String? deviceId;

  ProgressRecord({
    required this.progressRecordId,
    required this.userId,
    required this.lessonId,
    required this.sectionId,
    required this.completedAt,
    required this.pointsEarned,
    this.deviceId,
  });

  factory ProgressRecord.fromJson(Map<String, dynamic> json) {
    return ProgressRecord(
      progressRecordId: json['progressRecordId'] ?? '',
      userId: json['userId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      sectionId: json['sectionId'] ?? '',
      completedAt: json['completedAt']?.toDate() ?? DateTime.now(),
      pointsEarned: json['pointsEarned'] ?? 0,
      deviceId: json['deviceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progressRecordId': progressRecordId,
      'userId': userId,
      'lessonId': lessonId,
      'sectionId': sectionId,
      'completedAt': completedAt,
      'pointsEarned': pointsEarned,
      'deviceId': deviceId,
    };
  }

  /// Create unique progress record ID
  static String generateProgressRecordId() {
    return 'progress_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string for uniqueness
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[random % chars.length];
    }
    return result;
  }
}

/// User progress summary
class UserProgress {
  final String userId;
  final int totalPoints;
  final int completedLessons;
  final int completedSections;
  final DateTime lastUpdated;

  UserProgress({
    required this.userId,
    required this.totalPoints,
    required this.completedLessons,
    required this.completedSections,
    required this.lastUpdated,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      completedSections: json['completedSections'] ?? 0,
      lastUpdated: json['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'completedLessons': completedLessons,
      'completedSections': completedSections,
      'lastUpdated': lastUpdated,
    };
  }

  /// Create copy with updated points
  UserProgress withPointsUpdate(int additionalPoints) {
    return copyWith(
      totalPoints: totalPoints + additionalPoints,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress copyWith({
    String? userId,
    int? totalPoints,
    int? completedLessons,
    int? completedSections,
    DateTime? lastUpdated,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      completedLessons: completedLessons ?? this.completedLessons,
      completedSections: completedSections ?? this.completedSections,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String grade;
  final int points;
  final int rank;
  final String? schoolName;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.grade,
    required this.points,
    required this.rank,
    this.schoolName,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      grade: json['grade'] ?? '',
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
      schoolName: json['schoolName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'grade': grade,
      'points': points,
      'rank': rank,
      'schoolName': schoolName,
    };
  }
}