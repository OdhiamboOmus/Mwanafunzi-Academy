import '../core/services/storage_service.dart';
import '../data/models/lesson_model.dart';
import '../data/repositories/user_repository.dart';
import '../services/firebase/firestore_service.dart';
import 'lesson_retrieval_service.dart';
import 'lesson_navigation_service.dart';
import 'lesson_progress_service.dart';
import 'lesson_download_service.dart';
import 'lesson_cache_service.dart';
import 'question_service.dart';

/// Core lesson service for section-based lesson management and offline caching
class LessonService {
  final StorageService _storageService;
  final UserRepository _userRepository;

  late LessonRetrievalService _retrievalService;
  late LessonNavigationService _navigationService;
  late LessonProgressService _progressService;
  late LessonDownloadService _downloadService;
  late LessonCacheService _cacheService;
  late QuestionService _questionService;
  bool _servicesInitialized = false;

  final FirestoreService _firestoreService;
  
  LessonService({
    required StorageService storageService,
    required UserRepository userRepository,
    required FirestoreService firestoreService,
  }) : _storageService = storageService,
       _userRepository = userRepository,
       _firestoreService = firestoreService;

  void initializeServices() {
    if (_servicesInitialized) return;
    
    _retrievalService = LessonRetrievalService(
      storageService: _storageService,
      firestoreService: _firestoreService,
    );
    _navigationService = LessonNavigationService(
      lessonRetrievalService: _retrievalService,
    );
    _progressService = LessonProgressService();
    _downloadService = LessonDownloadService(
      storageService: _storageService,
      userRepository: _userRepository,
    );
    _cacheService = LessonCacheService(
      storageService: _storageService,
    );
    _questionService = QuestionService(
      storageService: _storageService,
      lessonService: this,
    );
    
    _servicesInitialized = true;
  }

  /// Get lessons metadata for a grade with single Firestore query
  Future<List<LessonMeta>> getLessonsForGrade(String grade) async {
    initializeServices();
    return await _retrievalService.getLessonsForGrade(grade);
  }

  /// Get lesson content with automatic download and caching
  Future<LessonContent> getLessonContent(String lessonId) async {
    initializeServices();
    return await _retrievalService.getLessonContent(lessonId);
  }

  /// Get specific lesson section
  Future<LessonSection> getLessonSection(String lessonId, String sectionId) async {
    initializeServices();
    return await _navigationService.getLessonSection(lessonId, sectionId);
  }

  /// Get lesson sections in order
  Future<List<LessonSection>> getLessonSections(String lessonId) async {
    initializeServices();
    return await _navigationService.getLessonSections(lessonId);
  }

  /// Get next section in lesson
  Future<LessonSection?> getNextSection(String lessonId, String currentSectionId) async {
    initializeServices();
    return await _navigationService.getNextSection(lessonId, currentSectionId);
  }

  /// Get previous section in lesson
  Future<LessonSection?> getPreviousSection(String lessonId, String currentSectionId) async {
    initializeServices();
    return await _navigationService.getPreviousSection(lessonId, currentSectionId);
  }

  /// Get section progress in lesson
  double getSectionProgress(String lessonId, String currentSectionId) {
    initializeServices();
    return _progressService.getSectionProgress(lessonId, currentSectionId);
  }

  /// Update section progress
  Future<void> updateSectionProgress(String lessonId, String sectionId, double progress) async {
    initializeServices();
    await _progressService.updateSectionProgress(lessonId, sectionId, progress);
  }

  /// Check if lesson has questions
  Future<bool> lessonHasQuestions(String lessonId) async {
    initializeServices();
    return await _navigationService.lessonHasQuestions(lessonId);
  }

  /// Get all question sections from a lesson
  Future<List<LessonSection>> getQuestionSections(String lessonId) async {
    initializeServices();
    return await _navigationService.getQuestionSections(lessonId);
  }

  /// Download lesson content with gzip decompression
  Future<void> downloadLessonContent(String lessonId) async {
    initializeServices();
    await _downloadService.downloadLessonContent(lessonId);
  }

  /// Check if lesson is cached (in local storage or SharedPreferences)
  bool isLessonCached(String lessonId) {
    initializeServices();
    return _downloadService.isLessonCached(lessonId);
  }

  /// Clear old cache with LRU eviction
  Future<void> clearOldCache() async {
    initializeServices();
    await _cacheService.clearOldCache();
  }

  /// Verify cache integrity and handle corruption
  Future<bool> verifyCacheIntegrity(String lessonId) async {
    initializeServices();
    return await _cacheService.verifyCacheIntegrity(lessonId);
  }

  /// Get total cache size (local + SharedPreferences)
  Future<int> getTotalCacheSize() async {
    initializeServices();
    return await _cacheService.getTotalCacheSize();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    initializeServices();
    return await _cacheService.getCacheStats();
  }

  /// Get question for a specific section
  Future<QuestionModel?> getQuestionForSection(String lessonId, String sectionId) async {
    initializeServices();
    return await _questionService.getQuestionForSection(lessonId, sectionId);
  }

  /// Record student answer for a question
  Future<void> recordAnswer(String questionId, int selectedOption, {String? lessonId}) async {
    initializeServices();
    await _questionService.recordAnswer(questionId, selectedOption, lessonId: lessonId);
  }

  /// Check if answer is correct
  bool isAnswerCorrect(String questionId, int selectedOption) {
    initializeServices();
    return _questionService.isAnswerCorrect(questionId, selectedOption);
  }

  /// Get explanation for a question
  String? getExplanation(String questionId) {
    initializeServices();
    return _questionService.getExplanation(questionId);
  }

  /// Check if question has been answered
  Future<bool> isQuestionAnswered(String questionId) async {
    initializeServices();
    return await _questionService.isQuestionAnswered(questionId);
  }

  /// Get answer details for a question
  Future<Map<String, dynamic>?> getAnswerDetails(String questionId) async {
    initializeServices();
    return await _questionService.getAnswerDetails(questionId);
  }

  /// Get all answered questions for a lesson
  Future<List<Map<String, dynamic>>> getAnsweredQuestionsForLesson(String lessonId) async {
    initializeServices();
    return await _questionService.getAnsweredQuestionsForLesson(lessonId);
  }

  /// Clear recorded answers
  Future<bool> clearAnswers() async {
    initializeServices();
    return await _questionService.clearAnswers();
  }

  /// Get recorded answers for parent dashboard
  Future<Map<String, dynamic>> getRecordedAnswers() async {
    initializeServices();
    return await _questionService.getRecordedAnswers();
  }

  // All methods have been moved to the appropriate service files
  // This class now acts as a facade that delegates to the specialized services
}