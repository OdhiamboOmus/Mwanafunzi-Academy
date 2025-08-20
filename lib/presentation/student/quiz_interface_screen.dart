import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../services/firebase/quiz_service.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/lesson_quiz_progress_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/quiz_model.dart' as quiz;
import '../shared/bottom_navigation_widget.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_answer_option.dart';
import 'widgets/quiz_feedback_section.dart';

class QuizInterfaceScreen extends StatefulWidget {
  final String subject;
  final String quizTitle;
  final String grade;
  final String topic;

  const QuizInterfaceScreen({
    super.key,
    required this.subject,
    required this.quizTitle,
    required this.grade,
    required this.topic,
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
  
  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Quiz data
  List<quiz.QuizQuestion> _questions = [];
  final QuizService _quizService = QuizService();
  final FirestoreService _firestoreService = FirestoreService();
  late LessonQuizProgressService _progressService;

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
          end: 0.0, // Will be updated when questions are loaded
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
    
    // Initialize progress service
    _progressService = LessonQuizProgressService(
      storageService: StorageService(),
      firestoreService: _firestoreService,
    );
    
    // Load quiz questions dynamically
    _loadQuizQuestions();
  }

  /// Load quiz questions from Firebase with caching
  Future<void> _loadQuizQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load questions from Firebase with 30-day caching
      _questions = await _quizService.getQuizQuestions(
        grade: widget.grade,
        subject: widget.subject,
        topic: widget.topic,
      );
      
      if (_questions.isEmpty) {
        throw Exception('No questions found for this quiz');
      }
      
      setState(() {
        _isLoading = false;
        _hasError = false;
        
        // Update progress animation after questions are loaded
        _progressAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );
      });
    } catch (e) {
      debugPrint('Error loading quiz questions: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load quiz questions. Please try again.';
      });
    }
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
            'Question ${_currentQuestionIndex + 1} of ${_questions.isNotEmpty ? _questions.length : 1}',
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
          child: _buildQuizContent(),
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

  Widget _buildQuizContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50E801)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading quiz questions...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuizQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
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
              itemCount: _getCurrentQuestion().options.isNotEmpty ? _getCurrentQuestion().options.length : 0,
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
                  _currentQuestionIndex >= _questions.length - 1,
              onNext: _nextQuestion,
            ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    HapticFeedback.lightImpact();

    if (_questions.isNotEmpty && _currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showFeedback = false;
      });

      _feedbackController.reset();
      _progressController.reset();
      _progressAnimation =
          Tween<double>(
            begin: _questions.isNotEmpty ? _currentQuestionIndex / _questions.length : 0.0,
            end: _questions.isNotEmpty ? (_currentQuestionIndex + 1) / _questions.length : 1.0,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );
      _progressController.forward();
    } else {
      // Quiz completed - record the attempt
      _recordQuizAttempt();
      Navigator.pop(context);
    }
  }

  /// Record quiz attempt to Firebase and update lesson progress
  Future<void> _recordQuizAttempt() async {
    try {
      final answers = List<int>.filled(_questions.isNotEmpty ? _questions.length : 0, -1);
      if (_selectedAnswerIndex != null) {
        answers[_currentQuestionIndex] = _selectedAnswerIndex!;
      }

      final attempt = quiz.QuizAttempt.calculateScore(
        studentId: 'current_user_id', // This should come from authentication
        grade: widget.grade,
        subject: widget.subject,
        topic: widget.topic,
        questions: _questions,
        answers: answers,
      );

      // Record quiz attempt
      await _quizService.batchRecordAttempts([attempt]);
      debugPrint('Quiz attempt recorded successfully');

      // Update lesson progress with quiz completion data
      await _updateLessonProgressWithQuiz(attempt);
    } catch (e) {
      debugPrint('Error recording quiz attempt: $e');
      // Don't show error to user, just log it
    }
  }

  /// Update lesson progress with quiz completion data
  Future<void> _updateLessonProgressWithQuiz(quiz.QuizAttempt attempt) async {
    try {
      // This would normally get the current user ID from authentication
      // For now, using a placeholder
      final studentId = 'current_user_id';
      
      // Create lesson ID based on grade, subject, and topic
      final lessonId = 'lesson_${attempt.grade}_${attempt.subject}_${attempt.topic}';
      
      // Update lesson progress with quiz completion using the progress service
      await _progressService.updateLessonProgressWithQuiz(
        studentId: studentId,
        grade: attempt.grade,
        subject: attempt.subject,
        topic: attempt.topic,
        lessonId: lessonId,
        quizAttempt: attempt,
      );

      debugPrint('Lesson progress updated with quiz completion data');
    } catch (e) {
      debugPrint('Error updating lesson progress with quiz: $e');
    }
  }

  quiz.QuizQuestion _getCurrentQuestion() {
    if (_questions.isEmpty) {
      throw Exception('No questions available');
    }
    return _questions[_currentQuestionIndex];
  }
}
