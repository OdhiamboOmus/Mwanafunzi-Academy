import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/teacher_model.dart';

/// Teacher verification status section widget
class TeacherVerificationSection extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherVerificationSection({
    super.key,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherVerificationSection: Building for ${teacher.fullName}');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  teacher.isVerified ? Icons.verified : Icons.pending,
                  color: teacher.isVerified ? const Color(0xFF50E801) : const Color(0xFF6B7280),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              teacher.verificationStatusText,
              style: TextStyle(
                fontSize: 14,
                color: teacher.isVerified ? const Color(0xFF50E801) : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (teacher.tscCertificateUrl != null) ...[
              const SizedBox(height: 12),
              Text(
                'TSC Certificate Available',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}