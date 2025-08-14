import 'package:flutter/material.dart';

class QuizProgressBar extends StatelessWidget {
  final Animation<double> animation;

  const QuizProgressBar({super.key, required this.animation});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) => LinearProgressIndicator(
        value: animation.value,
        backgroundColor: const Color(0xFFE5E7EB),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF50E801)),
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
