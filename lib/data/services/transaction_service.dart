import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'ledger_service.dart';

// Transaction service with comprehensive debugPrint logging
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LedgerService _ledgerService = LedgerService();

  // Create transaction record with audit logging and ledger tracking
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
    developer.log('TransactionService: Creating transaction - Type: $type, Amount: $amount');
    
    try {
      final transaction = TransactionModel(
        id: _generateTransactionId(),
        type: type,
        bookingId: bookingId,
        teacherId: teacherId,
        parentId: parentId,
        amount: amount,
        mpesaTransactionId: mpesaTransactionId,
        mpesaReceiptNumber: mpesaReceiptNumber,
        phoneNumber: phoneNumber,
        status: 'pending',
        providerResponse: {},
        createdAt: DateTime.now(),
      );

      await _firestore.collection('transactions').doc(transaction.id).set(transaction.toMap());
      
      // Create corresponding ledger entry
      await _createTransactionLedgerEntry(transaction);
      
      developer.log('TransactionService: Transaction created successfully - ID: ${transaction.id}');
      return transaction.id;
    } catch (e) {
      developer.log('TransactionService: Error creating transaction - Error: $e');
      rethrow;
    }
  }

  // Update transaction status with state change logging and ledger tracking
  Future<bool> updateTransactionStatus(String transactionId, String status, Map<String, dynamic>? providerResponse) async {
    developer.log('TransactionService: Updating transaction status - ID: $transactionId, Status: $status');
    
    try {
      final updateData = {
        'status': status,
        'processedAt': DateTime.now(),
      };
      
      if (providerResponse != null) {
        updateData['providerResponse'] = providerResponse;
      }
      
      // Get transaction details before update
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        developer.log('TransactionService: Transaction not found - ID: $transactionId');
        return false;
      }
      
      final transaction = TransactionModel.fromMap(transactionDoc.data()!);
      
      await _firestore.collection('transactions').doc(transactionId).update(updateData);
      
      // Create ledger entry for status change
      if (status == 'completed') {
        await _createTransactionLedgerEntry(transaction);
      }
      
      developer.log('TransactionService: Transaction status updated successfully - ID: $transactionId');
      return true;
    } catch (e) {
      developer.log('TransactionService: Error updating transaction status - ID: $transactionId, Error: $e');
      return false;
    }
  }

  // Get transaction history with query logging
  Future<List<TransactionModel>> getTransactionHistory({
    String? type,
    String? status,
    String? teacherId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('TransactionService: Getting transaction history - Type: $type, Status: $status, TeacherID: $teacherId');
    
    try {
      Query query = _firestore.collection('transactions');
      
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (teacherId != null) {
        query = query.where('teacherId', isEqualTo: teacherId);
      }
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }
      
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      final transactions = snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      
      developer.log('TransactionService: Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      developer.log('TransactionService: Error getting transaction history - Error: $e');
      return [];
    }
  }

  // Get transaction by ID with logging
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    developer.log('TransactionService: Getting transaction by ID - ID: $transactionId');
    
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      
      if (doc.exists) {
        final transaction = TransactionModel.fromMap(doc.data()!);
        developer.log('TransactionService: Transaction found - ID: ${transaction.id}');
        return transaction;
      } else {
        developer.log('TransactionService: Transaction not found - ID: $transactionId');
        return null;
      }
    } catch (e) {
      developer.log('TransactionService: Error getting transaction - ID: $transactionId, Error: $e');
      return null;
    }
  
  }

  // Get platform financial summary with logging
  Future<Map<String, dynamic>> getFinancialSummary() async {
    developer.log('TransactionService: Getting financial summary');
    
    try {
      // Get all completed payments
      final paymentsSnapshot = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payment')
          .where('status', isEqualTo: 'completed')
          .get();
      
      double totalRevenue = 0;
      for (var doc in paymentsSnapshot.docs) {
        final transaction = TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
        totalRevenue += transaction.amount;
      }
      
      // Get all pending payouts
      final payoutsSnapshot = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payout')
          .where('status', isEqualTo: 'pending')
          .get();
      
      double pendingPayouts = 0;
      for (var doc in payoutsSnapshot.docs) {
        final transaction = TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
        pendingPayouts += transaction.amount;
      }
      
      // Get this month's revenue
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final monthlySnapshot = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payment')
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThanOrEqualTo: endOfMonth)
          .get();
      
      double monthlyRevenue = 0;
      for (var doc in monthlySnapshot.docs) {
        final transaction = TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
        monthlyRevenue += transaction.amount;
      }
      
      final summary = {
        'totalRevenue': totalRevenue,
        'pendingPayouts': pendingPayouts,
        'monthlyRevenue': monthlyRevenue,
      };
      
      developer.log('TransactionService: Financial summary retrieved - $summary');
      return summary;
    } catch (e) {
      developer.log('TransactionService: Error getting financial summary - Error: $e');
      return {
        'totalRevenue': 0,
        'pendingPayouts': 0,
        'monthlyRevenue': 0,
      };
    }
  }

  // Create transaction ledger entry with logging
  Future<void> _createTransactionLedgerEntry(TransactionModel transaction) async {
    developer.log('TransactionService: Creating transaction ledger entry - TransactionID: ${transaction.id}');
    
    try {
      String ledgerType;
      String description;
      
      switch (transaction.type) {
        case 'payment':
          ledgerType = 'credit';
          description = 'Payment received for booking ${transaction.bookingId ?? 'unknown'}';
          break;
        case 'payout':
          ledgerType = 'debit';
          description = 'Teacher payout for booking ${transaction.bookingId ?? 'unknown'}';
          break;
        case 'refund':
          ledgerType = 'debit';
          description = 'Refund processed for booking ${transaction.bookingId ?? 'unknown'}';
          break;
        default:
          ledgerType = 'credit';
          description = 'Transaction ${transaction.type} for booking ${transaction.bookingId ?? 'unknown'}';
      }
      
      await _ledgerService.createLedgerEntry(
        transactionId: transaction.id,
        type: ledgerType,
        amount: transaction.amount,
        description: description,
        teacherId: transaction.teacherId,
      );
      
      developer.log('TransactionService: Transaction ledger entry created successfully - TransactionID: ${transaction.id}');
    } catch (e) {
      developer.log('TransactionService: Error creating transaction ledger entry - TransactionID: ${transaction.id}, Error: $e');
    }
  }

  // Generate unique transaction ID
  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch}${(1000 + DateTime.now().millisecond % 1000)}';
  }
}