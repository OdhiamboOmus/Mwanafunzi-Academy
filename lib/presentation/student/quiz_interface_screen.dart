import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/bottom_navigation_widget.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_answer_option.dart';
import 'widgets/quiz_feedback_section.dart';
import 'widgets/quiz_question_data.dart';

class QuizInterfaceScreen extends StatefulWidget {
  final String subject;
  final String quizTitle;
  final int totalQuestions;

  const QuizInterfaceScreen({
    super.key,
    required this.subject,
    required this.quizTitle,
    required this.totalQuestions,
  });

  @override
  State<QuizInterfaceScreen> createState() => _QuizInterfaceScreenState();
}

class _QuizInterfaceScreenState extends State<QuizInterfaceScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _selectedBottomNavIndex = 1;

  late AnimationController _progressController;
  late AnimationController _feedbackController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _feedbackSlideAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(
          begin: 0.0,
          end: (_currentQuestionIndex + 1) / widget.totalQuestions,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _feedbackSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _feedbackController,
            curve: Curves.easeOutBack,
          ),
        );

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Column(
        children: [
          Text(
            widget.quizTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            'Question ${_currentQuestionIndex + 1} of ${widget.totalQuestions}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF50E801),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'V3',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        QuizProgressBar(animation: _progressAnimation),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  _getCurrentQuestion().question,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: _getCurrentQuestion().options.length,
                    itemBuilder: (context, index) => QuizAnswerOption(
                      index: index,
                      option: _getCurrentQuestion().options[index],
                      isSelected: _selectedAnswerIndex == index,
                      showResult: _showFeedback,
                      isCorrect:
                          index == _getCurrentQuestion().correctAnswerIndex,
                      onTap: _showFeedback ? null : () => _selectAnswer(index),
                    ),
                  ),
                ),
                if (_showFeedback)
                  QuizFeedbackSection(
                    slideAnimation: _feedbackSlideAnimation,
                    isCorrect: _isCorrect,
                    explanation: _getCurrentQuestion().explanation,
                    isLastQuestion:
                        _currentQuestionIndex >= widget.totalQuestions - 1,
                    onNext: _nextQuestion,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
    ),
  );

  void _selectAnswer(int index) {
    if (_showFeedback) return;

    HapticFeedback.lightImpact();
    setState(() => _selectedAnswerIndex = index);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showFeedback = true;
          _isCorrect = index == _getCurrentQuestion().correctAnswerIndex;
        });
        _feedbackController.forward();

        if (_isCorrect) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      }
    });
  }

  void _nextQuestion() {
    HapticFeedback.lightImpact();

    if (_currentQuestionIndex < widget.totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showFeedback = false;
      });

      _feedbackController.reset();
      _progressController.reset();
      _progressAnimation =
          Tween<double>(
            begin: _currentQuestionIndex / widget.totalQuestions,
            end: (_currentQuestionIndex + 1) / widget.totalQuestions,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );
      _progressController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  QuizQuestion _getCurrentQuestion() =>
      QuizQuestionData.getQuestions(widget.subject)[_currentQuestionIndex];
}
