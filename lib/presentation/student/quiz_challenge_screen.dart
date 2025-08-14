import 'package:flutter/material.dart';
import '../shared/bottom_navigation_widget.dart';
import 'widgets/quiz_challenge_section.dart';
import 'widgets/quiz_competitions_section.dart';

class QuizChallengeScreen extends StatefulWidget {
  const QuizChallengeScreen({super.key});

  @override
  State<QuizChallengeScreen> createState() => _QuizChallengeScreenState();
}

class _QuizChallengeScreenState extends State<QuizChallengeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  int _selectedBottomNavIndex = 1;
  int _selectedCompetitionTab = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Quiz Challenge',
        style: TextStyle(
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
          const SizedBox(height: 16),
          QuizChallengeSection(
            pageController: _pageController,
            currentPage: _currentPage,
            onPageChanged: (index) => setState(() => _currentPage = index),
          ),
          const SizedBox(height: 32),
          QuizCompetitionsSection(
            selectedTab: _selectedCompetitionTab,
            onTabChanged: (index) =>
                setState(() => _selectedCompetitionTab = index),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
    ),
  );
}
