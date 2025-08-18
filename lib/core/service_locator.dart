import 'package:mwanafunzi_academy/core/services/storage_service.dart';
import 'package:mwanafunzi_academy/services/motivation_service.dart';
import 'package:mwanafunzi_academy/services/user_service.dart';
import 'package:mwanafunzi_academy/services/comment_service.dart';
import 'package:mwanafunzi_academy/services/progress_service.dart';
import 'package:mwanafunzi_academy/services/settings_service.dart';
import 'package:mwanafunzi_academy/services/parent_service.dart';
import 'package:mwanafunzi_academy/services/firebase/firestore_service.dart';
import 'package:mwanafunzi_academy/services/firebase/video_service.dart';
import 'package:mwanafunzi_academy/data/repositories/user_repository.dart';

/// Simple service locator for Flutter Lite compliance
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Services will be registered here
  UserService? _userService;
  MotivationService? _motivationService;
  CommentService? _commentService;
  StorageService? _storageService;
  ProgressService? _progressService;
  SettingsService? _settingsService;
  ParentService? _parentService;
  VideoService? _videoService;

  /// Register services
  void initializeServices({
    UserService? userService,
    MotivationService? motivationService,
    CommentService? commentService,
    StorageService? storageService,
    ProgressService? progressService,
    SettingsService? settingsService,
    ParentService? parentService,
    VideoService? videoService,
  }) {
    _userService = userService;
    _motivationService = motivationService;
    _commentService = commentService;
    _storageService = storageService;
    _progressService = progressService;
    _settingsService = settingsService;
    _parentService = parentService;
    _videoService = videoService;
  }

  /// Get user service
  UserService get userService {
    return _userService ?? _createDefaultUserService();
  }

  /// Get motivation service
  MotivationService get motivationService {
    return _motivationService ?? _createDefaultMotivationService();
  }

  /// Get comment service
  CommentService get commentService {
    return _commentService ?? _createDefaultCommentService();
  }

  /// Get storage service
  StorageService get storageService {
    return _storageService ?? _createDefaultStorageService();
  }

  /// Get progress service
  ProgressService get progressService {
    return _progressService ?? _createDefaultProgressService();
  }

  /// Get settings service
  SettingsService get settingsService {
    return _settingsService ?? _createDefaultSettingsService();
  }

  /// Get parent service
  ParentService get parentService {
    return _parentService ?? _createDefaultParentService();
  }

  /// Get video service
  VideoService get videoService {
    return _videoService ?? _createDefaultVideoService();
  }

  // Create default services for development
  UserService _createDefaultUserService() {
    final storageService = _storageService ?? StorageService();
    final userRepository = UserRepository();
    return UserService(
      userRepository: userRepository,
      storageService: storageService,
    );
  }

  MotivationService _createDefaultMotivationService() {
    final storageService = _storageService ?? StorageService();
    return MotivationService(storageService: storageService);
  }

  StorageService _createDefaultStorageService() {
    return StorageService();
  }

  ProgressService _createDefaultProgressService() {
    final storageService = _storageService ?? StorageService();
    final userRepository = UserRepository();
    return ProgressService(
      storageService: storageService,
      userRepository: userRepository,
    );
  }

  SettingsService _createDefaultSettingsService() {
    final storageService = _storageService ?? StorageService();
    final userRepository = UserRepository();
    return SettingsService(
      storageService: storageService,
      userRepository: userRepository,
    );
  }

  CommentService _createDefaultCommentService() {
    final storageService = _storageService ?? StorageService();
    final userRepository = UserRepository();
    return CommentService(
      storageService: storageService,
      userRepository: userRepository,
    );
  }

  ParentService _createDefaultParentService() {
    final storageService = _storageService ?? StorageService();
    final userRepository = UserRepository();
    final firestoreService = FirestoreService();
    return ParentService(
      userRepository: userRepository,
      firestoreService: firestoreService,
      storageService: storageService,
    );
  }

  VideoService _createDefaultVideoService() {
    return VideoService();
  }

  /// Check if services are initialized
  bool get isInitialized {
    return _userService != null &&
           _motivationService != null &&
           _commentService != null &&
           _storageService != null &&
           _progressService != null &&
           _settingsService != null &&
           _parentService != null &&
           _videoService != null;
  }
}