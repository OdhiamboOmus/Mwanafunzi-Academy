import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/video_model.dart';
import '../../data/models/video_metadata.dart';
import '../../utils/youtube_utils.dart';
import '../../utils/video_error_handler.dart';
import '../../utils/video_performance_manager.dart';

/// Simple video service following Flutter Lite rules
/// Maximum 150 lines per file, minimal dependencies
class VideoService {
  static const String _videoCachePrefix = 'video_cache_';
  static const int _cacheTTLSeconds = 24 * 60 * 60; // 24 hours
  final VideoPerformanceManager _performanceManager = VideoPerformanceManager.instance;

  /// Get videos by grade with optional subject filtering
  Future<List<VideoModel>> getVideosByGrade(String grade, {String? subject}) async {
    final result = await VideoErrorHandler.handleFirestoreError<List<VideoModel>?>(
      () async {
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
      },
      'getVideosByGrade',
      defaultValue: [],
    );
    
    return result ?? [];
  }

  /// Get real-time stream of videos by grade with automatic refresh
  Stream<List<VideoModel>> watchVideosByGrade(String grade, {String? subject}) {
    if (subject != null) {
      // Stream from specific subject with real-time updates
      return FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .collection(subject)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => VideoModel.fromJson(doc.data()))
              .where((video) => video.isAvailable)
              .toList());
    } else {
      // Stream from all subjects in grade with incremental sync
      return _getAllSubjectsStream(grade);
    }
  }

  /// Stream all subjects for a grade with incremental sync
  Stream<List<VideoModel>> _getAllSubjectsStream(String grade) {
    return FirebaseFirestore.instance
        .collection('videos')
        .doc(grade)
        .snapshots()
        .asyncExpand((gradeSnapshot) async* {
          if (!gradeSnapshot.exists) {
            yield [];
            return;
          }

          try {
            // Get all subjects in this grade
            final subjectsSnapshot = await FirebaseFirestore.instance
                .collection('videos')
                .doc(grade)
                .collection('subjects')
                .get();

            if (subjectsSnapshot.docs.isEmpty) {
              yield [];
              return;
            }

            // Stream from each subject and combine
            final subjectStreams = subjectsSnapshot.docs.map((subjectDoc) {
              return FirebaseFirestore.instance
                  .collection('videos')
                  .doc(grade)
                  .collection(subjectDoc.id)
                  .snapshots()
                  .map((snapshot) => snapshot.docs
                      .map((doc) => VideoModel.fromJson(doc.data()))
                      .where((video) => video.isAvailable)
                      .toList());
            });

            // Combine all subject streams
            yield* Stream<List<VideoModel>>.fromFutures(
              subjectStreams.map((stream) => stream.first),
            );
          } catch (e) {
            debugPrint('Error streaming all subjects: $e');
            yield [];
          }
        });
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

  /// Fetch videos from Firestore with batch optimization
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
        // Get all subjects for the grade with batch optimization
        return await _fetchAllSubjectsBatch(grade);
      }
    } catch (e) {
      debugPrint('Error fetching videos: $e');
      return [];
    }
  }

  /// Fetch all subjects with batch optimization
  Future<List<VideoModel>> _fetchAllSubjectsBatch(String grade) async {
    try {
      final videos = <VideoModel>[];
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(grade)
          .collection('subjects')
          .get();

      if (subjectsSnapshot.docs.isEmpty) {
        return videos;
      }

      // Process subjects in batches for better performance
      final batchSize = 5; // Process 5 subjects at a time
      for (int i = 0; i < subjectsSnapshot.docs.length; i += batchSize) {
        final batchEnd = (i + batchSize < subjectsSnapshot.docs.length)
            ? i + batchSize
            : subjectsSnapshot.docs.length;
        
        final batchSubjects = subjectsSnapshot.docs.sublist(i, batchEnd);
        
        // Fetch videos for this batch
        for (final subjectDoc in batchSubjects) {
          final subjectName = subjectDoc.id;
          final videosSnapshot = await FirebaseFirestore.instance
              .collection('videos')
              .doc(grade)
              .collection(subjectName)
              .get();
          
          videos.addAll(videosSnapshot.docs
              .map((doc) => VideoModel.fromJson(doc.data())));
        }

        // Small delay to prevent overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return videos;
    } catch (e) {
      debugPrint('Error fetching all subjects: $e');
      return [];
    }
  }

  /// Enhanced caching with LRU eviction
  Future<void> _originalCacheVideos(List<VideoModel> videos, String grade, String? subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_videoCachePrefix${grade}_${subject ?? "all"}';
      
      // Calculate cache size and check limits
      final videosJson = videos.map((v) => v.toJson()).toList();
      final jsonData = {
        'videos': videosJson,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'videoCount': videos.length,
        'totalSize': jsonEncode(videosJson).length,
      };
      
      await prefs.setString(cacheKey, jsonEncode(jsonData));
      
      // Run LRU cleanup if cache is getting large
      await _runCacheCleanup();
      
      debugPrint('Cached ${videos.length} videos for $grade/${subject ?? "all"}');
    } catch (e) {
      debugPrint('Error caching videos: $e');
    }
  }

  /// Run LRU cache cleanup to prevent excessive storage
  Future<void> _runCacheCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final videoCacheKeys = allKeys.where((key) => key.startsWith(_videoCachePrefix)).toList();
      
      if (videoCacheKeys.length > 20) { // Keep only 20 most recent caches
        // Sort by cache timestamp (newest first)
        videoCacheKeys.sort((a, b) {
          final aTime = prefs.getInt('${a}_timestamp') ?? 0;
          final bTime = prefs.getInt('${b}_timestamp') ?? 0;
          return bTime.compareTo(aTime);
        });
        
        // Remove oldest caches
        final keysToRemove = videoCacheKeys.skip(20).take(10).toList();
        for (final key in keysToRemove) {
          await prefs.remove(key);
          await prefs.remove('${key}_timestamp');
        }
        
        debugPrint('Cleaned up ${keysToRemove.length} old video caches');
      }
    } catch (e) {
      debugPrint('Error running cache cleanup: $e');
    }
  }

  /// Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final videoCacheKeys = allKeys.where((key) => key.startsWith(_videoCachePrefix)).toList();
      
      int totalSize = 0;
      int totalVideos = 0;
      int validCaches = 0;
      
      for (final key in videoCacheKeys) {
        final cachedJson = prefs.getString(key);
        if (cachedJson != null) {
          final jsonData = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedAt = jsonData['cachedAt'] as int?;
          
          if (cachedAt != null && (DateTime.now().millisecondsSinceEpoch - cachedAt) < (_cacheTTLSeconds * 1000)) {
            validCaches++;
            totalVideos += (jsonData['videoCount'] as int?) ?? 0;
            totalSize += (jsonData['totalSize'] as int?) ?? 0;
          }
        }
      }
      
      return {
        'totalCacheEntries': videoCacheKeys.length,
        'validCacheEntries': validCaches,
        'totalCachedVideos': totalVideos,
        'totalCacheSizeBytes': totalSize,
        'cacheTTLSeconds': _cacheTTLSeconds,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }

  /// Check if device is offline
  Future<bool> _isOffline() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return connectivity == ConnectivityResult.none;
    } catch (e) {
      // If we can't check connectivity, assume online for safety
      return false;
    }
  }

  /// Get videos with offline fallback
  Future<List<VideoModel>> getVideosByGradeWithOfflineFallback(String grade, {String? subject}) async {
    try {
      // First try to get cached videos
      final cached = await _getCachedVideos(grade, subject);
      if (cached != null) {
        debugPrint('Using cached videos for $grade/${subject ?? "all"}');
        return cached;
      }

      // If no cache and offline, return empty list with appropriate messaging
      final isOffline = await _isOffline();
      if (isOffline) {
        debugPrint('Offline mode: no cache available for $grade/${subject ?? "all"}');
        return [];
      }

      // Otherwise fetch from Firestore
      return await getVideosByGrade(grade, subject: subject);
    } catch (e) {
      debugPrint('Error getting videos with offline fallback: $e');
      return [];
    }
  }
}