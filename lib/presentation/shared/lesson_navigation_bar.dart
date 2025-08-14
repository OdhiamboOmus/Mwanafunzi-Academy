import 'package:flutter/material.dart';

// Lesson navigation bar following Flutter Lite rules (<150 lines)
class LessonNavigationBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoBack;

  const LessonNavigationBar({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.canGoBack = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF6366F1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Row(
        children: [
          // Previous button
          Expanded(
            flex: 1,
            child: canGoBack
                ? TextButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF50E801),
                      size: 20,
                    ),
                    label: const Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF50E801),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 16),

          // Next button
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF50E801).withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
