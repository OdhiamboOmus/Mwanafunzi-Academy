import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';

// Lesson completion service with comprehensive logging
class LessonCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark lesson as completed with logging
  Future<void> markLessonCompleted({
    required String lessonId,
    required String bookingId,
    required String teacherId,
    required String studentId,
    required String subject,
    required DateTime scheduledDate,
    String? teacherNotes,
  }) async {
    developer.log('LessonCompletionService: Starting lesson completion for lesson $lessonId');
    
    try {
      // Create lesson completion record
      final lessonData = {
        'id': lessonId,
        'bookingId': bookingId,
        'teacherId': teacherId,
        'studentId': studentId,
        'subject': subject,
        'scheduledDate': scheduledDate,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'teacherNotes': teacherNotes,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore.collection('lessons').doc(lessonId).set(lessonData);
      developer.log('LessonCompletionService: Lesson $lessonId marked as completed successfully');

      // Update booking progress
      await _updateBookingProgress(bookingId);
      developer.log('LessonCompletionService: Booking $bookingId progress updated');

      // Trigger payout calculation if all lessons completed
      await _checkForPayoutTrigger(bookingId);
      developer.log('LessonCompletionService: Payout check completed for booking $bookingId');

    } catch (e) {
      developer.log('LessonCompletionService: Error marking lesson $lessonId as completed - Error: $e');
      throw Exception('Failed to mark lesson as completed: ${e.toString()}');
    }
  }

  // Update booking progress with logging
  Future<void> _updateBookingProgress(String bookingId) async {
    developer.log('LessonCompletionService: Updating progress for booking $bookingId');
    
    try {
      // Get all lessons for this booking
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      final completedLessons = lessonsSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;

      final totalLessons = lessonsSnapshot.docs.length;

      // Update booking with progress
      await _firestore.collection('bookings').doc(bookingId).update({
        'completedLessons': completedLessons,
        'totalLessons': totalLessons,
        'progress': totalLessons > 0 ? completedLessons / totalLessons : 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('LessonCompletionService: Booking $bookingId progress updated - $completedLessons/$totalLessons completed');

    } catch (e) {
      developer.log('LessonCompletionService: Error updating booking $bookingId progress - Error: $e');
      throw Exception('Failed to update booking progress: ${e.toString()}');
    }
  }

  // Check if payout should be triggered with logging
  Future<void> _checkForPayoutTrigger(String bookingId) async {
    developer.log('LessonCompletionService: Checking payout trigger for booking $bookingId');
    
    try {
      // Get booking details
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      final booking = bookingDoc.data() as Map<String, dynamic>;

      if (booking == null) {
        developer.log('LessonCompletionService: Booking $bookingId not found');
        return;
      }

      // Get all lessons for this booking
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      final completedLessons = lessonsSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;

      final totalLessons = lessonsSnapshot.docs.length;

      // Check if all lessons are completed
      if (completedLessons == totalLessons && totalLessons > 0) {
        developer.log('LessonCompletionService: All lessons completed for booking $bookingId, triggering payout');
        
        // Update booking status to completed
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // TODO: Trigger payout process via Cloud Function
        // This would call the payout processor function
        developer.log('LessonCompletionService: Payout would be triggered for booking $bookingId');
      }

    } catch (e) {
      developer.log('LessonCompletionService: Error checking payout trigger for booking $bookingId - Error: $e');
      throw Exception('Failed to check payout trigger: ${e.toString()}');
    }
  }

  // Get teacher's upcoming lessons with logging
  Future<List<Map<String, dynamic>>> getTeacherUpcomingLessons(String teacherId) async {
    developer.log('LessonCompletionService: Getting upcoming lessons for teacher $teacherId');
    
    try {
      final now = DateTime.now();
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('scheduledDate', isGreaterThan: now)
          .where('status', whereIn: ['scheduled', 'active'])
          .orderBy('scheduledDate')
          .limit(10)
          .get();

      final lessons = lessonsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      developer.log('LessonCompletionService: Found ${lessons.length} upcoming lessons for teacher $teacherId');
      return lessons;

    } catch (e) {
      developer.log('LessonCompletionService: Error getting upcoming lessons for teacher $teacherId - Error: $e');
      throw Exception('Failed to get upcoming lessons: ${e.toString()}');
    }
  }

  // Get teacher's completed lessons with logging
  Future<List<Map<String, dynamic>>> getTeacherCompletedLessons(String teacherId) async {
    developer.log('LessonCompletionService: Getting completed lessons for teacher $teacherId');
    
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThan: thirtyDaysAgo)
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();

      final lessons = lessonsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      developer.log('LessonCompletionService: Found ${lessons.length} completed lessons for teacher $teacherId');
      return lessons;

    } catch (e) {
      developer.log('LessonCompletionService: Error getting completed lessons for teacher $teacherId - Error: $e');
      throw Exception('Failed to get completed lessons: ${e.toString()}');
    }
  }

  // Get attendance statistics for teacher with logging
  Future<Map<String, dynamic>> getTeacherAttendanceStats(String teacherId) async {
    developer.log('LessonCompletionService: Getting attendance stats for teacher $teacherId');
    
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get lessons from last 30 days
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('scheduledDate', isGreaterThan: thirtyDaysAgo)
          .get();

      final totalLessons = lessonsSnapshot.docs.length;
      final completedLessons = lessonsSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;
      const missedLessons = 0; // Placeholder - would be calculated from actual data

      final attendanceRate = totalLessons > 0 
          ? (completedLessons / totalLessons * 100).round()
          : 0;

      final stats = {
        'totalLessons': totalLessons,
        'completedLessons': completedLessons,
        'missedLessons': missedLessons,
        'attendanceRate': attendanceRate,
        'period': 'Last 30 days',
      };

      developer.log('LessonCompletionService: Attendance stats for teacher $teacherId - $stats');
      return stats;

    } catch (e) {
      developer.log('LessonCompletionService: Error getting attendance stats for teacher $teacherId - Error: $e');
      throw Exception('Failed to get attendance stats: ${e.toString()}');
    }
  }
}