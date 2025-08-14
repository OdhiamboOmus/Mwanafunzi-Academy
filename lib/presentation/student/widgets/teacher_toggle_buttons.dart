import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeacherToggleButtons extends StatelessWidget {
  final bool isOnlineSelected;
  final Function(bool) onToggle;

  const TeacherToggleButtons({
    super.key,
    required this.isOnlineSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle(true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isOnlineSelected
                    ? const Color(0xFF50E801)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOnlineSelected
                      ? const Color(0xFF50E801)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    color: isOnlineSelected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online Classes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOnlineSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle(false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !isOnlineSelected
                    ? const Color(0xFF50E801)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isOnlineSelected
                      ? const Color(0xFF50E801)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home,
                    color: !isOnlineSelected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Home Tutoring',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !isOnlineSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
