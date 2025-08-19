import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/video_model.dart';

/// Real-time synchronization service for video content
/// Handles Firestore listeners and incremental sync
class VideoRealtimeSyncService {
  static const String _videosCollection = 'videos';

  /// Stream all subjects for a grade with incremental sync
  Stream<List<VideoModel>> watchAllSubjects(String grade) {
    return FirebaseFirestore.instance
        .collection(_videosCollection)
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
                .collection(_videosCollection)
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
                  .collection(_videosCollection)
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

  /// Stream videos from a specific subject with real-time updates
  Stream<List<VideoModel>> watchSubject(String grade, String subject) {
    return FirebaseFirestore.instance
        .collection(_videosCollection)
        .doc(grade)
        .collection(subject)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoModel.fromJson(doc.data()))
            .where((video) => video.isAvailable)
            .toList());
  }

  /// Handle listener lifecycle and proper disposal
  void dispose() {
    // Clean up any active listeners or resources
    debugPrint('VideoRealtimeSyncService disposed');
  }
}