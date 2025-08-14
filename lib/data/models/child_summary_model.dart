/// Child summary model for parent dashboard
class ChildSummary {
  final String childId;
  final String childName;
  final String grade;
  final String schoolName;
  final int totalPoints;
  final int completedLessons;
  final int completedSections;
  final DateTime lastActivity;
  final String? profileImageUrl;

  const ChildSummary({
    required this.childId,
    required this.childName,
    required this.grade,
    required this.schoolName,
    required this.totalPoints,
    required this.completedLessons,
    required this.completedSections,
    required this.lastActivity,
    this.profileImageUrl,
  });

  factory ChildSummary.fromJson(Map<String, dynamic> json) {
    return ChildSummary(
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '',
      grade: json['grade'] ?? '',
      schoolName: json['schoolName'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      completedSections: json['completedSections'] ?? 0,
      lastActivity: json['lastActivity']?.toDate() ?? DateTime.now(),
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'childName': childName,
      'grade': grade,
      'schoolName': schoolName,
      'totalPoints': totalPoints,
      'completedLessons': completedLessons,
      'completedSections': completedSections,
      'lastActivity': lastActivity,
      'profileImageUrl': profileImageUrl,
    };
  }

  ChildSummary copyWith({
    String? childId,
    String? childName,
    String? grade,
    String? schoolName,
    int? totalPoints,
    int? completedLessons,
    int? completedSections,
    DateTime? lastActivity,
    String? profileImageUrl,
  }) {
    return ChildSummary(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      grade: grade ?? this.grade,
      schoolName: schoolName ?? this.schoolName,
      totalPoints: totalPoints ?? this.totalPoints,
      completedLessons: completedLessons ?? this.completedLessons,
      completedSections: completedSections ?? this.completedSections,
      lastActivity: lastActivity ?? this.lastActivity,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

/// Child comment activity model for parent monitoring
class ChildCommentActivity {
  final String commentId;
  final String lessonId;
  final String lessonTitle;
  final String sectionId;
  final String sectionTitle;
  final String commentContent;
  final DateTime postedAt;
  final int likes;
  final int dislikes;

  const ChildCommentActivity({
    required this.commentId,
    required this.lessonId,
    required this.lessonTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.commentContent,
    required this.postedAt,
    required this.likes,
    required this.dislikes,
  });

  factory ChildCommentActivity.fromJson(Map<String, dynamic> json) {
    return ChildCommentActivity(
      commentId: json['commentId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      sectionId: json['sectionId'] ?? '',
      sectionTitle: json['sectionTitle'] ?? '',
      commentContent: json['commentContent'] ?? '',
      postedAt: json['postedAt']?.toDate() ?? DateTime.now(),
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'sectionId': sectionId,
      'sectionTitle': sectionTitle,
      'commentContent': commentContent,
      'postedAt': postedAt,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  ChildCommentActivity copyWith({
    String? commentId,
    String? lessonId,
    String? lessonTitle,
    String? sectionId,
    String? sectionTitle,
    String? commentContent,
    DateTime? postedAt,
    int? likes,
    int? dislikes,
  }) {
    return ChildCommentActivity(
      commentId: commentId ?? this.commentId,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      sectionId: sectionId ?? this.sectionId,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      commentContent: commentContent ?? this.commentContent,
      postedAt: postedAt ?? this.postedAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
}

/// Parent link model for tracking parent-child relationships
class ParentLink {
  final String linkId;
  final String parentId;
  final String childId;
  final String status; // 'linked_by_parent', 'revoked'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdByIp;

  const ParentLink({
    required this.linkId,
    required this.parentId,
    required this.childId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.createdByIp,
  });

  factory ParentLink.fromJson(Map<String, dynamic> json) {
    return ParentLink(
      linkId: json['linkId'] ?? '',
      parentId: json['parentId'] ?? '',
      childId: json['childId'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate(),
      createdByIp: json['createdByIp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkId': linkId,
      'parentId': parentId,
      'childId': childId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdByIp': createdByIp,
    };
  }

  ParentLink copyWith({
    String? linkId,
    String? parentId,
    String? childId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByIp,
  }) {
    return ParentLink(
      linkId: linkId ?? this.linkId,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByIp: createdByIp ?? this.createdByIp,
    );
  }
}