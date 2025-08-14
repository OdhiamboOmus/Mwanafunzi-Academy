/// Comment model for lesson section discussions
class Comment {
  final String commentId;
  final String userId;
  final String userName;
  final String lessonId;
  final String sectionId;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final String? userAvatarUrl;
  final bool isLiked;
  final bool isDisliked;
  final bool isOwner;

  Comment({
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.lessonId,
    required this.sectionId,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    this.userAvatarUrl,
    this.isLiked = false,
    this.isDisliked = false,
    this.isOwner = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      lessonId: json['lessonId'] ?? '',
      sectionId: json['sectionId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      userAvatarUrl: json['userAvatarUrl'],
      isLiked: json['isLiked'] ?? false,
      isDisliked: json['isDisliked'] ?? false,
      isOwner: json['isOwner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'userId': userId,
      'userName': userName,
      'lessonId': lessonId,
      'sectionId': sectionId,
      'content': content,
      'createdAt': createdAt,
      'likes': likes,
      'dislikes': dislikes,
      'userAvatarUrl': userAvatarUrl,
      'isLiked': isLiked,
      'isDisliked': isDisliked,
      'isOwner': isOwner,
    };
  }

  /// Create copy with updated like/dislike state
  Comment withLikeState({bool? isLiked, bool? isDisliked}) {
    return copyWith(
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
    );
  }

  /// Create copy with updated like counts
  Comment withLikeCounts({int? likes, int? dislikes}) {
    return copyWith(
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }

  Comment copyWith({
    String? commentId,
    String? userId,
    String? userName,
    String? lessonId,
    String? sectionId,
    String? content,
    DateTime? createdAt,
    int? likes,
    int? dislikes,
    String? userAvatarUrl,
    bool? isLiked,
    bool? isDisliked,
    bool? isOwner,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      lessonId: lessonId ?? this.lessonId,
      sectionId: sectionId ?? this.sectionId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  /// Generate unique comment ID
  static String generateCommentId() {
    return 'comment_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
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

/// Comment action for queuing
class CommentAction {
  final String actionId;
  final String commentId;
  final String actionType; // 'like', 'dislike', 'delete'
  final String userId;
  final DateTime createdAt;

  CommentAction({
    required this.actionId,
    required this.commentId,
    required this.actionType,
    required this.userId,
    required this.createdAt,
  });

  factory CommentAction.fromJson(Map<String, dynamic> json) {
    return CommentAction(
      actionId: json['actionId'] ?? '',
      commentId: json['commentId'] ?? '',
      actionType: json['actionType'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'commentId': commentId,
      'actionType': actionType,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  /// Generate unique action ID
  static String generateActionId() {
    return 'action_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
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

/// Comments for a specific section
class SectionComments {
  final String lessonId;
  final String sectionId;
  final List<Comment> comments;
  final DateTime lastUpdated;

  SectionComments({
    required this.lessonId,
    required this.sectionId,
    required this.comments,
    required this.lastUpdated,
  });

  factory SectionComments.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'] as List?;
    final comments = commentsJson?.map((comment) => 
        Comment.fromJson(comment)).toList() ?? [];

    return SectionComments(
      lessonId: json['lessonId'] ?? '',
      sectionId: json['sectionId'] ?? '',
      comments: comments,
      lastUpdated: json['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'sectionId': sectionId,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'lastUpdated': lastUpdated,
    };
  }

  /// Add comment to section
  SectionComments addComment(Comment comment) {
    final updatedComments = List<Comment>.from(comments)..add(comment);
    return copyWith(
      comments: updatedComments,
      lastUpdated: DateTime.now(),
    );
  }

  /// Remove comment from section
  SectionComments removeComment(String commentId) {
    final updatedComments = comments.where((c) => c.commentId != commentId).toList();
    return copyWith(
      comments: updatedComments,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update comment like state
  SectionComments updateCommentLike(String commentId, bool isLiked) {
    final updatedComments = comments.map((comment) {
      if (comment.commentId == commentId) {
        return comment.withLikeState(isLiked: isLiked);
      }
      return comment;
    }).toList();
    
    return copyWith(comments: updatedComments);
  }

  SectionComments copyWith({
    String? lessonId,
    String? sectionId,
    List<Comment>? comments,
    DateTime? lastUpdated,
  }) {
    return SectionComments(
      lessonId: lessonId ?? this.lessonId,
      sectionId: sectionId ?? this.sectionId,
      comments: comments ?? this.comments,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}