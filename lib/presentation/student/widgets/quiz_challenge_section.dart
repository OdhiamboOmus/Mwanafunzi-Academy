import 'package:flutter/material.dart';
import '../quiz_interface_screen.dart';
import 'quiz_card_widget.dart';
import 'subject_indicator_widget.dart';

class QuizChallengeSection extends StatelessWidget {
  final PageController pageController;
  final int currentPage;
  final Function(int) onPageChanged;

  const QuizChallengeSection({
    super.key,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose Your Challenge',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Row(
              children: List.generate(
                _getQuizCards().length > 3 ? 3 : _getQuizCards().length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == currentPage % 3
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
      const SizedBox(height: 16),
      Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SubjectIndicatorWidget(subject: 'CHEM', isActive: true),
                  SubjectIndicatorWidget(subject: 'PHYS', isActive: false),
                  SubjectIndicatorWidget(subject: 'BIO', isActive: false),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 80),
            height: 280,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: _getQuizCards().length,
              itemBuilder: (context, index) => QuizCardWidget(
                card: _getQuizCards()[index],
                onTap: () => _navigateToQuiz(context, _getQuizCards()[index]),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  void _navigateToQuiz(BuildContext context, QuizCardData card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizInterfaceScreen(
          subject: card.title.replaceAll(' Quiz', ''),
          quizTitle: card.title,
          totalQuestions: card.questionCount,
        ),
      ),
    );
  }

  List<QuizCardData> _getQuizCards() => [
    const QuizCardData(
      title: 'Kiswahili Quiz',
      description:
          'Test your knowledge with interactive questions and instant feedback',
      questionCount: 15,
      duration: '5 mins',
      bestScore: 85,
      icon: Icons.translate,
    ),
    const QuizCardData(
      title: 'Mathematics Quiz',
      description:
          'Challenge yourself with algebra, geometry and arithmetic problems',
      questionCount: 20,
      duration: '8 mins',
      bestScore: 92,
      icon: Icons.calculate,
    ),
    const QuizCardData(
      title: 'Science Quiz',
      description:
          'Explore physics, chemistry and biology concepts through fun quizzes',
      questionCount: 18,
      duration: '7 mins',
      bestScore: 78,
      icon: Icons.science,
    ),
  ];
}

class QuizCardData {
  final String title;
  final String description;
  final int questionCount;
  final String duration;
  final int bestScore;
  final IconData icon;

  const QuizCardData({
    required this.title,
    required this.description,
    required this.questionCount,
    required this.duration,
    required this.bestScore,
    required this.icon,
  });
}
