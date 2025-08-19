import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';

// Payout transaction card widget with comprehensive debugPrint logging
class PayoutTransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const PayoutTransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('PayoutTransactionCard: Building transaction card - TransactionID: ${transaction.id}');
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          transaction.status == 'completed' ? Icons.check_circle : Icons.schedule,
          color: transaction.status == 'completed' ? Colors.green : Colors.orange,
        ),
        title: Text(
          transaction.typeText,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.displayAmount),
            Text(
              transaction.displayDateTime,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
            if (transaction.mpesaTransactionId.isNotEmpty)
              Text(
                'M-Pesa: ${transaction.mpesaTransactionId}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  // Get status color with logging
  Color _getStatusColor() {
    developer.log('PayoutTransactionCard: Determining status color - Status: ${transaction.status}');
    
    switch (transaction.status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}