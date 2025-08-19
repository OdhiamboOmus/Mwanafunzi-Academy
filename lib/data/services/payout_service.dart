import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/lesson_model.dart';
import '../models/transaction_model.dart';
import 'teacher_service.dart';
import 'booking_service.dart';
import 'transaction_service.dart';

// Payout service with comprehensive debugPrint logging
class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeacherService _teacherService = TeacherService();
  final BookingService _bookingService = BookingService();
  final TransactionService _transactionService = TransactionService();

  // Calculate payout amount after lesson completion with calculation logging
  Future<double> calculatePayoutAmount(String bookingId) async {
    developer.log('PayoutService: Calculating payout amount for booking $bookingId');
    
    try {
      // Get booking details
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('PayoutService: Booking not found - ID: $bookingId');
        throw Exception('Booking not found');
      }

      // Calculate platform fee (20% of total amount)
      final platformFee = booking.totalAmount * 0.20;
      final teacherPayout = booking.totalAmount - platformFee;

      developer.log('PayoutService: Payout calculation completed - BookingID: $bookingId, TotalAmount: ${booking.totalAmount}, PlatformFee: $platformFee, TeacherPayout: $teacherPayout');

      return teacherPayout;
    } catch (e) {
      developer.log('PayoutService: Error calculating payout amount - BookingID: $bookingId, Error: $e');
      rethrow;
    }
  }

  // Check if payout is eligible for a booking with logging
  Future<bool> isPayoutEligible(String bookingId) async {
    developer.log('PayoutService: Checking payout eligibility for booking $bookingId');
    
    try {
      // Get booking details
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('PayoutService: Booking not found - ID: $bookingId');
        return false;
      }

      // Check if booking is completed
      if (booking.status != 'completed') {
        developer.log('PayoutService: Booking not completed - Status: ${booking.status}');
        return false;
      }

      // Check if all lessons are completed
      final allLessonsCompleted = await _areAllLessonsCompleted(bookingId);
      if (!allLessonsCompleted) {
        developer.log('PayoutService: Not all lessons completed for booking $bookingId');
        return false;
      }

      // Check if payout already processed
      final payoutExists = await _checkExistingPayout(bookingId);
      if (payoutExists) {
        developer.log('PayoutService: Payout already processed for booking $bookingId');
        return false;
      }

      developer.log('PayoutService: Payout eligibility confirmed for booking $bookingId');
      return true;
    } catch (e) {
      developer.log('PayoutService: Error checking payout eligibility - BookingID: $bookingId, Error: $e');
      return false;
    }
  }

  // Initiate payout process with comprehensive logging
  Future<String?> initiatePayout(String bookingId) async {
    developer.log('PayoutService: Initiating payout process for booking $bookingId');
    
    try {
      // Check eligibility
      final eligible = await isPayoutEligible(bookingId);
      if (!eligible) {
        developer.log('PayoutService: Payout not eligible for booking $bookingId');
        return null;
      }

      // Calculate payout amount
      final payoutAmount = await calculatePayoutAmount(bookingId);

      // Get booking details for transaction creation
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        developer.log('PayoutService: Could not get booking details for payout initiation');
        return null;
      }

      // Create payout transaction
      final transactionId = await _transactionService.createTransaction(
        type: 'payout',
        amount: payoutAmount,
        mpesaTransactionId: '', // Will be populated by Cloud Function
        mpesaReceiptNumber: '', // Will be populated by Cloud Function
        phoneNumber: '', // Will be populated from teacher profile
        bookingId: bookingId,
      );

      developer.log('PayoutService: Payout initiated successfully - BookingID: $bookingId, TransactionID: $transactionId, PayoutAmount: $payoutAmount');

      return transactionId;
    } catch (e) {
      developer.log('PayoutService: Error initiating payout - BookingID: $bookingId, Error: $e');
      return null;
    }
  }

  // Get teacher payout history with query logging
  Future<List<TransactionModel>> getTeacherPayoutHistory(String teacherId) async {
    developer.log('PayoutService: Getting payout history for teacher $teacherId');
    
    try {
      final transactions = await _transactionService.getTransactionHistory(
        type: 'payout',
        teacherId: teacherId,
      );

      developer.log('PayoutService: Retrieved ${transactions.length} payout transactions for teacher $teacherId');
      return transactions;
    } catch (e) {
      developer.log('PayoutService: Error getting payout history - TeacherID: $teacherId, Error: $e');
      return [];
    }
  }

  // Get teacher earnings summary with calculation logging
  Future<Map<String, dynamic>> getTeacherEarningsSummary(String teacherId) async {
    developer.log('PayoutService: Calculating earnings summary for teacher $teacherId');
    
    try {
      // Get all completed payouts
      final payouts = await _transactionService.getTransactionHistory(
        type: 'payout',
        status: 'completed',
        teacherId: teacherId,
      );

      // Get all pending payouts
      final pendingPayouts = await _transactionService.getTransactionHistory(
        type: 'payout',
        status: 'pending',
        teacherId: teacherId,
      );

      double totalEarnings = 0;
      double pendingEarnings = 0;
      int totalPayouts = 0;
      int pendingPayoutsCount = 0;

      for (final payout in payouts) {
        totalEarnings += payout.amount;
        totalPayouts++;
      }

      for (final payout in pendingPayouts) {
        pendingEarnings += payout.amount;
        pendingPayoutsCount++;
      }

      final summary = {
        'totalEarnings': totalEarnings,
        'pendingEarnings': pendingEarnings,
        'totalPayouts': totalPayouts,
        'pendingPayoutsCount': pendingPayoutsCount,
        'availableBalance': totalEarnings, // For now, all completed earnings are available
      };

      developer.log('PayoutService: Earnings summary calculated - TeacherID: $teacherId, Summary: $summary');

      return summary;
    } catch (e) {
      developer.log('PayoutService: Error calculating earnings summary - TeacherID: $teacherId, Error: $e');
      return {
        'totalEarnings': 0,
        'pendingEarnings': 0,
        'totalPayouts': 0,
        'pendingPayoutsCount': 0,
        'availableBalance': 0,
      };
    }
  }

  // Mark lesson as completed and trigger payout process with logging
  Future<bool> markLessonCompleted(String lessonId, {String? teacherNotes}) async {
    developer.log('PayoutService: Marking lesson as completed - LessonID: $lessonId');
    
    try {
      // Get lesson details
      final lessonDoc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!lessonDoc.exists) {
        developer.log('PayoutService: Lesson not found - ID: $lessonId');
        return false;
      }

      final lesson = LessonModel.fromMap(lessonDoc.data()!);
      
      // Update lesson status to completed
      final updateData = {
        'status': 'completed',
        'completedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      if (teacherNotes != null) {
        updateData['teacherNotes'] = teacherNotes;
      }

      await lessonDoc.reference.update(updateData);

      developer.log('PayoutService: Lesson marked as completed - LessonID: $lessonId');

      // Check if all lessons in booking are completed to trigger payout
      final allCompleted = await _areAllLessonsCompleted(lesson.bookingId);
      if (allCompleted) {
        developer.log('PayoutService: All lessons completed, triggering payout for booking ${lesson.bookingId}');
        await initiatePayout(lesson.bookingId);
      }

      return true;
    } catch (e) {
      developer.log('PayoutService: Error marking lesson as completed - LessonID: $lessonId, Error: $e');
      return false;
    }
  }

  // Check if all lessons in a booking are completed with logging
  Future<bool> _areAllLessonsCompleted(String bookingId) async {
    developer.log('PayoutService: Checking if all lessons completed for booking $bookingId');
    
    try {
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      final totalLessons = lessonsSnapshot.docs.length;
      final completedLessons = lessonsSnapshot.docs.where((doc) {
        final lesson = LessonModel.fromMap(doc.data());
        return lesson.status == 'completed';
      }).length;

      final allCompleted = completedLessons == totalLessons;

      developer.log('PayoutService: Lesson completion check result - BookingID: $bookingId, TotalLessons: $totalLessons, CompletedLessons: $completedLessons, AllCompleted: $allCompleted');

      return allCompleted;
    } catch (e) {
      developer.log('PayoutService: Error checking lesson completion - BookingID: $bookingId, Error: $e');
      return false;
    }
  }

  // Check if payout already exists for booking with logging
  Future<bool> _checkExistingPayout(String bookingId) async {
    developer.log('PayoutService: Checking for existing payout for booking $bookingId');
    
    try {
      final existingPayout = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payout')
          .where('bookingId', isEqualTo: bookingId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      final payoutExists = existingPayout.docs.isNotEmpty;

      developer.log('PayoutService: Existing payout check result - BookingID: $bookingId, PayoutExists: $payoutExists');

      return payoutExists;
    } catch (e) {
      developer.log('PayoutService: Error checking existing payout - BookingID: $bookingId, Error: $e');
      return false;
    }
  }
}