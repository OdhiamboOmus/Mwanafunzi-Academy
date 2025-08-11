import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LessonCardsWidget extends StatelessWidget {
  final String selectedGrade;

  const LessonCardsWidget({
    super.key,
    required this.selectedGrade,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Your Lessons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _getLessonCards().length,
          itemBuilder: (context, index) {
            final card = _getLessonCards()[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            card.icon,
                            color: const Color(0xFF50E801),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              card.subject,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${card.lessonCount} lessons',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            card.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: card.progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF50E801),
                        ),
                        minHeight: 4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF50E801),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Continue Learning',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  List<LessonCardData> _getLessonCards() {
    // Generate infinite-like lesson cards based on selected grade
    final baseCards = [
      LessonCardData(
        subject: 'Mathematics',
        description: 'Master algebra, geometry, and calculus concepts',
        lessonCount: 24,
        duration: '12 weeks',
        progress: 0.65,
        icon: Icons.calculate,
      ),
      LessonCardData(
        subject: 'English',
        description: 'Improve grammar, vocabulary, and writing skills',
        lessonCount: 18,
        duration: '9 weeks',
        progress: 0.40,
        icon: Icons.menu_book,
      ),
      LessonCardData(
        subject: 'Science',
        description: 'Explore physics, chemistry, and biology',
        lessonCount: 30,
        duration: '15 weeks',
        progress: 0.20,
        icon: Icons.science,
      ),
      LessonCardData(
        subject: 'Social Studies',
        description: 'Learn about history, geography, and culture',
        lessonCount: 20,
        duration: '10 weeks',
        progress: 0.80,
        icon: Icons.public,
      ),
      LessonCardData(
        subject: 'Kiswahili',
        description: 'Develop language skills and cultural understanding',
        lessonCount: 16,
        duration: '8 weeks',
        progress: 0.55,
        icon: Icons.translate,
      ),
    ];

    // Add more cards to simulate infinite scrolling
    return List.generate(10, (index) {
      final originalIndex = index % baseCards.length;
      final originalCard = baseCards[originalIndex];
      return LessonCardData(
        subject: '${originalCard.subject} ${index + 1}',
        description: originalCard.description,
        lessonCount: originalCard.lessonCount,
        duration: originalCard.duration,
        progress: originalCard.progress,
        icon: originalCard.icon,
      );
    });
  }
}

class LessonCardData {
  final String subject;
  final String description;
  final int lessonCount;
  final String duration;
  final double progress;
  final IconData icon;

  const LessonCardData({
    required this.subject,
    required this.description,
    required this.lessonCount,
    required this.duration,
    required this.progress,
    required this.icon,
  });
}