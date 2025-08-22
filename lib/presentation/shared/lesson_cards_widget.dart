import 'package:flutter/material.dart';
import 'lesson_card_item.dart';
import '../../services/firebase/student_lesson_service.dart';

// Lesson cards widget following Flutter Lite rules (<150 lines)
class LessonCardsWidget extends StatefulWidget {
  final String selectedGrade;

  const LessonCardsWidget({super.key, required this.selectedGrade});

  @override
  State<LessonCardsWidget> createState() => _LessonCardsWidgetState();
}

class _LessonCardsWidgetState extends State<LessonCardsWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final StudentLessonService _lessonService = StudentLessonService();
  int _currentPage = 0;
  bool _isLoading = true;
  List<LessonCardData> _lessonCards = [];

  @override
  void initState() {
    super.initState();
    _loadLessonCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LessonCardsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGrade != widget.selectedGrade) {
      _loadLessonCards();
    }
  }

  Future<void> _loadLessonCards() async {
    if (widget.selectedGrade.isEmpty) {
      setState(() {
        _isLoading = false;
        _lessonCards = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('🔍 DEBUG: Loading lesson cards for grade: ${widget.selectedGrade}');
      
      // Fetch lessons from Firebase for the selected grade
      final firebaseLessons = await _lessonService.getLessonsForGrade(widget.selectedGrade);
      
      if (mounted) {
        setState(() {
          _lessonCards = _convertFirebaseLessonsToLessonCards(firebaseLessons);
          _isLoading = false;
        });

        debugPrint('🔍 DEBUG: Loaded ${_lessonCards.length} lesson cards for grade ${widget.selectedGrade}');
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to load lesson cards: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lessonCards = _getFallbackLessonCards();
        });
      }
    }
  }

  List<LessonCardData> _convertFirebaseLessonsToLessonCards(List<Map<String, dynamic>> firebaseLessons) {
    return firebaseLessons.map((lesson) {
      return LessonCardData(
        subject: lesson['subject'] ?? 'Mathematics',
        description: lesson['topic'] ?? lesson['title'] ?? 'Lesson content',
        lessonCount: lesson['totalSections'] ?? 5,
        duration: _calculateDuration(lesson),
        progress: 0.5, // Default progress, could be enhanced with actual progress tracking
        icon: _getSubjectIcon(lesson['subject'] ?? 'Mathematics'),
        lessonId: lesson['id'] ?? lesson['lessonId'] ?? 'default_lesson',
      );
    }).toList();
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate;
      case 'english':
        return Icons.menu_book;
      case 'science':
        return Icons.science;
      case 'social studies':
      case 'social':
        return Icons.public;
      case 'kiswahili':
        return Icons.translate;
      default:
        return Icons.school;
    }
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

  List<LessonCardData> _getFallbackLessonCards() {
    // Fallback lesson cards in case Firebase is unavailable
    return [
      const LessonCardData(
        subject: 'Loading...',
        description: 'Please wait while we fetch your lessons',
        lessonCount: 0,
        duration: '',
        progress: 0.0,
        icon: Icons.hourglass_empty,
        lessonId: 'loading',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Continue Learning',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            // Scroll indicator dots
            if (_lessonCards.isNotEmpty)
              Row(
                children: List.generate(
                  _lessonCards.length > 5 ? 5 : _lessonCards.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _currentPage % _lessonCards.length
                          ? const Color(0xFF50E801)
                          : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      // Lesson cards from Firebase
      SizedBox(
        height: 220,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _lessonCards.isEmpty
                ? const Center(
                    child: Text(
                      'No lessons available for this grade.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _lessonCards.length,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final isCurrentPage = index == _currentPage;
                      final scale = isCurrentPage ? 1.0 : 0.9;
                      final opacity = isCurrentPage ? 1.0 : 0.7;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        transform: Matrix4.identity()..scale(scale),
                        child: Opacity(
                          opacity: opacity,
                          child: LessonCardItem(
                            card: _lessonCards[index],
                            selectedGrade: widget.selectedGrade,
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ],
  );
}
