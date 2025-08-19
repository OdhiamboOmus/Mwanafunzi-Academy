import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/teacher_model.dart';

/// Teacher profile header widget showing basic information and verification status
class TeacherProfileHeader extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherProfileHeader({
    super.key,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherProfileHeader: Building header for ${teacher.fullName}');
    
    return Row(
      children: [
        // Profile image
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFF50E801),
          backgroundImage: teacher.profileImageUrl != null 
              ? NetworkImage(teacher.profileImageUrl!) 
              : null,
          child: teacher.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 48)
              : null,
        ),
        const SizedBox(width: 20),
        
        // Teacher info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      teacher.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (teacher.isVerified)
                    _buildVerificationBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${teacher.gender}, ${teacher.age} years old',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacher.subjects.join(', '),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build verification badge
  Widget _buildVerificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF50E801),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Verified',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}