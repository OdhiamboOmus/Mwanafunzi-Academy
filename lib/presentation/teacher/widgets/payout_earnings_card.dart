import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Payout earnings card widget with comprehensive debugPrint logging
class PayoutEarningsCard extends StatelessWidget {
  final Map<String, dynamic> earnings;

  const PayoutEarningsCard({
    super.key,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('PayoutEarningsCard: Building earnings card');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 16),
            _buildEarningsRow('Total Earnings', 'KES ${_formatAmount(earnings['totalEarnings'])}', Colors.green),
            SizedBox(height: 8),
            _buildEarningsRow('Pending Earnings', 'KES ${_formatAmount(earnings['pendingEarnings'])}', Colors.orange),
            SizedBox(height: 8),
            _buildEarningsRow('Total Payouts', '${earnings['totalPayouts'] ?? 0}', Colors.blue),
            SizedBox(height: 8),
            _buildEarningsRow('Pending Payouts', '${earnings['pendingPayoutsCount'] ?? 0}', Colors.red),
          ],
        ),
      ),
    );
  }

  // Build earnings row with logging
  Widget _buildEarningsRow(String label, String value, Color color) {
    developer.log('PayoutEarningsCard: Building earnings row - Label: $label, Value: $value');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Format amount with logging
  String _formatAmount(dynamic amount) {
    developer.log('PayoutEarningsCard: Formatting amount - Amount: $amount');
    
    if (amount == null) return '0.00';
    return amount.toDouble().toStringAsFixed(2);
  }
}