import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Notification widget for displaying notifications across all screens with logging
class NotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final String? bookingId;
  final Duration duration;
  final VoidCallback? onTap;
  final bool autoHide;

  const NotificationWidget({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.bookingId,
    this.duration = const Duration(seconds: 4),
    this.onTap,
    this.autoHide = true,
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  bool _isVisible = true;
  late final Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.duration;
    developer.log('NotificationWidget: Initializing notification - Title: ${widget.title}, Type: ${widget.type}');
    
    if (widget.autoHide) {
      _startAutoHide();
    }
  }

  void _startAutoHide() {
    developer.log('NotificationWidget: Starting auto-hide timer - Duration: ${_duration.inSeconds}s');
    
    Future.delayed(_duration, () {
      if (mounted && _isVisible) {
        _hideNotification();
      }
    });
  }

  void _hideNotification() {
    developer.log('NotificationWidget: Hiding notification - Title: ${widget.title}');
    
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
      
      // Remove from widget tree after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    developer.log('NotificationWidget: Building notification widget - Title: ${widget.title}, Type: ${widget.type}');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            developer.log('NotificationWidget: Notification tapped - Title: ${widget.title}');
            if (widget.onTap != null) {
              widget.onTap!();
            }
            _hideNotification();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.bookingId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Booking ID: ${widget.bookingId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color iconColor;

    switch (widget.type) {
      case NotificationType.success:
        icon = Icons.check_circle;
        iconColor = Colors.white;
        break;
      case NotificationType.error:
        icon = Icons.error;
        iconColor = Colors.white;
        break;
      case NotificationType.info:
        icon = Icons.info;
        iconColor = Colors.white;
        break;
      case NotificationType.warning:
        icon = Icons.warning;
        iconColor = Colors.white;
        break;
      case NotificationType.booking:
        icon = Icons.event_available;
        iconColor = Colors.white;
        break;
      case NotificationType.payment:
        icon = Icons.payment;
        iconColor = Colors.white;
        break;
      case NotificationType.verification:
        icon = Icons.verified;
        iconColor = Colors.white;
        break;
      case NotificationType.lesson:
        icon = Icons.school;
        iconColor = Colors.white;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildCloseButton() {
    return InkWell(
      onTap: _hideNotification,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.close,
          color: Colors.white70,
          size: 16,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF50E801);
      case NotificationType.error:
        return const Color(0xFFEF4444);
      case NotificationType.info:
        return const Color(0xFF3B82F6);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.booking:
        return const Color(0xFF10B981);
      case NotificationType.payment:
        return const Color(0xFF8B5CF6);
      case NotificationType.verification:
        return const Color(0xFF06B6D4);
      case NotificationType.lesson:
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF50E801).withOpacity(0.2);
      case NotificationType.error:
        return const Color(0xFFEF4444).withOpacity(0.2);
      case NotificationType.info:
        return const Color(0xFF3B82F6).withOpacity(0.2);
      case NotificationType.warning:
        return const Color(0xFFF59E0B).withOpacity(0.2);
      case NotificationType.booking:
        return const Color(0xFF10B981).withOpacity(0.2);
      case NotificationType.payment:
        return const Color(0xFF8B5CF6).withOpacity(0.2);
      case NotificationType.verification:
        return const Color(0xFF06B6D4).withOpacity(0.2);
      case NotificationType.lesson:
        return const Color(0xFF6366F1).withOpacity(0.2);
      default:
        return const Color(0xFF3B82F6).withOpacity(0.2);
    }
  }
}

// Notification types enumeration
enum NotificationType {
  success,
  error,
  info,
  warning,
  booking,
  payment,
  verification,
  lesson,
}

// Notification manager for managing multiple notifications
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final List<NotificationWidget> _activeNotifications = [];
  final GlobalKey<_NotificationOverlayState> _overlayKey = GlobalKey();

  // Show notification with logging
  void showNotification({
    required BuildContext context,
    required String title,
    required String message,
    required NotificationType type,
    String? bookingId,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    bool autoHide = true,
  }) {
    developer.log('NotificationManager: Showing notification - Title: $title, Type: $type');
    
    final notification = NotificationWidget(
      title: title,
      message: message,
      type: type,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
      autoHide: autoHide,
    );

    _activeNotifications.add(notification);
    _updateOverlay();
  }

  // Show success notification with logging
  void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? bookingId,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing success notification - Title: $title');
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.success,
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
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing error notification - Title: $title');
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.error,
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
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.info,
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
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing booking notification - Title: $title');
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.booking,
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
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    developer.log('NotificationManager: Showing payment notification - Title: $title');
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.payment,
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
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.verification,
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
    
    showNotification(
      context: context,
      title: title,
      message: message,
      type: NotificationType.lesson,
      bookingId: bookingId,
      duration: duration,
      onTap: onTap,
    );
  }

  // Hide notification with logging
  void hideNotification(NotificationWidget notification) {
    developer.log('NotificationManager: Hiding notification - Title: ${notification.title}');
    
    _activeNotifications.remove(notification);
    _updateOverlay();
  }

  // Clear all notifications with logging
  void clearAllNotifications() {
    developer.log('NotificationManager: Clearing all notifications - Count: ${_activeNotifications.length}');
    
    _activeNotifications.clear();
    _updateOverlay();
  }

  // Update overlay with logging
  void _updateOverlay() {
    developer.log('NotificationManager: Updating overlay - Active notifications: ${_activeNotifications.length}');
    
    if (_overlayKey.currentState != null) {
      _overlayKey.currentState!.updateNotifications(_activeNotifications);
    }
  }

  // Build notification overlay
  Widget buildNotificationOverlay(BuildContext context) {
    developer.log('NotificationManager: Building notification overlay');
    
    return NotificationOverlay(
      key: _overlayKey,
      notifications: _activeNotifications,
      onNotificationRemoved: hideNotification,
    );
  }
}

// Notification overlay widget
class NotificationOverlay extends StatefulWidget {
  final List<NotificationWidget> notifications;
  final Function(NotificationWidget) onNotificationRemoved;

  const NotificationOverlay({
    super.key,
    required this.notifications,
    required this.onNotificationRemoved,
  });

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  late List<NotificationWidget> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.notifications;
  }

  void updateNotifications(List<NotificationWidget> notifications) {
    developer.log('NotificationOverlay: Updating notifications - Count: ${notifications.length}');
    
    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    developer.log('NotificationOverlay: Building overlay - Count: ${_notifications.length}');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Column(
        children: _notifications.reversed
            .map((notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: notification,
                ))
            .toList(),
      ),
    );
  }
}