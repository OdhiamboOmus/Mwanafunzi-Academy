import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/lesson_content_card.dart';
import '../shared/section_comment_sheet.dart';
import 'package:mwanafunzi_academy/core/service_locator.dart';
import 'package:mwanafunzi_academy/services/comment_service.dart';
import '../../services/firebase/student_lesson_service.dart';

// Lesson content screen following Flutter Lite rules (<150 lines)
class LessonContentScreen extends StatefulWidget {
  final String lessonTitle;
  final String subject;
  final String lessonId;
  final String sectionId;
  final int currentStep;
  final int totalSteps;

  const LessonContentScreen({
    super.key,
    required this.lessonTitle,
    required this.subject,
    required this.lessonId,
    required this.sectionId,
    this.currentStep = 3,
    this.totalSteps = 5,
  });

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  final CommentService _commentService = ServiceLocator().commentService;
  final StudentLessonService _lessonService = StudentLessonService();
  int _commentCount = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _lessonContent;
  String _displayTitle = '';
  String _displayContent = '';

  @override
  void initState() {
    super.initState();
    _loadLessonContent();
    _loadCommentCount();
  }

  Future<void> _loadCommentCount() async {
    try {
      final count = await _commentService.getCommentCount(
        widget.lessonId,
        widget.sectionId,
      );
      setState(() {
        _commentCount = count;
      });
    } catch (e) {
      debugPrint('❌ Error loading comment count: $e');
    }
  }

  Future<void> _loadLessonContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Extract grade from lesson ID (assuming format like "math_grade5_lesson1")
      final gradeParts = widget.lessonId.split('_');
      String grade = gradeParts.length > 1 ? gradeParts[1] : '5';
      
      // Normalize grade format - remove "grade" prefix if present (e.g., "grade5" -> "5")
      grade = grade.replaceFirst('grade', '');
      
      debugPrint('🔍 DEBUG: Loading lesson content for: ${widget.lessonId}, grade: $grade');
      
      // Fetch lesson content from Firebase
      final lessonData = await _lessonService.getLessonContent(grade, widget.lessonId);
      
      if (lessonData != null && mounted) {
        setState(() {
          _lessonContent = lessonData;
          _displayTitle = lessonData['title'] ?? widget.lessonTitle;
          _displayContent = _extractContentFromSections(lessonData['sections'] ?? []);
          _isLoading = false;
        });
        
        debugPrint('🔍 DEBUG: Loaded lesson content: $_displayTitle');
      } else {
        setState(() {
          _displayTitle = widget.lessonTitle;
          _displayContent = 'Lesson content not available. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to load lesson content: $e');
      setState(() {
        _displayTitle = widget.lessonTitle;
        _displayContent = 'Failed to load lesson content. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  String _extractContentFromSections(List<dynamic> sections) {
    final content = <String>[];
    
    for (final section in sections) {
      if (section['type'] == 'content') {
        final title = section['title'] ?? '';
        final contentText = section['content'] ?? '';
        
        if (title.isNotEmpty) {
          content.add(title);
        }
        if (contentText.isNotEmpty) {
          content.add(contentText);
        }
      }
    }
    
    return content.join('\n\n');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${widget.currentStep} of ${widget.totalSteps}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        // Main content
        ListView(
          children: [
            const SizedBox(height: kToolbarHeight + 20), // Space for app bar
            LessonContentCard(
              lessonTitle: _displayTitle,
              subject: widget.subject,
              lessonContent: _displayContent,
            ),
            const SizedBox(height: 80), // Space for smaller buttons
          ],
        ),
        // Floating action buttons at the bottom
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous button - smaller
              if (widget.currentStep > 1)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goToPrevious,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.chevron_left, size: 20, color: Colors.black),
                    ),
                  ),
                ),
              // Comments button - smaller text button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showComments,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF50E801),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Next button - smaller
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _goToNext,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF50E801),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_right, size: 20, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _goToPrevious() {
    HapticFeedback.lightImpact();
    // Navigate to previous step
  }

  void _goToNext() {
    HapticFeedback.lightImpact();
    // Navigate to next step
  }

  void _showComments() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SectionCommentSheet(
        lessonId: widget.lessonId,
        sectionId: widget.sectionId,
        onCommentPosted: _loadCommentCount,
      ),
    );
  }
}
