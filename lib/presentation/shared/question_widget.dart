import 'package:flutter/material.dart';
import '../../data/models/quiz_model.dart';
import 'question_logic.dart';
import 'question_option_widget.dart';
import 'question_feedback_widget.dart';

/// Embedded question widget for lesson sections
class QuestionWidget extends StatefulWidget {
  final String lessonId;
  final String sectionId;
  final QuizQuestion question;
  final Function(int)? onAnswerSelected;
  final Function(bool, String)? onAnswerFeedback;

  const QuestionWidget({
    super.key,
    required this.lessonId,
    required this.sectionId,
    required this.question,
    this.onAnswerSelected,
    this.onAnswerFeedback,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late QuestionLogicHandler _logicHandler;

  @override
  void initState() {
    super.initState();
    _logicHandler = QuestionLogicHandler(
      lessonId: widget.lessonId,
      sectionId: widget.sectionId,
      questionId: widget.question.id,
    );
    _checkIfQuestionAnswered();
  }

  Future<void> _checkIfQuestionAnswered() async {
    await _logicHandler.checkIfQuestionAnswered();
    if (mounted) {
      setState(() {});
    }
  }

  void _handleOptionSelected(int index) {
    _logicHandler.handleOptionSelected(index, widget.onAnswerSelected);
    
    // Show feedback after a short delay
    _logicHandler.showFeedbackAfterDelay((isCorrect, explanation) {
      widget.onAnswerFeedback?.call(isCorrect, widget.question.explanation);
      if (mounted) {
        setState(() {});
      }
    });
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Question title
          const Text(
            'Question',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 8),
          
          // Question text
          Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          // Answer options
          ...widget.question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _logicHandler.selectedOption == index;
            final isCorrect = widget.question.isCorrect(index);
            
            return QuestionOptionWidget(
              option: option,
              index: index,
              isSelected: isSelected,
              isCorrect: isCorrect,
              showFeedback: _logicHandler.showFeedback,
              onTap: () => _handleOptionSelected(index),
            );
          }),
          
          // Feedback and explanation
          if (_logicHandler.showFeedback) ...[
            const SizedBox(height: 16),
            QuestionFeedbackWidget(
              isCorrect: widget.question.isCorrect(_logicHandler.selectedOption!),
              explanation: widget.question.explanation,
            ),
          ],
        ],
      ),
    );
  }
}