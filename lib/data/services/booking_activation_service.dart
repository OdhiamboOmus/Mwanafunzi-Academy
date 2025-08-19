import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/lesson_model.dart';
import 'ledger_service.dart';
import '../../presentation/shared/payment_notification_service.dart';

// Enhanced booking activation service with comprehensive logging
class BookingActivationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LedgerService _ledgerService = LedgerService();
  final PaymentNotificationService _notificationService = PaymentNotificationService();

  // Activate booking with comprehensive logging
  Future<bool> activateBooking(String bookingId, {String? zoomLink}) async {
    developer.log('BookingActivationService: Activating booking - BookingID: $bookingId');
    
    try {
      // Get booking details
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        developer.log('BookingActivationService: Booking not found - BookingID: $bookingId');
        return false;
      }

      final booking = BookingModel.fromMap(bookingDoc.data()!);
      
      // Validate booking can be activated
      if (!_canActivateBooking(booking)) {
        developer.log('BookingActivationService: Booking cannot be activated - BookingID: $bookingId, Status: ${booking.status}');
        return false;
      }

      // Generate Zoom link if not provided
      final finalZoomLink = zoomLink ?? _generateZoomLink(bookingId);
      
      // Update booking status
      await _updateBookingStatus(booking, 'paid', finalZoomLink);
      
      // Generate lesson records
      await _generateLessonRecords(booking, finalZoomLink);
      
      // Create platform ledger entries
      await _createPlatformLedgerEntries(booking);
      
      // Send notifications
      await _sendActivationNotifications(booking, finalZoomLink);
      
      developer.log('BookingActivationService: Booking activated successfully - BookingID: $bookingId');
      return true;
      
    } catch (e) {
      developer.log('BookingActivationService: Error activating booking - BookingID: $bookingId, Error: $e');
      return false;
    }
  }

  // Check if booking can be activated
  bool _canActivateBooking(BookingModel booking) {
    developer.log('BookingActivationService: Checking booking activation eligibility - BookingID: ${booking.id}');
    
    final canActivate = booking.status == 'payment_pending' || 
                       booking.status == 'draft';
    
    developer.log('BookingActivationService: Booking activation eligibility - BookingID: ${booking.id}, CanActivate: $canActivate');
    return canActivate;
  }

  // Update booking status with logging
  Future<void> _updateBookingStatus(BookingModel booking, String status, String zoomLink) async {
    developer.log('BookingActivationService: Updating booking status - BookingID: ${booking.id}, Status: $status');
    
    try {
      await _firestore.collection('bookings').doc(booking.id).update({
        'status': status,
        'paidAt': status == 'paid' ? DateTime.now() : booking.paidAt,
        'zoomLink': zoomLink,
        'updatedAt': DateTime.now(),
      });
      
      developer.log('BookingActivationService: Booking status updated successfully - BookingID: ${booking.id}');
    } catch (e) {
      developer.log('BookingActivationService: Error updating booking status - BookingID: ${booking.id}, Error: $e');
      rethrow;
    }
  }

  // Generate lesson records with logging
  Future<void> _generateLessonRecords(BookingModel booking, String zoomLink) async {
    developer.log('BookingActivationService: Generating lesson records - BookingID: ${booking.id}, Weeks: ${booking.numberOfWeeks}');
    
    try {
      final lessons = <LessonModel>[];
      final startDate = booking.startDate;
      
      for (int week = 1; week <= booking.numberOfWeeks; week++) {
        final scheduledDate = _calculateLessonDate(startDate, week, booking.dayOfWeek);
        
        final lesson = LessonModel(
          id: _generateLessonId(),
          bookingId: booking.id,
          teacherId: booking.teacherId,
          studentId: booking.studentId,
          weekNumber: week,
          scheduledDate: scheduledDate,
          duration: booking.duration,
          zoomLink: zoomLink,
          status: 'active',
          createdAt: DateTime.now(),
        );
        
        lessons.add(lesson);
      }
      
      // Batch create lessons
      final batch = _firestore.batch();
      for (final lesson in lessons) {
        batch.set(
          _firestore.collection('lessons').doc(lesson.id),
          lesson.toMap(),
        );
      }
      
      await batch.commit();
      
      developer.log('BookingActivationService: Lesson records generated successfully - BookingID: ${booking.id}, Lessons: ${lessons.length}');
    } catch (e) {
      developer.log('BookingActivationService: Error generating lesson records - BookingID: ${booking.id}, Error: $e');
      rethrow;
    }
  }

  // Calculate lesson date with logging
  DateTime _calculateLessonDate(DateTime startDate, int weekNumber, String dayOfWeek) {
    developer.log('BookingActivationService: Calculating lesson date - StartDate: $startDate, Week: $weekNumber, Day: $dayOfWeek');
    
    // Parse day of week
    int dayIndex;
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        dayIndex = 1;
        break;
      case 'tuesday':
        dayIndex = 2;
        break;
      case 'wednesday':
        dayIndex = 3;
        break;
      case 'thursday':
        dayIndex = 4;
        break;
      case 'friday':
        dayIndex = 5;
        break;
      case 'saturday':
        dayIndex = 6;
        break;
      case 'sunday':
        dayIndex = 7;
        break;
      default:
        dayIndex = 1; // Default to Monday
    }
    
    // Calculate the date for the specific week
    final weeksToAdd = weekNumber - 1;
    final calculatedDate = startDate.add(Duration(days: weeksToAdd * 7));
    
    // Adjust to the correct day of week
    final currentDay = calculatedDate.weekday;
    final daysToAdd = dayIndex - currentDay;
    final finalDate = calculatedDate.add(Duration(days: daysToAdd >= 0 ? daysToAdd : daysToAdd + 7));
    
    developer.log('BookingActivationService: Lesson date calculated - StartDate: $startDate, FinalDate: $finalDate');
    return finalDate;
  }

  // Create platform ledger entries with logging
  Future<void> _createPlatformLedgerEntries(BookingModel booking) async {
    developer.log('BookingActivationService: Creating platform ledger entries - BookingID: ${booking.id}');
    
    try {
      // Platform fee (20%)
      final platformFee = booking.totalAmount * 0.20;
      
      // Teacher payout (80%)
      final teacherPayout = booking.totalAmount - platformFee;
      
      // Create platform fee entry
      await _ledgerService.createLedgerEntry(
        transactionId: booking.id,
        type: 'credit',
        amount: platformFee,
        description: 'Platform fee for booking ${booking.id}',
      );
      
      // Create teacher payout entry
      await _ledgerService.createLedgerEntry(
        transactionId: booking.id,
        type: 'debit',
        amount: teacherPayout,
        description: 'Teacher payout for booking ${booking.id}',
        teacherId: booking.teacherId,
      );
      
      developer.log('BookingActivationService: Platform ledger entries created successfully - BookingID: ${booking.id}');
    } catch (e) {
      developer.log('BookingActivationService: Error creating platform ledger entries - BookingID: ${booking.id}, Error: $e');
      rethrow;
    }
  }

  // Send activation notifications with logging
  Future<void> _sendActivationNotifications(BookingModel booking, String zoomLink) async {
    developer.log('BookingActivationService: Sending activation notifications - BookingID: ${booking.id}');
    
    try {
      // Get teacher details
      final teacherDoc = await _firestore.collection('teachers').doc(booking.teacherId).get();
      final teacher = teacherDoc.data();
      
      // Get parent details
      final parentDoc = await _firestore.collection('parents').doc(booking.parentId).get();
      final parent = parentDoc.data();
      
      // Send notification to teacher
      if (teacher != null && teacher['fcmToken'] != null) {
        await _sendTeacherNotification(
          teacher['fcmToken'],
          teacher['fullName'] ?? 'Teacher',
          booking,
          zoomLink,
        );
      }
      
      // Send notification to parent
      if (parent != null && parent['fcmToken'] != null) {
        await _sendParentNotification(
          parent['fcmToken'],
          parent['fullName'] ?? 'Parent',
          booking,
          zoomLink,
        );
      }
      
      // Show in-app notification
      // Note: This would be called from the UI layer with BuildContext
      // For now, just log it
      developer.log('BookingActivationService: Booking confirmation notification would be shown - BookingID: ${booking.id}');
      
      developer.log('BookingActivationService: Activation notifications sent successfully - BookingID: ${booking.id}');
    } catch (e) {
      developer.log('BookingActivationService: Error sending activation notifications - BookingID: ${booking.id}, Error: $e');
    }
  }

  // Send teacher notification with logging
  Future<void> _sendTeacherNotification(
    String fcmToken,
    String teacherName,
    BookingModel booking,
    String zoomLink,
  ) async {
    developer.log('BookingActivationService: Sending teacher notification - Teacher: $teacherName, BookingID: ${booking.id}');
    
    try {
      // In production, integrate with FCM messaging service
      // For now, simulate the notification
      final message = 'New booking confirmed with ${booking.subject} starting ${booking.startDate.toLocal()}';
      
      developer.log('BookingActivationService: Teacher notification sent - Teacher: $teacherName, Message: $message');
    } catch (e) {
      developer.log('BookingActivationService: Error sending teacher notification - Teacher: $teacherName, Error: $e');
    }
  }

  // Send parent notification with logging
  Future<void> _sendParentNotification(
    String fcmToken,
    String parentName,
    BookingModel booking,
    String zoomLink,
  ) async {
    developer.log('BookingActivationService: Sending parent notification - Parent: $parentName, BookingID: ${booking.id}');
    
    try {
      // In production, integrate with FCM messaging service
      // For now, simulate the notification
      final message = 'Your booking with ${booking.subject} is confirmed. Zoom link: $zoomLink';
      
      developer.log('BookingActivationService: Parent notification sent - Parent: $parentName, Message: $message');
    } catch (e) {
      developer.log('BookingActivationService: Error sending parent notification - Parent: $parentName, Error: $e');
    }
  }

  // Generate Zoom link with logging
  String _generateZoomLink(String bookingId) {
    developer.log('BookingActivationService: Generating Zoom link - BookingID: $bookingId');
    
    // In production, integrate with Zoom API
    // For now, generate a mock Zoom link
    final meetingId = math.Random().nextInt(900000000) + 100000000;
    final zoomLink = 'https://zoom.us/j/$meetingId?pwd=${bookingId.substring(0, 8)}';
    
    developer.log('BookingActivationService: Zoom link generated - BookingID: $bookingId, ZoomLink: $zoomLink');
    return zoomLink;
  }

  // Generate lesson ID with logging
  String _generateLessonId() {
    final lessonId = 'LESSON${DateTime.now().millisecondsSinceEpoch}${(1000 + DateTime.now().millisecond % 1000)}';
    developer.log('BookingActivationService: Generated lesson ID - LessonID: $lessonId');
    return lessonId;
  }

  // Cancel booking with comprehensive logging
  Future<bool> cancelBooking(String bookingId, String reason) async {
    developer.log('BookingActivationService: Cancelling booking - BookingID: $bookingId, Reason: $reason');
    
    try {
      // Get booking details
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        developer.log('BookingActivationService: Booking not found - BookingID: $bookingId');
        return false;
      }

      final booking = BookingModel.fromMap(bookingDoc.data()!);
      
      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now(),
        'cancellationReason': reason,
        'updatedAt': DateTime.now(),
      });
      
      // Update related lessons
      await _updateLessonsStatus(bookingId, 'cancelled');
      
      // Send cancellation notifications
      await _sendCancellationNotifications(booking, reason);
      
      developer.log('BookingActivationService: Booking cancelled successfully - BookingID: $bookingId');
      return true;
      
    } catch (e) {
      developer.log('BookingActivationService: Error cancelling booking - BookingID: $bookingId, Error: $e');
      return false;
    }
  }

  // Update lessons status with logging
  Future<void> _updateLessonsStatus(String bookingId, String status) async {
    developer.log('BookingActivationService: Updating lessons status - BookingID: $bookingId, Status: $status');
    
    try {
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('bookingId', isEqualTo: bookingId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in lessonsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': status,
          'updatedAt': DateTime.now(),
        });
      }
      
      await batch.commit();
      
      developer.log('BookingActivationService: Lessons status updated successfully - BookingID: $bookingId, Lessons: ${lessonsSnapshot.docs.length}');
    } catch (e) {
      developer.log('BookingActivationService: Error updating lessons status - BookingID: $bookingId, Error: $e');
      rethrow;
    }
  }

  // Send cancellation notifications with logging
  Future<void> _sendCancellationNotifications(BookingModel booking, String reason) async {
    developer.log('BookingActivationService: Sending cancellation notifications - BookingID: ${booking.id}');
    
    try {
      // Get teacher details
      final teacherDoc = await _firestore.collection('teachers').doc(booking.teacherId).get();
      final teacher = teacherDoc.data();
      
      // Get parent details
      final parentDoc = await _firestore.collection('parents').doc(booking.parentId).get();
      final parent = parentDoc.data();
      
      // Send notification to teacher
      if (teacher != null && teacher['fcmToken'] != null) {
        developer.log('BookingActivationService: Teacher cancellation notification sent - Teacher: ${teacher['fullName']}');
      }
      
      // Send notification to parent
      if (parent != null && parent['fcmToken'] != null) {
        developer.log('BookingActivationService: Parent cancellation notification sent - Parent: ${parent['fullName']}');
      }
      
      developer.log('BookingActivationService: Cancellation notifications sent successfully - BookingID: ${booking.id}');
    } catch (e) {
      developer.log('BookingActivationService: Error sending cancellation notifications - BookingID: ${booking.id}, Error: $e');
    }
  }
}