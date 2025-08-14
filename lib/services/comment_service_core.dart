import '../data/models/comment_model.dart';

/// Core comment service interface
abstract class CommentServiceCore {
  Future<List<Comment>> getCommentsForSection(String lessonId, String sectionId);
  Future<void> postComment(String lessonId, String sectionId, String text);
  Future<void> likeComment(String commentId);
  Future<void> dislikeComment(String commentId);
  Future<void> deleteComment(String commentId);
  Future<void> syncQueuedActions();
  Future<int> getCommentCount(String lessonId, String sectionId);
  Future<bool> isCacheExpired(String lessonId, String sectionId);
  Future<void> clearSectionCache(String lessonId, String sectionId);
  Future<Map<String, dynamic>> getSyncStatus();
  Future<Map<String, dynamic>> getCacheStats();
  Future<List<Map<String, dynamic>>> getChildCommentActivity(String childId);
}