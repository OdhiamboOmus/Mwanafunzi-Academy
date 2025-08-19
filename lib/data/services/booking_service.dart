import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/lesson_model.dart';
import 'teacher_service.dart';
import 'payment_service.dart';
import 'notification_service.dart';

// Booking service with comprehensive debugPrint logging
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeacherService _teacherService = TeacherService();
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();

  // Create weekly booking with comprehensive logging
  Future<String> createWeeklyBooking(BookingModel booking) async {
    developer.log('BookingService: Creating weekly booking for teacher ${booking.teacherId}');
    developer.log('BookingService: Booking details - weeks: ${booking.numberOfWeeks}, amount: ${booking.totalAmount}');
    
    try {
      // Generate booking ID
      final bookingId = _generateBookingId();
      
      // Create booking document
      final bookingWithId = booking.copyWith(id: bookingId);
      await _firestore.collection('bookings').doc(bookingId).set(bookingWithId.toMap());
      
      // Generate individual lesson records
      await _generateLessonRecords(bookingWithId);
      
      // Update teacher's last booking date
      await _teacherService.updateLastBookingDate(booking.teacherId);
      
      developer.log('BookingService: Weekly booking created with ID: $bookingId');
      return bookingId;
    } catch (e) {
      developer.log('BookingService: Error creating weekly booking - Error: $e');
      rethrow;
    }
  }

  // Generate individual lesson records with logging
  Future<void> _generateLessonRecords(BookingModel booking) async {
    developer.log('BookingService: Generating lesson records for booking ${booking.id}');
    
    try {
      final lessons = <LessonModel>[];
      final startDate = booking.startDate;
      
      for (int week = 1; week <= booking.numberOfWeeks; week++) {
        final lessonDate = _calculateLessonDate(startDate, booking.dayOfWeek, week);
        
        final lesson = LessonModel(
          id: _generateLessonId(),
          bookingId: booking.id,
          teacherId: booking.teacherId,
          studentId: booking.studentId,
          weekNumber: week,
          scheduledDate: lessonDate,
          duration: booking.duration,
          zoomLink: '', // Will be generated when payment is confirmed
          status: 'scheduled',
          teacherNotes: null,
          createdAt: DateTime.now(),
        );
        
        lessons.add(lesson);
      }
      
      // Batch create lessons
      final batch = _firestore.batch();
      for (final lesson in lessons) {
        batch.set(_firestore.collection('lessons').doc(lesson.id), lesson.toMap());
      }
      
      await batch.commit();
      developer.log('BookingService: Created ${lessons.length} lesson records for booking ${booking.id}');
    } catch (e) {
      developer.log('BookingService: Error generating lesson records - Error: $e');
      rethrow;
    }
  }

  // Update booking status with state change logging and notifications
  Future<bool> updateBookingStatus(String bookingId, String status, {String? zoomLink, BuildContext? context}) async {
    developer.log('BookingService: Updating booking status - ID: $bookingId, Status: $status');
    
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        developer.log('BookingService: Booking not found - ID: $bookingId');
        return false;
      }

      final previousStatus = booking.status;
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now(),
      };
      
      if (zoomLink != null) {
        updateData['zoomLink'] = zoomLink;
      }
      
      await _firestore.collection('bookings').doc(bookingId).update(updateData);
      
      // Update all related lessons to the same status
      if (status == 'active' || status == 'completed') {
        await _updateLessonsStatus(bookingId, status);
      }

      // Send notifications based on status change
      if (context != null) {
        await _sendStatusChangeNotifications(
          context: context,
          booking: booking,
          previousStatus: previousStatus,
          newStatus: status,
        );
      }
      
      developer.log('BookingService: Booking status updated successfully - ID: $bookingId');
      return true;
    } catch (e) {
      developer.log('BookingService: Error updating booking status - ID: $bookingId, Error: $e');
      return false;
    }
  }

  // Update lessons status with logging
  Future<void> _updateLessonsStatus(String bookingId, String status) async {
    developer.log('BookingService: Updating lessons status for booking $bookingId to $status');
    
    try {
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('bookingId', isEqualTo: bookingId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in lessonsSnapshot.docs) {
        final updateData = {
          'status': status,
          'updatedAt': DateTime.now(),
        };
        
        if (status == 'completed') {
          updateData['completedAt'] = DateTime.now();
        }
        
        batch.update(doc.reference, updateData);
      }
      
      await batch.commit();
      developer.log('BookingService: Updated ${lessonsSnapshot.docs.length} lessons status');
    } catch (e) {
      developer.log('BookingService: Error updating lessons status - Error: $e');
    }
  }

  // Generate Zoom link with logging
  Future<String> generateZoomLink(String bookingId) async {
    developer.log('BookingService: Generating Zoom link for booking $bookingId');
    
    try {
      // In a real implementation, this would integrate with Zoom API
      // For now, generate a mock Zoom link
      final zoomLink = 'https://zoom.us/j/${_generateZoomMeetingId()}';
      
      await _firestore.collection('bookings').doc(bookingId).update({
        'zoomLink': zoomLink,
        'updatedAt': DateTime.now(),
      });
      
      developer.log('BookingService: Zoom link generated successfully - $zoomLink');
      return zoomLink;
    } catch (e) {
      developer.log('BookingService: Error generating Zoom link - Error: $e');
      rethrow;
    }
  }

  // Get booking by ID with logging
  Future<BookingModel?> getBookingById(String bookingId) async {
    developer.log('BookingService: Getting booking by ID - ID: $bookingId');
    
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (doc.exists) {
        final booking = BookingModel.fromMap(doc.data()!);
        developer.log('BookingService: Booking found - ID: ${booking.id}');
        return booking;
      } else {
        developer.log('BookingService: Booking not found - ID: $bookingId');
        return null;
      }
    } catch (e) {
      developer.log('BookingService: Error getting booking - ID: $bookingId, Error: $e');
      return null;
    }
  }

  // Get bookings by teacher ID with logging
  Future<List<BookingModel>> getBookingsByTeacher(String teacherId) async {
    developer.log('BookingService: Getting bookings for teacher - TeacherID: $teacherId');
    
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final bookings = snapshot.docs.map((doc) => BookingModel.fromMap(doc.data())).toList();
      developer.log('BookingService: Retrieved ${bookings.length} bookings for teacher $teacherId');
      return bookings;
    } catch (e) {
      developer.log('BookingService: Error getting bookings for teacher $teacherId, Error: $e');
      return [];
    }
  }

  // Get bookings by student ID with logging
  Future<List<BookingModel>> getBookingsByStudent(String studentId) async {
    developer.log('BookingService: Getting bookings for student - StudentID: $studentId');
    
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final bookings = snapshot.docs.map((doc) => BookingModel.fromMap(doc.data())).toList();
      developer.log('BookingService: Retrieved ${bookings.length} bookings for student $studentId');
      return bookings;
    } catch (e) {
      developer.log('BookingService: Error getting bookings for student $studentId, Error: $e');
      return [];
    }
  }

  // Cancel booking with reason logging and notifications
  Future<bool> cancelBooking(String bookingId, String reason, {BuildContext? context}) async {
    developer.log('BookingService: Cancelling booking - ID: $bookingId, Reason: $reason');
    
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        developer.log('BookingService: Booking not found - ID: $bookingId');
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'rejectionReason': reason,
        'updatedAt': DateTime.now(),
      });
      
      // Update all related lessons to cancelled
      await _updateLessonsStatus(bookingId, 'cancelled');

      // Send cancellation notifications
      if (context != null) {
        await _notificationService.sendBookingCancellation(
          context: context,
          teacherId: booking.teacherId,
          studentId: booking.studentId,
          bookingId: bookingId,
          reason: reason,
          initiatedByTeacher: false,
        );
      }
      
      developer.log('BookingService: Booking cancelled successfully - ID: $bookingId');
      return true;
    } catch (e) {
      developer.log('BookingService: Error cancelling booking - ID: $bookingId, Error: $e');
      return false;
    }
  }

  // Calculate booking cost with logging
  static double calculateBookingCost(double weeklyRate, int numberOfWeeks) {
    developer.log('BookingService: Calculating booking cost - WeeklyRate: $weeklyRate, NumberOfWeeks: $numberOfWeeks');
    
    final totalCost = weeklyRate * numberOfWeeks;
    final platformFee = totalCost * 0.20; // 20% platform fee
    final teacherPayout = totalCost - platformFee;
    
    developer.log('BookingService: Cost calculated - Total: $totalCost, PlatformFee: $platformFee, TeacherPayout: $teacherPayout');
    
    return totalCost;
  }

  // Generate unique booking ID
  String _generateBookingId() {
    return 'BK${DateTime.now().millisecondsSinceEpoch}${(1000 + DateTime.now().millisecond % 1000)}';
  }

  // Generate unique lesson ID
  String _generateLessonId() {
    return 'LSN${DateTime.now().millisecondsSinceEpoch}${(1000 + DateTime.now().millisecond % 1000)}';
  }

  // Generate unique Zoom meeting ID
  String _generateZoomMeetingId() {
    return (100000000 + DateTime.now().millisecond % 900000000).toString();
  }

  // Calculate lesson date for specific week
  DateTime _calculateLessonDate(DateTime startDate, String dayOfWeek, int weekNumber) {
    developer.log('BookingService: Calculating lesson date - StartDate: $startDate, DayOfWeek: $dayOfWeek, WeekNumber: $weekNumber');
    
    // Find the first occurrence of the specified day of week
    int targetDay = _getDayOfWeekNumber(dayOfWeek);
    int currentDay = startDate.weekday;
    
    // Calculate days to add to reach the target day
    int daysToAdd = targetDay - currentDay;
    if (daysToAdd < 0) daysToAdd += 7;
    
    // Add weeks
    daysToAdd += (weekNumber - 1) * 7;
    
    final lessonDate = startDate.add(Duration(days: daysToAdd));
    developer.log('BookingService: Lesson date calculated - $lessonDate');
    
    return lessonDate;
  }

  // Convert day string to number (Monday = 1, Sunday = 7)
  int _getDayOfWeekNumber(String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 1; // Default to Monday
    }
  }

  // Send status change notifications with logging
  Future<void> _sendStatusChangeNotifications({
    required BuildContext context,
    required BookingModel booking,
    required String previousStatus,
    required String newStatus,
  }) async {
    developer.log('BookingService: Sending status change notifications - BookingID: ${booking.id}, From: $previousStatus, To: $newStatus');
    
    try {
      switch (newStatus) {
        case 'paid':
          await _notificationService.sendPaymentConfirmation(
            context: context,
            teacherId: booking.teacherId,
            studentId: booking.studentId,
            bookingId: booking.id,
            amount: booking.totalAmount,
            paymentMethod: 'M-Pesa',
          );
          break;
          
        case 'active':
          await _notificationService.sendZoomLink(
            context: context,
            teacherId: booking.teacherId,
            studentId: booking.studentId,
            bookingId: booking.id,
            zoomLink: booking.zoomLink ?? '',
            sessionDate: booking.startDate,
            sessionTime: booking.startTime,
          );
          break;
          
        case 'completed':
          await _notificationService.sendLessonCompletion(
            context: context,
            teacherId: booking.teacherId,
            studentId: booking.studentId,
            bookingId: booking.id,
            lessonId: 'all_lessons',
            teacherName: 'Teacher',
            studentName: 'Student',
            subject: booking.subject,
          );
          break;
      }
      
      developer.log('BookingService: Status change notifications sent successfully - BookingID: ${booking.id}');
    } catch (e) {
      developer.log('BookingService: Error sending status change notifications - BookingID: ${booking.id}, Error: $e');
    }
  }
}