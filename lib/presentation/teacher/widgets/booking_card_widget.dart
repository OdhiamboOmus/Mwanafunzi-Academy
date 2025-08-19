import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../data/models/booking_model.dart';
import '../../../core/constants.dart';
import 'booking_status_badget.dart';
import 'booking_schedule_info.dart';
import 'booking_lesson_progress.dart';
import 'booking_action_buttons.dart';

// Booking card widget showing student details and lesson information with interaction logging
class BookingCardWidget extends StatelessWidget {
  final BookingModel booking;
  final Function(String) onLessonCompleted;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.onLessonCompleted,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('BookingCardWidget: Building card for booking ${booking.id}');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student and Subject Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: ${booking.studentId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subject: ${booking.subject}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                BookingStatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Schedule Info
            BookingScheduleInfo(
              dayOfWeek: booking.dayOfWeek,
              startTime: booking.startTime,
              numberOfWeeks: booking.numberOfWeeks,
            ),
            const SizedBox(height: 16),
            
            // Lesson Progress
            BookingLessonProgress(
              completedLessons: 3, // Placeholder - would come from actual data
              totalLessons: booking.numberOfWeeks,
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            BookingActionButtons(
              bookingId: booking.id,
              isActive: booking.isActive,
              zoomLink: booking.zoomLink,
              onMarkComplete: () => _showLessonCompletionDialog(context),
              onJoinZoom: () => _launchZoomLink(context),
            ),
          ],
        ),
      ),
    );
  }

  // Show lesson completion dialog with logging
  void _showLessonCompletionDialog(BuildContext context) {
    developer.log('BookingCardWidget: Showing lesson completion dialog for booking ${booking.id}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Lesson Complete'),
        content: const Text('Are you sure you want to mark this lesson as completed?'),
        actions: [
          TextButton(
            onPressed: () {
              developer.log('BookingCardWidget: Lesson completion dialog cancelled for booking ${booking.id}');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              developer.log('BookingCardWidget: Lesson confirmed completed for booking ${booking.id}');
              Navigator.pop(context);
              onLessonCompleted('lesson_${booking.id}_${DateTime.now().millisecondsSinceEpoch}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  // Launch Zoom link with logging
  void _launchZoomLink(BuildContext context) {
    developer.log('BookingCardWidget: Launching Zoom link for booking ${booking.id}');
    
    // In a real app, this would use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Zoom: ${booking.zoomLink}'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Launch URL logic here
          },
        ),
      ),
    );
  }
}