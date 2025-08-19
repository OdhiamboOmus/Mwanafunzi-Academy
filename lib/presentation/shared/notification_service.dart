import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Notification type enum for different notification categories
enum NotificationType {
  success,
  error,
  info,
  booking,
  payment,
  verification,
  lesson,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize notification service with logging
  Future<void> initialize() async {
    developer.log('NotificationService: Initializing notification service');
    
    try {
      // In a real implementation, this would set up FCM listeners and initialize services
      developer.log('NotificationService: Notification service initialized successfully');
    } catch (e) {
      developer.log('NotificationService: Error initializing notification service - Error: $e');
      rethrow;
    }
  }

  void showSuccessMessage(BuildContext context, String message) {
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.check_circle,
    );
  }

  void showErrorMessage(BuildContext context, String message) {
    _showOverlayMessage(
      context,
      message,
      const Color(0xFFEF4444),
      Icons.error,
    );
  }

  void showInfoMessage(BuildContext context, String message) {
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF3B82F6),
      Icons.info,
    );
  }

  void _showOverlayMessage(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
      ),
    );

    overlay.insert(overlayEntry);
    
    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // Get unread notification count with logging
  Future<int> getUnreadNotificationCount(String userId) async {
    developer.log('NotificationService: Getting unread notification count for user - UserID: $userId');
    
    try {
      // In a real implementation, this would query Firestore for unread notifications
      // For now, return a placeholder value
      final count = 0; // Placeholder - would be actual unread count from Firestore
      developer.log('NotificationService: Retrieved unread count - $count');
      return count;
    } catch (e) {
      developer.log('NotificationService: Error getting unread count - Error: $e');
      return 0;
    }
  }

  // Mark all notifications as read with logging
  Future<bool> markAllNotificationsAsRead(String userId) async {
    developer.log('NotificationService: Marking all notifications as read for user - UserID: $userId');
    
    try {
      // In a real implementation, this would update Firestore to mark all notifications as read
      // For now, return success
      developer.log('NotificationService: All notifications marked as read successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error marking all notifications as read - Error: $e');
      return false;
    }
  }

  // Mark notification as read with logging
  Future<bool> markNotificationAsRead(String notificationId) async {
    developer.log('NotificationService: Marking notification as read - NotificationID: $notificationId');
    
    try {
      // In a real implementation, this would update Firestore to mark the specific notification as read
      // For now, return success
      developer.log('NotificationService: Notification marked as read successfully');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error marking notification as read - Error: $e');
      return false;
    }
  }

  // Get user notifications with logging
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    developer.log('NotificationService: Getting user notifications - UserID: $userId');
    
    try {
      // In a real implementation, this would query Firestore for user notifications
      // For now, return an empty list
      final notifications = <Map<String, dynamic>>[];
      developer.log('NotificationService: Retrieved ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      developer.log('NotificationService: Error getting user notifications - Error: $e');
      return [];
    }
  }

  // Send booking confirmation with logging
  Future<void> sendBookingConfirmation({
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
    developer.log('NotificationService: Sending booking confirmation - BookingID: $bookingId');
    
    try {
      // In a real implementation, this would send FCM notification and/or email
      developer.log('NotificationService: Booking confirmation sent successfully');
    } catch (e) {
      developer.log('NotificationService: Error sending booking confirmation - Error: $e');
    }
  }

  // Send payment confirmation with logging
  Future<void> sendPaymentConfirmation({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    developer.log('NotificationService: Sending payment confirmation - BookingID: $bookingId, Amount: $amount');
    
    try {
      // In a real implementation, this would send FCM notification and/or email
      developer.log('NotificationService: Payment confirmation sent successfully');
    } catch (e) {
      developer.log('NotificationService: Error sending payment confirmation - Error: $e');
    }
  }

  // Send booking cancellation with logging
  Future<void> sendBookingCancellation({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String reason,
    required bool initiatedByTeacher,
  }) async {
    developer.log('NotificationService: Sending booking cancellation - BookingID: $bookingId');
    
    try {
      // In a real implementation, this would send FCM notification and/or email
      developer.log('NotificationService: Booking cancellation sent successfully');
    } catch (e) {
      developer.log('NotificationService: Error sending booking cancellation - Error: $e');
    }
  }

  // Send lesson completion with logging
  Future<void> sendLessonCompletion({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String lessonId,
    required String teacherName,
    required String studentName,
    required String subject,
  }) async {
    developer.log('NotificationService: Sending lesson completion - LessonID: $lessonId, BookingID: $bookingId');
    
    try {
      // In a real implementation, this would send FCM notification and/or email
      developer.log('NotificationService: Lesson completion sent successfully');
    } catch (e) {
      developer.log('NotificationService: Error sending lesson completion - Error: $e');
    }
  }

  // Send Zoom link with logging
  Future<void> sendZoomLink({
    required BuildContext context,
    required String teacherId,
    required String studentId,
    required String bookingId,
    required String zoomLink,
    required DateTime sessionDate,
    required String sessionTime,
  }) async {
    developer.log('NotificationService: Sending Zoom link - BookingID: $bookingId, ZoomLink: $zoomLink');
    
    try {
      // In a real implementation, this would send FCM notification and/or email
      developer.log('NotificationService: Zoom link sent successfully');
    } catch (e) {
      developer.log('NotificationService: Error sending Zoom link - Error: $e');
    }
  }
}

class _NotificationOverlay extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;

  const _NotificationOverlay({
    required this.message,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}