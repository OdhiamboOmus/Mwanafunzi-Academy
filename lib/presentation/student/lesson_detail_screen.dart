import 'package:flutter/material.dart';
import '../shared/lesson_header_card.dart';
import '../shared/lesson_list_widget.dart';
import '../../services/firebase/student_lesson_service.dart';

// Lesson detail screen following Flutter Lite rules (<150 lines)
class LessonDetailScreen extends StatefulWidget {
  final String subject;
  final String grade;
  final IconData icon;
  final double progress;
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.subject,
    required this.grade,
    required this.icon,
    required this.progress,
    required this.lessonId,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final StudentLessonService _lessonService = StudentLessonService();
  bool _isLoading = true;
  List<LessonData> _lessons = [];
  List<Map<String, dynamic>> _firebaseLessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadFirebaseLesson();
  }

  Future<void> _loadFirebaseLesson() async {
    try {
      debugPrint('🔍 DEBUG: Loading Firebase lesson for: ${widget.lessonId}');
      final lessonContent = await _lessonService.getLessonContent(widget.grade, widget.lessonId);
      
      if (lessonContent != null && mounted) {
        setState(() {
          _firebaseLessons.add(lessonContent);
          debugPrint('🔍 DEBUG: Loaded Firebase lesson: ${lessonContent['title']}');
        });
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to load Firebase lesson: $e');
    }
  }

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
        widget.subject,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Header Card
                LessonHeaderCard(
                  subject: widget.subject,
                  grade: widget.grade,
                  icon: widget.icon,
                  progress: widget.progress,
                  lessonCount: _lessons.length,
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
                _lessons.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No lessons available for this grade.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : LessonListWidget(lessons: _lessons),

                const SizedBox(height: 32),
              ],
            ),
          ),
  );

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch lessons from Firebase
      final firebaseLessons = await _lessonService.getLessonsForGrade(widget.grade);
      
      if (mounted) {
        setState(() {
          _firebaseLessons = firebaseLessons;
          _lessons = _convertFirebaseLessonsToLessonData(firebaseLessons);
          _isLoading = false;
        });

        debugPrint('🔍 DEBUG: Loaded ${_lessons.length} lessons for grade ${widget.grade}');
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to load lessons: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lessons = _getFallbackLessons();
        });
      }
    }
  }

  List<LessonData> _convertFirebaseLessonsToLessonData(List<Map<String, dynamic>> firebaseLessons) {
    return firebaseLessons.map((lesson) {
      return LessonData(
        title: lesson['title'] ?? 'Untitled Lesson',
        description: lesson['subject'] ?? 'No description available',
        duration: _calculateDuration(lesson),
        steps: _calculateSteps(lesson),
        lessonId: lesson['id'],
        subject: lesson['subject'],
      );
    }).toList();
  }

  String _calculateDuration(Map<String, dynamic> lesson) {
    // Estimate duration based on number of sections
    final sections = lesson['totalSections'] ?? 1;
    final minutesPerSection = 5; // 5 minutes per section
    final totalMinutes = sections * minutesPerSection;
    
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return hours > 1 ? '$hours hours $minutes min' : '$hours hour $minutes min';
    }
  }

  int _calculateSteps(Map<String, dynamic> lesson) {
    // Use number of sections as steps
    return lesson['totalSections'] ?? 5;
  }

  List<LessonData> _getFallbackLessons() {
    // Fallback lessons in case Firebase is unavailable
    return [
      const LessonData(
        title: 'Loading Lessons...',
        description: 'Please wait while we fetch your lessons',
        duration: '',
        steps: 0,
      ),
    ];
  }
}

class LessonData {
  final String title;
  final String description;
  final String duration;
  final int steps;
  final String? lessonId;
  final String? subject;

  const LessonData({
    required this.title,
    required this.description,
    required this.duration,
    required this.steps,
    this.lessonId,
    this.subject,
  });
}
