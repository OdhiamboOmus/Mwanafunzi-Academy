import '../../services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/lesson_service_core.dart';
import '../../services/firebase/firestore_service.dart';

/// Logic handler for question widget operations
class QuestionLogicHandler {
  final QuestionService _questionService;
  final String lessonId;
  final String sectionId;
  final String questionId;

  int? _selectedOption;
  bool _showFeedback = false;

  QuestionLogicHandler({
    required this.lessonId,
    required this.sectionId,
    required this.questionId,
    QuestionService? questionService,
  }) : _questionService = questionService ?? QuestionService(
    storageService: StorageService(),
    lessonService: LessonService(
      storageService: StorageService(),
      userRepository: UserRepository(),
      firestoreService: FirestoreService(),
    ),
  );

  /// Get the currently selected option
  int? get selectedOption => _selectedOption;

  /// Get whether feedback is currently shown
  bool get showFeedback => _showFeedback;

  /// Check if question has been answered before
  Future<bool> checkIfQuestionAnswered() async {
    final hasAnswered = await _questionService.isQuestionAnswered(questionId);
    if (hasAnswered) {
      final answerDetails = await _questionService.getAnswerDetails(questionId);
      _selectedOption = answerDetails?['selectedOption'] as int?;
      _showFeedback = true;
    }
    return hasAnswered;
  }

  /// Handle option selection
  void handleOptionSelected(int index, Function(int)? onAnswerSelected) {
    if (_showFeedback) return; // Don't allow changes after feedback

    _selectedOption = index;
    onAnswerSelected?.call(index);

    // Record the answer
    _questionService.recordAnswer(
      questionId,
      index,
      lessonId: lessonId,
    );
  }

  /// Show feedback after a delay
  Future<void> showFeedbackAfterDelay(Function(bool, String)? onAnswerFeedback) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _showFeedback = true;
    onAnswerFeedback?.call(
      _selectedOption != null && _selectedOption! >= 0,
      '', // This would be passed from the widget
    );
  }

  /// Reset the question state
  void reset() {
    _selectedOption = null;
    _showFeedback = false;
  }
}