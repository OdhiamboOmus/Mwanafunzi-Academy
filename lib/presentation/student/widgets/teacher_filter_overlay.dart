import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'filter_section_widget.dart';

class TeacherFilterOverlay extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final String selectedSubject;
  final String selectedClassSize;
  final String selectedTime;
  final Function(String) onSubjectChanged;
  final Function(String) onClassSizeChanged;
  final Function(String) onTimeChanged;
  final VoidCallback onClose;

  const TeacherFilterOverlay({
    super.key,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.selectedSubject,
    required this.selectedClassSize,
    required this.selectedTime,
    required this.onSubjectChanged,
    required this.onClassSizeChanged,
    required this.onTimeChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      AnimatedBuilder(
        animation: fadeAnimation,
        builder: (context, child) => Container(
          color: Colors.black.withValues(alpha: fadeAnimation.value),
          child: GestureDetector(onTap: onClose, child: Container()),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SlideTransition(
          position: slideAnimation,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Teachers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF6B7280),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      FilterSectionWidget(
                        title: 'Subject',
                        options: const [
                          'All Subjects',
                          'Mathematics',
                          'English',
                        ],
                        selectedValue: selectedSubject,
                        onChanged: onSubjectChanged,
                      ),
                      const SizedBox(height: 24),
                      FilterSectionWidget(
                        title: 'Class Size & Pricing',
                        options: const [
                          '1 Student\nKSH 4,000',
                          '3 Students\nKSH 3,000',
                          '5 Students\nKSH 2,000',
                        ],
                        selectedValue: selectedClassSize,
                        onChanged: onClassSizeChanged,
                      ),
                      const SizedBox(height: 24),
                      FilterSectionWidget(
                        title: 'Preferred Time',
                        options: const [
                          'Morning (8AM - 12PM)',
                          'Afternoon (12PM - 4PM)',
                          'Evening (4PM - 8PM)',
                          'Weekend (Flexible)',
                        ],
                        selectedValue: selectedTime,
                        onChanged: onTimeChanged,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onClose();
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
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
