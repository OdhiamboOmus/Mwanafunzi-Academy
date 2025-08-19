import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

// Teacher welcome section widget with dashboard access logging
class TeacherWelcomeSection extends StatelessWidget {
  final String teacherName;
  final String subject;

  const TeacherWelcomeSection({
    super.key,
    required this.teacherName,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherWelcomeSection: Building welcome section for teacher $teacherName');
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppConstants.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $teacherName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$subject - Manage your classes and students',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}