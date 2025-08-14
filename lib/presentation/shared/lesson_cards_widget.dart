import 'package:flutter/material.dart';
import 'lesson_card_item.dart';

// Lesson cards widget following Flutter Lite rules (<150 lines)
class LessonCardsWidget extends StatefulWidget {
  final String selectedGrade;

  const LessonCardsWidget({super.key, required this.selectedGrade});

  @override
  State<LessonCardsWidget> createState() => _LessonCardsWidgetState();
}

class _LessonCardsWidgetState extends State<LessonCardsWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            Row(
              children: List.generate(
                _getLessonCards().length > 5 ? 5 : _getLessonCards().length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentPage % 5
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
      // Premium scrollable cards with visual cues
      Stack(
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _getLessonCards().length,
              itemBuilder: (context, index) => LessonCardItem(
                card: _getLessonCards()[index],
                selectedGrade: widget.selectedGrade,
              ),
            ),
          ),
          // Left scroll indicator
          if (_currentPage > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: Color(0xFF50E801),
                    size: 20,
                  ),
                ),
              ),
            ),
          // Right scroll indicator
          if (_currentPage < _getLessonCards().length - 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.white.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF50E801),
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  List<LessonCardData> _getLessonCards() {
    final baseCards = [
      const LessonCardData(
        subject: 'Mathematics',
        description: 'Master algebra, geometry, and calculus concepts',
        lessonCount: 24,
        duration: '12 weeks',
        progress: 0.65,
        icon: Icons.calculate,
      ),
      const LessonCardData(
        subject: 'English',
        description: 'Improve grammar, vocabulary, and writing skills',
        lessonCount: 18,
        duration: '9 weeks',
        progress: 0.40,
        icon: Icons.menu_book,
      ),
      const LessonCardData(
        subject: 'Science',
        description: 'Explore physics, chemistry, and biology',
        lessonCount: 30,
        duration: '15 weeks',
        progress: 0.20,
        icon: Icons.science,
      ),
      const LessonCardData(
        subject: 'Social Studies',
        description: 'Learn about history, geography, and culture',
        lessonCount: 20,
        duration: '10 weeks',
        progress: 0.80,
        icon: Icons.public,
      ),
      const LessonCardData(
        subject: 'Kiswahili',
        description: 'Develop language skills and cultural understanding',
        lessonCount: 16,
        duration: '8 weeks',
        progress: 0.55,
        icon: Icons.translate,
      ),
    ];

    return List.generate(10, (index) {
      final originalIndex = index % baseCards.length;
      final originalCard = baseCards[originalIndex];
      return LessonCardData(
        subject: originalCard.subject,
        description: originalCard.description,
        lessonCount: originalCard.lessonCount,
        duration: originalCard.duration,
        progress: originalCard.progress,
        icon: originalCard.icon,
      );
    });
  }
}
