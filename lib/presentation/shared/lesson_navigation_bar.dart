import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Lesson navigation bar following Flutter Lite rules (<150 lines)
class LessonNavigationBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComments;
  final bool canGoBack;

  const LessonNavigationBar({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onComments,
    this.canGoBack = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Previous button (smaller)
      if (canGoBack)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.small(
            onPressed: onPrevious,
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            elevation: 2,
            child: const Icon(Icons.chevron_left, size: 20),
          ),
        ),
      // Comments button (medium)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onComments();
          },
          backgroundColor: const Color(0xFF50E801),
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Text(
            'C',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Next button (larger, primary action)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: onNext,
          backgroundColor: const Color(0xFF50E801),
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.chevron_right, size: 24),
          label: const Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}
