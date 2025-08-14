import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'competition_card_widget.dart';

class QuizCompetitionsSection extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabChanged;

  const QuizCompetitionsSection({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quiz Competitions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              'View All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF50E801),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Compete with schools and students to earn points\nand climb the leaderboard! 🏆',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildCompetitionTab('All', 0),
            const SizedBox(width: 12),
            _buildCompetitionTab('School vs School', 1),
            const SizedBox(width: 12),
            _buildCompetitionTab('Student vs Student', 2),
          ],
        ),
        const SizedBox(height: 20),
        const CompetitionCardWidget(
          schoolName1: 'Mwanafunzi Primary',
          schoolName2: 'Excellence Academy',
          status: 'School vs School',
          statusColor: Colors.blue,
          date: 'Dec 15, 2024 - Dec 22, 2024',
          duration: '1 week',
          participants: '48 participants',
          prize: 'Certificates & Trophies',
          avatar1: 'MP',
          avatar2: 'EA',
          avatar1Color: Colors.blue,
          avatar2Color: Colors.blue,
        ),
        const SizedBox(height: 16),
        const CompetitionCardWidget(
          schoolName1: 'Sarah M. (Grade 5)',
          schoolName2: 'Looking for\nopponent...',
          status: 'Student vs Student',
          statusColor: Colors.orange,
          date: 'Today - Today',
          duration: '30 minutes',
          participants: '2 participants',
          prize: 'Points & Badges',
          avatar1: 'S',
          avatar2: '?',
          avatar1Color: Colors.orange,
          avatar2Color: Colors.grey,
        ),
      ],
    ),
  );

  Widget _buildCompetitionTab(String title, int index) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTabChanged(index);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selectedTab == index
            ? const Color(0xFF50E801)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedTab == index
              ? const Color(0xFF50E801)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selectedTab == index ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    ),
  );
}
