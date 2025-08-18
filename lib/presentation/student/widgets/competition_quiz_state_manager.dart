import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/firebase/student_challenge_service.dart';
import '../../../services/firebase/challenge_models.dart';
import '../../../data/models/quiz_model.dart' as quiz;

enum CompetitionQuizState {
  loading,
  ready,
  answering,
  showingResult,
  completed,
  error,
}

class CompetitionQuizStateManager extends StatefulWidget {
  final String challengeId;
  final String studentId;
  final String studentName;
  final bool isChallenger;
  final StudentChallenge challenge;
  final Widget Function(CompetitionQuizState state, Map<String, dynamic> data) builder;

  const CompetitionQuizStateManager({
    super.key,
    required this.challengeId,
    required this.studentId,
    required this.studentName,
    required this.isChallenger,
    required this.challenge,
    required this.builder,
  });

  @override
  State<CompetitionQuizStateManager> createState() => _CompetitionQuizStateManagerState();
}

class _CompetitionQuizStateManagerState extends State<CompetitionQuizStateManager> {
  late StudentChallengeService _challengeService;
  
  // State management
  CompetitionQuizState _state = CompetitionQuizState.loading;
  int _currentQuestionIndex = 0;
  List<int> _answers = [];
  int? _selectedAnswer;
  bool _showResult = false;
  String _errorMessage = '';
  
  // Challenge data
  late StudentChallenge _challenge;
  String _opponentName = '';
  String _opponentId = '';
  
  // Timer for auto-advance
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();
    _challengeService = StudentChallengeService();
    _initializeChallenge();
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChallenge() async {
    try {
      // Set challenge data
      _challenge = widget.challenge;
      
      // Determine opponent name and ID
      if (widget.isChallenger) {
        _opponentName = _challenge.challenged['name'] ?? 'Unknown Student';
        _opponentId = _challenge.challenged['studentId'] ?? '';
      } else {
        _opponentName = _challenge.challenger['name'] ?? 'Unknown Student';
        _opponentId = _challenge.challenger['studentId'] ?? '';
      }
      
      // Initialize answers array
      _answers = List.filled(_challenge.questions.length, -1);
      
      // Check if challenge is already completed
      if (_challenge.status == 'completed') {
        setState(() {
          _state = CompetitionQuizState.completed;
        });
        return;
      }
      
      // Accept challenge if it's pending and student is challenged
      if (_challenge.status == 'pending' && !widget.isChallenger) {
        await _challengeService.acceptChallenge(widget.challengeId);
      }
      
      setState(() {
        _state = CompetitionQuizState.ready;
      });
    } catch (e) {
      debugPrint('Error initializing challenge: $e');
      setState(() {
        _state = CompetitionQuizState.error;
        _errorMessage = 'Failed to initialize challenge: $e';
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    if (_state != CompetitionQuizState.answering) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _selectedAnswer = answerIndex;
      _answers[_currentQuestionIndex] = answerIndex;
      _showResult = true;
      _state = CompetitionQuizState.showingResult;
    });
    
    // Auto-advance to next question after showing result
    _resultTimer = Timer(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    _resultTimer?.cancel();
    
    if (_currentQuestionIndex < _challenge.questions.length - 1) {
      // Move to next question
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _state = CompetitionQuizState.answering;
      });
    } else {
      // Complete the quiz
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    try {
      setState(() {
        _state = CompetitionQuizState.loading;
      });
      
      // Submit answers
      await _challengeService.completeChallenge(
        challengeId: widget.challengeId,
        studentId: widget.studentId,
        answers: _answers,
      );
      
      setState(() {
        _state = CompetitionQuizState.completed;
      });
    } catch (e) {
      debugPrint('Error completing quiz: $e');
      setState(() {
        _state = CompetitionQuizState.error;
        _errorMessage = 'Failed to complete quiz: $e';
      });
    }
  }

  void _retry() {
    setState(() {
      _state = CompetitionQuizState.loading;
      _currentQuestionIndex = 0;
      _answers = List.filled(_challenge.questions.length, -1);
      _selectedAnswer = null;
      _showResult = false;
      _errorMessage = '';
    });
    
    _initializeChallenge();
  }

  void _goToChallengeTracking() {
    Navigator.pop(context);
  }

  // Get current question
  quiz.QuizQuestion get currentQuestion {
    return quiz.QuizQuestion.fromJson(_challenge.questions[_currentQuestionIndex]);
  }

  // Get quiz results
  Map<String, dynamic> get quizResults {
    if (_challenge.status != 'completed' || _challenge.results == null) {
      return {
        'yourScore': 0,
        'opponentScore': 0,
        'winner': null,
        'pointsAwarded': {},
      };
    }
    
    final results = _challenge.results!;
    
    // Determine which score belongs to the current student
    int yourScore;
    int opponentScore;
    
    if (widget.isChallenger) {
      yourScore = results.challengerScore;
      opponentScore = results.challengedScore;
    } else {
      yourScore = results.challengedScore;
      opponentScore = results.challengerScore;
    }
    
    return {
      'yourScore': yourScore,
      'opponentScore': opponentScore,
      'winner': results.winner,
      'pointsAwarded': results.pointsAwarded,
    };
  }

  // Get state data for builder
  Map<String, dynamic> get stateData {
    return {
      'state': _state,
      'currentQuestionIndex': _currentQuestionIndex,
      'answers': _answers,
      'selectedAnswer': _selectedAnswer,
      'showResult': _showResult,
      'errorMessage': _errorMessage,
      'challenge': _challenge,
      'opponentName': _opponentName,
      'opponentId': _opponentId,
      'currentQuestion': currentQuestion,
      'quizResults': quizResults,
      'selectAnswer': _selectAnswer,
      'nextQuestion': _nextQuestion,
      'completeQuiz': _completeQuiz,
      'retry': _retry,
      'goToChallengeTracking': _goToChallengeTracking,
      'startQuiz': _startQuiz,
    };
  }

  void _startQuiz() {
    setState(() {
      _state = CompetitionQuizState.answering;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_state, stateData);
  }
}