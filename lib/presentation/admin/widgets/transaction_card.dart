import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../../data/models/transaction_model.dart';

// Transaction card widget following Flutter Lite rules (<150 lines)
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TransactionCard: Building card for transaction ${transaction.id}');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildTransactionIcon(transaction.type),
        title: Text(transaction.typeText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction.id}'),
            Text('Amount: ${transaction.displayAmount}'),
            Text('Date: ${transaction.displayDateTime}'),
          ],
        ),
        trailing: _buildStatusChip(transaction.status),
        onTap: () {
          developer.log('TransactionCard: Transaction ${transaction.id} tapped');
          onTap?.call();
        },
      ),
    );
  }

  Widget _buildTransactionIcon(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'payment':
        icon = Icons.payment;
        color = Colors.green;
        break;
      case 'payout':
        icon = Icons.money_off;
        color = Colors.blue;
        break;
      case 'refund':
        icon = Icons.money_off;
        color = Colors.orange;
        break;
      default:
        icon = Icons.receipt;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'failed':
        color = Colors.red;
        text = 'Failed';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }
}