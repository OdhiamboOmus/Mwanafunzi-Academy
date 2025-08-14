import 'package:flutter/material.dart';

class QuizAnswerOption extends StatelessWidget {
  final int index;
  final String option;
  final bool isSelected;
  final bool showResult;
  final bool isCorrect;
  final VoidCallback? onTap;

  const QuizAnswerOption({
    super.key,
    required this.index,
    required this.option,
    required this.isSelected,
    required this.showResult,
    required this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFFE5E7EB);
    Color backgroundColor = Colors.white;
    Color textColor = Colors.black;
    Widget? trailingIcon;

    if (showResult) {
      if (isCorrect) {
        borderColor = const Color(0xFF50E801);
        backgroundColor = const Color(0xFF50E801).withValues(alpha: 0.1);
        textColor = const Color(0xFF50E801);
        trailingIcon = Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF50E801),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        trailingIcon = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        );
      }
    } else if (isSelected) {
      borderColor = const Color(0xFF50E801);
      backgroundColor = const Color(0xFF50E801).withValues(alpha: 0.1);
      textColor = const Color(0xFF50E801);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null) trailingIcon,
            ],
          ),
        ),
      ),
    );
  }
}
