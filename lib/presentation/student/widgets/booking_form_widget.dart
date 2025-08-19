import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../core/constants.dart';

/// Booking form widget with week selection and cost calculation with calculation logging
class BookingFormWidget extends StatefulWidget {
  final int selectedWeeks;
  final String selectedDay;
  final String selectedTime;
  final DateTime startDate;
  final double totalAmount;
  final Function(int) onWeeksChanged;
  final Function(String) onDayChanged;
  final Function(String) onTimeChanged;

  const BookingFormWidget({
    super.key,
    required this.selectedWeeks,
    required this.selectedDay,
    required this.selectedTime,
    required this.startDate,
    required this.totalAmount,
    required this.onWeeksChanged,
    required this.onDayChanged,
    required this.onTimeChanged,
  });

  @override
  State<BookingFormWidget> createState() => _BookingFormWidgetState();
}

class _BookingFormWidgetState extends State<BookingFormWidget> {
  late int _currentWeeks;
  late String _currentDay;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    developer.log('BookingFormWidget: Initializing with selectedWeeks: ${widget.selectedWeeks}');
    _currentWeeks = widget.selectedWeeks;
    _currentDay = widget.selectedDay;
    _currentTime = widget.selectedTime;
  }

  @override
  void didUpdateWidget(BookingFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeeks != widget.selectedWeeks) {
      developer.log('BookingFormWidget: Weeks updated from ${oldWidget.selectedWeeks} to ${widget.selectedWeeks}');
      setState(() {
        _currentWeeks = widget.selectedWeeks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('BookingFormWidget: Building form widget');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          // Week Selection
          _buildWeekSelection(),
          
          const SizedBox(height: 20),
          
          // Day Selection
          _buildDaySelection(),
          
          const SizedBox(height: 20),
          
          // Time Selection
          _buildTimeSelection(),
          
          const SizedBox(height: 20),
          
          // Start Date Display
          _buildStartDateDisplay(),
        ],
      ),
    );
  }

  // Build week selection widget
  Widget _buildWeekSelection() {
    developer.log('BookingFormWidget: Building week selection widget');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Weeks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildWeekOption(2),
            const SizedBox(width: 8),
            _buildWeekOption(4),
            const SizedBox(width: 8),
            _buildWeekOption(8),
            const SizedBox(width: 8),
            _buildWeekOption(12),
          ],
        ),
      ],
    );
  }

  // Build week option button
  Widget _buildWeekOption(int weeks) {
    final isSelected = _currentWeeks == weeks;
    final cost = weeks * 1500; // Assuming weekly rate of 1500 for calculation
    
    developer.log('BookingFormWidget: Building week option - Weeks: $weeks, IsSelected: $isSelected');
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          developer.log('BookingFormWidget: Week option tapped - Weeks: $weeks');
          setState(() {
            _currentWeeks = weeks;
          });
          widget.onWeeksChanged(weeks);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF50E801) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$weeks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'weeks',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ksh $cost',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white70 : Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build day selection widget
  Widget _buildDaySelection() {
    developer.log('BookingFormWidget: Building day selection widget');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Day of Week',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.weekDays.map((day) {
            final isSelected = _currentDay == day;
            
            return GestureDetector(
              onTap: () {
                developer.log('BookingFormWidget: Day option tapped - Day: $day');
                setState(() {
                  _currentDay = day;
                });
                widget.onDayChanged(day);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF50E801) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  day.substring(0, 3), // Show first 3 letters
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build time selection widget
  Widget _buildTimeSelection() {
    developer.log('BookingFormWidget: Building time selection widget');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time of Day',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
            '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'
          ].map((time) {
            final isSelected = _currentTime == time;
            
            return GestureDetector(
              onTap: () {
                developer.log('BookingFormWidget: Time option tapped - Time: $time');
                setState(() {
                  _currentTime = time;
                });
                widget.onTimeChanged(time);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF50E801) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build start date display widget
  Widget _buildStartDateDisplay() {
    developer.log('BookingFormWidget: Building start date display widget');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: Color(0xFF50E801),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'First Session',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year} at ${widget.selectedTime}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}