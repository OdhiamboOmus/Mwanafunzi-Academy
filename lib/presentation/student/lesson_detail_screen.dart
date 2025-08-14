import 'package:flutter/material.dart';
import '../shared/lesson_header_card.dart';
import '../shared/lesson_list_widget.dart';

// Lesson detail screen following Flutter Lite rules (<150 lines)
class LessonDetailScreen extends StatelessWidget {
  final String subject;
  final String grade;
  final IconData icon;
  final double progress;

  const LessonDetailScreen({
    super.key,
    required this.subject,
    required this.grade,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        subject,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Header Card
          LessonHeaderCard(
            subject: subject,
            grade: grade,
            icon: icon,
            progress: progress,
            lessonCount: _getLessons().length,
          ),

          // Lessons Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Lessons',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lessons List
          LessonListWidget(lessons: _getLessons()),

          const SizedBox(height: 32),
        ],
      ),
    ),
  );

  List<LessonData> _getLessons() => [
    const LessonData(
      title: 'Numbers 1-10',
      description: 'Learn to recognize, count, and write numbers from 1 to 10',
      duration: '15-20 min',
      steps: 5,
    ),
    const LessonData(
      title: 'Simple Addition',
      description: 'Learn to add numbers using objects and simple problems',
      duration: '20-25 min',
      steps: 6,
    ),
    const LessonData(
      title: 'Shapes Around Us',
      description: 'Identify and learn about basic shapes in everyday objects',
      duration: '18-22 min',
      steps: 4,
    ),
    const LessonData(
      title: 'Counting to 20',
      description: 'Extend counting skills from 11 to 20 with fun activities',
      duration: '16-20 min',
      steps: 5,
    ),
    const LessonData(
      title: 'Simple Subtraction',
      description: 'Learn basic subtraction using visual aids and practice',
      duration: '22-28 min',
      steps: 7,
    ),
  ];
}

class LessonData {
  final String title;
  final String description;
  final String duration;
  final int steps;

  const LessonData({
    required this.title,
    required this.description,
    required this.duration,
    required this.steps,
  });
}
