import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'widgets/transaction_list_widget.dart';

// Financial overview tab following Flutter Lite rules (<150 lines)
class FinancialOverviewTab extends StatelessWidget {
  const FinancialOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('FinancialOverviewTab: Building financial overview');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Financial Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildFinancialSummary(),
          const SizedBox(height: 24),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: TransactionListWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Total Platform Revenue', 'KES 2,450,000', Colors.green),
          const SizedBox(height: 8),
          _buildSummaryRow('Pending Payouts', 'KES 850,000', Colors.orange),
          const SizedBox(height: 8),
          _buildSummaryRow('This Month Revenue', 'KES 450,000', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}