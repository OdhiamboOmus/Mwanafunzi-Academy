import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../data/models/progress_model.dart';
import '../data/repositories/user_repository.dart';

/// Settings service for managing settings screen data and leaderboard functionality
class SettingsService {
  final StorageService _storageService;
  final UserRepository _userRepository;
  
  static const String _leaderboardCacheKey = 'leaderboard_cache_';
  static const String _nextUpdateKey = 'leaderboard_next_update';
  static const int _cacheTtlHours = 12; // 12-hour cache TTL
  // Future implementation: Limit leaderboard entries for performance
  // static const int _maxLeaderboardEntries = 100;

  SettingsService({
    required StorageService storageService,
    required UserRepository userRepository,
  }) : _storageService = storageService,
       _userRepository = userRepository;

  /// Get leaderboard data for a grade
  Future<LeaderboardData> getLeaderboard(String grade) async {
    try {
      // Check if we have cached data that's still valid
      final cachedLeaderboard = await _getCachedLeaderboard(grade);
      if (cachedLeaderboard != null) {
        return cachedLeaderboard;
      }

      // Fetch fresh data from Firestore
      final leaderboardData = await _fetchLeaderboardFromFirestore(grade);
      
      // Cache the data
      await _cacheLeaderboard(grade, leaderboardData);
      
      return leaderboardData;
    } catch (e) {
      debugPrint('❌ SettingsService error in getLeaderboard: $e');
      rethrow;
    }
  }

  /// Get user rank in leaderboard
  Future<UserRank?> getUserRank(String userId, String grade) async {
    try {
      final leaderboard = await getLeaderboard(grade);
      final userEntry = leaderboard.overall.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => LeaderboardEntry(
          userId: '',
          userName: '',
          grade: '',
          points: 0,
          rank: 0,
        ),
      );

      if (userEntry.userId.isNotEmpty) {
        return UserRank(
          userId: userEntry.userId,
          userName: userEntry.userName,
          grade: userEntry.grade,
          points: userEntry.points,
          rank: userEntry.rank,
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ SettingsService error in getUserRank: $e');
      return null;
    }
  }

  /// Get time until next leaderboard update
  Future<Duration> getTimeUntilNextUpdate() async {
    try {
      final nextUpdateJson = await _storageService.getValue(_nextUpdateKey);
      if (nextUpdateJson != null) {
        final nextUpdate = DateTime.parse(nextUpdateJson);
        final now = DateTime.now();
        return nextUpdate.difference(now).isNegative
            ? Duration.zero
            : nextUpdate.difference(now);
      }
      
      // If no next update time, return default (6 hours from now)
      return DateTime.now().add(const Duration(hours: 6)).difference(DateTime.now());
    } catch (e) {
      debugPrint('❌ SettingsService error in getTimeUntilNextUpdate: $e');
      return const Duration(hours: 6);
    }
  }

  /// Refresh leaderboard data
  Future<void> refreshLeaderboard(String grade) async {
    try {
      // Clear existing cache
      await _clearLeaderboardCache(grade);
      
      // Fetch fresh data
      final leaderboardData = await _fetchLeaderboardFromFirestore(grade);
      
      // Cache the data
      await _cacheLeaderboard(grade, leaderboardData);
      
      // Update next update time
      await _updateNextUpdateTime();
      
      debugPrint('✅ Leaderboard refreshed for grade: $grade');
    } catch (e) {
      debugPrint('❌ SettingsService error in refreshLeaderboard: $e');
      rethrow;
    }
  }

  /// Check if leaderboard cache is expired
  Future<bool> isLeaderboardCacheExpired(String grade) async {
    try {
      final cachedData = await _getCachedLeaderboard(grade);
      if (cachedData == null) {
        return true; // No cached data
      }

      // Check if cache is older than TTL
      final cacheKey = '$_leaderboardCacheKey$grade';
      final cachedJson = await _storageService.getValue('${cacheKey}_metadata');
      
      if (cachedJson != null) {
        final metadata = jsonDecode(cachedJson) as Map<String, dynamic>;
        final cachedAt = DateTime.parse(metadata['cachedAt'] as String);
        final now = DateTime.now();
        final expiration = cachedAt.add(const Duration(hours: _cacheTtlHours));
        
        return now.isAfter(expiration);
      }

      return true;
    } catch (e) {
      debugPrint('❌ SettingsService error in isLeaderboardCacheExpired: $e');
      return true;
    }
  }

  /// Get cached leaderboard data
  Future<LeaderboardData?> _getCachedLeaderboard(String grade) async {
    try {
      final cacheKey = '$_leaderboardCacheKey$grade';
      final cachedJson = await _storageService.getValue(cacheKey);
      
      if (cachedJson != null) {
        return LeaderboardData.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ SettingsService error in _getCachedLeaderboard: $e');
      return null;
    }
  }

  /// Cache leaderboard data
  Future<void> _cacheLeaderboard(String grade, LeaderboardData data) async {
    try {
      final cacheKey = '$_leaderboardCacheKey$grade';
      final metadataKey = '${cacheKey}_metadata';
      
      // Cache the leaderboard data
      await _storageService.setValue(
        cacheKey,
        jsonEncode(data.toJson()),
      );
      
      // Cache metadata with timestamp
      await _storageService.setValue(
        metadataKey,
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'grade': grade,
        }),
      );
    } catch (e) {
      debugPrint('❌ SettingsService error in _cacheLeaderboard: $e');
    }
  }

  /// Clear leaderboard cache
  Future<void> _clearLeaderboardCache(String grade) async {
    try {
      final cacheKey = '$_leaderboardCacheKey$grade';
      final metadataKey = '${cacheKey}_metadata';
      
      await _storageService.removeValue(cacheKey);
      await _storageService.removeValue(metadataKey);
    } catch (e) {
      debugPrint('❌ SettingsService error in _clearLeaderboardCache: $e');
    }
  }

  /// Update next update time
  Future<void> _updateNextUpdateTime() async {
    try {
      final nextUpdate = DateTime.now().add(const Duration(hours: _cacheTtlHours));
      await _storageService.setValue(
        _nextUpdateKey,
        nextUpdate.toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ SettingsService error in _updateNextUpdateTime: $e');
    }
  }

  /// Fetch leaderboard data from Firestore
  Future<LeaderboardData> _fetchLeaderboardFromFirestore(String grade) async {
    try {
      // Get leaderboard document from Firestore
      // For now, return sample leaderboard data
      // In real implementation, this would call _userRepository.getLeaderboardByGrade(grade)
      return LeaderboardData(
        grade: grade,
        overall: _getSampleLeaderboardEntries(),
        subjects: _getSampleSubjectLeaderboards(),
        updatedAt: DateTime.now(),
        nextUpdateAt: DateTime.now().add(const Duration(hours: 12)),
      );
    } catch (e) {
      debugPrint('❌ SettingsService error in _fetchLeaderboardFromFirestore: $e');
      rethrow;
    }
  }

  /// Get user points for display
  Future<int> getUserPoints(String userId) async {
    try {
      final userDoc = await _userRepository.getUserById(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['points'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ SettingsService error in getUserPoints: $e');
      return 0;
    }
  }
  /// Get sample leaderboard entries for demonstration
  List<LeaderboardEntry> _getSampleLeaderboardEntries() {
    return [
      LeaderboardEntry(
        userId: 'user1',
        userName: 'John D.',
        grade: '5',
        points: 450,
        rank: 1,
      ),
      LeaderboardEntry(
        userId: 'user2',
        userName: 'Mary K.',
        grade: '5',
        points: 380,
        rank: 2,
      ),
      LeaderboardEntry(
        userId: 'user3',
        userName: 'James M.',
        grade: '5',
        points: 320,
        rank: 3,
      ),
      LeaderboardEntry(
        userId: 'user4',
        userName: 'Sarah L.',
        grade: '5',
        points: 280,
        rank: 4,
      ),
      LeaderboardEntry(
        userId: 'user5',
        userName: 'David P.',
        grade: '5',
        points: 250,
        rank: 5,
      ),
    ];
  }

  /// Get sample subject leaderboards for demonstration
  Map<String, List<LeaderboardEntry>> _getSampleSubjectLeaderboards() {
    return {
      'Mathematics': [
        LeaderboardEntry(
          userId: 'user1',
          userName: 'John D.',
          grade: '5',
          points: 180,
          rank: 1,
        ),
        LeaderboardEntry(
          userId: 'user2',
          userName: 'Mary K.',
          grade: '5',
          points: 150,
          rank: 2,
        ),
      ],
      'English': [
        LeaderboardEntry(
          userId: 'user2',
          userName: 'Mary K.',
          grade: '5',
          points: 160,
          rank: 1,
        ),
        LeaderboardEntry(
          userId: 'user1',
          userName: 'John D.',
          grade: '5',
          points: 140,
          rank: 2,
        ),
      ],
    };
  }
}

/// Leaderboard data model
class LeaderboardData {
  final String grade;
  final List<LeaderboardEntry> overall;
  final Map<String, List<LeaderboardEntry>> subjects;
  final DateTime updatedAt;
  final DateTime nextUpdateAt;

  LeaderboardData({
    required this.grade,
    required this.overall,
    required this.subjects,
    required this.updatedAt,
    required this.nextUpdateAt,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      grade: json['grade'] ?? '',
      overall: (json['overall'] as List?)
          ?.map((entry) => LeaderboardEntry.fromJson(entry))
          .toList() ?? [],
      subjects: (json['subjects'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((entry) => LeaderboardEntry.fromJson(entry)).toList(),
        ),
      ) ?? {},
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      nextUpdateAt: json['nextUpdateAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'overall': overall.map((entry) => entry.toJson()).toList(),
      'subjects': subjects.map((key, value) => MapEntry(
        key,
        value.map((entry) => entry.toJson()).toList(),
      )),
      'updatedAt': updatedAt,
      'nextUpdateAt': nextUpdateAt,
    };
  }
}

/// User rank data model
class UserRank {
  final String userId;
  final String userName;
  final String grade;
  final int points;
  final int rank;

  UserRank({
    required this.userId,
    required this.userName,
    required this.grade,
    required this.points,
    required this.rank,
  });

  factory UserRank.fromJson(Map<String, dynamic> json) {
    return UserRank(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      grade: json['grade'] ?? '',
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'grade': grade,
      'points': points,
      'rank': rank,
    };
  }
}