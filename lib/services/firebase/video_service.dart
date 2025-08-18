import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/video_model.dart';
import '../../data/models/video_metadata.dart';
import '../../utils/youtube_utils.dart';

/// Simple video service following Flutter Lite rules
/// Maximum 150 lines per file, minimal dependencies
class VideoService {
  static const String _videoCachePrefix = 'video_cache_';
  static const int _cacheTTLSeconds = 24 * 60 * 60; // 24 hours

  /// Get videos by grade with optional subject filtering
  Future<List<VideoModel>> getVideosByGrade(String grade, {String? subject}) async {
    try {
      // Try cache first
      final cached = await _getCachedVideos(grade, subject);
      if (cached != null) {
        return cached;
      }

      // Fetch from Firestore
      final videos = await _fetchVideosFromFirestore(grade, subject);
      
      // Cache for future requests
      await _cacheVideos(videos, grade, subject);
      
      return videos;
    } catch (e) {
      debugPrint('Error getting videos: $e');
      return [];
    }
  }

  /// Get real-time stream of videos by grade
  Stream<List<VideoModel>> watchVideosByGrade(String grade, {String? subject}) {
    if (subject != null) {
      // Stream from specific subject
      return FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .collection(subject)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => VideoModel.fromJson(doc.data()))
              .toList());
    } else {
      // Stream from all subjects in grade
      return FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .snapshots()
          .map((snapshot) => <VideoModel>[]); // Simplified for now
    }
  }

  /// Upload a new video
  Future<void> uploadVideo(VideoModel video) async {
    try {
      final videoRef = FirebaseFirestore.instance
          .collection('videos')
          .doc(video.grade)
          .collection(video.subject)
          .doc(video.topic)
          .collection('videos')
          .doc(video.id);

      await videoRef.set(video.toJson());
      
      // Clear cache for this grade/subject
      await _clearVideoCache(video.grade, video.subject);
      
      debugPrint('Video uploaded: ${video.title}');
    } catch (e) {
      debugPrint('Error uploading video: $e');
      throw Exception('Failed to upload video: $e');
    }
  }

  /// Update an existing video
  Future<void> updateVideo(String videoId, VideoModel video) async {
    try {
      final videoRef = FirebaseFirestore.instance
          .collection('videos')
          .doc(video.grade)
          .collection(video.subject)
          .doc(video.topic)
          .collection('videos')
          .doc(videoId);

      await videoRef.update(video.toJson());
      
      // Clear cache
      await _clearVideoCache(video.grade, video.subject);
      
      debugPrint('Video updated: ${video.title}');
    } catch (e) {
      debugPrint('Error updating video: $e');
      throw Exception('Failed to update video: $e');
    }
  }

  /// Delete a video
  Future<void> deleteVideo(String videoId, String grade, String subject, String topic) async {
    try {
      final videoRef = FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .collection(subject)
          .doc(topic)
          .collection('videos')
          .doc(videoId);

      await videoRef.delete();
      
      // Clear cache
      await _clearVideoCache(grade, subject);
      
      debugPrint('Video deleted: $videoId');
    } catch (e) {
      debugPrint('Error deleting video: $e');
      throw Exception('Failed to delete video: $e');
    }
  }

  /// Extract YouTube metadata from URL
  Future<VideoMetadata> extractYouTubeMetadata(String url) async {
    try {
      return await VideoMetadata.fromYouTubeUrl(url);
    } catch (e) {
      debugPrint('Error extracting YouTube metadata: $e');
      throw Exception('Failed to extract video metadata: $e');
    }
  }

  /// Get YouTube thumbnail URL
  String getYouTubeThumbnailUrl(String videoId) {
    return YouTubeUtils.getThumbnailUrl(videoId, quality: 'maxresdefault');
  }

  /// Get available subjects for a grade
  Future<List<String>> getAvailableSubjects(String grade) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .collection('subjects')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      return [];
    }
  }

  /// Get available topics for a grade and subject
  Future<List<String>> getAvailableTopics(String grade, String subject) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .collection(subject)
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching topics: $e');
      return [];
    }
  }

  /// Validate YouTube URL
  bool isValidYouTubeUrl(String url) {
    return YouTubeUtils.isValidYouTubeUrl(url);
  }

  /// Extract video ID from URL
  String? extractVideoId(String url) {
    return YouTubeUtils.extractVideoId(url);
  }

  /// Get cached videos
  Future<List<VideoModel>?> _getCachedVideos(String grade, String? subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_videoCachePrefix${grade}_${subject ?? "all"}';
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson == null) return null;
      
      final jsonData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final cachedAt = jsonData['cachedAt'] as int?;
      
      // Check TTL
      if (cachedAt == null) return null;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      if ((now - cachedAt) > (_cacheTTLSeconds * 1000)) {
        await prefs.remove(cacheKey);
        return null;
      }
      
      final videosData = jsonData['videos'] as List;
      return videosData.map((v) => VideoModel.fromJson(v)).toList();
    } catch (e) {
      debugPrint('Error reading cached videos: $e');
      return null;
    }
  }

  /// Cache videos
  Future<void> _cacheVideos(List<VideoModel> videos, String grade, String? subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_videoCachePrefix${grade}_${subject ?? "all"}';
      
      final jsonData = {
        'videos': videos.map((v) => v.toJson()).toList(),
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(cacheKey, jsonEncode(jsonData));
    } catch (e) {
      debugPrint('Error caching videos: $e');
    }
  }

  /// Clear video cache
  Future<void> _clearVideoCache(String grade, String? subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_videoCachePrefix${grade}_${subject ?? "all"}';
      await prefs.remove(cacheKey);
    } catch (e) {
      debugPrint('Error clearing video cache: $e');
    }
  }

  /// Fetch videos from Firestore
  Future<List<VideoModel>> _fetchVideosFromFirestore(String grade, String? subject) async {
    try {
      if (subject != null) {
        // Get videos for specific grade and subject
        final snapshot = await FirebaseFirestore.instance
            .collection('videos')
            .doc(grade)
            .collection(subject)
            .get();
        
        return snapshot.docs
            .map((doc) => VideoModel.fromJson(doc.data()))
            .toList();
      } else {
        // Get all subjects for the grade (simplified)
        final videos = <VideoModel>[];
        final subjectsSnapshot = await FirebaseFirestore.instance
            .collection('videos')
            .doc(grade)
            .collection('subjects')
            .get();

        for (final subjectDoc in subjectsSnapshot.docs) {
          final subjectName = subjectDoc.id;
          final videosSnapshot = await FirebaseFirestore.instance
              .collection('videos')
              .doc(grade)
              .collection(subjectName)
              .get();
          
          videos.addAll(videosSnapshot.docs
              .map((doc) => VideoModel.fromJson(doc.data())));
        }

        return videos;
      }
    } catch (e) {
      debugPrint('Error fetching videos: $e');
      return [];
    }
  }
}