import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/video_model.dart';

/// LRU cache service for video metadata
/// Implements cache eviction and offline capability
class VideoLRUCacheService {
  static const String _videoCachePrefix = 'video_cache_';
  static const String _cacheTimestampPrefix = 'video_cache_timestamp_';
  static const String _watchedVideosPrefix = 'video_watched_';
  static const int _cacheTTLSeconds = 24 * 60 * 60; // 24 hours
  static const int _maxCacheSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Cache video metadata locally
  Future<void> cacheVideos(List<VideoModel> videos, String grade, {String? subject}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(grade, subject);
      final timestampKey = _getTimestampKey(grade, subject);
      
      // Convert videos to JSON
      final videosJson = videos.map((video) => video.toJson()).toList();
      final jsonString = json.encode(videosJson);
      
      // Store cache with timestamp
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);
      
      developer.log('Cached ${videos.length} videos for $grade/${subject ?? "all"}');
    } catch (e) {
      developer.log('Error caching videos: $e');
    }
  }

  /// Get cached videos with TTL check
  Future<List<VideoModel>?> getCachedVideos(String grade, {String? subject}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(grade, subject);
      final timestampKey = _getTimestampKey(grade, subject);
      
      final jsonString = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);
      
      if (jsonString == null || timestamp == null) {
        return null;
      }
      
      // Check if cache is expired
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now - timestamp > _cacheTTLSeconds) {
        await clearCache(grade, subject: subject);
        return null;
      }
      
      // Parse JSON to videos
      final videosJson = json.decode(jsonString) as List;
      final videos = videosJson.map((json) => VideoModel.fromJson(json)).toList();
      
      developer.log('Loaded ${videos.length} cached videos for $grade/${subject ?? "all"}');
      return videos;
    } catch (e) {
      developer.log('Error getting cached videos: $e');
      return null;
    }
  }

  /// Clear cache for specific grade/subject
  Future<void> clearCache(String grade, {String? subject}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(grade, subject);
      final timestampKey = _getTimestampKey(grade, subject);
      
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      
      developer.log('Cleared cache for $grade/${subject ?? "all"}');
    } catch (e) {
      developer.log('Error clearing cache: $e');
    }
  }

  /// Mark video as watched
  Future<void> markVideoAsWatched(String userId, String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedKey = '$_watchedVideosPrefix$userId';
      
      final watchedVideos = prefs.getStringList(watchedKey) ?? [];
      if (!watchedVideos.contains(videoId)) {
        watchedVideos.add(videoId);
        await prefs.setStringList(watchedKey, watchedVideos);
      }
    } catch (e) {
      developer.log('Error marking video as watched: $e');
    }
  }

  /// Check if video is watched
  Future<bool> isVideoWatched(String userId, String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedKey = '$_watchedVideosPrefix$userId';
      
      final watchedVideos = prefs.getStringList(watchedKey) ?? [];
      return watchedVideos.contains(videoId);
    } catch (e) {
      developer.log('Error checking watched status: $e');
      return false;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoCacheKeys = prefs.getKeys().where((key) => key.startsWith(_videoCachePrefix)).toList();
      
      int validCaches = 0;
      int totalVideos = 0;
      int totalSize = 0;
      
      for (final cacheKey in videoCacheKeys) {
        final jsonString = prefs.getString(cacheKey);
        if (jsonString != null) {
          validCaches++;
          final jsonData = json.decode(jsonString);
          totalVideos += (jsonData.length as int?) ?? 0;
          totalSize += (jsonString.length * 2); // Rough estimate
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
      developer.log('Error getting cache stats: $e');
      return {};
    }
  }

  /// Check if device is offline
  Future<bool> isOffline() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return connectivity == ConnectivityResult.none;
    } catch (e) {
      // If we can't check connectivity, assume online for safety
      return false;
    }
  }

  /// Get cache key for grade/subject combination
  String _getCacheKey(String grade, String? subject) {
    return '$_videoCachePrefix$grade${subject != null ? '_$subject' : ''}';
  }

  /// Get timestamp key for grade/subject combination
  String _getTimestampKey(String grade, String? subject) {
    return '$_cacheTimestampPrefix$grade${subject != null ? '_$subject' : ''}';
  }
}