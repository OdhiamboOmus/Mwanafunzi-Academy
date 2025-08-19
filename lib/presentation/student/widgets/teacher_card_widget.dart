import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/teacher_model.dart';

/// Teacher card widget displaying verification badges and teacher information
/// with comprehensive interaction logging for debugging and analytics.
class TeacherCardWidget extends StatelessWidget {
  final TeacherModel teacher;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const TeacherCardWidget({
    super.key,
    required this.teacher,
    required this.index,
    this.onTap,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherCardWidget: Building card for teacher ${teacher.fullName} at position $index');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          developer.log('TeacherCardWidget: Teacher card tapped for ${teacher.fullName}');
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher header with image and name
              _buildTeacherHeader(),
              
              const SizedBox(height: 12),
              
              // Teacher details
              _buildTeacherDetails(),
              
              const SizedBox(height: 12),
              
              // Price and book button
              _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build teacher header with profile image and name
  Widget _buildTeacherHeader() {
    return Row(
      children: [
        // Profile image
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF50E801),
          backgroundImage: teacher.profileImageUrl != null 
              ? NetworkImage(teacher.profileImageUrl!) 
              : null,
          child: teacher.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 24)
              : null,
        ),
        const SizedBox(width: 12),
        
        // Teacher info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    teacher.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Verification badge
                  if (teacher.isVerified)
                    _buildVerificationBadge(),
                ],
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

  /// Build verification badge
  Widget _buildVerificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF50E801),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Verified',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build teacher details section
  Widget _buildTeacherDetails() {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.location_on,
          text: teacher.areaOfOperation,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.access_time,
          text: teacher.availability,
        ),
        if (teacher.availableTimes.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.schedule,
            text: teacher.availableTimes.join(', '),
          ),
        ],
      ],
    );
  }

  /// Build detail row with icon and text
  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build action row with price and book button
  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'KSH ${teacher.price.toStringAsFixed(0)}/week',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF50E801),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            developer.log('TeacherCardWidget: Book button tapped for ${teacher.fullName}');
            onBook?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF50E801),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Book',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}