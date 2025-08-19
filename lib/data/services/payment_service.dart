import 'dart:developer' as developer;
import 'mpesa_service.dart';
import 'transaction_service.dart';

// Payment service with comprehensive debugPrint logging
class PaymentService {
  final MpesaService _mpesaService = MpesaService();
  final TransactionService _transactionService = TransactionService();

  // Initiate M-Pesa STK Push with detailed logging
  Future<Map<String, dynamic>> initiateSTKPush(double amount, String phoneNumber) async {
    developer.log('PaymentService: Initiating STK Push for amount: $amount, phone: $phoneNumber');
    
    try {
      final response = await _mpesaService.initiateSTKPush(amount, phoneNumber);
      
      developer.log('PaymentService: STK Push initiated successfully - Response: $response');
      
      return response;
    } catch (e) {
      developer.log('PaymentService: Error initiating STK Push - Error: $e');
      return {
        'success': false,
        'message': 'Failed to initiate STK Push: ${e.toString()}',
      };
    }
  }

  // Process payment webhook with detailed payload logging
  Future<bool> processPaymentWebhook(Map<String, dynamic> payload) async {
    developer.log('PaymentService: Processing payment webhook - Payload: $payload');
    
    try {
      final success = await _mpesaService.processPaymentWebhook(payload);
      
      if (success) {
        developer.log('PaymentService: Payment webhook processed successfully');
      } else {
        developer.log('PaymentService: Payment webhook processing failed');
      }
      
      return success;
    } catch (e) {
      developer.log('PaymentService: Error processing payment webhook - Error: $e');
      return false;
    }
  }

  // Create transaction record with audit logging
  Future<String> createTransaction({
    required String type,
    required double amount,
    required String mpesaTransactionId,
    required String mpesaReceiptNumber,
    required String phoneNumber,
    String? bookingId,
    String? teacherId,
    String? parentId,
  }) async {
    developer.log('PaymentService: Creating transaction - Type: $type, Amount: $amount');
    
    try {
      final transactionId = await _transactionService.createTransaction(
        type: type,
        amount: amount,
        mpesaTransactionId: mpesaTransactionId,
        mpesaReceiptNumber: mpesaReceiptNumber,
        phoneNumber: phoneNumber,
        bookingId: bookingId,
        teacherId: teacherId,
        parentId: parentId,
      );
      
      developer.log('PaymentService: Transaction created successfully - ID: $transactionId');
      return transactionId;
    } catch (e) {
      developer.log('PaymentService: Error creating transaction - Error: $e');
      rethrow;
    }
  }

  // Update transaction status with state change logging
  Future<bool> updateTransactionStatus(String transactionId, String status, Map<String, dynamic>? providerResponse) async {
    developer.log('PaymentService: Updating transaction status - ID: $transactionId, Status: $status');
    
    try {
      final success = await _transactionService.updateTransactionStatus(transactionId, status, providerResponse);
      
      if (success) {
        developer.log('PaymentService: Transaction status updated successfully - ID: $transactionId');
      } else {
        developer.log('PaymentService: Failed to update transaction status - ID: $transactionId');
      }
      
      return success;
    } catch (e) {
      developer.log('PaymentService: Error updating transaction status - ID: $transactionId, Error: $e');
      return false;
    }
  }

  // Process teacher payout with B2C transaction logging
  Future<bool> processTeacherPayout(String teacherId, double amount) async {
    developer.log('PaymentService: Processing teacher payout - TeacherID: $teacherId, Amount: $amount');
    
    try {
      final success = await _mpesaService.processTeacherPayout(teacherId, amount);
      
      if (success) {
        developer.log('PaymentService: Teacher payout processed successfully - TeacherID: $teacherId');
      } else {
        developer.log('PaymentService: Teacher payout failed - TeacherID: $teacherId');
      }
      
      return success;
    } catch (e) {
      developer.log('PaymentService: Error processing teacher payout - TeacherID: $teacherId, Error: $e');
      return false;
    }
  }

  // Get transaction history with query logging
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('PaymentService: Getting transaction history - Type: $type, Status: $status');
    
    try {
      final transactions = await _transactionService.getTransactionHistory(
        type: type,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      
      final formattedTransactions = transactions.map((transaction) {
        return {
          'id': transaction.id,
          'type': transaction.type,
          'amount': transaction.amount,
          'status': transaction.status,
          'createdAt': transaction.createdAt,
          'displayAmount': transaction.displayAmount,
          'displayDateTime': transaction.displayDateTime,
          'typeText': transaction.typeText,
          'statusText': transaction.statusText,
        };
      }).toList();
      
      developer.log('PaymentService: Retrieved ${formattedTransactions.length} transactions');
      return formattedTransactions;
    } catch (e) {
      developer.log('PaymentService: Error getting transaction history - Error: $e');
      return [];
    }
  }

  // Get platform financial summary with logging
  Future<Map<String, dynamic>> getFinancialSummary() async {
    developer.log('PaymentService: Getting financial summary');
    
    try {
      final summary = await _transactionService.getFinancialSummary();
      
      developer.log('PaymentService: Financial summary retrieved - $summary');
      return summary;
    } catch (e) {
      developer.log('PaymentService: Error getting financial summary - Error: $e');
      return {
        'totalRevenue': 0,
        'pendingPayouts': 0,
        'monthlyRevenue': 0,
      };
    }
  }
}