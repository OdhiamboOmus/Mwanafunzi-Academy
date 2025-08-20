import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/routes.dart';
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
        'Mwanafunzi Academy',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF50E801)),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: 1, // Quiz tab is selected
      onTabChanged: (index) {
        if (index == 0) { // Home tab
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 2) { // Video tab
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushNamed(context, AppRoutes.video);
        } else if (index == 3) { // Teachers tab
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushNamed(context, AppRoutes.findTeachers);
        }
        // If it's the quiz tab, just update the local state
        setState(() {});
      },
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
  );
}
