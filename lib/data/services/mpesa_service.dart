import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

// M-Pesa service with comprehensive debugPrint logging
class MpesaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initiate M-Pesa STK Push with detailed logging
  Future<Map<String, dynamic>> initiateSTKPush(double amount, String phoneNumber) async {
    developer.log('MpesaService: Initiating STK Push for amount: $amount, phone: $phoneNumber');
    
    try {
      // Simulate M-Pesa API call
      final response = await _simulateMpesaApiCall(amount, phoneNumber);
      
      developer.log('MpesaService: STK Push initiated successfully - Response: $response');
      
      return {
        'success': true,
        'transactionId': response['transactionId'],
        'checkoutRequestID': response['checkoutRequestID'],
        'message': 'STK Push initiated successfully',
      };
    } catch (e) {
      developer.log('MpesaService: Error initiating STK Push - Error: $e');
      return {
        'success': false,
        'message': 'Failed to initiate STK Push: ${e.toString()}',
      };
    }
  }

  // Process payment webhook with detailed payload logging
  Future<bool> processPaymentWebhook(Map<String, dynamic> payload) async {
    developer.log('MpesaService: Processing payment webhook - Payload: $payload');
    
    try {
      final mpesaTransactionId = payload['TransactionID'];
      final resultCode = payload['ResultCode'];
      final resultDesc = payload['ResultDesc'];
      
      developer.log('MpesaService: Webhook processed - TransactionID: $mpesaTransactionId, ResultCode: $resultCode');
      
      if (resultCode == 0) {
        // Payment successful
        await _updateTransactionStatus(mpesaTransactionId, 'completed', payload);
        developer.log('MpesaService: Payment completed successfully for transaction: $mpesaTransactionId');
        return true;
      } else {
        // Payment failed
        await _updateTransactionStatus(mpesaTransactionId, 'failed', payload);
        developer.log('MpesaService: Payment failed for transaction: $mpesaTransactionId - Reason: $resultDesc');
        return false;
      }
    } catch (e) {
      developer.log('MpesaService: Error processing payment webhook - Error: $e');
      return false;
    }
  }

  // Process teacher payout with B2C transaction logging
  Future<bool> processTeacherPayout(String teacherId, double amount) async {
    developer.log('MpesaService: Processing teacher payout - TeacherID: $teacherId, Amount: $amount');
    
    try {
      final payoutTransactionId = _generateTransactionId();
      final mpesaResponse = await _simulateMpesaB2CTransfer(teacherId, amount);
      
      if (mpesaResponse['success']) {
        await _createPayoutRecord(
          teacherId: teacherId,
          amount: amount,
          transactionId: payoutTransactionId,
          mpesaTransactionId: mpesaResponse['transactionId'],
          mpesaReceiptNumber: mpesaResponse['receiptNumber'],
        );
        
        developer.log('MpesaService: Teacher payout processed successfully - TeacherID: $teacherId');
        return true;
      } else {
        developer.log('MpesaService: Teacher payout failed - TeacherID: $teacherId, Error: ${mpesaResponse['error']}');
        return false;
      }
    } catch (e) {
      developer.log('MpesaService: Error processing teacher payout - TeacherID: $teacherId, Error: $e');
      return false;
    }
  }

  // Simulate M-Pesa API call for development
  Future<Map<String, dynamic>> _simulateMpesaApiCall(double amount, String phoneNumber) async {
    developer.log('MpesaService: Simulating M-Pesa API call - Amount: $amount, Phone: $phoneNumber');
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    
    return {
      'transactionId': _generateTransactionId(),
      'checkoutRequestID': 'COD${DateTime.now().millisecondsSinceEpoch}',
      'responseCode': '0',
      'responseDescription': 'Success',
    };
  }

  // Simulate M-Pesa B2C transfer for development
  Future<Map<String, dynamic>> _simulateMpesaB2CTransfer(String teacherId, double amount) async {
    developer.log('MpesaService: Simulating M-Pesa B2C transfer - TeacherID: $teacherId, Amount: $amount');
    
    await Future.delayed(const Duration(seconds: 3)); // Simulate network delay
    
    final success = amount > 0 && amount < 100000; // Simulate success/failure logic
    
    return {
      'success': success,
      'transactionId': _generateTransactionId(),
      'receiptNumber': 'REC${DateTime.now().millisecondsSinceEpoch}',
      'error': success ? null : 'Insufficient balance',
    };
  }

  // Create payout record with audit logging
  Future<void> _createPayoutRecord({
    required String teacherId,
    required double amount,
    required String transactionId,
    required String mpesaTransactionId,
    required String mpesaReceiptNumber,
  }) async {
    developer.log('MpesaService: Creating payout record - TeacherID: $teacherId, Amount: $amount');
    
    final payout = TransactionModel(
      id: transactionId,
      type: 'payout',
      teacherId: teacherId,
      amount: amount,
      mpesaTransactionId: mpesaTransactionId,
      mpesaReceiptNumber: mpesaReceiptNumber,
      phoneNumber: '254712345678', // Would get from teacher profile
      status: 'completed',
      providerResponse: {},
      createdAt: DateTime.now(),
      processedAt: DateTime.now(),
    );

    await _firestore.collection('transactions').doc(payout.id).set(payout.toMap());
  }

  // Update transaction status with state change logging
  Future<bool> _updateTransactionStatus(String transactionId, String status, Map<String, dynamic>? providerResponse) async {
    developer.log('MpesaService: Updating transaction status - ID: $transactionId, Status: $status');
    
    try {
      final updateData = {
        'status': status,
        'processedAt': DateTime.now(),
      };
      
      if (providerResponse != null) {
        updateData['providerResponse'] = providerResponse;
      }
      
      await _firestore.collection('transactions').doc(transactionId).update(updateData);
      
      developer.log('MpesaService: Transaction status updated successfully - ID: $transactionId');
      return true;
    } catch (e) {
      developer.log('MpesaService: Error updating transaction status - ID: $transactionId, Error: $e');
      return false;
    }
  }

  // Generate unique transaction ID
  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch}${(1000 + DateTime.now().millisecond % 1000)}';
  }
}