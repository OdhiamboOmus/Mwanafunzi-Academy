import 'package:flutter/material.dart';
import 'competition_quiz_state_manager.dart';
import 'competition_quiz_header.dart';
import 'competition_question_widget.dart';
import 'competition_results_widget.dart';
import 'competition_error_widget.dart';
import '../../../services/firebase/challenge_models.dart';

class CompetitionQuizLogic extends StatelessWidget {
  final String challengeId;
  final String studentId;
  final String studentName;
  final bool isChallenger;
  final StudentChallenge challenge;

  const CompetitionQuizLogic({
    super.key,
    required this.challengeId,
    required this.studentId,
    required this.studentName,
    required this.isChallenger,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    return CompetitionQuizStateManager(
      challengeId: challengeId,
      studentId: studentId,
      studentName: studentName,
      isChallenger: isChallenger,
      challenge: challenge,
      builder: (state, data) {
        switch (state) {
          case CompetitionQuizState.loading:
            return const Center(
              child: CircularProgressIndicator(),
            );
            
          case CompetitionQuizState.ready:
            return Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 16),
                Text(
                  'Ready to start the competition?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => data['startQuiz'](),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50E801),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Start Quiz'),
                ),
              ],
            );
            
          case CompetitionQuizState.answering:
            return Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 16),
                CompetitionQuestionWidget(
                  question: data['currentQuestion'],
                  questionIndex: data['currentQuestionIndex'],
                  onAnswerSelected: (index) => data['selectAnswer'](index),
                  selectedAnswer: data['selectedAnswer'],
                  showResult: false,
                ),
              ],
            );
            
          case CompetitionQuizState.showingResult:
            return Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 16),
                CompetitionQuestionWidget(
                  question: data['currentQuestion'],
                  questionIndex: data['currentQuestionIndex'],
                  onAnswerSelected: (index) => data['selectAnswer'](index),
                  selectedAnswer: data['selectedAnswer'],
                  showResult: true,
                ),
              ],
            );
            
          case CompetitionQuizState.completed:
            return CompetitionResultsWidget(
              opponentName: data['opponentName'],
              results: data['quizResults'],
              studentId: studentId,
              onBackToChallenges: () => data['goToChallengeTracking'](),
            );
            
          case CompetitionQuizState.error:
            return CompetitionErrorWidget(
              errorMessage: data['errorMessage'],
              onRetry: () => data['retry'](),
            );
        }
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return CompetitionQuizHeader(
      opponentName: data['opponentName'],
      subject: data['challenge'].subject,
      topic: data['challenge'].topic,
      currentQuestion: data['currentQuestionIndex'] + 1,
      totalQuestions: data['challenge'].questions.length,
    );
  }
}