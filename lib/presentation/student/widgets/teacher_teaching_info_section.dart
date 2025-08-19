import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/teacher_model.dart';

/// Teacher teaching information section widget
class TeacherTeachingInfoSection extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherTeachingInfoSection({
    super.key,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherTeachingInfoSection: Building for ${teacher.fullName}');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teaching Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Area of Operation',
              value: teacher.areaOfOperation,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time,
              title: 'Availability',
              value: teacher.availability,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.schedule,
              title: 'Available Times',
              value: teacher.availableTimes.join(', '),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.star,
              title: 'Experience',
              value: '${teacher.completedLessons} lessons completed',
            ),
          ],
        ),
      ),
    );
  }

  // Build information row with icon
  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}