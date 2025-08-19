import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../data/models/booking_model.dart';
import 'booking_card_widget.dart';

// Teacher bookings section widget with interaction logging
class TeacherBookingsSection extends StatelessWidget {
  final List<BookingModel> activeBookings;
  final Function(String) onLessonCompleted;
  final VoidCallback onViewAll;

  const TeacherBookingsSection({
    super.key,
    required this.activeBookings,
    required this.onLessonCompleted,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherBookingsSection: Building bookings section with ${activeBookings.length} bookings');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Bookings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (activeBookings.isEmpty)
          _buildEmptyState()
        else
          _buildBookingsList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No active bookings at the moment',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activeBookings.take(3).map((booking) {
          developer.log('TeacherBookingsSection: Building booking card for booking ${booking.id}');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BookingCardWidget(
              booking: booking,
              onLessonCompleted: onLessonCompleted,
            ),
          );
        }),
        if (activeBookings.length > 3)
          _buildViewAllButton(),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return TextButton(
      onPressed: () {
        developer.log('TeacherBookingsSection: View all bookings tapped');
        onViewAll();
      },
      child: Text('View all ${activeBookings.length} bookings'),
    );
  }
}