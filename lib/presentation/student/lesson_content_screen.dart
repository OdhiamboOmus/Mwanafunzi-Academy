import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/lesson_content_card.dart';
import '../shared/lesson_navigation_bar.dart';
import '../shared/section_comment_sheet.dart';
import 'package:mwanafunzi_academy/core/service_locator.dart';
import 'package:mwanafunzi_academy/services/comment_service.dart';

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
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF6366F1),
    appBar: AppBar(
      backgroundColor: const Color(0xFF6366F1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${widget.currentStep} of ${widget.totalSteps}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF50E801),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF50E801).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$_commentCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: _showComments,
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: LessonContentCard(
            lessonTitle: widget.lessonTitle,
            subject: widget.subject,
          ),
        ),
        LessonNavigationBar(
          onPrevious: _goToPrevious,
          onNext: _goToNext,
          canGoBack: widget.currentStep > 1,
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
