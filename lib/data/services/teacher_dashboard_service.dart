import 'dart:developer' as developer;
import '../../data/services/booking_service.dart';
import '../../data/services/realtime_booking_service.dart';
import '../../data/services/lesson_completion_service.dart';
import '../../data/services/teacher_notification_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/booking_model.dart';

// Teacher dashboard service for managing dashboard functionality with logging
class TeacherDashboardService {
  final UserRepository _userRepository = UserRepository();
  final BookingService _bookingService = BookingService();
  final RealtimeBookingService _realtimeBookingService = RealtimeBookingService();
  final LessonCompletionService _lessonCompletionService = LessonCompletionService();
  final TeacherNotificationService _notificationService = TeacherNotificationService();

  // Load user data and bookings with comprehensive logging
  Future<Map<String, dynamic>> loadUserDataAndBookings() async {
    developer.log('TeacherDashboardService: Loading user data and bookings');
    
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final teacherId = user.uid;
        final bookings = await _bookingService.getBookingsByTeacher(teacherId);
        
        // Separate active bookings and upcoming lessons
        final activeBookings = bookings.where((b) => b.isActive || b.isPaid).toList();
        final upcomingLessons = bookings.where((b) => b.isActive).take(3).toList();
        
        developer.log('TeacherDashboardService: Loaded ${activeBookings.length} active bookings and ${upcomingLessons.length} upcoming lessons');
        
        return {
          'success': true,
          'teacherId': teacherId,
          'teacherName': 'Teacher Name', // Would come from Firestore
          'subject': 'Mathematics', // Would come from Firestore
          'activeBookings': activeBookings,
          'upcomingLessons': upcomingLessons,
        };
      }
      
      developer.log('TeacherDashboardService: No user found');
      return {'success': false, 'error': 'No user found'};
      
    } catch (e) {
      developer.log('TeacherDashboardService: Error loading user data - Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Handle lesson completion with logging
  Future<Map<String, dynamic>> handleLessonCompleted({
    required String lessonId,
    required String teacherId,
    required String subject,
    required List<BookingModel> activeBookings,
  }) async {
    developer.log('TeacherDashboardService: Handling lesson completion for lesson $lessonId');
    
    try {
      // Find the booking
      final booking = activeBookings.firstWhere(
        (b) => b.id == lessonId.split('_')[1], 
        orElse: () => throw Exception('Booking not found'),
      );
      
      // Mark lesson as completed
      await _lessonCompletionService.markLessonCompleted(
        lessonId: lessonId,
        bookingId: booking.id,
        teacherId: teacherId,
        studentId: 'student_placeholder', // This would come from actual booking data
        subject: subject,
        scheduledDate: DateTime.now(),
        teacherNotes: 'Lesson completed successfully',
      );
      
      // Send completion notification
      await _notificationService.sendLessonCompletionNotification(
        teacherId: teacherId,
        bookingId: booking.id,
        subject: subject,
        completedDate: DateTime.now(),
      );
      
      developer.log('TeacherDashboardService: Lesson $lessonId completion handled successfully');
      
      return {
        'success': true,
        'message': 'Lesson marked as completed successfully',
      };
      
    } catch (e) {
      developer.log('TeacherDashboardService: Error handling lesson completion for lesson $lessonId - Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Refresh dashboard data with logging
  Future<Map<String, dynamic>> refreshDashboard() async {
    developer.log('TeacherDashboardService: Refreshing dashboard');
    
    try {
      final result = await loadUserDataAndBookings();
      developer.log('TeacherDashboardService: Dashboard refreshed successfully');
      return result;
    } catch (e) {
      developer.log('TeacherDashboardService: Error refreshing dashboard - Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Setup real-time streams with logging
  void setupRealtimeStreams({
    required String teacherId,
    required Function(List<Map<String, dynamic>>) onActiveBookingsUpdated,
    required Function(Map<String, dynamic>) onNewBooking,
    required Function(List<Map<String, dynamic>>) onStatusChanges,
    required Function(List<Map<String, dynamic>>) onPaymentConfirmations,
  }) {
    developer.log('TeacherDashboardService: Setting up real-time streams for teacher $teacherId');
    
    // Setup active bookings stream
    _realtimeBookingService.listenToBookingStatusChanges(teacherId).listen((changes) {
      if (changes.isNotEmpty) {
        developer.log('TeacherDashboardService: Active bookings stream updated - ${changes.length} changes');
        onActiveBookingsUpdated(changes);
      }
    });

    // Setup new bookings stream
    _realtimeBookingService.listenToBookingStatusChanges(teacherId).listen((changes) {
      for (var change in changes) {
        if (change['type'] == 'new_booking') {
          developer.log('TeacherDashboardService: New booking received - ${change['bookingId']}');
          onNewBooking(change['booking']);
        }
      }
    });

    // Setup status changes stream
    _realtimeBookingService.listenToBookingStatusChanges(teacherId).listen((changes) {
      if (changes.isNotEmpty) {
        developer.log('TeacherDashboardService: Status changes received - ${changes.length} changes');
        onStatusChanges(changes);
      }
    });

    // Setup payment confirmations stream
    _realtimeBookingService.listenToPaymentConfirmations(teacherId).listen((confirmations) {
      if (confirmations.isNotEmpty) {
        developer.log('TeacherDashboardService: Payment confirmations received - ${confirmations.length} confirmations');
        onPaymentConfirmations(confirmations);
      }
    });
  }

  // Handle new booking with logging
  Future<Map<String, dynamic>> handleNewBooking({
    required String teacherId,
    required Map<String, dynamic> booking,
  }) async {
    developer.log('TeacherDashboardService: Handling new booking ${booking['id']}');
    
    try {
      // Send notification for new booking
      await _notificationService.sendNewBookingNotification(
        teacherId: teacherId,
        studentId: booking['parentId'] ?? 'unknown',
        bookingId: booking['id'],
        subject: booking['subject'] ?? 'Unknown Subject',
        scheduledDate: booking['startDate']?.toDate() ?? DateTime.now(),
      );
      
      return {
        'success': true,
        'message': 'New booking notification sent',
        'bookingId': booking['id'],
      };
      
    } catch (e) {
      developer.log('TeacherDashboardService: Error handling new booking ${booking['id']} - Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Handle status changes with logging
  void handleStatusChanges({
    required String teacherId,
    required List<Map<String, dynamic>> changes,
  }) {
    developer.log('TeacherDashboardService: Handling ${changes.length} status changes');
    
    for (var change in changes) {
      // Mark booking as viewed
      _realtimeBookingService.markBookingAsViewed(change['bookingId']);
      
      // Send notification for status change
      if (change['newStatus'] == 'paid' || change['newStatus'] == 'active') {
        _notificationService.sendPaymentConfirmationNotification(
          teacherId: teacherId,
          bookingId: change['bookingId'],
          amount: change['booking']['totalAmount']?.toDouble() ?? 0.0,
          studentName: 'Student', // Would come from actual data
        );
      }
    }
  }

  // Handle payment confirmations with logging
  Future<Map<String, dynamic>> handlePaymentConfirmations({
    required List<Map<String, dynamic>> confirmations,
  }) async {
    developer.log('TeacherDashboardService: Handling ${confirmations.length} payment confirmations');
    
    try {
      // Process each confirmation
      for (var confirmation in confirmations) {
        // Send payment confirmation notification
        await _notificationService.sendPaymentConfirmationNotification(
          teacherId: 'teacher_placeholder', // Would come from actual context
          bookingId: confirmation['bookingId'],
          amount: confirmation['amount']?.toDouble() ?? 0.0,
          studentName: 'Student', // Would come from actual data
        );
      }
      
      return {
        'success': true,
        'message': 'Payment confirmations processed',
        'count': confirmations.length,
      };
      
    } catch (e) {
      developer.log('TeacherDashboardService: Error handling payment confirmations - Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}