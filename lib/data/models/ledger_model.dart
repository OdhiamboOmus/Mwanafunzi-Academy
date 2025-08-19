import 'dart:developer' as developer;

// Platform ledger model for immutable financial tracking
class LedgerModel {
  final String id;
  final String transactionId;
  final String type; // "credit" | "debit"
  final double amount;
  final double balance;
  final String description;
  final String? teacherId;
  final DateTime createdAt;

  const LedgerModel({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.balance,
    required this.description,
    this.teacherId,
    required this.createdAt,
  });

  // Create from map (Firestore document)
  factory LedgerModel.fromMap(Map<String, dynamic> map) {
    developer.log('LedgerModel: Creating from map for ledger ${map['id']}');
    return LedgerModel(
      id: map['id'] ?? '',
      transactionId: map['transactionId'] ?? '',
      type: map['type'] ?? 'credit',
      amount: (map['amount'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      teacherId: map['teacherId'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to map (Firestore document)
  Map<String, dynamic> toMap() {
    developer.log('LedgerModel: Converting to map for ledger $id');
    return {
      'id': id,
      'transactionId': transactionId,
      'type': type,
      'amount': amount,
      'balance': balance,
      'description': description,
      'teacherId': teacherId,
      'createdAt': createdAt,
    };
  }

  // Check if this is a credit entry
  bool get isCredit => type == 'credit';
  
  // Check if this is a debit entry
  bool get isDebit => type == 'debit';
  
  // Get formatted amount with type indicator
  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '${sign}Ksh ${amount.toStringAsFixed(2)}';
  }
  
  // Get formatted balance
  String get formattedBalance => 'Ksh ${balance.toStringAsFixed(2)}';
  
  // Get type display text
  String get typeText {
    switch (type) {
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      default:
        return 'Unknown';
    }
  }
}