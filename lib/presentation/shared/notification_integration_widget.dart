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
    developer.log('NotificationIntegrationWidget: Initializing for user ${widget.userId} of type ${widget.userType}');
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    developer.log('NotificationIntegrationWidget: Starting notification initialization');
    
    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Get unread count
      _unreadCount = await _notificationService.getUnreadNotificationCount(widget.userId);
      developer.log('NotificationIntegrationWidget: Retrieved unread count - $_unreadCount');
      
      // Mark all notifications as read (for demo purposes)
      await _notificationService.markAllNotificationsAsRead(widget.userId);
      
      setState(() {
        _isInitialized = true;
      });
      
      developer.log('NotificationIntegrationWidget: Notification initialization completed successfully');
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error during notification initialization - Error: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    developer.log('NotificationIntegrationWidget: Disposing notification service for user ${widget.userId}');
    super.dispose();
  }

  // Mark notification as read with logging
  Future<bool> markNotificationAsRead(String notificationId) async {
    developer.log('NotificationIntegrationWidget: Marking notification as read - NotificationID: $notificationId');
    
    try {
      final success = await _notificationService.markNotificationAsRead(notificationId);
      if (success) {
        _unreadCount = await _notificationService.getUnreadNotificationCount(widget.userId);
        setState(() {});
        developer.log('NotificationIntegrationWidget: Notification marked as read successfully');
      }
      return success;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error marking notification as read - Error: $e');
      return false;
    }
  }

  // Mark all notifications as read with logging
  Future<bool> markAllNotificationsAsRead() async {
    developer.log('NotificationIntegrationWidget: Marking all notifications as read for user ${widget.userId}');
    
    try {
      final success = await _notificationService.markAllNotificationsAsRead(widget.userId);
      if (success) {
        _unreadCount = 0;
        setState(() {});
        developer.log('NotificationIntegrationWidget: All notifications marked as read successfully');
      }
      return success;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error marking all notifications as read - Error: $e');
      return false;
    }
  }

  // Get user notifications with logging
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    developer.log('NotificationIntegrationWidget: Getting user notifications for user ${widget.userId}');
    
    try {
      final notifications = await _notificationService.getUserNotifications(widget.userId);
      developer.log('NotificationIntegrationWidget: Retrieved ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      developer.log('NotificationIntegrationWidget: Error getting user notifications - Error: $e');
      return [];
    }
  }

  // Show custom notification with logging
  void showCustomNotification({
    required String title,
    required String message,
    required String type,
    Duration duration = const Duration(seconds: 3),
  }) {
    developer.log('NotificationIntegrationWidget: Showing custom notification - Title: $title, Type: $type');
    
    switch (type) {
      case 'success':
        _notificationService.showSuccessMessage(context, message);
        break;
      case 'error':
        _notificationService.showErrorMessage(context, message);
        break;
      case 'info':
      case 'booking':
      case 'payment':
      case 'verification':
      case 'lesson':
        _notificationService.showInfoMessage(context, message);
        break;
    }
    
    developer.log('NotificationIntegrationWidget: Custom notification shown successfully');
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
    String type = 'info',
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // Use the NotificationService directly
    final notificationService = NotificationService();
    
    switch (type) {
      case 'success':
        notificationService.showSuccessMessage(this, message);
        break;
      case 'error':
        notificationService.showErrorMessage(this, message);
        break;
      case 'info':
      case 'booking':
      case 'payment':
      case 'verification':
      case 'lesson':
        notificationService.showInfoMessage(this, message);
        break;
    }
  }
}