import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'notification_service.dart';
import 'notification_manager.dart';
import 'loading_and_error_handler.dart';

// Notification integration widget for all screens with comprehensive logging
class NotificationIntegrationWidget extends StatefulWidget {
  final String userId;
  final String userType; // 'teacher', 'student', 'parent', 'admin'
  final Widget child;
  final Function(Map<String, dynamic>)? onNotificationReceived;
  final Function(List<Map<String, dynamic>>)? onBookingStatusChanges;
  final Function(List<Map<String, dynamic>>)? onNewBookings;
  final Function(List<Map<String, dynamic>>)? onPaymentConfirmations;
  final Function(List<Map<String, dynamic>>)? onLessonCompletions;

  const NotificationIntegrationWidget({
    super.key,
    required this.userId,
    required this.userType,
    required this.child,
    this.onNotificationReceived,
    this.onBookingStatusChanges,
    this.onNewBookings,
    this.onPaymentConfirmations,
    this.onLessonCompletions,
  });

  @override
  State<NotificationIntegrationWidget> createState() => _NotificationIntegrationWidgetState();
}

class _NotificationIntegrationWidgetState extends State<NotificationIntegrationWidget> {
  final NotificationService _notificationService = NotificationService();
  final NotificationManager _notificationManager = NotificationManager();
  final LoadingAndErrorHandler _loadingHandler = LoadingAndErrorHandler();
  
  bool _isInitialized = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    developer.log('NotificationIntegrationWidget: Initializing - UserID: ${widget.userId}, UserType: ${widget.userType}');
    
    _initializeNotifications();
  }

  @override
  void dispose() {
    developer.log('NotificationIntegrationWidget: Disposing - UserID: ${widget.userId}');
    
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    developer.log('NotificationIntegrationWidget: Initializing notification system');
    
    try {
      // Get unread notification count
      _unreadCount = await _notificationService.getUnreadNotificationCount(widget.userId);
      setState(() {});

      // Mark all notifications as read for this session
      await _notificationService.markAllNotificationsAsRead(widget.userId);

      _isInitialized = true;
      developer.log('NotificationIntegrationWidget: Notification system initialized successfully');
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error initializing notification system - Error: $e');
      _loadingHandler.handleError(
        title: 'Notification Error',
        message: 'Failed to initialize notification system. Some features may not work properly.',
      );
    }
  }

  // Show custom notification with logging
  void showCustomNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationIntegrationWidget: Showing custom notification - Title: $title, Type: $type');
    
    switch (type) {
      case NotificationType.success:
        _notificationManager.showSuccess(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      case NotificationType.error:
        _notificationManager.showError(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      case NotificationType.info:
        _notificationManager.showInfo(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      case NotificationType.booking:
        _notificationManager.showBooking(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      case NotificationType.payment:
        _notificationManager.showPayment(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      case NotificationType.verification:
        _notificationManager.showVerification(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      case NotificationType.lesson:
        _notificationManager.showLesson(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
        break;
      default:
        _notificationManager.showInfo(
          context: context,
          title: title,
          message: message,
          bookingId: bookingId,
          duration: duration,
          onTap: onTap,
        );
    }
  }

  // Get unread notification count with logging
  Future<int> getUnreadNotificationCount() async {
    developer.log('NotificationIntegrationWidget: Getting unread notification count');
    
    try {
      final count = await _notificationService.getUnreadNotificationCount(widget.userId);
      setState(() {
        _unreadCount = count;
      });
      developer.log('NotificationIntegrationWidget: Retrieved unread count - $count');
      return count;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error getting unread count - Error: $e');
      return 0;
    }
  }

  // Mark notification as read with logging
  Future<bool> markNotificationAsRead(String notificationId) async {
    developer.log('NotificationIntegrationWidget: Marking notification as read - NotificationID: $notificationId');
    
    try {
      final success = await _notificationService.markNotificationAsRead(notificationId);
      if (success) {
        await getUnreadNotificationCount();
      }
      developer.log('NotificationIntegrationWidget: Notification marked as read - Success: $success');
      return success;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error marking notification as read - Error: $e');
      return false;
    }
  }

  // Mark all notifications as read with logging
  Future<bool> markAllNotificationsAsRead() async {
    developer.log('NotificationIntegrationWidget: Marking all notifications as read');
    
    try {
      final success = await _notificationService.markAllNotificationsAsRead(widget.userId);
      if (success) {
        await getUnreadNotificationCount();
      }
      developer.log('NotificationIntegrationWidget: All notifications marked as read - Success: $success');
      return success;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error marking all notifications as read - Error: $e');
      return false;
    }
  }

  // Get user notifications with logging
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    developer.log('NotificationIntegrationWidget: Getting user notifications');
    
    try {
      final notifications = await _notificationService.getUserNotifications(widget.userId);
      developer.log('NotificationIntegrationWidget: Retrieved ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error getting user notifications - Error: $e');
      return [];
    }
  }

  // Build notification badge with logging
  Widget buildNotificationBadge({
    required Widget child,
    bool showBadge = true,
    Color badgeColor = Colors.red,
    String? badgeText,
  }) {
    developer.log('NotificationIntegrationWidget: Building notification badge - ShowBadge: $showBadge');
    
    if (!showBadge || _unreadCount == 0) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: badgeText != null
                ? Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ],
    );
  }

  // Build notification icon with logging
  Widget buildNotificationIcon({
    required IconData icon,
    double size = 24,
    Color color = Colors.black,
    VoidCallback? onTap,
  }) {
    developer.log('NotificationIntegrationWidget: Building notification icon');
    
    return GestureDetector(
      onTap: onTap ?? () => _showNotificationsScreen(),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  // Show notifications screen with logging
  void _showNotificationsScreen() {
    developer.log('NotificationIntegrationWidget: Showing notifications screen');
    
    // In a real implementation, this would navigate to a notifications screen
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications screen would open here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log('NotificationIntegrationWidget: Building widget - Initialized: $_isInitialized');
    
    if (!_isInitialized) {
      return _loadingHandler.buildLoadingWidget(message: 'Initializing notifications...');
    }

    return widget.child;
  }
}

// Extension methods for easy notification access
extension NotificationExtensions on BuildContext {
  void showNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // Find the NotificationIntegrationWidget in the widget tree
    final widget = findAncestorWidgetOfExactType<NotificationIntegrationWidget>();
    if (widget != null) {
      widget.showCustomNotification(
        title: title,
        message: message,
        type: type,
        bookingId: bookingId,
        duration: duration,
        onTap: onTap,
      );
    } else {
      // Fallback to showing a snackbar if no NotificationIntegrationWidget is found
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          duration: duration,
        ),
      );
    }
  }
}