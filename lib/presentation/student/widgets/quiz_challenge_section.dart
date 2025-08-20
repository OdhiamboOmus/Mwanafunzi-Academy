import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../quiz_interface_screen.dart';
import 'quiz_card_widget.dart';
import 'subject_indicator_widget.dart';
import '../../../services/firebase/student_challenge_service.dart';

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
            height: 200,
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
    // Check if this is a competition challenge
    if (card.title == 'Challenge Random Student') {
      _showChallengeDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizInterfaceScreen(
            subject: card.title.replaceAll(' Quiz', ''),
            quizTitle: card.title,
            grade: 'Grade 1', // Default grade, should be selected by user
            topic: card.title.replaceAll(' Quiz', ''), // Use subject as topic for now
          ),
        ),
      );
    }
  }

  void _showChallengeDialog(BuildContext context) {
    final List<String> subjects = ['Mathematics', 'Science', 'Kiswahili', 'English', 'Social Studies'];
    final List<String> grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];
    final List<String> topics = ['Basic', 'Intermediate', 'Advanced'];
    
    String selectedSubject = subjects.first;
    String selectedGrade = grades.first;
    String selectedTopic = topics.first;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Challenge Random Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select competition details:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: subjects.map((subject) => DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                )).toList(),
                onChanged: (value) => setState(() => selectedSubject = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
                items: grades.map((grade) => DropdownMenuItem(
                  value: grade,
                  child: Text(grade),
                )).toList(),
                onChanged: (value) => setState(() => selectedGrade = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTopic,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                ),
                items: topics.map((topic) => DropdownMenuItem(
                  value: topic,
                  child: Text(topic),
                )).toList(),
                onChanged: (value) => setState(() => selectedTopic = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _createChallenge(context, selectedSubject, selectedGrade, selectedTopic);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                foregroundColor: Colors.white,
              ),
              child: const Text('Challenge'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createChallenge(
    BuildContext context,
    String subject,
    String grade,
    String topic,
  ) async {
    try {
      HapticFeedback.lightImpact();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user info (this would come from authentication service)
      final String studentId = 'current_user_id'; // Replace with actual user ID
      final String studentName = 'Current User'; // Replace with actual user name
      final String studentSchool = 'Current School'; // Replace with actual school

      final challengeService = StudentChallengeService();
      await challengeService.createRandomChallenge(
        challengerId: studentId,
        challengerName: studentName,
        challengerSchool: studentSchool,
        topic: topic,
        subject: subject,
        grade: grade,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge sent! Waiting for opponent to accept.'),
          backgroundColor: Color(0xFF50E801),
        ),
      );
      }

      // Navigate to challenge tracking screen (to be implemented)
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ChallengeTrackingScreen(challengeId: challengeId)));

    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      HapticFeedback.heavyImpact();
      
      // Show error message
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Challenge Failed'),
          content: Text(e.toString().contains('No opponents')
              ? 'No opponents available for challenge. Please try again later.'
              : 'Failed to create challenge. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      }
    }
  }

  List<QuizCardData> _getQuizCards() => [
    const QuizCardData(
      title: 'Challenge Random Student',
      description:
          'Compete with other students in real-time quiz battles',
      questionCount: 10,
      duration: 'Unlimited',
      bestScore: 0,
      icon: Icons.sports_esports,
    ),
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
