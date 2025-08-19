import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../data/services/teacher_dashboard_service.dart';
import '../../data/models/booking_model.dart';

// Teacher dashboard controller for managing real-time functionality with logging
class TeacherDashboardController {
  final TeacherDashboardService _dashboardService = TeacherDashboardService();
  String _teacherId = '';
  String _teacherName = 'Loading...';
  String _subject = 'Loading...';
  List<BookingModel> _activeBookings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Getters
  String get teacherId => _teacherId;
  String get teacherName => _teacherName;
  String get subject => _subject;
  List<BookingModel> get activeBookings => _activeBookings;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  // Setters
  set teacherId(String value) => _teacherId = value;
  set teacherName(String value) => _teacherName = value;
  set subject(String value) => _subject = value;
  set activeBookings(List<BookingModel> value) => _activeBookings = value;
  set isLoading(bool value) => _isLoading = value;
  set isRefreshing(bool value) => _isRefreshing = value;

  // Setup real-time streams with logging
  void setupRealtimeStreams({
    required String teacherId,
    required Function(List<Map<String, dynamic>>) onActiveBookingsUpdated,
    required Function(Map<String, dynamic>) onNewBooking,
    required Function(List<Map<String, dynamic>>) onStatusChanges,
    required Function(List<Map<String, dynamic>>) onPaymentConfirmations,
  }) {
    developer.log('TeacherDashboardController: Setting up real-time streams for teacher $teacherId');
    
    if (teacherId.isNotEmpty) {
      _dashboardService.setupRealtimeStreams(
        teacherId: teacherId,
        onActiveBookingsUpdated: onActiveBookingsUpdated,
        onNewBooking: onNewBooking,
        onStatusChanges: onStatusChanges,
        onPaymentConfirmations: onPaymentConfirmations,
      );
    }
  }

  // Update active bookings with logging
  void updateActiveBookings(List<Map<String, dynamic>> bookings) {
    developer.log('TeacherDashboardController: Updating active bookings from stream');
    
    _activeBookings = bookings.map((booking) => BookingModel.fromMap(booking)).toList();
  }

  // Handle new booking with logging
  Future<Map<String, dynamic>> handleNewBooking(Map<String, dynamic> booking) async {
    developer.log('TeacherDashboardController: Handling new booking ${booking['id']}');
    
    return await _dashboardService.handleNewBooking(
      teacherId: _teacherId,
      booking: booking,
    );
  }

  // Handle status changes with logging
  void handleStatusChanges(List<Map<String, dynamic>> changes) {
    developer.log('TeacherDashboardController: Handling ${changes.length} status changes');
    
    _dashboardService.handleStatusChanges(
      teacherId: _teacherId,
      changes: changes,
    );
  }

  // Handle payment confirmations with logging
  Future<Map<String, dynamic>> handlePaymentConfirmations(List<Map<String, dynamic>> confirmations) async {
    developer.log('TeacherDashboardController: Handling ${confirmations.length} payment confirmations');
    
    return await _dashboardService.handlePaymentConfirmations(
      confirmations: confirmations,
    );
  }

  // Load user data and bookings with comprehensive logging
  Future<Map<String, dynamic>> loadUserDataAndBookings() async {
    developer.log('TeacherDashboardController: Loading user data and bookings');
    
    try {
      final result = await _dashboardService.loadUserDataAndBookings();
      
      if (result['success']) {
        _teacherId = result['teacherId'];
        _teacherName = result['teacherName'];
        _subject = result['subject'];
        _activeBookings = result['activeBookings'];
        _isLoading = false;
        
        developer.log('TeacherDashboardController: User data and bookings loaded successfully - TeacherID: $_teacherId');
      } else {
        _isLoading = false;
        developer.log('TeacherDashboardController: Error loading user data - Error: ${result['error']}');
      }
      
      return result;
      
    } catch (e) {
      _isLoading = false;
      developer.log('TeacherDashboardController: Error loading user data - Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Handle lesson completion with logging
  Future<Map<String, dynamic>> handleLessonCompleted(String lessonId) async {
    developer.log('TeacherDashboardController: Handling lesson completion for lesson $lessonId');
    
    return await _dashboardService.handleLessonCompleted(
      lessonId: lessonId,
      teacherId: _teacherId,
      subject: _subject,
      activeBookings: _activeBookings,
    );
  }

  // Refresh dashboard data with logging
  Future<Map<String, dynamic>> refreshDashboard() async {
    developer.log('TeacherDashboardController: Refreshing dashboard for teacher $_teacherId');
    
    _isRefreshing = true;

    try {
      final result = await _dashboardService.refreshDashboard();
      
      if (result['success']) {
        _teacherName = result['teacherName'];
        _subject = result['subject'];
        _activeBookings = result['activeBookings'];
        
        developer.log('TeacherDashboardController: Dashboard refreshed successfully for teacher $_teacherId');
      } else {
        developer.log('TeacherDashboardController: Error refreshing dashboard - Error: ${result['error']}');
      }
      
      return result;
      
    } catch (e) {
      developer.log('TeacherDashboardController: Error refreshing dashboard - Error: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      _isRefreshing = false;
    }
  }

  // Show snackbar with logging
  void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    developer.log('TeacherDashboardController: Showing snackbar: $message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}