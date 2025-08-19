import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/teacher_model.dart';

/// Teacher availability and pricing section widget
class TeacherAvailabilitySection extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherAvailabilitySection({
    super.key,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherAvailabilitySection: Building for ${teacher.fullName}');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing & Availability',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Rate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'KSH ${teacher.price.toStringAsFixed(0)}/week',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF50E801),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Currently Available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  teacher.isAvailable ? 'Yes' : 'No',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: teacher.isAvailable ? const Color(0xFF50E801) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}