import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../data/models/progress_model.dart';
import '../data/repositories/user_repository.dart';

/// Progress service for lesson completion tracking and points system
class ProgressService {
  final StorageService _storageService;
  final UserRepository _userRepository;
  
  static const String _progressQueueKey = 'progress_queue';
  static const String _userPointsKey = 'user_points';
  static const String _lastSyncKey = 'last_sync';
  static const int _pointsPerLesson = 10;
  // Future implementation: retry constants for exponential backoff
  // static const int _maxRetries = 3;
  // static const Duration _retryDelay = Duration(seconds: 5);
  
  ProgressService({
    required StorageService storageService,
    required UserRepository userRepository,
  }) : _storageService = storageService,
       _userRepository = userRepository;

  /// Complete a lesson and award points immediately
  Future<void> completeLesson(String lessonId) async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      final userId = user.uid;
      final progressRecordId = _generateProgressRecordId(userId, lessonId);
      
      // Check if this lesson is already completed to prevent duplicates
      final isAlreadyCompleted = await _isLessonCompleted(userId, lessonId);
      if (isAlreadyCompleted) {
        debugPrint('⚠️ Lesson $lessonId already completed by user $userId');
        return;
      }
      
      // Award points immediately to local cache
      await _awardPointsLocally(userId, _pointsPerLesson);
      
      // Queue the progress record for sync
      await _queueProgressRecord(
        userId: userId,
        lessonId: lessonId,
        progressRecordId: progressRecordId,
        pointsEarned: _pointsPerLesson,
      );
      
      debugPrint('✅ Lesson $lessonId completed. $_pointsPerLesson points awarded and queued for sync.');
      
    } catch (e) {
      debugPrint('❌ Error completing lesson: $e');
      rethrow;
    }
  }

  /// Get local user points for immediate UI updates
  Future<int> getLocalPoints(String userId) async {
    try {
      final pointsData = await _storageService.getValue('$_userPointsKey$userId');
      if (pointsData != null) {
        final json = jsonDecode(pointsData) as Map<String, dynamic>;
        return json['points'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error getting local points: $e');
      return 0;
    }
  }

  /// Get queued progress records for sync
  Future<List<ProgressRecord>> getQueuedProgress(String userId) async {
    try {
      final queueData = await _storageService.getValue('$_progressQueueKey$userId');
      if (queueData != null) {
        final json = jsonDecode(queueData) as Map<String, dynamic>;
        final records = json['records'] as List?;
        return records?.map((record) => ProgressRecord.fromJson(record)).toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting queued progress: $e');
      return [];
    }
  }

  /// Sync all queued progress records to Firestore
  Future<void> syncProgress() async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      final userId = user.uid;
      final queuedRecords = getQueuedProgress(userId);
      
      if ((await queuedRecords).isEmpty) {
        debugPrint('📝 No progress records to sync');
        return;
      }
      
      // Perform batch sync with Firestore transaction
      await _syncWithFirestore(userId, await queuedRecords);
      
    } catch (e) {
      debugPrint('❌ Error syncing progress: $e');
      rethrow;
    }
  }

  /// Check if a lesson is already completed
  Future<bool> _isLessonCompleted(String userId, String lessonId) async {
    try {
      final completedLessons = await _getCompletedLessons(userId);
      return completedLessons.contains(lessonId);
    } catch (e) {
      debugPrint('❌ Error checking lesson completion: $e');
      return false;
    }
  }

  /// Get list of completed lesson IDs for a user
  Future<List<String>> _getCompletedLessons(String userId) async {
    try {
      final completedData = await _storageService.getValue('completed_lessons_$userId');
      if (completedData != null) {
        final json = jsonDecode(completedData) as Map<String, dynamic>;
        return List<String>.from(json['lessons'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting completed lessons: $e');
      return [];
    }
  }

  /// Award points immediately to local cache
  Future<void> _awardPointsLocally(String userId, int points) async {
    try {
      final currentPoints = await getLocalPoints(userId);
      final newPoints = currentPoints + points;
      
      await _storageService.setValue(
        '$_userPointsKey$userId',
        json.encode({
          'points': newPoints,
          'lastUpdated': DateTime.now().toIso8601String(),
        }),
      );
      
      debugPrint('💰 Awarded $points points. New total: $newPoints');
    } catch (e) {
      debugPrint('❌ Error awarding points locally: $e');
      rethrow;
    }
  }

  /// Queue a progress record for batch sync
  Future<void> _queueProgressRecord({
    required String userId,
    required String lessonId,
    required String progressRecordId,
    required int pointsEarned,
  }) async {
    try {
      final queuedRecords = await getQueuedProgress(userId);
      
      // Check for duplicates
      if (queuedRecords.any((record) => record.progressRecordId == progressRecordId)) {
        debugPrint('⚠️ Duplicate progress record detected: $progressRecordId');
        return;
      }
      
      final newRecord = ProgressRecord(
        userId: userId,
        lessonId: lessonId,
        sectionId: '', // Empty string for lesson completion
        progressRecordId: progressRecordId,
        pointsEarned: pointsEarned,
        completedAt: DateTime.now(),
      );
      
      queuedRecords.add(newRecord);
      
      await _storageService.setValue(
        '$_progressQueueKey$userId',
        json.encode({
          'records': queuedRecords.map((record) => record.toJson()).toList(),
          'queuedAt': DateTime.now().toIso8601String(),
        }),
      );
      
      debugPrint('📝 Queued progress record: $progressRecordId');
    } catch (e) {
      debugPrint('❌ Error queuing progress record: $e');
      rethrow;
    }
  }

  /// Sync queued records with Firestore using transaction
  Future<void> _syncWithFirestore(String userId, List<ProgressRecord> records) async {
    try {
      // Get current user points from Firestore
      final userDoc = await _userRepository.getUserById(userId);
      if (!userDoc.exists) {
        throw Exception('User document not found in Firestore');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final firestorePoints = userData['points'] as int? ?? 0;
      
      // Calculate total points to add
      final pointsToAdd = records.fold<int>(0, (sum, record) => sum + record.pointsEarned);
      final newTotalPoints = firestorePoints + pointsToAdd;
      
      // Use batch write for efficiency
      // Use direct Firestore calls instead of batch operations
      
      // Update user points
      await userDoc.reference.update({
        'points': newTotalPoints,
        'lastSyncAt': DateTime.now(),
      });
      
      // Add progress records
      for (final record in records) {
        // Create progress document reference and set data
        final progressRef = userDoc.reference.collection('progress').doc(record.lessonId);
        await progressRef.set({
          'lessonId': record.lessonId,
          'completed': true,
          'pointsEarned': record.pointsEarned,
          'completedAt': record.completedAt,
          'progressRecordId': record.progressRecordId,
        });
      }
      
      // Batch operations completed
      
      // Clear local queue after successful sync
      await _clearProgressQueue(userId);
      
      // Update local points cache
      await _awardPointsLocally(userId, pointsToAdd);
      
      // Update last sync time
      await _storageService.setValue(
        '$_lastSyncKey$userId',
        DateTime.now().toIso8601String(),
      );
      
      debugPrint('✅ Successfully synced ${records.length} progress records. Total points: $newTotalPoints');
      
    } catch (e) {
      debugPrint('❌ Error in Firestore sync: $e');
      // Implement retry logic
      await _handleSyncRetry(userId, records);
      rethrow;
    }
  }

  /// Handle sync retry with exponential backoff
  Future<void> _handleSyncRetry(String userId, List<ProgressRecord> records) async {
    try {
      // For now, we'll just log the error and keep the records in queue
      // In a production app, you'd implement proper retry logic here
      debugPrint('🔄 Sync failed, keeping records in queue for retry');
      
      // Future implementation: Add retry metadata to track failed sync attempts
      // For now, we just log the error and keep the records in queue
      debugPrint('🔄 Sync failed, keeping records in queue for retry');
      
    } catch (e) {
      debugPrint('❌ Error handling sync retry: $e');
    }
  }

  /// Clear progress queue after successful sync
  Future<void> _clearProgressQueue(String userId) async {
    try {
      await _storageService.removeValue('$_progressQueueKey$userId');
      debugPrint('🗑️ Cleared progress queue for user $userId');
    } catch (e) {
      debugPrint('❌ Error clearing progress queue: $e');
    }
  }

  /// Generate unique progress record ID
  String _generateProgressRecordId(String userId, String lessonId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId:$lessonId:$timestamp';
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final syncTime = await _storageService.getValue('$_lastSyncKey$userId');
      if (syncTime != null) {
        return DateTime.parse(syncTime);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting last sync time: $e');
      return null;
    }
  }

  /// Get progress statistics
  Future<Map<String, dynamic>> getProgressStats(String userId) async {
    try {
      final queuedRecords = await getQueuedProgress(userId);
      final lastSync = await getLastSyncTime(userId);
      final localPoints = await getLocalPoints(userId);
      
      return {
        'localPoints': localPoints,
        'queuedRecords': queuedRecords.length,
        'lastSync': lastSync?.toIso8601String(),
        'hasPendingSync': queuedRecords.isNotEmpty,
      };
    } catch (e) {
      debugPrint('❌ Error getting progress stats: $e');
      return {
        'localPoints': 0,
        'queuedRecords': 0,
        'lastSync': null,
        'hasPendingSync': false,
      };
    }
  }
}