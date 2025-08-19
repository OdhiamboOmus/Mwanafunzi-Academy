import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ledger_model.dart';

// Ledger service for immutable financial tracking with comprehensive logging
class LedgerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create ledger entry with audit logging
  Future<String> createLedgerEntry({
    required String transactionId,
    required String type,
    required double amount,
    required String description,
    String? teacherId,
  }) async {
    developer.log('LedgerService: Creating ledger entry - Type: $type, Amount: $amount');
    
    try {
      // Get current balance
      final currentBalance = await _getCurrentBalance();
      
      // Calculate new balance
      final newBalance = type == 'credit' 
          ? currentBalance + amount 
          : currentBalance - amount;

      // Generate ledger entry ID
      final ledgerId = _generateLedgerId();

      // Create ledger entry
      final ledgerEntry = LedgerModel(
        id: ledgerId,
        transactionId: transactionId,
        type: type,
        amount: amount,
        balance: newBalance,
        description: description,
        teacherId: teacherId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('platform_ledger').doc(ledgerId).set(ledgerEntry.toMap());
      
      developer.log('LedgerService: Ledger entry created successfully - ID: $ledgerId, Balance: $newBalance');
      return ledgerId;
    } catch (e) {
      developer.log('LedgerService: Error creating ledger entry - Error: $e');
      rethrow;
    }
  }

  // Get current balance with logging
  Future<double> _getCurrentBalance() async {
    developer.log('LedgerService: Getting current balance');
    
    try {
      final snapshot = await _firestore
          .collection('platform_ledger')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final latestEntry = LedgerModel.fromMap(snapshot.docs.first.data());
        developer.log('LedgerService: Current balance retrieved - Balance: ${latestEntry.balance}');
        return latestEntry.balance;
      } else {
        developer.log('LedgerService: No ledger entries found, returning 0');
        return 0.0;
      }
    } catch (e) {
      developer.log('LedgerService: Error getting current balance - Error: $e');
      return 0.0;
    }
  }

  // Get ledger history with query logging
  Future<List<LedgerModel>> getLedgerHistory({
    String? type,
    String? teacherId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    developer.log('LedgerService: Getting ledger history - Type: $type, TeacherID: $teacherId');
    
    try {
      Query query = _firestore.collection('platform_ledger');
      
      if (type != null) {
        query = query.where('type', isEqualTo: type);
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
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final ledgerEntries = snapshot.docs
          .map((doc) => LedgerModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      developer.log('LedgerService: Retrieved ${ledgerEntries.length} ledger entries');
      return ledgerEntries;
    } catch (e) {
      developer.log('LedgerService: Error getting ledger history - Error: $e');
      return [];
    }
  }

  // Get ledger entry by ID with logging
  Future<LedgerModel?> getLedgerEntryById(String ledgerId) async {
    developer.log('LedgerService: Getting ledger entry by ID - ID: $ledgerId');
    
    try {
      final doc = await _firestore.collection('platform_ledger').doc(ledgerId).get();
      
      if (doc.exists) {
        final ledgerEntry = LedgerModel.fromMap(doc.data()!);
        developer.log('LedgerService: Ledger entry found - ID: ${ledgerEntry.id}');
        return ledgerEntry;
      } else {
        developer.log('LedgerService: Ledger entry not found - ID: $ledgerId');
        return null;
      }
    } catch (e) {
      developer.log('LedgerService: Error getting ledger entry - ID: $ledgerId, Error: $e');
      return null;
    }
  }

  // Get platform financial summary with logging
  Future<Map<String, dynamic>> getFinancialSummary() async {
    developer.log('LedgerService: Getting financial summary');
    
    try {
      // Get current balance
      final currentBalance = await _getCurrentBalance();
      
      // Get total credits
      final creditsSnapshot = await _firestore
          .collection('platform_ledger')
          .where('type', isEqualTo: 'credit')
          .get();
      
      double totalCredits = 0;
      for (var doc in creditsSnapshot.docs) {
        final entry = LedgerModel.fromMap(doc.data());
        totalCredits += entry.amount;
      }
      
      // Get total debits
      final debitsSnapshot = await _firestore
          .collection('platform_ledger')
          .where('type', isEqualTo: 'debit')
          .get();
      
      double totalDebits = 0;
      for (var doc in debitsSnapshot.docs) {
        final entry = LedgerModel.fromMap(doc.data());
        totalDebits += entry.amount;
      }
      
      // Get this month's revenue
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final monthlySnapshot = await _firestore
          .collection('platform_ledger')
          .where('type', isEqualTo: 'credit')
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThanOrEqualTo: endOfMonth)
          .get();
      
      double monthlyRevenue = 0;
      for (var doc in monthlySnapshot.docs) {
        final entry = LedgerModel.fromMap(doc.data());
        monthlyRevenue += entry.amount;
      }
      
      final summary = {
        'currentBalance': currentBalance,
        'totalCredits': totalCredits,
        'totalDebits': totalDebits,
        'monthlyRevenue': monthlyRevenue,
        'netRevenue': totalCredits - totalDebits,
      };
      
      developer.log('LedgerService: Financial summary retrieved - $summary');
      return summary;
    } catch (e) {
      developer.log('LedgerService: Error getting financial summary - Error: $e');
      return {
        'currentBalance': 0.0,
        'totalCredits': 0.0,
        'totalDebits': 0.0,
        'monthlyRevenue': 0.0,
        'netRevenue': 0.0,
      };
    }
  }

  // Get teacher payout summary with logging
  Future<Map<String, dynamic>> getTeacherPayoutSummary(String teacherId) async {
    developer.log('LedgerService: Getting teacher payout summary - TeacherID: $teacherId');
    
    try {
      // Get teacher's debit entries (payouts)
      final payoutsSnapshot = await _firestore
          .collection('platform_ledger')
          .where('teacherId', isEqualTo: teacherId)
          .where('type', isEqualTo: 'debit')
          .get();
      
      double totalPayouts = 0;
      for (var doc in payoutsSnapshot.docs) {
        final entry = LedgerModel.fromMap(doc.data());
        totalPayouts += entry.amount;
      }
      
      // Get teacher's related bookings revenue
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('teacherId', isEqualTo: teacherId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      double totalRevenue = 0;
      for (var doc in bookingsSnapshot.docs) {
        final booking = doc.data();
        totalRevenue += booking['teacherPayout'] ?? 0;
      }
      
      final summary = {
        'teacherId': teacherId,
        'totalPayouts': totalPayouts,
        'totalRevenue': totalRevenue,
        'pendingPayouts': totalRevenue - totalPayouts,
      };
      
      developer.log('LedgerService: Teacher payout summary retrieved - $summary');
      return summary;
    } catch (e) {
      developer.log('LedgerService: Error getting teacher payout summary - Error: $e');
      return {
        'teacherId': teacherId,
        'totalPayouts': 0.0,
        'totalRevenue': 0.0,
        'pendingPayouts': 0.0,
      };
    }
  }

  // Generate unique ledger ID
  String _generateLedgerId() {
    return 'PLG${DateTime.now().millisecondsSinceEpoch}${(1000 + DateTime.now().millisecond % 1000)}';
  }
}