import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'notification_service.dart';
import 'notification_widget.dart' as notification_widget;

// Notification manager for handling different notification types with comprehensive logging
class NotificationManager {
  final NotificationService _notificationService = NotificationService();
  
  // Show success notification with logging
  void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing success notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.success,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show error notification with logging
  void showError({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing error notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.error,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show info notification with logging
  void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing info notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.info,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show booking notification with logging
  void showBooking({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing booking notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.booking,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show payment notification with logging
  void showPayment({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing payment notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.payment,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show verification notification with logging
  void showVerification({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing verification notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.verification,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show lesson notification with logging
  void showLesson({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing lesson notification - Title: $title');
    
    _showNotificationWidget(
      context: context,
      type: notification_widget.NotificationType.lesson,
      title: title,
      message: message,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }
  
  // Show notification widget with logging
  void _showNotificationWidget({
    required BuildContext context,
    required notification_widget.NotificationType type,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing notification widget - Type: $type, Title: $title');
    
    // In a real implementation, this would show a notification widget
    // For now, we'll show a snackbar
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
        backgroundColor: _getBackgroundColor(type),
        duration: duration,
        action: SnackBarAction(
          label: 'View',
          onPressed: onTap ?? () {},
        ),
      ),
    );
  }
  
  // Get background color based on notification type with logging
  Color _getBackgroundColor(notification_widget.NotificationType type) {
    developer.log('NotificationManager: Getting background color for type: $type');
    
    switch (type) {
      case notification_widget.NotificationType.success:
        return Colors.green;
      case notification_widget.NotificationType.error:
        return Colors.red;
      case notification_widget.NotificationType.info:
        return Colors.blue;
      case notification_widget.NotificationType.booking:
        return Colors.purple;
      case notification_widget.NotificationType.payment:
        return Colors.orange;
      case notification_widget.NotificationType.verification:
        return Colors.teal;
      case notification_widget.NotificationType.lesson:
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }
}