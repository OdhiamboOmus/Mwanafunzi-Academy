import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Payout retry card widget with comprehensive debugPrint logging
class PayoutRetryCard extends StatelessWidget {
  final Map<String, dynamic> retry;

  const PayoutRetryCard({
    super.key,
    required this.retry,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('PayoutRetryCard: Building retry card - RetryID: ${retry['id']}');
    
    final status = retry['status'] ?? 'unknown';
    final attempts = retry['attempts'] ?? 0;
    final maxAttempts = retry['maxAttempts'] ?? 0;
    final scheduledAt = retry['scheduledAt']?.toDate();
    final retryAt = retry['retryAt']?.toDate();

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.refresh,
          color: _getStatusColor(),
        ),
        title: Text(
          'Retry #$attempts/$maxAttempts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: KES ${_formatAmount(retry['amount'])}'),
            if (scheduledAt != null)
              Text(
                'Scheduled: ${_formatDateTime(scheduledAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (retryAt != null)
              Text(
                'Retry at: ${_formatDateTime(retryAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get status color with logging
  Color _getStatusColor() {
    developer.log('PayoutRetryCard: Determining status color - Status: ${retry['status']}');
    
    switch (retry['status']) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Format amount with logging
  String _formatAmount(dynamic amount) {
    developer.log('PayoutRetryCard: Formatting amount - Amount: $amount');
    
    if (amount == null) return '0.00';
    return amount.toDouble().toStringAsFixed(2);
  }

  // Format date time with logging
  String _formatDateTime(DateTime? dateTime) {
    developer.log('PayoutRetryCard: Formatting date time - DateTime: $dateTime');
    
    if (dateTime == null) return '';
    return dateTime.toLocal().toString();
  }
}