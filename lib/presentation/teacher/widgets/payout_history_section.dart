import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import 'payout_transaction_card.dart';

// Payout history section widget with comprehensive debugPrint logging
class PayoutHistorySection extends StatelessWidget {
  final List<TransactionModel>? transactions;

  const PayoutHistorySection({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('PayoutHistorySection: Building payout history section');
    
    if (transactions == null || transactions!.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payout History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
                Text(
                  '${transactions!.length} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  // Build empty state with logging
  Widget _buildEmptyState() {
    developer.log('PayoutHistorySection: Building empty state');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No payout history available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Build transaction list with logging
  Widget _buildTransactionList() {
    developer.log('PayoutHistorySection: Building transaction list with ${transactions!.length} items');
    
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: transactions!.length,
      itemBuilder: (context, index) {
        final transaction = transactions![index];
        return PayoutTransactionCard(transaction: transaction);
      },
    );
  }
}