import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/quiz_model.dart';

/// Service for handling incremental sync of quiz question updates
/// Minimizes Firebase costs by only syncing changed content
class IncrementalSyncService {
  static const String _lastSyncPrefix = 'quiz_last_sync_';
  static const int _syncIntervalSeconds = 300; // 5 minutes
  static const int _maxPendingUpdates = 50; // Max updates to queue before sync
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _pendingUpdates = [];
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  /// Singleton instance
  static final IncrementalSyncService _instance = IncrementalSyncService._internal();
  
  factory IncrementalSyncService() => _instance;
  
  IncrementalSyncService._internal();
  
  /// Initialize sync service and start periodic sync
  Future<void> initialize() async {
    _ensureSyncTimer();
    await _loadPendingUpdates();
  }
  
  /// Queue a quiz update for incremental sync
  Future<void> queueQuizUpdate({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
    required String operation, // 'create', 'update', 'delete'
  }) async {
    final updateId = _generateUpdateId();
    final updateData = {
      'id': updateId,
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'questions': questions.map((q) => q.toJson()).toList(),
      'operation': operation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };
    
    _pendingUpdates.add(updateData);
    
    // Save to persistent storage
    await _savePendingUpdates();
    
    // Check if we need to sync immediately
    if (_pendingUpdates.length >= _maxPendingUpdates) {
      await _syncPendingUpdates();
    }
    
    // Update last sync timestamp
    await _updateLastSyncTimestamp(grade, subject, topic);
    
    debugPrint('Queued quiz update: $operation for $grade/$subject/$topic');
  }
  
  /// Get last sync timestamp for a specific quiz
  Future<int?> getLastSyncTimestamp({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final key = '$_lastSyncPrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      debugPrint('Error reading sync timestamp: $e');
      return null;
    }
  }
  
  /// Check if quiz needs sync based on last sync time
  Future<bool> needsSync({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    final lastSync = await getLastSyncTimestamp(
      grade: grade,
      subject: subject,
      topic: topic,
    );
    
    if (lastSync == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final syncThreshold = _syncIntervalSeconds * 1000;
    
    return (now - lastSync) > syncThreshold;
  }
  
  /// Force immediate sync of all pending updates
  Future<void> forceSync() async {
    if (_pendingUpdates.isNotEmpty) {
      await _syncPendingUpdates();
    }
  }
  
  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final pendingCount = _pendingUpdates.length;
    final syncedCount = _pendingUpdates.where((u) => u['synced'] == true).length;
    
    return {
      'total_updates': _pendingUpdates.length,
      'synced_updates': syncedCount,
      'pending_updates': pendingCount,
      'sync_in_progress': _isSyncing,
      'sync_interval_seconds': _syncIntervalSeconds,
      'max_pending_updates': _maxPendingUpdates,
    };
  }
  
  /// Clean up old synced updates
  Future<int> cleanupOldUpdates() async {
    try {
      final cutoffTime = DateTime.now().millisecondsSinceEpoch - (7 * 24 * 60 * 60 * 1000); // 7 days ago
      
      final initialCount = _pendingUpdates.length;
      _pendingUpdates.removeWhere((update) => 
        update['synced'] == true && update['timestamp'] < cutoffTime
      );
      
      await _savePendingUpdates();
      
      return initialCount - _pendingUpdates.length;
    } catch (e) {
      debugPrint('Error cleaning up old updates: $e');
      return 0;
    }
  }
  
  /// Ensure sync timer is running
  void _ensureSyncTimer() {
    _syncTimer ??= Timer.periodic(
        Duration(seconds: _syncIntervalSeconds),
        (timer) async {
          if (_pendingUpdates.isNotEmpty && !_isSyncing) {
            await _syncPendingUpdates();
          }
        },
      );
  }
  
  /// Load pending updates from persistent storage
  Future<void> _loadPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesJson = prefs.getString('pending_quiz_updates');
      
      if (updatesJson != null) {
        final updates = jsonDecode(updatesJson) as List;
        _pendingUpdates.addAll(updates.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Error loading pending updates: $e');
    }
  }
  
  /// Save pending updates to persistent storage
  Future<void> _savePendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesJson = jsonEncode(_pendingUpdates);
      await prefs.setString('pending_quiz_updates', updatesJson);
    } catch (e) {
      debugPrint('Error saving pending updates: $e');
    }
  }
  
  /// Sync pending updates to Firebase
  Future<void> _syncPendingUpdates() async {
    if (_pendingUpdates.isEmpty || _isSyncing) return;
    
    _isSyncing = true;
    
    try {
      // Process updates in batches
      final updatesToSync = List<Map<String, dynamic>>.from(_pendingUpdates);
      
      for (final update in updatesToSync) {
        if (update['synced'] == true) continue;
        
        await _processUpdate(update);
        update['synced'] = true;
      }
      
      // Remove synced updates
      _pendingUpdates.removeWhere((update) => update['synced'] == true);
      
      // Save updated state
      await _savePendingUpdates();
      
      debugPrint('Synced ${updatesToSync.length} quiz updates');
    } catch (e) {
      debugPrint('Error syncing pending updates: $e');
      // Don't remove pending updates on error, retry on next sync
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Process a single update
  Future<void> _processUpdate(Map<String, dynamic> update) async {
    final grade = update['grade'];
    final subject = update['subject'];
    final topic = update['topic'];
    final operation = update['operation'];
    final questions = (update['questions'] as List)
        .map((q) => QuizQuestion.fromJson(q))
        .toList();
    
    final batch = _firestore.batch();
    
    switch (operation) {
      case 'create':
      case 'update':
        final docRef = _firestore
            .collection('quizzes')
            .doc(grade)
            .collection(subject)
            .doc(topic);
        
        final quizData = {
          'questions': questions.map((q) => q.toJson()).toList(),
          'metadata': {
            'totalQuestions': questions.length,
            'lastUpdated': DateTime.now().toIso8601String(),
            'grade': grade,
            'subject': subject,
            'topic': topic,
          },
        };
        
        batch.set(docRef, quizData, SetOptions(merge: true));
        break;
        
      case 'delete':
        final docRef = _firestore
            .collection('quizzes')
            .doc(grade)
            .collection(subject)
            .doc(topic);
        
        batch.delete(docRef);
        break;
    }
    
    await batch.commit();
  }
  
  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp(
    String grade,
    String subject,
    String topic,
  ) async {
    final key = '$_lastSyncPrefix${grade}_${subject}_$topic';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(key, now);
    } catch (e) {
      debugPrint('Error updating sync timestamp: $e');
    }
  }
  
  /// Generate unique update ID
  String _generateUpdateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 10000;
    return 'update_${now}_$random';
  }
  
  /// Dispose sync timer and clean up
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

/// Service for handling conflict resolution during sync
class SyncConflictResolutionService {
  /// Detect and resolve conflicts between local and remote quiz data
  static Future<Map<String, dynamic>> resolveConflict({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> localData,
    required List<QuizQuestion> remoteData,
    required int localTimestamp,
    required int remoteTimestamp,
  }) async {
    // If remote is newer, use remote data
    if (remoteTimestamp > localTimestamp) {
      return {
        'resolved_data': remoteData,
        'resolution': 'remote_wins',
        'reason': 'Remote data is newer',
      };
    }
    
    // If local is newer, use local data
    if (localTimestamp > remoteTimestamp) {
      return {
        'resolved_data': localData,
        'resolution': 'local_wins',
        'reason': 'Local data is newer',
      };
    }
    
    // If timestamps are equal, merge intelligently
    return {
      'resolved_data': _mergeQuizData(localData, remoteData),
      'resolution': 'merged',
      'reason': 'Equal timestamps, merged data',
    };
  }
  
  /// Merge quiz data intelligently
  static List<QuizQuestion> _mergeQuizData(
    List<QuizQuestion> localData,
    List<QuizQuestion> remoteData,
  ) {
    // Simple merge: prefer remote data for conflicts
    final merged = <QuizQuestion>[];
    final remoteQuestions = {for (final q in remoteData) q.id: q};
    
    // Add all local questions that don't exist in remote
    for (final localQuestion in localData) {
      if (!remoteQuestions.containsKey(localQuestion.id)) {
        merged.add(localQuestion);
      }
    }
    
    // Add all remote questions
    merged.addAll(remoteData);
    
    return merged;
  }
}