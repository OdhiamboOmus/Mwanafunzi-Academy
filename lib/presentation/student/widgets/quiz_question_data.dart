class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}

class QuizQuestionData {
  static List<QuizQuestion> getQuestions(String subject) {
    switch (subject.toLowerCase()) {
      case 'kiswahili':
        return [
          const QuizQuestion(
            question: 'Neno "haraka" ni aina gani ya maneno?',
            options: ['Nomino', 'Kivumishi', 'Kitenzi', 'Kielezi'],
            correctAnswerIndex: 1,
            explanation:
                'Neno "haraka" ni kivumishi kinachoelezea hali au mazingira ya kitu au tendo.',
          ),
          const QuizQuestion(
            question: 'Wingi wa neno "mti" ni nini?',
            options: ['Miti', 'Mati', 'Meti', 'Moti'],
            correctAnswerIndex: 0,
            explanation:
                'Wingi wa "mti" ni "miti" kulingana na kanuni za Kiswahili.',
          ),
        ];
      case 'mathematics':
        return [
          const QuizQuestion(
            question: 'What is 15 + 27?',
            options: ['40', '42', '45', '47'],
            correctAnswerIndex: 1,
            explanation:
                'When adding 15 + 27, we get 42. You can break it down as 15 + 20 + 7 = 35 + 7 = 42',
          ),
          const QuizQuestion(
            question: 'What is 8 × 7?',
            options: ['54', '56', '58', '60'],
            correctAnswerIndex: 1,
            explanation: '8 × 7 = 56. This is a basic multiplication fact.',
          ),
        ];
      case 'science':
        return [
          const QuizQuestion(
            question: 'What is the largest planet in our solar system?',
            options: ['Earth', 'Saturn', 'Jupiter', 'Neptune'],
            correctAnswerIndex: 2,
            explanation:
                'Jupiter is the largest planet in our solar system, with a mass greater than all other planets combined.',
          ),
          const QuizQuestion(
            question: 'What gas do plants absorb from the atmosphere?',
            options: ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'],
            correctAnswerIndex: 1,
            explanation:
                'Plants absorb carbon dioxide from the atmosphere during photosynthesis to make their food.',
          ),
        ];
      default:
        return [
          QuizQuestion(
            question: 'Sample question for $subject?',
            options: const ['Option A', 'Option B', 'Option C', 'Option D'],
            correctAnswerIndex: 1,
            explanation: 'This is a sample explanation for the correct answer.',
          ),
        ];
    }
  }
}
