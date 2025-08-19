import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

// Booking action buttons widget with logging
class BookingActionButtons extends StatelessWidget {
  final String bookingId;
  final bool isActive;
  final String? zoomLink;
  final VoidCallback onMarkComplete;
  final VoidCallback onJoinZoom;

  const BookingActionButtons({
    super.key,
    required this.bookingId,
    required this.isActive,
    required this.zoomLink,
    required this.onMarkComplete,
    required this.onJoinZoom,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('BookingActionButtons: Building action buttons for booking $bookingId');
    
    return Row(
      children: [
        if (isActive)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                developer.log('BookingActionButtons: Mark lesson completed tapped for booking $bookingId');
                onMarkComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: const Text('Mark Lesson Complete'),
            ),
          ),
        if (isActive)
          const SizedBox(width: 8),
        if (zoomLink != null)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                developer.log('BookingActionButtons: Zoom link tapped for booking $bookingId');
                onJoinZoom();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.brandColor,
                side: BorderSide(color: AppConstants.brandColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: const Text('Join Zoom'),
            ),
          ),
      ],
    );
  }
}