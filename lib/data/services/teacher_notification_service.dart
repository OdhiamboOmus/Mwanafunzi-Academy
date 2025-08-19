import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

// Teacher notification service with comprehensive logging (simplified for Flutter Lite)
class TeacherNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification service with logging
  Future<void> initialize() async {
    developer.log('TeacherNotificationService: Initializing notification service');
    
    try {
      // For Flutter Lite, we'll use Firestore-based notifications
      // instead of Firebase Messaging to minimize dependencies
      developer.log('TeacherNotificationService: Firestore-based notification service initialized');

    } catch (e) {
      developer.log('TeacherNotificationService: Error initializing notification service - Error: $e');
      throw Exception('Failed to initialize notification service: ${e.toString()}');
    }
  }

  // Subscribe to teacher notifications with logging
  Future<void> subscribeToTeacherNotifications(String teacherId) async {
    developer.log('TeacherNotificationService: Subscribing teacher $teacherId to notifications');
    
    try {
      // Create notification subscription
      await _firestore.collection('notification_subscriptions').doc(teacherId).set({
        'userId': teacherId,
        'userType': 'teacher',
        'subscribedAt': FieldValue.serverTimestamp(),
        'active': true,
        'topics': ['teacher_updates', 'booking_notifications', 'payment_notifications'],
      });

      developer.log('TeacherNotificationService: Teacher $teacherId subscribed to notifications successfully');

    } catch (e) {
      developer.log('TeacherNotificationService: Error subscribing teacher $teacherId to notifications - Error: $e');
      throw Exception('Failed to subscribe to notifications: ${e.toString()}');
    }
  }

  // Send new booking notification with logging
  Future<void> sendNewBookingNotification({
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String subject,
    required DateTime scheduledDate,
  }) async {
    developer.log('TeacherNotificationService: Sending new booking notification to teacher $teacherId');
    
    try {
      // Create notification record
      final notificationData = {
        'type': 'new_booking',
        'title': 'New Booking Request',
        'body': 'You have a new booking request for $subject',
        'teacherId': teacherId,
        'studentId': studentId,
        'bookingId': bookingId,
        'subject': subject,
        'scheduledDate': scheduledDate,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'high',
      };

      // Save to Firestore
      await _firestore.collection('notifications').add(notificationData);
      
      // For Flutter Lite, we'll use in-app notifications instead of push notifications
      developer.log('TeacherNotificationService: New booking notification saved to Firestore for teacher $teacherId');

    } catch (e) {
      developer.log('TeacherNotificationService: Error sending new booking notification to teacher $teacherId - Error: $e');
      throw Exception('Failed to send new booking notification: ${e.toString()}');
    }
  }

  // Send payment confirmation notification with logging
  Future<void> sendPaymentConfirmationNotification({
    required String teacherId,
    required String bookingId,
    required double amount,
    required String studentName,
  }) async {
    developer.log('TeacherNotificationService: Sending payment confirmation notification to teacher $teacherId');
    
    try {
      // Create notification record
      final notificationData = {
        'type': 'payment_confirmed',
        'title': 'Payment Confirmed',
        'body': 'Payment of KES $amount from $studentName has been confirmed',
        'teacherId': teacherId,
        'bookingId': bookingId,
        'amount': amount,
        'studentName': studentName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'medium',
      };

      // Save to Firestore
      await _firestore.collection('notifications').add(notificationData);
      
      developer.log('TeacherNotificationService: Payment confirmation notification saved to Firestore for teacher $teacherId');

    } catch (e) {
      developer.log('TeacherNotificationService: Error sending payment confirmation notification to teacher $teacherId - Error: $e');
      throw Exception('Failed to send payment confirmation notification: ${e.toString()}');
    }
  }

  // Send lesson reminder notification with logging
  Future<void> sendLessonReminderNotification({
    required String teacherId,
    required String bookingId,
    required String subject,
    required DateTime lessonDate,
  }) async {
    developer.log('TeacherNotificationService: Sending lesson reminder notification to teacher $teacherId');
    
    try {
      // Create notification record
      final notificationData = {
        'type': 'lesson_reminder',
        'title': 'Lesson Reminder',
        'body': 'You have a $subject lesson scheduled for ${_formatDate(lessonDate)}',
        'teacherId': teacherId,
        'bookingId': bookingId,
        'subject': subject,
        'lessonDate': lessonDate,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'medium',
      };

      // Save to Firestore
      await _firestore.collection('notifications').add(notificationData);
      
      developer.log('TeacherNotificationService: Lesson reminder notification saved to Firestore for teacher $teacherId');

    } catch (e) {
      developer.log('TeacherNotificationService: Error sending lesson reminder notification to teacher $teacherId - Error: $e');
      throw Exception('Failed to send lesson reminder notification: ${e.toString()}');
    }
  }

  // Send lesson completion notification with logging
  Future<void> sendLessonCompletionNotification({
    required String teacherId,
    required String bookingId,
    required String subject,
    required DateTime completedDate,
  }) async {
    developer.log('TeacherNotificationService: Sending lesson completion notification to teacher $teacherId');
    
    try {
      // Create notification record
      final notificationData = {
        'type': 'lesson_completed',
        'title': 'Lesson Completed',
        'body': 'You have completed a $subject lesson',
        'teacherId': teacherId,
        'bookingId': bookingId,
        'subject': subject,
        'completedDate': completedDate,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'low',
      };

      // Save to Firestore
      await _firestore.collection('notifications').add(notificationData);
      
      developer.log('TeacherNotificationService: Lesson completion notification saved to Firestore for teacher $teacherId');

    } catch (e) {
      developer.log('TeacherNotificationService: Error sending lesson completion notification to teacher $teacherId - Error: $e');
      throw Exception('Failed to send lesson completion notification: ${e.toString()}');
    }
  }

  // Get teacher's unread notifications with logging
  Future<List<Map<String, dynamic>>> getTeacherUnreadNotifications(String teacherId) async {
    developer.log('TeacherNotificationService: Getting unread notifications for teacher $teacherId');
    
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('teacherId', isEqualTo: teacherId)
          .where('read', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final notifications = notificationsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      developer.log('TeacherNotificationService: Found ${notifications.length} unread notifications for teacher $teacherId');
      return notifications;

    } catch (e) {
      developer.log('TeacherNotificationService: Error getting unread notifications for teacher $teacherId - Error: $e');
      throw Exception('Failed to get unread notifications: ${e.toString()}');
    }
  }

  // Get teacher's all notifications with logging
  Future<List<Map<String, dynamic>>> getTeacherAllNotifications(String teacherId) async {
    developer.log('TeacherNotificationService: Getting all notifications for teacher $teacherId');
    
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final notifications = notificationsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      developer.log('TeacherNotificationService: Found ${notifications.length} total notifications for teacher $teacherId');
      return notifications;

    } catch (e) {
      developer.log('TeacherNotificationService: Error getting all notifications for teacher $teacherId - Error: $e');
      throw Exception('Failed to get all notifications: ${e.toString()}');
    }
  }

  // Mark notification as read with logging
  Future<void> markNotificationAsRead(String notificationId) async {
    developer.log('TeacherNotificationService: Marking notification $notificationId as read');
    
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      developer.log('TeacherNotificationService: Notification $notificationId marked as read successfully');

    } catch (e) {
      developer.log('TeacherNotificationService: Error marking notification $notificationId as read - Error: $e');
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read with logging
  Future<void> markAllNotificationsAsRead(String teacherId) async {
    developer.log('TeacherNotificationService: Marking all notifications as read for teacher $teacherId');
    
    try {
      await _firestore.collection('notifications')
          .where('teacherId', isEqualTo: teacherId)
          .where('read', isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      });

      developer.log('TeacherNotificationService: All notifications marked as read for teacher $teacherId successfully');

    } catch (e) {
      developer.log('TeacherNotificationService: Error marking all notifications as read for teacher $teacherId - Error: $e');
      throw Exception('Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  // Delete notification with logging
  Future<void> deleteNotification(String notificationId) async {
    developer.log('TeacherNotificationService: Deleting notification $notificationId');
    
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      developer.log('TeacherNotificationService: Notification $notificationId deleted successfully');

    } catch (e) {
      developer.log('TeacherNotificationService: Error deleting notification $notificationId - Error: $e');
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  // Format date for display with logging
  String _formatDate(DateTime date) {
    developer.log('TeacherNotificationService: Formatting date ${date.toIso8601String()}');
    
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get notification statistics with logging
  Future<Map<String, dynamic>> getNotificationStats(String teacherId) async {
    developer.log('TeacherNotificationService: Getting notification stats for teacher $teacherId');
    
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get notifications from last 30 days
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('teacherId', isEqualTo: teacherId)
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();

      final totalNotifications = notificationsSnapshot.docs.length;
      final unreadNotifications = notificationsSnapshot.docs
          .where((doc) => doc['read'] == false)
          .length;
      const newBookings = 0; // Placeholder - would be calculated from actual data
      const paymentConfirmations = 0; // Placeholder - would be calculated from actual data

      final stats = {
        'totalNotifications': totalNotifications,
        'unreadNotifications': unreadNotifications,
        'newBookings': newBookings,
        'paymentConfirmations': paymentConfirmations,
        'period': 'Last 30 days',
      };

      developer.log('TeacherNotificationService: Notification stats for teacher $teacherId - $stats');
      return stats;

    } catch (e) {
      developer.log('TeacherNotificationService: Error getting notification stats for teacher $teacherId - Error: $e');
      throw Exception('Failed to get notification stats: ${e.toString()}');
    }
  }
}