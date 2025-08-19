import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

// Payout retry service with comprehensive debugPrint logging
class PayoutRetryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  // Schedule payout retry for failed transactions with retry logging
  Future<bool> schedulePayoutRetry(String transactionId) async {
    developer.log('PayoutRetryService: Scheduling payout retry - TransactionID: $transactionId');
    
    try {
      // Get transaction details
      final transaction = await _transactionService.getTransactionById(transactionId);
      if (transaction == null) {
        developer.log('PayoutRetryService: Transaction not found - ID: $transactionId');
        return false;
      }

      // Check if transaction is a payout and failed
      if (transaction.type != 'payout' || transaction.status != 'failed') {
        developer.log('PayoutRetryService: Transaction not eligible for retry - Type: ${transaction.type}, Status: ${transaction.status}');
        return false;
      }

      // Get existing retry attempts
      final retryDoc = await _firestore
          .collection('payout_retries')
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (retryDoc.docs.isNotEmpty) {
        final existingRetry = retryDoc.docs.first.data();
        final attempts = existingRetry['attempts'] ?? 0;
        final maxAttempts = existingRetry['maxAttempts'] ?? 3;

        if (attempts >= maxAttempts) {
          developer.log('PayoutRetryService: Max retry attempts reached - TransactionID: $transactionId, Attempts: $attempts');
          return false;
        }

        // Update existing retry record
        await retryDoc.docs.first.reference.update({
          'attempts': attempts + 1,
          'scheduledAt': FieldValue.serverTimestamp(),
          'retryAt': DateTime.now().add(Duration(hours: 1)), // Retry after 1 hour
        });

        developer.log('PayoutRetryService: Retry attempt updated - TransactionID: $transactionId, Attempt: ${attempts + 1}');
      } else {
        // Create new retry record
        await _firestore.collection('payout_retries').add({
          'transactionId': transactionId,
          'teacherId': transaction.teacherId,
          'amount': transaction.amount,
          'attempts': 1,
          'maxAttempts': 3,
          'scheduledAt': FieldValue.serverTimestamp(),
          'retryAt': DateTime.now().add(Duration(hours: 1)), // Retry after 1 hour
          'status': 'scheduled',
        });

        developer.log('PayoutRetryService: New retry scheduled - TransactionID: $transactionId, Attempt: 1');
      }

      return true;
    } catch (e) {
      developer.log('PayoutRetryService: Error scheduling payout retry - TransactionID: $transactionId, Error: $e');
      return false;
    }
  }

  // Process scheduled retries with comprehensive logging
  Future<void> processScheduledRetries() async {
    developer.log('PayoutRetryService: Processing scheduled payout retries');
    
    try {
      // Get all scheduled retries that are due
      final now = DateTime.now();
      final dueRetries = await _firestore
          .collection('payout_retries')
          .where('status', isEqualTo: 'scheduled')
          .where('retryAt', isLessThanOrEqualTo: now)
          .get();

      developer.log('PayoutRetryService: Found ${dueRetries.docs.length} due retries');

      for (final retryDoc in dueRetries.docs) {
        final retryData = retryDoc.data();
        final transactionId = retryData['transactionId'];
        
        developer.log('PayoutRetryService: Processing retry - TransactionID: $transactionId');

        // Update retry status to processing
        await retryDoc.reference.update({
          'status': 'processing',
          'processedAt': FieldValue.serverTimestamp(),
        });

        try {
          // Get transaction details
          final transaction = await _transactionService.getTransactionById(transactionId);
          if (transaction == null) {
            developer.log('PayoutRetryService: Transaction not found for retry - ID: $transactionId');
            await _markRetryAsFailed(retryDoc.id, 'Transaction not found');
            continue;
          }

          // Re-initiate payout process
          final retrySuccess = await _retryPayoutProcess(transaction);
          
          if (retrySuccess) {
            // Mark retry as completed
            await retryDoc.reference.update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });

            developer.log('PayoutRetryService: Payout retry successful - TransactionID: $transactionId');
          } else {
            // Check if we should retry again
            final attempts = retryData['attempts'] ?? 0;
            final maxAttempts = retryData['maxAttempts'] ?? 3;

            if (attempts < maxAttempts) {
              // Schedule another retry
              await retryDoc.reference.update({
                'status': 'scheduled',
                'retryAt': DateTime.now().add(Duration(hours: 2)), // Longer delay for subsequent retries
                'attempts': attempts + 1,
              });

              developer.log('PayoutRetryService: Scheduling additional retry - TransactionID: $transactionId, Attempt: ${attempts + 1}');
            } else {
              // Mark as failed
              await _markRetryAsFailed(retryDoc.id, 'Max retry attempts reached');
            }
          }
        } catch (e) {
          developer.log('PayoutRetryService: Error processing retry - RetryID: ${retryDoc.id}, Error: $e');
          await _markRetryAsFailed(retryDoc.id, 'Processing error: $e');
        }
      }

      developer.log('PayoutRetryService: Completed processing scheduled retries');
    } catch (e) {
      developer.log('PayoutRetryService: Error processing scheduled retries - Error: $e');
    }
  }

  // Get retry history with query logging
  Future<List<Map<String, dynamic>>> getRetryHistory({
    String? teacherId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('PayoutRetryService: Getting retry history - TeacherID: $teacherId');
    
    try {
      Query query = _firestore.collection('payout_retries');
      
      if (teacherId != null) {
        query = query.where('teacherId', isEqualTo: teacherId);
      }
      
      if (startDate != null) {
        query = query.where('scheduledAt', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('scheduledAt', isLessThanOrEqualTo: endDate);
      }
      
      final snapshot = await query.orderBy('scheduledAt', descending: true).get();
      final retries = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      developer.log('PayoutRetryService: Retrieved ${retries.length} retry records');
      return retries;
    } catch (e) {
      developer.log('PayoutRetryService: Error getting retry history - Error: $e');
      return [];
    }
  }

  // Get retry statistics with calculation logging
  Future<Map<String, dynamic>> getRetryStatistics() async {
    developer.log('PayoutRetryService: Calculating retry statistics');
    
    try {
      // Get total retry attempts
      final totalRetries = await _firestore.collection('payout_retries').get();
      
      // Get successful retries
      final successfulRetries = await _firestore
          .collection('payout_retries')
          .where('status', isEqualTo: 'completed')
          .get();
      
      // Get failed retries
      final failedRetries = await _firestore
          .collection('payout_retries')
          .where('status', isEqualTo: 'failed')
          .get();
      
      // Get scheduled retries
      final scheduledRetries = await _firestore
          .collection('payout_retries')
          .where('status', isEqualTo: 'scheduled')
          .get();
      
      // Get processing retries
      final processingRetries = await _firestore
          .collection('payout_retries')
          .where('status', isEqualTo: 'processing')
          .get();
      
      final stats = {
        'totalRetries': totalRetries.docs.length,
        'successfulRetries': successfulRetries.docs.length,
        'failedRetries': failedRetries.docs.length,
        'scheduledRetries': scheduledRetries.docs.length,
        'processingRetries': processingRetries.docs.length,
        'successRate': totalRetries.docs.length > 0 
            ? (successfulRetries.docs.length / totalRetries.docs.length * 100).toStringAsFixed(1)
            : '0.0',
      };

      developer.log('PayoutRetryService: Retry statistics calculated - $stats');
      return stats;
    } catch (e) {
      developer.log('PayoutRetryService: Error calculating retry statistics - Error: $e');
      return {
        'totalRetries': 0,
        'successfulRetries': 0,
        'failedRetries': 0,
        'scheduledRetries': 0,
        'processingRetries': 0,
        'successRate': '0.0',
      };
    }
  }

  // Manually trigger retry for a specific transaction with logging
  Future<bool> manualRetry(String transactionId) async {
    developer.log('PayoutRetryService: Manually triggering retry - TransactionID: $transactionId');
    
    try {
      // Cancel any existing retry attempts
      await _cancelExistingRetries(transactionId);
      
      // Schedule new retry
      final success = await schedulePayoutRetry(transactionId);
      
      if (success) {
        developer.log('PayoutRetryService: Manual retry scheduled successfully - TransactionID: $transactionId');
      } else {
        developer.log('PayoutRetryService: Failed to schedule manual retry - TransactionID: $transactionId');
      }
      
      return success;
    } catch (e) {
      developer.log('PayoutRetryService: Error triggering manual retry - TransactionID: $transactionId, Error: $e');
      return false;
    }
  }

  // Cancel existing retry attempts for a transaction with logging
  Future<bool> _cancelExistingRetries(String transactionId) async {
    developer.log('PayoutRetryService: Cancelling existing retries - TransactionID: $transactionId');
    
    try {
      final existingRetries = await _firestore
          .collection('payout_retries')
          .where('transactionId', isEqualTo: transactionId)
          .get();

      for (final retryDoc in existingRetries.docs) {
        await retryDoc.reference.update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledReason': 'Manual retry triggered',
        });
      }

      developer.log('PayoutRetryService: Cancelled ${existingRetries.docs.length} existing retries - TransactionID: $transactionId');
      return true;
    } catch (e) {
      developer.log('PayoutRetryService: Error cancelling existing retries - TransactionID: $transactionId, Error: $e');
      return false;
    }
  }

  // Mark retry as failed with logging
  Future<void> _markRetryAsFailed(String retryId, String reason) async {
    developer.log('PayoutRetryService: Marking retry as failed - RetryID: $retryId, Reason: $reason');
    
    try {
      await _firestore.collection('payout_retries').doc(retryId).update({
        'status': 'failed',
        'failedAt': FieldValue.serverTimestamp(),
        'failureReason': reason,
      });
      
      developer.log('PayoutRetryService: Retry marked as failed - RetryID: $retryId');
    } catch (e) {
      developer.log('PayoutRetryService: Error marking retry as failed - RetryID: $retryId, Error: $e');
    }
  }

  // Retry payout process with comprehensive logging
  Future<bool> _retryPayoutProcess(TransactionModel transaction) async {
    developer.log('PayoutRetryService: Retrying payout process - TransactionID: ${transaction.id}');
    
    try {
      // In a real implementation, this would call the actual M-Pesa B2C API
      // For now, we'll simulate the retry with a success rate of 70%
      final success = await _simulateRetryProcess(transaction);
      
      if (success) {
        // Update transaction status to completed
        await _transactionService.updateTransactionStatus(
          transaction.id, 
          'completed', 
          {'retry': true, 'retryCount': (transaction.providerResponse?['retryCount'] ?? 0) + 1}
        );
        
        developer.log('PayoutRetryService: Payout retry successful - TransactionID: ${transaction.id}');
        return true;
      } else {
        // Update transaction status to failed again
        await _transactionService.updateTransactionStatus(
          transaction.id, 
          'failed', 
          {'retry': true, 'retryCount': (transaction.providerResponse?['retryCount'] ?? 0) + 1, 'error': 'Retry failed'}
        );
        
        developer.log('PayoutRetryService: Payout retry failed - TransactionID: ${transaction.id}');
        return false;
      }
    } catch (e) {
      developer.log('PayoutRetryService: Error retrying payout process - TransactionID: ${transaction.id}, Error: $e');
      return false;
    }
  }

  // Simulate retry process with logging
  Future<bool> _simulateRetryProcess(TransactionModel transaction) async {
    developer.log('PayoutRetryService: Simulating retry process - TransactionID: ${transaction.id}, Amount: ${transaction.amount}');
    
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));
    
    // 70% success rate for retries
    final success = transaction.amount > 0 && transaction.amount <= 50000 && DateTime.now().millisecond % 100 < 70;
    
    developer.log('PayoutRetryService: Retry simulation result - TransactionID: ${transaction.id}, Success: $success');
    return success;
  }
}