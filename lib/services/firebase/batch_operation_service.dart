import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint;
import '../../data/models/quiz_model.dart';

/// Service for batching operations to minimize Firebase costs
class BatchOperationService {
  static const int _maxBatchSize = 50;
  static const int _syncIntervalSeconds = 300; // 5 minutes
  static const int _maxPendingAttempts = 10; // Sync after 10 attempts
  
  final List<QuizAttempt> _pendingAttempts = [];
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  /// Singleton instance
  static final BatchOperationService _instance = BatchOperationService._internal();
  
  factory BatchOperationService() => _instance;
  
  BatchOperationService._internal();
  
  /// Queue a quiz attempt for batch processing
  Future<void> queueQuizAttempt(QuizAttempt attempt) async {
    _pendingAttempts.add(attempt);
    
    // Check if we need to sync immediately
    if (_pendingAttempts.length >= _maxPendingAttempts) {
      await _flushBatch();
    }
    
    // Start sync timer if not already running
    _ensureSyncTimer();
  }
  
  /// Ensure sync timer is running
  void _ensureSyncTimer() {
    _syncTimer ??= Timer.periodic(
        Duration(seconds: _syncIntervalSeconds),
        (timer) async {
          if (_pendingAttempts.isNotEmpty && !_isSyncing) {
            await _flushBatch();
          }
        },
      );
  }
  
  /// Flush pending attempts to Firebase in batches
  Future<void> _flushBatch() async {
    if (_pendingAttempts.isEmpty || _isSyncing) return;
    
    _isSyncing = true;
    
    try {
      // Process in batches of maxBatchSize
      for (int i = 0; i < _pendingAttempts.length; i += _maxBatchSize) {
        final batchEnd = min(i + _maxBatchSize, _pendingAttempts.length);
        final batchAttempts = _pendingAttempts.sublist(i, batchEnd);
        
        await _writeBatchToFirebase(batchAttempts);
      }
      
      // Clear all processed attempts
      _pendingAttempts.clear();
    } catch (e) {
      debugPrint('Error flushing batch: $e');
      // Don't clear pending attempts on error, retry on next sync
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Write a batch of attempts to Firebase
  Future<void> _writeBatchToFirebase(List<QuizAttempt> attempts) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (final attempt in attempts) {
      final docRef = FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(attempt.studentId)
          .collection('regular')
          .doc();
      
      batch.set(docRef, attempt.toJson());
    }
    
    await batch.commit();
  }
  
  /// Get current number of pending attempts
  int get pendingAttemptsCount => _pendingAttempts.length;
  
  /// Check if service is currently syncing
  bool get isSyncing => _isSyncing;
  
  /// Force immediate sync of all pending attempts
  Future<void> forceSync() async {
    if (_pendingAttempts.isNotEmpty) {
      await _flushBatch();
    }
  }
  
  /// Cancel sync timer and clean up
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  /// Get pending attempts for debugging
  List<QuizAttempt> get pendingAttempts => List.unmodifiable(_pendingAttempts);
}

/// Service for handling competition challenges with atomic updates
class CompetitionChallengeService {
  /// Create a challenge with atomic document write
  Future<String> createChallenge({
    required String challengerId,
    required String challengerName,
    required String challengerSchool,
    required String challengedId,
    required String challengedName,
    required String challengedSchool,
    required String topic,
    required String subject,
    required String grade,
    required List<QuizQuestion> questions,
  }) async {
    final challengeId = _generateChallengeId();
    
    final challengeData = {
      'id': challengeId,
      'challenger': {
        'studentId': challengerId,
        'name': challengerName,
        'school': challengerSchool,
      },
      'challenged': {
        'studentId': challengedId,
        'name': challengedName,
        'school': challengedSchool,
      },
      'topic': topic,
      'subject': subject,
      'grade': grade,
      'status': 'pending',
      'questions': questions.map((q) => q.toJson()).toList(),
      'results': null,
      'createdAt': DateTime.now().toIso8601String(),
      'completedAt': null,
    };
    
    // Atomic document creation
    await FirebaseFirestore.instance
        .collection('student_challenges')
        .doc(challengeId)
        .set(challengeData);
    
    return challengeId;
  }
  
  /// Complete a challenge with atomic update
  Future<void> completeChallenge({
    required String challengeId,
    required String studentId,
    required List<int> answers,
  }) async {
    final challengeDoc = await FirebaseFirestore.instance
        .collection('student_challenges')
        .doc(challengeId)
        .get();
    
    if (!challengeDoc.exists) {
      throw Exception('Challenge not found');
    }
    
    final challengeData = challengeDoc.data()!;
    final questions = (challengeData['questions'] as List)
        .map((q) => QuizQuestion.fromJson(q))
        .toList();
    
    // Calculate score
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (questions[i].isCorrect(answers[i])) {
        score++;
      }
    }
    
    // Determine if this is the challenger or challenged student
    final isChallenger = studentId == challengeData['challenger']['studentId'];
    final studentField = isChallenger ? 'challengerScore' : 'challengedScore';
    
    // Check if both students have completed
    final challengerCompleted = challengeData['results']?['challengerScore'] != null;
    final challengedCompleted = challengeData['results']?['challengedScore'] != null;
    
    Map<String, dynamic> results;
    String status;
    
    if (challengerCompleted && challengedCompleted) {
      // Both completed, determine winner
      final challengerScore = challengeData['results']!['challengerScore'];
      final challengedScore = challengeData['results']!['challengedScore'];
      
      String winner;
      Map<String, dynamic> pointsAwarded;
      
      if (challengerScore > challengedScore) {
        winner = challengeData['challenger']['studentId'];
        pointsAwarded = {
          'challenger': challengerScore + 3, // Winner bonus
          'challenged': challengedScore,
        };
      } else if (challengedScore > challengerScore) {
        winner = challengeData['challenged']['studentId'];
        pointsAwarded = {
          'challenger': challengerScore,
          'challenged': challengedScore + 3, // Winner bonus
        };
      } else {
        winner = 'draw';
        pointsAwarded = {
          'challenger': challengerScore + 1, // Draw bonus
          'challenged': challengedScore + 1, // Draw bonus
        };
      }
      
      results = {
        'challengerScore': challengerScore,
        'challengedScore': challengedScore,
        'winner': winner,
        'pointsAwarded': pointsAwarded,
      };
      status = 'completed';
    } else {
      // First completion, just record score
      results = Map<String, dynamic>.from(challengeData['results'] ?? {});
      results[studentField] = score;
      status = 'in_progress';
    }
    
    // Atomic update
    await FirebaseFirestore.instance
        .collection('student_challenges')
        .doc(challengeId)
        .update({
      'results': results,
      'status': status,
      if (status == 'completed') 'completedAt': DateTime.now().toIso8601String(),
    });
  }
  
  /// Generate unique challenge ID
  String _generateChallengeId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}

/// Service for handling gzip compression for uploads
class CompressionService {
  /// Compress JSON data using gzip
  Future<List<int>> compressJson(Map<String, dynamic> data) async {
    // In a real implementation, you would use the 'archive' package
    // For now, we'll simulate compression with simple JSON encoding
    final jsonString = jsonEncode(data);
    return utf8.encode(jsonString);
  }
  
  /// Get cache headers for CDN-style caching
  Map<String, String> getCdnCacheHeaders() {
    return {
      'Cache-Control': 'public, max-age=2592000', // 30 days
      'Content-Type': 'application/json',
    };
  }
}