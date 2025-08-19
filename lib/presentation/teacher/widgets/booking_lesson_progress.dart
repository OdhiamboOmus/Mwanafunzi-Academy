import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

// Booking lesson progress widget with logging
class BookingLessonProgress extends StatelessWidget {
  final int completedLessons;
  final int totalLessons;

  const BookingLessonProgress({
    super.key,
    required this.completedLessons,
    required this.totalLessons,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('BookingLessonProgress: Building progress - Completed: $completedLessons, Total: $totalLessons');
    
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Lesson Progress',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brandColor),
        ),
        const SizedBox(height: 4),
        Text(
          '$completedLessons of $totalLessons lessons completed',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}