import 'package:flutter/material.dart';

// Lesson content card following Flutter Lite rules (<150 lines)
class LessonContentCard extends StatelessWidget {
  final String lessonTitle;
  final String subject;
  final String lessonContent;

  const LessonContentCard({
    super.key,
    required this.lessonTitle,
    required this.subject,
    required this.lessonContent,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // Add this to allow shrink-wrapping
      children: [
        // Subject badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF50E801).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF50E801).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFF50E801), size: 16),
              const SizedBox(width: 4),
              Text(
                subject.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF50E801),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Lesson title
        Text(
          lessonTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Content area
        Flexible(
          fit: FlexFit.loose, // Use Flexible instead of Expanded with loose fit
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildLessonContent(lessonContent),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLessonContent(String content) {
    // Split content by lines and format each section
    final lines = content.split('\n');
    final widgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      if (line.startsWith('What are fractions?') ||
          line.startsWith('Numerator and Denominator') ||
          line.startsWith('Equivalent Fractions')) {
        // Section title
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
        );
      } else if (line.startsWith('A fraction represents') ||
                 line.startsWith('In a fraction like') ||
                 line.startsWith('Equivalent fractions are')) {
        // Section content
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (line.startsWith('Which fraction represents') ||
                 line.startsWith('In the fraction') ||
                 line.startsWith('Which of the following')) {
        // Question
        widgets.add(
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
