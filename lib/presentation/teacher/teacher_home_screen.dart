import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'teacher_dashboard_controller.dart';
import 'teacher_navigation_handlers.dart';
import 'widgets/booking_card_widget.dart';
import 'widgets/teacher_bookings_section.dart';
import 'widgets/teacher_welcome_section.dart';
import 'widgets/teacher_quick_actions.dart';
import '../../shared/notification_integration_widget.dart';
import '../shared/notification_integration_widget.dart';

// Teacher home screen following Flutter Lite rules (<150 lines)
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final TeacherDashboardController _controller = TeacherDashboardController();
  final TeacherNavigationHandlers _navigationHandlers = TeacherNavigationHandlers(TeacherDashboardController());

  @override
  void initState() {
    super.initState();
    developer.log('TeacherHomeScreen: Initializing teacher dashboard');
    _loadUserData();
    _setupRealtimeStreams();
  }

  // Setup real-time streams with logging
  void _setupRealtimeStreams() {
    developer.log('TeacherHomeScreen: Setting up real-time streams');
    
    _controller.setupRealtimeStreams(
      teacherId: _controller.teacherId,
      onActiveBookingsUpdated: _updateActiveBookings,
      onNewBooking: _handleNewBooking,
      onStatusChanges: _handleStatusChanges,
      onPaymentConfirmations: _handlePaymentConfirmations,
    );
  }

  // Update active bookings with logging
  void _updateActiveBookings(List<Map<String, dynamic>> bookings) {
    developer.log('TeacherHomeScreen: Updating active bookings from stream');
    _controller.updateActiveBookings(bookings);
    if (mounted) setState(() {});
  }

  // Handle new booking with logging
  void _handleNewBooking(Map<String, dynamic> booking) {
    developer.log('TeacherHomeScreen: Handling new booking ${booking['id']}');
    
    _controller.handleNewBooking(booking).then((result) {
      if (mounted && result['success']) {
        _controller.showSnackBar(
          context,
          'New booking request for ${booking['subject']}!',
        );
      }
    });

    _refreshDashboard();
  }

  // Handle status changes with logging
  void _handleStatusChanges(List<Map<String, dynamic>> changes) {
    developer.log('TeacherHomeScreen: Handling ${changes.length} status changes');
    
    _controller.handleStatusChanges(changes);
    _refreshDashboard();
  }

  // Handle payment confirmations with logging
  void _handlePaymentConfirmations(List<Map<String, dynamic>> confirmations) {
    developer.log('TeacherHomeScreen: Handling ${confirmations.length} payment confirmations');
    
    _controller.handlePaymentConfirmations(confirmations).then((result) {
      if (mounted && result['success']) {
        for (var confirmation in confirmations) {
          _controller.showSnackBar(
            context,
            'Payment confirmed for KES ${confirmation['amount']}!',
            backgroundColor: Colors.green,
          );
        }
      }
    });

    _refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherHomeScreen: Building UI for teacher ${_controller.teacherId}');
    
    return NotificationIntegrationWidget(
      userId: _controller.teacherId,
      userType: 'teacher',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Teacher Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _controller.isRefreshing ? null : _refreshDashboard,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => context.showNotification(
                title: 'Notifications',
                message: 'You have no new notifications',
                type: NotificationType.info,
              ),
              tooltip: 'Notifications',
            ),
          ],
        ),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      TeacherWelcomeSection(
                        teacherName: _controller.teacherName,
                        subject: _controller.subject,
                      ),
                      const SizedBox(height: 32),
                      
                      // Active Bookings Section
                      TeacherBookingsSection(
                        activeBookings: _controller.activeBookings,
                        onLessonCompleted: _handleLessonCompleted,
                        onViewAll: _navigationHandlers.navigateToBookingsScreen,
                      ),
                      const SizedBox(height: 32),
                      
                      // Quick Actions
                      TeacherQuickActions(
                        onMyClasses: _navigationHandlers.navigateToMyClasses,
                        onCreateAssignment: _navigationHandlers.navigateToCreateAssignment,
                        onStudentManagement: _navigationHandlers.navigateToStudentManagement,
                        onGrades: _navigationHandlers.navigateToGrades,
                        onAttendance: _navigationHandlers.navigateToAttendance,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Load user data and bookings with comprehensive logging
  Future<void> _loadUserData() async {
    developer.log('TeacherHomeScreen: Loading user data and bookings');
    
    try {
      final result = await _controller.loadUserDataAndBookings();
      
      if (!result['success']) {
        developer.log('TeacherHomeScreen: Error loading user data - Error: ${result['error']}');
        _controller.showSnackBar(
          context,
          'Error loading user data: ${result['error']}',
        );
      }
      
      if (mounted) setState(() {});
      
    } catch (e) {
      developer.log('TeacherHomeScreen: Error loading user data - Error: $e');
      _controller.showSnackBar(
        context,
        'Error loading user data: ${e.toString()}',
      );
      if (mounted) setState(() {});
    }
  }

  // Handle lesson completion with logging
  Future<void> _handleLessonCompleted(String lessonId) async {
    developer.log('TeacherHomeScreen: Handling lesson completion for lesson $lessonId');
    
    try {
      final result = await _controller.handleLessonCompleted(lessonId);
      
      if (result['success']) {
        _controller.showSnackBar(
          context,
          'Lesson marked as completed successfully!',
          backgroundColor: Colors.green,
        );
        
        await _refreshDashboard();
      } else {
        _controller.showSnackBar(
          context,
          'Error marking lesson as completed: ${result['error']}',
          backgroundColor: Colors.red,
        );
      }
      
    } catch (e) {
      developer.log('TeacherHomeScreen: Error handling lesson completion for lesson $lessonId - Error: $e');
      _controller.showSnackBar(
        context,
        'Error marking lesson as completed: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  // Refresh dashboard data with logging
  Future<void> _refreshDashboard() async {
    developer.log('TeacherHomeScreen: Refreshing dashboard for teacher ${_controller.teacherId}');
    
    try {
      final result = await _controller.refreshDashboard();
      
      if (!result['success']) {
        developer.log('TeacherHomeScreen: Error refreshing dashboard - Error: ${result['error']}');
        _controller.showSnackBar(
          context,
          'Error refreshing dashboard',
        );
      }
      
      if (mounted) setState(() {});
      
    } catch (e) {
      developer.log('TeacherHomeScreen: Error refreshing dashboard - Error: $e');
      _controller.showSnackBar(
        context,
        'Error refreshing dashboard',
      );
    }
  }
}