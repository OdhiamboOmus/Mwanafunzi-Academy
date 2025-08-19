import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Availability selector widget following Flutter Lite rules (<150 lines)
class AvailabilitySelector extends StatefulWidget {
  final List<String> selectedTimes;
  final Function(List<String>) onTimesChanged;
  
  const AvailabilitySelector({
    super.key,
    required this.selectedTimes,
    required this.onTimesChanged,
  });

  @override
  State<AvailabilitySelector> createState() => _AvailabilitySelectorState();
}

class _AvailabilitySelectorState extends State<AvailabilitySelector> {
  final List<String> _availableTimes = [
    'Morning',
    'Afternoon', 
    'Evening',
    'Weekend',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Select Available Times',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTimes.map((time) {
              final isSelected = widget.selectedTimes.contains(time);
              return _buildTimeChip(time, isSelected);
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          _buildSelectionInfo(),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String time, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          final updatedTimes = List<String>.from(widget.selectedTimes);
          
          if (updatedTimes.contains(time)) {
            updatedTimes.remove(time);
            developer.log('AvailabilitySelector: Removed $time from selection');
          } else {
            updatedTimes.add(time);
            developer.log('AvailabilitySelector: Added $time to selection');
          }
          
          widget.onTimesChanged(updatedTimes);
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Colors.blue : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            const SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionInfo() {
    final selectedCount = widget.selectedTimes.length;
    final totalCount = _availableTimes.length;
    
    return Row(
      children: [
        Icon(
          Icons.info,
          color: Colors.grey[600],
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '$selectedCount of $totalCount time slots selected',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }


  void _toggleTimeSelection(String time) {
    developer.log('AvailabilitySelector: Toggling time selection for $time');
    
    setState(() {
      final updatedTimes = List<String>.from(widget.selectedTimes);
      
      if (updatedTimes.contains(time)) {
        updatedTimes.remove(time);
        developer.log('AvailabilitySelector: Removed $time from selection');
      } else {
        updatedTimes.add(time);
        developer.log('AvailabilitySelector: Added $time to selection');
      }
      
      widget.onTimesChanged(updatedTimes);
    });
  }
}