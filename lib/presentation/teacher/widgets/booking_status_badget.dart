import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Booking status badge widget with logging
class BookingStatusBadge extends StatelessWidget {
  final String status;

  const BookingStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('BookingStatusBadge: Building badge for status: $status');
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Paid';
        break;
      case 'active':
        statusColor = Colors.blue;
        statusText = 'Active';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}