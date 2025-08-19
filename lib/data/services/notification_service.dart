import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';
import '../models/booking_model.dart';
import '../models/lesson_model.dart';

// Enhanced notification service for in-app and email notifications with comprehensive logging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send booking confirmation notification with logging
  Future<bool> sendBookingConfirmation({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String teacherName,
    required String studentName,
    required String subject,
    required DateTime startDate,
    required String zoomLink,
  }) async {
    developer.log('NotificationService: Sending booking confirmation - TeacherID: $teacherId, StudentID: $studentId, BookingID: $bookingId');
    
    try {
      // Send in-app notification to teacher
      await _sendInAppNotification(
        context: context,
        userId: teacherId,
        title: 'New Booking Confirmed',
        message: 'New booking confirmed with $studentName for $subject. Check your dashboard for details.',
        type: 'booking_confirmation',
        bookingId: bookingId,
      );

      // Send in-app notification to student
      await _sendInAppNotification(
        context: context,
        userId: studentId,
        title: 'Booking Confirmed',
        message: 'Booking confirmed with $teacherName for $subject. Check your email for the Zoom link.',
        type: 'booking_confirmation',
        bookingId: bookingId,
      );

      // Send email notifications
      await _sendBookingConfirmationEmail(
        teacherId: teacherId,
        studentId: studentId,
        teacherName: teacherName,
        studentName: studentName,
        subject: subject,
        startDate: startDate,
        zoomLink: zoomLink,
        bookingId: bookingId,
      );

      developer.log('NotificationService: Booking confirmation notifications sent successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error sending booking confirmation notifications - Error: $e');
      return false;
    }
  }

  // Send payment confirmation notification with logging
  Future<bool> sendPaymentConfirmation({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    developer.log('NotificationService: Sending payment confirmation - TeacherID: $teacherId, StudentID: $studentId, BookingID: $bookingId, Amount: $amount');
    
    try {
      // Send in-app notification to teacher
      await _sendInAppNotification(
        context: context,
        userId: teacherId,
        title: 'Payment Received',
        message: 'Payment of Ksh ${amount.toStringAsFixed(2)} received for booking. Payout will be processed after completion.',
        type: 'payment_confirmation',
        bookingId: bookingId,
      );

      // Send in-app notification to student
      await _sendInAppNotification(
        context: context,
        userId: studentId,
        title: 'Payment Successful',
        message: 'Payment of Ksh ${amount.toStringAsFixed(2)} processed successfully. Your sessions are now active.',
        type: 'payment_confirmation',
        bookingId: bookingId,
      );

      developer.log('NotificationService: Payment confirmation notifications sent successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error sending payment confirmation notifications - Error: $e');
      return false;
    }
  }

  // Send lesson completion notification with logging
  Future<bool> sendLessonCompletion({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String lessonId,
    required String teacherName,
    required String studentName,
    required String subject,
  }) async {
    developer.log('NotificationService: Sending lesson completion - TeacherID: $teacherId, StudentID: $studentId, LessonID: $lessonId');
    
    try {
      // Send in-app notification to teacher
      await _sendInAppNotification(
        context: context,
        userId: teacherId,
        title: 'Lesson Completed',
        message: 'Lesson completed with $studentName for $subject. Payout will be processed soon.',
        type: 'lesson_completion',
        bookingId: bookingId,
      );

      // Send in-app notification to student
      await _sendInAppNotification(
        context: context,
        userId: studentId,
        title: 'Lesson Completed',
        message: 'Lesson completed with $teacherName for $subject. Well done on your session!',
        type: 'lesson_completion',
        bookingId: bookingId,
      );

      developer.log('NotificationService: Lesson completion notifications sent successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error sending lesson completion notifications - Error: $e');
      return false;
    }
  }

  // Send booking cancellation notification with logging
  Future<bool> sendBookingCancellation({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String reason,
    required bool initiatedByTeacher,
  }) async {
    developer.log('NotificationService: Sending booking cancellation - TeacherID: $teacherId, StudentID: $studentId, BookingID: $bookingId');
    
    try {
      final initiator = initiatedByTeacher ? 'teacher' : 'student';
      final recipient = initiatedByTeacher ? 'student' : 'teacher';
      final recipientName = initiatedByTeacher ? 'Student' : 'Teacher';

      // Send in-app notification to the other party
      await _sendInAppNotification(
        context: context,
        userId: initiatedByTeacher ? studentId : teacherId,
        title: 'Booking Cancelled',
        message: 'Booking cancelled by $initiator. Reason: $reason',
        type: 'booking_cancellation',
        bookingId: bookingId,
      );

      developer.log('NotificationService: Booking cancellation notifications sent successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error sending booking cancellation notifications - Error: $e');
      return false;
    }
  }

  // Send verification status update notification with logging
  Future<bool> sendVerificationStatusUpdate({
    required BuildContext context,
    required String teacherId,
    required String status,
    required String? rejectionReason,
  }) async {
    developer.log('NotificationService: Sending verification status update - TeacherID: $teacherId, Status: $status');
    
    try {
      String message;
      switch (status) {
        case 'verified':
          message = 'Your teacher profile has been verified! You can now receive bookings.';
          break;
        case 'rejected':
          message = 'Your teacher profile has been rejected. Reason: ${rejectionReason ?? "Not specified"}. You can resubmit your application.';
          break;
        default:
          message = 'Your teacher profile is under review.';
      }

      await _sendInAppNotification(
        context: context,
        userId: teacherId,
        title: 'Profile Verification Update',
        message: message,
        type: 'verification_update',
      );

      developer.log('NotificationService: Verification status update notification sent successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error sending verification status update notification - Error: $e');
      return false;
    }
  }

  // Send Zoom link distribution with logging
  Future<bool> sendZoomLink({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String zoomLink,
    required DateTime sessionDate,
    required String sessionTime,
  }) async {
    developer.log('NotificationService: Sending Zoom link - TeacherID: $teacherId, StudentID: $studentId, BookingID: $bookingId');
    
    try {
      final sessionDateTime = '${sessionDate.day}/${sessionDate.month}/${sessionDate.year} at $sessionTime';

      // Send in-app notification to teacher
      await _sendInAppNotification(
        context: context,
        userId: teacherId,
        title: 'Session Details',
        message: 'Your session is scheduled for $sessionDateTime. Zoom link: $zoomLink',
        type: 'zoom_link',
        bookingId: bookingId,
      );

      // Send in-app notification to student
      await _sendInAppNotification(
        context: context,
        userId: studentId,
        title: 'Session Details',
        message: 'Your session with your teacher is scheduled for $sessionDateTime. Zoom link: $zoomLink',
        type: 'zoom_link',
        bookingId: bookingId,
      );

      // Send email notifications
      await _sendZoomLinkEmail(
        teacherId: teacherId,
        studentId: studentId,
        zoomLink: zoomLink,
        sessionDateTime: sessionDateTime,
        bookingId: bookingId,
      );

      developer.log('NotificationService: Zoom link distribution completed successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error sending Zoom link distribution - Error: $e');
      return false;
    }
  }

  // Send in-app notification with logging
  Future<void> _sendInAppNotification({
    required BuildContext context,
    required String userId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
  }) async {
    developer.log('NotificationService: Sending in-app notification - UserID: $userId, Type: $type, Title: $title');
    
    try {
      // Create notification document
      final notificationId = 'NOT${DateTime.now().millisecondsSinceEpoch}';
      final notification = {
        'id': notificationId,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'bookingId': bookingId,
        'createdAt': DateTime.now(),
        'isRead': false,
        'delivered': true,
      };

      await _firestore.collection('notifications').doc(notificationId).set(notification);
      
      // Show immediate in-app notification
      _showInAppToast(context, title, message);
      
      developer.log('NotificationService: In-app notification sent successfully - NotificationID: $notificationId');
    } catch (e) {
      developer.log('NotificationService: Error sending in-app notification - Error: $e');
    }
  }

  // Show in-app toast notification
  void _showInAppToast(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Send booking confirmation email with logging
  Future<void> _sendBookingConfirmationEmail({
    required String teacherId,
    required String studentId,
    required String teacherName,
    required String studentName,
    required String subject,
    required DateTime startDate,
    required String zoomLink,
    required String bookingId,
  }) async {
    developer.log('NotificationService: Sending booking confirmation email - TeacherID: $teacherId, StudentID: $studentId');
    
    try {
      // In a real implementation, this would integrate with an email service
      // For now, we'll log the email details
      final emailData = {
        'to': ['$teacherId@example.com', '$studentId@example.com'],
        'subject': 'Booking Confirmation - $subject',
        'body': '''
          Dear $teacherName and $studentName,
          
          Your booking for $subject has been confirmed!
          
          Details:
          - Teacher: $teacherName
          - Student: $studentName
          - Subject: $subject
          - Start Date: ${startDate.toLocal()}
          - Zoom Link: $zoomLink
          - Booking ID: $bookingId
          
          Please check your dashboard for more details.
        ''',
        'sentAt': DateTime.now(),
      };
      
      developer.log('NotificationService: Email data prepared - $emailData');
      
      // In a real app, you would send the email here
      // await _emailService.send(emailData);
      
    } catch (e) {
      developer.log('NotificationService: Error sending booking confirmation email - Error: $e');
    }
  }

  // Send Zoom link email with logging
  Future<void> _sendZoomLinkEmail({
    required String teacherId,
    required String studentId,
    required String zoomLink,
    required String sessionDateTime,
    required String bookingId,
  }) async {
    developer.log('NotificationService: Sending Zoom link email - TeacherID: $teacherId, StudentID: $studentId');
    
    try {
      // In a real implementation, this would integrate with an email service
      // For now, we'll log the email details
      final emailData = {
        'to': ['$teacherId@example.com', '$studentId@example.com'],
        'subject': 'Your Session Zoom Link',
        'body': '''
          Dear Teacher and Student,
          
          Your upcoming session details:
          
          - Session Date & Time: $sessionDateTime
          - Zoom Link: $zoomLink
          - Booking ID: $bookingId
          
          Please join the session on time using the provided Zoom link.
        ''',
        'sentAt': DateTime.now(),
      };
      
      developer.log('NotificationService: Zoom link email data prepared - $emailData');
      
      // In a real app, you would send the email here
      // await _emailService.send(emailData);
      
    } catch (e) {
      developer.log('NotificationService: Error sending Zoom link email - Error: $e');
    }
  
  }

  // Get user notifications with logging
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    developer.log('NotificationService: Getting notifications for user - UserID: $userId');
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final notifications = snapshot.docs.map((doc) => {
        'id': doc.id,
        'title': doc['title'],
        'message': doc['message'],
        'type': doc['type'],
        'bookingId': doc['bookingId'],
        'createdAt': doc['createdAt'],
        'isRead': doc['isRead'] ?? false,
        'delivered': doc['delivered'] ?? false,
      }).toList();
      
      developer.log('NotificationService: Retrieved ${notifications.length} notifications for user $userId');
      return notifications;
    } catch (e) {
      developer.log('NotificationService: Error getting notifications for user $userId - Error: $e');
      return [];
    }
  }

  // Mark notification as read with logging
  Future<bool> markNotificationAsRead(String notificationId) async {
    developer.log('NotificationService: Marking notification as read - NotificationID: $notificationId');
    
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now(),
      });
      
      developer.log('NotificationService: Notification marked as read successfully - NotificationID: $notificationId');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error marking notification as read - NotificationID: $notificationId, Error: $e');
      return false;
    }
  }

  // Mark all notifications as read with logging
  Future<bool> markAllNotificationsAsRead(String userId) async {
    developer.log('NotificationService: Marking all notifications as read - UserID: $userId');
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now(),
        });
      }
      
      await batch.commit();
      
      developer.log('NotificationService: Marked ${snapshot.docs.length} notifications as read for user $userId');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error marking all notifications as read - Error: $e');
      return false;
    }
  }

  // Delete notification with logging
  Future<bool> deleteNotification(String notificationId) async {
    developer.log('NotificationService: Deleting notification - NotificationID: $notificationId');
    
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      
      developer.log('NotificationService: Notification deleted successfully - NotificationID: $notificationId');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error deleting notification - NotificationID: $notificationId, Error: $e');
      return false;
    }
  }

  // Get unread notification count with logging
  Future<int> getUnreadNotificationCount(String userId) async {
    developer.log('NotificationService: Getting unread notification count - UserID: $userId');
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final count = snapshot.docs.length;
      developer.log('NotificationService: Retrieved $count unread notifications for user $userId');
      return count;
    } catch (e) {
      developer.log('NotificationService: Error getting unread notification count - Error: $e');
      return 0;
    }
  }
}