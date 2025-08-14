import 'package:flutter/material.dart';

class SubjectIndicatorWidget extends StatelessWidget {
  final String subject;
  final bool isActive;

  const SubjectIndicatorWidget({
    super.key,
    required this.subject,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: isActive ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        subject,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    ),
  );
}
