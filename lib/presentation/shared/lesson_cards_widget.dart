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
      // Subject cards directly in the UI without container
      SizedBox(
        height: 220,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: _getLessonCards().length,
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
                  card: _getLessonCards()[index],
                  selectedGrade: widget.selectedGrade,
                ),
              ),
            );
          },
        ),
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
