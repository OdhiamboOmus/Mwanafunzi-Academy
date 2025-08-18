import 'package:flutter/material.dart';
import '../../../data/models/quiz_model.dart';

// Question editor widget following Flutter Lite rules (<150 lines)
class QuestionEditorWidget extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final Function(QuizQuestion) onQuestionUpdated;

  const QuestionEditorWidget({
    super.key,
    required this.question,
    required this.index,
    required this.onQuestionUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF9FAFB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Question ${index + 1}', style: TextStyle(color: const Color(0xFF50E801), fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _editQuestion(context),
                tooltip: 'Edit question',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.question),
          const SizedBox(height: 8),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            final isCorrect = optionIndex == question.correctAnswerIndex;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFF50E801) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isCorrect ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(option, style: TextStyle(color: isCorrect ? const Color(0xFF50E801) : Colors.black))),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text('Explanation: ${question.explanation}', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Future<void> _editQuestion(BuildContext context) async {
    final controller = TextEditingController(text: question.question);
    final optionControllers = question.options.map((option) => TextEditingController(text: option)).toList();
    final explanationController = TextEditingController(text: question.explanation);
    int? selectedCorrectIndex = question.correctAnswerIndex;

    final updatedQuestion = await showDialog<QuizQuestion>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Question'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ...List.generate(4, (optionIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('${String.fromCharCode(65 + optionIndex)}. '),
                        Expanded(
                          child: TextField(
                            controller: optionControllers[optionIndex],
                            decoration: InputDecoration(labelText: 'Option ${optionIndex + 1}'),
                          ),
                        ),
                        Radio<int>(
                          value: optionIndex,
                          groupValue: selectedCorrectIndex,
                          onChanged: (value) => setState(() => selectedCorrectIndex = value),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: explanationController,
                  decoration: const InputDecoration(labelText: 'Explanation'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updated = QuizQuestion(
                  id: question.id,
                  question: controller.text,
                  options: optionControllers.map((c) => c.text).toList(),
                  correctAnswerIndex: selectedCorrectIndex!,
                  explanation: explanationController.text,
                );
                Navigator.pop(context, updated);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (updatedQuestion != null) {
      onQuestionUpdated(updatedQuestion);
    }
  }
}