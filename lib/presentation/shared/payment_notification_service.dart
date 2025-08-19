import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Enhanced notification service for payment confirmations with comprehensive logging
class PaymentNotificationService {
  static final PaymentNotificationService _instance = PaymentNotificationService._internal();
  factory PaymentNotificationService() => _instance;
  PaymentNotificationService._internal();

  // Show payment success notification with logging
  void showPaymentSuccess(BuildContext context, String message, {String? bookingId}) {
    developer.log('PaymentNotificationService: Showing payment success notification - Message: $message, BookingID: $bookingId');
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.check_circle,
      'Payment Successful',
      bookingId: bookingId,
    );
  }

  // Show payment failure notification with logging
  void showPaymentFailure(BuildContext context, String message, {String? bookingId, String? reason}) {
    developer.log('PaymentNotificationService: Showing payment failure notification - Message: $message, BookingID: $bookingId, Reason: $reason');
    
    final errorMessage = reason != null ? '$message\nReason: $reason' : message;
    
    _showOverlayMessage(
      context,
      errorMessage,
      const Color(0xFFEF4444),
      Icons.error,
      'Payment Failed',
      bookingId: bookingId,
    );
  }

  // Show payment pending notification with logging
  void showPaymentPending(BuildContext context, String message, {String? bookingId}) {
    developer.log('PaymentNotificationService: Showing payment pending notification - Message: $message, BookingID: $bookingId');
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF3B82F6),
      Icons.hourglass_empty,
      'Payment Pending',
      bookingId: bookingId,
    );
  }

  // Show booking confirmation notification with logging
  void showBookingConfirmation(BuildContext context, String teacherName, String subject, {String? bookingId}) {
    developer.log('PaymentNotificationService: Showing booking confirmation - Teacher: $teacherName, Subject: $subject, BookingID: $bookingId');
    
    final message = 'Booking confirmed with $teacherName for $subject. Check your email for the Zoom link.';
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.event_available,
      'Booking Confirmed',
      bookingId: bookingId,
    );
  }

  // Show payout notification with logging
  void showPayoutNotification(BuildContext context, double amount, String transactionId) {
    developer.log('PaymentNotificationService: Showing payout notification - Amount: $amount, TransactionID: $transactionId');
    
    final message = 'Payout of Ksh ${amount.toStringAsFixed(2)} processed successfully. Transaction ID: $transactionId';
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.account_balance_wallet,
      'Payout Processed',
    );
  }

  // Show payment reminder notification with logging
  void showPaymentReminder(BuildContext context, String bookingId, double amount) {
    developer.log('PaymentNotificationService: Showing payment reminder - BookingID: $bookingId, Amount: $amount');
    
    final message = 'Payment of Ksh ${amount.toStringAsFixed(2)} is still pending for your booking.';
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFFF59E0B),
      Icons.payment,
      'Payment Reminder',
      bookingId: bookingId,
    );
  }

  // Show refund notification with logging
  void showRefundNotification(BuildContext context, double amount, String transactionId) {
    developer.log('PaymentNotificationService: Showing refund notification - Amount: $amount, TransactionID: $transactionId');
    
    final message = 'Refund of Ksh ${amount.toStringAsFixed(2)} processed successfully. Transaction ID: $transactionId';
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF3B82F6),
      Icons.money_off,
      'Refund Processed',
    );
  }

  // Generic overlay message with logging
  void _showOverlayMessage(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
    String title, {
    String? bookingId,
  }) {
    developer.log('PaymentNotificationService: Creating overlay message - Title: $title, BookingID: $bookingId');
    
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _PaymentNotificationOverlay(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        title: title,
        bookingId: bookingId,
      ),
    );

    overlay.insert(overlayEntry);
    
    // Auto remove after 4 seconds for payment notifications
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Show in-app notification for new booking with logging
  void showNewBookingNotification(BuildContext context, String teacherName, String subject, String bookingId) {
    developer.log('PaymentNotificationService: Showing new booking notification - Teacher: $teacherName, Subject: $subject, BookingID: $bookingId');
    
    final message = 'New booking confirmed with $teacherName for $subject. Check your dashboard for details.';
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.notifications_active,
      'New Booking',
      bookingId: bookingId,
    );
  }

  // Show lesson completion notification with logging
  void showLessonCompletionNotification(BuildContext context, String studentName, String subject, String bookingId) {
    developer.log('PaymentNotificationService: Showing lesson completion notification - Student: $studentName, Subject: $subject, BookingID: $bookingId');
    
    final message = 'Lesson completed with $studentName for $subject. Payout will be processed soon.';
    
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.school,
      'Lesson Completed',
      bookingId: bookingId,
    );
  }
}

// Enhanced notification overlay widget
class _PaymentNotificationOverlay extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final String title;
  final String? bookingId;

  const _PaymentNotificationOverlay({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.title,
    this.bookingId,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (bookingId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Booking ID: $bookingId',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}