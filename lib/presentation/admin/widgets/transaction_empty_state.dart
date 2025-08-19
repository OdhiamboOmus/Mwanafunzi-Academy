import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Transaction empty state widget following Flutter Lite rules (<150 lines)
class TransactionEmptyState extends StatelessWidget {
  final String? message;

  const TransactionEmptyState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TransactionEmptyState: Building empty state');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No transactions found',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}