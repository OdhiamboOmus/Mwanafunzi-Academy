import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Booking schedule info widget with logging
class BookingScheduleInfo extends StatelessWidget {
  final String dayOfWeek;
  final String startTime;
  final int numberOfWeeks;

  const BookingScheduleInfo({
    super.key,
    required this.dayOfWeek,
    required this.startTime,
    required this.numberOfWeeks,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('BookingScheduleInfo: Building schedule info - Day: $dayOfWeek, Time: $startTime, Weeks: $numberOfWeeks');
    
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$dayOfWeek at $startTime',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          '$numberOfWeeks weeks',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}