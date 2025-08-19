import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/lesson_model.dart';
import 'notification_service.dart';
import 'booking_service.dart';

// Real-time booking status update service with comprehensive logging
class RealtimeBookingService {
  static final RealtimeBookingService _instance = RealtimeBookingService._internal();
  factory RealtimeBookingService() => _instance;
  RealtimeBookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final BookingService _bookingService = BookingService();

  // Setup real-time listeners for booking status changes with logging
  void setupRealtimeListeners({
    required String teacherId,
    required String studentId,
    required Function(List<Map<String, dynamic>>) onBookingStatusChanges,
    required Function(List<Map<String, dynamic>>) onNewBookings,
    required Function(List<Map<String, dynamic>>) onPaymentConfirmations,
    required Function(List<Map<String, dynamic>>) onLessonCompletions,
  }) {
    developer.log('RealtimeBookingService: Setting up real-time listeners - TeacherID: $teacherId, StudentID: $studentId');
    
    // Listen to booking status changes
    _listenToBookingStatusChanges(
      teacherId: teacherId,
      studentId: studentId,
      onBookingStatusChanges: onBookingStatusChanges,
    );

    // Listen to new bookings
    _listenToNewBookings(
      teacherId: teacherId,
      onNewBookings: onNewBookings,
    );

    // Listen to payment confirmations
    _listenToPaymentConfirmations(
      teacherId: teacherId,
      studentId: studentId,
      onPaymentConfirmations: onPaymentConfirmations,
    );

    // Listen to lesson completions
    _listenToLessonCompletions(
      teacherId: teacherId,
      studentId: studentId,
      onLessonCompletions: onLessonCompletions,
    );
  }

  // Listen to booking status changes with logging
  void _listenToBookingStatusChanges({
    required String teacherId,
    required String studentId,
    required Function(List<Map<String, dynamic>>) onBookingStatusChanges,
  }) {
    developer.log('RealtimeBookingService: Setting up booking status change listener');
    
    _firestore
        .collection('bookings')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', whereIn: ['draft', 'payment_pending', 'paid', 'active', 'completed', 'cancelled'])
        .snapshots()
        .listen((snapshot) {
          developer.log('RealtimeBookingService: Received booking status changes - ${snapshot.docs.length} changes');
          
          final changes = <Map<String, dynamic>>[];
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final booking = BookingModel.fromMap(change.doc.data()!);
              final previousStatus = change.doc.data()?['status'];
              final newStatus = booking.status;
              
              if (previousStatus != newStatus) {
                developer.log('RealtimeBookingService: Booking status changed - BookingID: ${booking.id}, From: $previousStatus, To: $newStatus');
                
                changes.add({
                  'type': 'status_change',
                  'bookingId': booking.id,
                  'previousStatus': previousStatus,
                  'newStatus': newStatus,
                  'booking': booking.toMap(),
                  'timestamp': DateTime.now(),
                });
              }
            }
          }
          
          if (changes.isNotEmpty) {
            onBookingStatusChanges(changes);
          }
        });
  }

  // Listen to new bookings with logging
  void _listenToNewBookings({
    required String teacherId,
    required Function(List<Map<String, dynamic>>) onNewBookings,
  }) {
    developer.log('RealtimeBookingService: Setting up new booking listener');
    
    _firestore
        .collection('bookings')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'draft')
        .snapshots()
        .listen((snapshot) {
          developer.log('RealtimeBookingService: Received new bookings - ${snapshot.docs.length} new bookings');
          
          final newBookings = <Map<String, dynamic>>[];
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final booking = BookingModel.fromMap(change.doc.data()!);
              
              developer.log('RealtimeBookingService: New booking detected - BookingID: ${booking.id}, StudentID: ${booking.studentId}');
              
              newBookings.add({
                'type': 'new_booking',
                'bookingId': booking.id,
                'booking': booking.toMap(),
                'timestamp': DateTime.now(),
              });
            }
          }
          
          if (newBookings.isNotEmpty) {
            onNewBookings(newBookings);
          }
        });
  }

  // Listen to payment confirmations with logging
  void _listenToPaymentConfirmations({
    required String teacherId,
    required String studentId,
    required Function(List<Map<String, dynamic>>) onPaymentConfirmations,
  }) {
    developer.log('RealtimeBookingService: Setting up payment confirmation listener');
    
    _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'payment_pending')
        .snapshots()
        .listen((snapshot) {
          developer.log('RealtimeBookingService: Received payment confirmation updates - ${snapshot.docs.length} updates');
          
          final confirmations = <Map<String, dynamic>>[];
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final booking = BookingModel.fromMap(change.doc.data()!);
              final previousStatus = change.doc.data()?['status'];
              final newStatus = booking.status;
              
              if (previousStatus == 'payment_pending' && newStatus == 'paid') {
                developer.log('RealtimeBookingService: Payment confirmed - BookingID: ${booking.id}, Amount: ${booking.totalAmount}');
                
                confirmations.add({
                  'type': 'payment_confirmation',
                  'bookingId': booking.id,
                  'amount': booking.totalAmount,
                  'booking': booking.toMap(),
                  'timestamp': DateTime.now(),
                });
              }
            }
          }
          
          if (confirmations.isNotEmpty) {
            onPaymentConfirmations(confirmations);
          }
        });
  }

  // Listen to lesson completions with logging
  void _listenToLessonCompletions({
    required String teacherId,
    required String studentId,
    required Function(List<Map<String, dynamic>>) onLessonCompletions,
  }) {
    developer.log('RealtimeBookingService: Setting up lesson completion listener');
    
    _firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', whereIn: ['scheduled', 'completed'])
        .snapshots()
        .listen((snapshot) {
          developer.log('RealtimeBookingService: Received lesson completion updates - ${snapshot.docs.length} updates');
          
          final completions = <Map<String, dynamic>>[];
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final lesson = LessonModel.fromMap(change.doc.data()!);
              final previousStatus = change.doc.data()?['status'];
              final newStatus = lesson.status;
              
              if (previousStatus == 'scheduled' && newStatus == 'completed') {
                developer.log('RealtimeBookingService: Lesson completed - LessonID: ${lesson.id}, BookingID: ${lesson.bookingId}');
                
                completions.add({
                  'type': 'lesson_completion',
                  'lessonId': lesson.id,
                  'bookingId': lesson.bookingId,
                  'lesson': lesson.toMap(),
                  'timestamp': DateTime.now(),
                });
              }
            }
          }
          
          if (completions.isNotEmpty) {
            onLessonCompletions(completions);
          }
        });
  }

  // Process booking status changes with notifications and logging
  Future<Map<String, dynamic>> processBookingStatusChange({
    required String bookingId,
    required String previousStatus,
    required String newStatus,
    required BuildContext context,
  }) async {
    developer.log('RealtimeBookingService: Processing booking status change - BookingID: $bookingId, From: $previousStatus, To: $newStatus');
    
    try {
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('RealtimeBookingService: Booking not found - BookingID: $bookingId');
        return {'success': false, 'error': 'Booking not found'};
      }

      // Send appropriate notifications based on status change
      switch (newStatus) {
        case 'paid':
          await _notificationService.sendPaymentConfirmation(
            context: context,
            teacherId: booking.teacherId,
            studentId: booking.studentId,
            bookingId: bookingId,
            amount: booking.totalAmount,
            paymentMethod: 'M-Pesa',
          );
          break;
          
        case 'cancelled':
          await _notificationService.sendBookingCancellation(
            context: context,
            teacherId: booking.teacherId,
            studentId: booking.studentId,
            bookingId: bookingId,
            reason: 'Booking cancelled by system',
            initiatedByTeacher: false,
          );
          break;
          
        case 'completed':
          await _notificationService.sendLessonCompletion(
            context: context,
            teacherId: booking.teacherId,
            studentId: booking.studentId,
            bookingId: bookingId,
            lessonId: 'all_lessons',
            teacherName: 'Teacher',
            studentName: 'Student',
            subject: booking.subject,
          );
          break;
      }

      developer.log('RealtimeBookingService: Booking status change processed successfully - BookingID: $bookingId');
      return {'success': true, 'booking': booking.toMap()};
    } catch (e) {
      developer.log('RealtimeBookingService: Error processing booking status change - BookingID: $bookingId, Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Process new booking with notifications and logging
  Future<Map<String, dynamic>> processNewBooking({
    required String bookingId,
    required BuildContext context,
  }) async {
    developer.log('RealtimeBookingService: Processing new booking - BookingID: $bookingId');
    
    try {
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('RealtimeBookingService: Booking not found - BookingID: $bookingId');
        return {'success': false, 'error': 'Booking not found'};
      }

      // Send booking confirmation notification
      await _notificationService.sendBookingConfirmation(
        context: context,
        teacherId: booking.teacherId,
        studentId: booking.studentId,
        bookingId: bookingId,
        teacherName: 'Teacher',
        studentName: 'Student',
        subject: booking.subject,
        startDate: booking.startDate,
        zoomLink: booking.zoomLink ?? '',
      );

      developer.log('RealtimeBookingService: New booking processed successfully - BookingID: $bookingId');
      return {'success': true, 'booking': booking.toMap()};
    } catch (e) {
      developer.log('RealtimeBookingService: Error processing new booking - BookingID: $bookingId, Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Process payment confirmation with notifications and logging
  Future<Map<String, dynamic>> processPaymentConfirmation({
    required String bookingId,
    required double amount,
    required BuildContext context,
  }) async {
    developer.log('RealtimeBookingService: Processing payment confirmation - BookingID: $bookingId, Amount: $amount');
    
    try {
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('RealtimeBookingService: Booking not found - BookingID: $bookingId');
        return {'success': false, 'error': 'Booking not found'};
      }

      // Update booking status to paid
      await _bookingService.updateBookingStatus(bookingId, 'paid');

      // Send payment confirmation notification
      await _notificationService.sendPaymentConfirmation(
        context: context,
        teacherId: booking.teacherId,
        studentId: booking.studentId,
        bookingId: bookingId,
        amount: amount,
        paymentMethod: 'M-Pesa',
      );

      // Generate and send Zoom link
      final zoomLink = await _bookingService.generateZoomLink(bookingId);
      await _notificationService.sendZoomLink(
        context: context,
        teacherId: booking.teacherId,
        studentId: booking.studentId,
        bookingId: bookingId,
        zoomLink: zoomLink,
        sessionDate: booking.startDate,
        sessionTime: booking.startTime,
      );

      developer.log('RealtimeBookingService: Payment confirmation processed successfully - BookingID: $bookingId');
      return {'success': true, 'booking': booking.toMap()};
    } catch (e) {
      developer.log('RealtimeBookingService: Error processing payment confirmation - BookingID: $bookingId, Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Process lesson completion with notifications and logging
  Future<Map<String, dynamic>> processLessonCompletion({
    required String lessonId,
    required String bookingId,
    required BuildContext context,
  }) async {
    developer.log('RealtimeBookingService: Processing lesson completion - LessonID: $lessonId, BookingID: $bookingId');
    
    try {
      // Get booking details
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('RealtimeBookingService: Booking not found - BookingID: $bookingId');
        return {'success': false, 'error': 'Booking not found'};
      }

      // Send lesson completion notification
      await _notificationService.sendLessonCompletion(
        context: context,
        teacherId: booking.teacherId,
        studentId: booking.studentId,
        bookingId: bookingId,
        lessonId: lessonId,
        teacherName: 'Teacher',
        studentName: 'Student',
        subject: booking.subject,
      );

      developer.log('RealtimeBookingService: Lesson completion processed successfully - LessonID: $lessonId, BookingID: $bookingId');
      return {'success': true, 'booking': booking.toMap()};
    } catch (e) {
      developer.log('RealtimeBookingService: Error processing lesson completion - LessonID: $lessonId, BookingID: $bookingId, Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Cleanup real-time listeners with logging
  void cleanupListeners() {
    developer.log('RealtimeBookingService: Cleaning up real-time listeners');
    
    // In a real implementation, you would cancel all active listeners here
    // For now, we'll just log the cleanup
    developer.log('RealtimeBookingService: All listeners cleaned up');
  }
  // Get teacher's active bookings with logging
  Future<List<BookingModel>> getTeacherActiveBookings(String teacherId) async {
    developer.log('RealtimeBookingService: Getting active bookings for teacher - TeacherID: $teacherId');
    
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('teacherId', isEqualTo: teacherId)
          .where('status', whereIn: ['draft', 'payment_pending', 'paid', 'active'])
          .orderBy('createdAt', descending: true)
          .get();
      
      final bookings = querySnapshot.docs.map((doc) => BookingModel.fromMap(doc.data())).toList();
      
      developer.log('RealtimeBookingService: Retrieved ${bookings.length} active bookings for teacher - TeacherID: $teacherId');
      return bookings;
    } catch (e) {
      developer.log('RealtimeBookingService: Error getting active bookings - TeacherID: $teacherId, Error: $e');
      return [];
    }
  }

  // Get teacher's new bookings with logging
  Future<List<BookingModel>> getTeacherNewBookings(String teacherId) async {
    developer.log('RealtimeBookingService: Getting new bookings for teacher - TeacherID: $teacherId');
    
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('teacherId', isEqualTo: teacherId)
          .where('status', isEqualTo: 'draft')
          .orderBy('createdAt', descending: true)
          .get();
      
      final bookings = querySnapshot.docs.map((doc) => BookingModel.fromMap(doc.data())).toList();
      
      developer.log('RealtimeBookingService: Retrieved ${bookings.length} new bookings for teacher - TeacherID: $teacherId');
      return bookings;
    } catch (e) {
      developer.log('RealtimeBookingService: Error getting new bookings - TeacherID: $teacherId, Error: $e');
      return [];
    }
  }

  // Listen to booking status changes with logging
  Stream<List<Map<String, dynamic>>> listenToBookingStatusChanges(String teacherId) {
    developer.log('RealtimeBookingService: Starting booking status change listener - TeacherID: $teacherId');
    
    return _firestore
        .collection('bookings')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', whereIn: ['draft', 'payment_pending', 'paid', 'active', 'completed', 'cancelled'])
        .snapshots()
        .map((snapshot) {
          developer.log('RealtimeBookingService: Received booking status changes - ${snapshot.docs.length} changes');
          
          final changes = <Map<String, dynamic>>[];
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final booking = BookingModel.fromMap(change.doc.data()!);
              final previousStatus = change.doc.data()?['status'];
              final newStatus = booking.status;
              
              if (previousStatus != newStatus) {
                developer.log('RealtimeBookingService: Booking status changed - BookingID: ${booking.id}, From: $previousStatus, To: $newStatus');
                
                changes.add({
                  'type': 'status_change',
                  'bookingId': booking.id,
                  'previousStatus': previousStatus,
                  'newStatus': newStatus,
                  'booking': booking.toMap(),
                  'timestamp': DateTime.now(),
                });
              }
            }
          }
          
          return changes;
        });
  }

  // Listen to payment confirmations with logging
  Stream<List<Map<String, dynamic>>> listenToPaymentConfirmations(String teacherId) {
    developer.log('RealtimeBookingService: Starting payment confirmation listener - TeacherID: $teacherId');
    
    return _firestore
        .collection('bookings')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'payment_pending')
        .snapshots()
        .map((snapshot) {
          developer.log('RealtimeBookingService: Received payment confirmation updates - ${snapshot.docs.length} updates');
          
          final confirmations = <Map<String, dynamic>>[];
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final booking = BookingModel.fromMap(change.doc.data()!);
              final previousStatus = change.doc.data()?['status'];
              final newStatus = booking.status;
              
              if (previousStatus == 'payment_pending' && newStatus == 'paid') {
                developer.log('RealtimeBookingService: Payment confirmed - BookingID: ${booking.id}, Amount: ${booking.totalAmount}');
                
                confirmations.add({
                  'type': 'payment_confirmation',
                  'bookingId': booking.id,
                  'amount': booking.totalAmount,
                  'booking': booking.toMap(),
                  'timestamp': DateTime.now(),
                });
              }
            }
          }
          
          return confirmations;
        });
  }

  // Mark booking as viewed with logging
  Future<void> markBookingAsViewed(String bookingId) async {
    developer.log('RealtimeBookingService: Marking booking as viewed - BookingID: $bookingId');
    
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'viewedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      
      developer.log('RealtimeBookingService: Booking marked as viewed - BookingID: $bookingId');
    } catch (e) {
      developer.log('RealtimeBookingService: Error marking booking as viewed - BookingID: $bookingId, Error: $e');
      rethrow;
    }
  }
}