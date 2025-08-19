import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Teacher book button widget with comprehensive logging
class TeacherBookButton extends StatelessWidget {
  final String teacherName;
  final VoidCallback? onPressed;

  const TeacherBookButton({
    super.key,
    required this.teacherName,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherBookButton: Building for teacher: $teacherName');
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          developer.log('TeacherBookButton: Book button tapped for teacher: $teacherName');
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF50E801),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Book This Teacher',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}