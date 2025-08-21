import 'package:flutter/material.dart';
import '../../services/firebase/school_competition_service.dart';
import '../../services/firebase/student_challenge_service.dart';
import '../../data/models/quiz_model.dart';
import '../shared/widgets.dart';

// Competition quiz screen following Flutter Lite rules (<150 lines)
class CompetitionQuizScreen extends StatefulWidget {
  final String competitionId;
  final String studentId;
  final List<Map<String, dynamic>> questions;
  final StudentChallenge? challenge;

  const CompetitionQuizScreen({
    super.key,
    required this.competitionId,
    required this.studentId,
    required this.questions,
    this.challenge,
  });

  @override
  State<CompetitionQuizScreen> createState() => _CompetitionQuizScreenState();
}

class _CompetitionQuizScreenState extends State<CompetitionQuizScreen> {
  int _currentQuestionIndex = 0;
  final List<int> _selectedAnswers = [];
  // bool _isSubmitting = false; // Removed - unused field
  bool _showResults = false;
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsScreen();
    }

    final currentQuestion = QuizQuestion.fromJson(widget.questions[_currentQuestionIndex]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            _buildQuestionHeader(currentQuestion),
            const SizedBox(height: 16),
            _buildQuizQuestion(currentQuestion),
            const SizedBox(height: 24),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    automaticallyImplyLeading: false, // Remove back arrow
    title: const Text(
      'School Competition',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
    actions: [
      TextButton(
        onPressed: _showSubmitDialog,
        child: const Text(
          'Submit',
          style: TextStyle(
            color: Color(0xFF50E801),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _buildProgressIndicator() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            '${((_currentQuestionIndex + 1) / widget.questions.length * 100).round()}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: (_currentQuestionIndex + 1) / widget.questions.length,
        backgroundColor: const Color(0xFFE5E7EB),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF50E801)),
      ),
    ],
  );

  Widget _buildQuestionHeader(QuizQuestion question) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF50E801).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.quiz,
                color: Color(0xFF50E801),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Question',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildNavigationButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      if (_currentQuestionIndex > 0)
        ElevatedButton(
          onPressed: _previousQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Previous'),
        )
      else
        const SizedBox(width: 120),
      
      if (_currentQuestionIndex < widget.questions.length - 1)
        ElevatedButton(
          onPressed: _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF50E801),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Next'),
        )
      else
        ElevatedButton(
          onPressed: _showSubmitDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF50E801),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Submit Quiz'),
        ),
    ],
  );

  Widget _buildResultsScreen() => Scaffold(
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          const SizedBox(height: 24),
          _buildScoreCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    ),
  );

  Widget _buildResultsHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Quiz Completed!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Your score has been submitted to the competition',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    ],
  );

  Widget _buildScoreCard() => Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF50E801).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF50E801),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '$_score / ${widget.questions.length}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF50E801),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_score / widget.questions.length * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Great job! Your points have been added to your school\'s total.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildActionButtons() => Column(
    children: [
      BrandButton(
        text: 'View School Rankings',
        onPressed: _viewRankings,
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _backToCompetitions,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Back to Competitions'),
      ),
    ],
  );

  void _previousQuestion() {
    setState(() {
      _currentQuestionIndex--;
    });
  }

  void _nextQuestion() {
    if (_selectedAnswers.length <= _currentQuestionIndex) {
      _selectedAnswers.add(-1); // No answer selected
    }
    setState(() {
      _currentQuestionIndex++;
    });
  }

  void _showSubmitDialog() {
    if (_selectedAnswers.length <= _currentQuestionIndex) {
      _selectedAnswers.add(-1); // No answer selected
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz'),
        content: const Text(
          'Are you sure you want to submit your answers? You cannot change them after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50E801),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    Navigator.pop(context); // Close dialog

    setState(() {
      // _isSubmitting = true; // Removed - unused field
    });

    try {
      // Calculate score
      _score = 0;
      for (int i = 0; i < widget.questions.length; i++) {
        final question = QuizQuestion.fromJson(widget.questions[i]);
        if (_selectedAnswers[i] == question.correctAnswerIndex) {
          _score++;
        }
      }

      // Submit results based on competition type
      if (widget.challenge != null) {
        // Student vs Student challenge
        await StudentChallengeService().completeChallenge(
          challengeId: widget.challenge!.id,
          studentId: widget.studentId,
          answers: _selectedAnswers,
        );
      } else {
        // School vs School competition
        await SchoolCompetitionService.submitResults(
          competitionId: widget.competitionId,
          studentId: widget.studentId,
          score: _score,
        );
      }

      setState(() {
        _showResults = true;
        // _isSubmitting = false; // Removed - unused field
      });
    } catch (e) {
      setState(() {
        // _isSubmitting = false; // Removed - unused field
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quiz: ${e.toString()}')),
        );
      }
    }
  }

  void _viewRankings() {
    Navigator.pushNamed(
      context,
      '/school-rankings',
      arguments: {'competitionId': widget.competitionId},
    );
  }

  void _backToCompetitions() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
  Widget _buildQuizQuestion(QuizQuestion question) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        
        // Answer options
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _selectedAnswers.isNotEmpty ? _selectedAnswers[_currentQuestionIndex] == index : false;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAnswers[_currentQuestionIndex] = index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF50E801).withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF50E801) : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF50E801) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.black : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}