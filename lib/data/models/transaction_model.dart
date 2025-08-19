import 'dart:developer' as developer;

// Transaction model for payment tracking
class TransactionModel {
  final String id;
  final String type; // "payment" | "payout" | "refund"
  
  // Payment details
  final String? bookingId;
  final String? teacherId; // For payouts
  final String? parentId; // For payments
  final double amount;
  
  // M-Pesa details
  final String mpesaTransactionId;
  final String mpesaReceiptNumber;
  final String phoneNumber;
  
  // Status
  final String status; // "pending" | "completed" | "failed"
  final Map<String, dynamic>? providerResponse;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? processedAt;

  const TransactionModel({
    required this.id,
    required this.type,
    this.bookingId,
    this.teacherId,
    this.parentId,
    required this.amount,
    required this.mpesaTransactionId,
    required this.mpesaReceiptNumber,
    required this.phoneNumber,
    required this.status,
    this.providerResponse,
    required this.createdAt,
    this.processedAt,
  });

  // Create from map (Firestore document)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    developer.log('TransactionModel: Creating from map for transaction ${map['id']}');
    return TransactionModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      bookingId: map['bookingId'],
      teacherId: map['teacherId'],
      parentId: map['parentId'],
      amount: (map['amount'] ?? 0).toDouble(),
      mpesaTransactionId: map['mpesaTransactionId'] ?? '',
      mpesaReceiptNumber: map['mpesaReceiptNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      status: map['status'] ?? 'pending',
      providerResponse: map['providerResponse'] as Map<String, dynamic>?,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      processedAt: map['processedAt']?.toDate(),
    );
  }

  // Convert to map (Firestore document)
  Map<String, dynamic> toMap() {
    developer.log('TransactionModel: Converting to map for transaction $id');
    return {
      'id': id,
      'type': type,
      'bookingId': bookingId,
      'teacherId': teacherId,
      'parentId': parentId,
      'amount': amount,
      'mpesaTransactionId': mpesaTransactionId,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'phoneNumber': phoneNumber,
      'status': status,
      'providerResponse': providerResponse,
      'createdAt': createdAt,
      'processedAt': processedAt,
    };
  }

  // Copy with method for immutability
  TransactionModel copyWith({
    String? id,
    String? type,
    String? bookingId,
    String? teacherId,
    String? parentId,
    double? amount,
    String? mpesaTransactionId,
    String? mpesaReceiptNumber,
    String? phoneNumber,
    String? status,
    Map<String, dynamic>? providerResponse,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    developer.log('TransactionModel: Copying with changes for transaction $id');
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      teacherId: teacherId ?? this.teacherId,
      parentId: parentId ?? this.parentId,
      amount: amount ?? this.amount,
      mpesaTransactionId: mpesaTransactionId ?? this.mpesaTransactionId,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      providerResponse: providerResponse ?? this.providerResponse,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  // Check if transaction is completed
  bool get isCompleted => status == 'completed';
  
  // Check if transaction is pending
  bool get isPending => status == 'pending';
  
  // Check if transaction is failed
  bool get isFailed => status == 'failed';
  
  // Get status display text
  String get statusText {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }
  
  // Get type display text
  String get typeText {
    switch (type) {
      case 'payment':
        return 'Payment';
      case 'payout':
        return 'Payout';
      case 'refund':
        return 'Refund';
      default:
        return type;
    }
  }
  
  // Check if transaction is a payment
  bool get isPayment => type == 'payment';
  
  // Check if transaction is a payout
  bool get isPayout => type == 'payout';
  
  // Check if transaction is a refund
  bool get isRefund => type == 'refund';
  
  // Get display amount
  String get displayAmount {
    return 'KES ${amount.toStringAsFixed(2)}';
  }
  
  // Get display date
  String get displayDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
  
  // Get display time
  String get displayTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
  
  // Get display date and time
  String get displayDateTime {
    return '$displayDate at $displayTime';
  }
}