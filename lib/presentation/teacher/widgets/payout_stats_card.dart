import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Payout statistics card widget with comprehensive debugPrint logging
class PayoutStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const PayoutStatsCard({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log('PayoutStatsCard: Building stats card');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retry Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            SizedBox(height: 16),
            _buildStatsRow('Total Retries', '${stats['totalRetries'] ?? 0}', Colors.purple),
            SizedBox(height: 8),
            _buildStatsRow('Success Rate', '${stats['successRate'] ?? '0.0'}%', _getSuccessRateColor()),
          ],
        ),
      ),
    );
  }

  // Build statistics row with logging
  Widget _buildStatsRow(String label, String value, Color color) {
    developer.log('PayoutStatsCard: Building stats row - Label: $label, Value: $value');
    
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

  // Get success rate color with logging
  Color _getSuccessRateColor() {
    developer.log('PayoutStatsCard: Determining success rate color');
    
    final successRate = double.tryParse(stats['successRate']?.toString() ?? '0.0') ?? 0.0;
    return successRate >= 80 ? Colors.green : Colors.orange;
  }
}