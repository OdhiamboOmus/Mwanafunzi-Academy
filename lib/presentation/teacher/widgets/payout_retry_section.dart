import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'payout_retry_card.dart';

// Payout retry history section widget with comprehensive debugPrint logging
class PayoutRetrySection extends StatelessWidget {
  final List<Map<String, dynamic>>? retryHistory;

  const PayoutRetrySection({
    Key? key,
    required this.retryHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log('PayoutRetrySection: Building retry history section');
    
    if (retryHistory == null || retryHistory!.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retry History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            SizedBox(height: 16),
            _buildRetryList(),
          ],
        ),
      ),
    );
  }

  // Build retry list with logging
  Widget _buildRetryList() {
    developer.log('PayoutRetrySection: Building retry list with ${retryHistory!.length} items');
    
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: retryHistory!.length,
      itemBuilder: (context, index) {
        final retry = retryHistory![index];
        return PayoutRetryCard(retry: retry);
      },
    );
  }
}