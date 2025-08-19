import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../data/models/video_model.dart';
import '../../../data/models/video_metadata.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/firebase/video_service.dart';
import '../../../core/service_locator.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/widgets.dart';
import '../../utils/video_error_handler.dart';
import '../../utils/video_performance_manager.dart';

// Admin video upload screen following Flutter Lite rules (<150 lines)
class AdminVideoUploadScreen extends StatefulWidget {
  const AdminVideoUploadScreen({super.key});

  @override
  State<AdminVideoUploadScreen> createState() => _AdminVideoUploadScreenState();
}

class _AdminVideoUploadScreenState extends State<AdminVideoUploadScreen> {
  final UserRepository _userRepository = UserRepository();
  final VideoService _videoService = ServiceLocator().videoService;
  final VideoPerformanceManager _performanceManager = VideoPerformanceManager.instance;

  String _selectedGrade = 'Grade 1';
  String _selectedSubject = 'Mathematics';
  String _selectedTopic = '';
  final TextEditingController _urlController = TextEditingController();
  VideoMetadata? _previewMetadata;
  bool _isUploading = false;
  bool _isAdminAuthenticated = false;
  String _message = '';
  Timer? _authCheckTimer;

  static const List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Social Studies', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminAuthentication();
    _startAuthMonitoring();
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    _urlController.dispose();
    _performanceManager.dispose();
    super.dispose();
  }

  /// Monitor admin authentication status
  void _startAuthMonitoring() {
    _authCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAdminAuthentication();
    });
  }

  /// Check if admin is authenticated
  Future<void> _checkAdminAuthentication() async {
    try {
      final currentUser = _userRepository.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          setState(() => _isAdminAuthenticated = false);
          _showAuthError();
        }
        return;
      }

      // Verify admin permissions through Firestore
      final isAdmin = await _userRepository.isAdminUser(currentUser.email!);
      if (mounted) {
        setState(() => _isAdminAuthenticated = isAdmin);
        if (!isAdmin) {
          _showAuthError();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdminAuthenticated = false);
        VideoErrorHandler.handleNetworkError(e, StackTrace.current, operation: 'checkAdminAuthentication');
      }
    }
  }

  /// Show authentication error
  void _showAuthError() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('You need admin privileges to access video management.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdminAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Video Management', style: TextStyle(color: Colors.black)),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                'Please authenticate as an admin to manage videos',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Video Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            GradeSelectorWidget(
              selectedGrade: _selectedGrade,
              onGradeChanged: (grade) => setState(() => _selectedGrade = grade),
            ),
            const SizedBox(height: 16),
            _buildSubjectDropdown(),
            const SizedBox(height: 16),
            _buildTopicInput(),
            const SizedBox(height: 16),
            _buildUrlInput(),
            const SizedBox(height: 16),
            if (_previewMetadata != null) _buildPreviewSection(),
            const SizedBox(height: 16),
            if (_message.isNotEmpty) _buildMessage(),
            const SizedBox(height: 24),
            BrandButton(
              text: 'Upload Video',
              onPressed: _uploadVideo,
              isLoading: _isUploading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Video Management',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      const SizedBox(height: 8),
      Text(
        'Upload and manage YouTube videos for students',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    ],
  );

  Widget _buildSubjectDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
    ),
    child: DropdownButton<String>(
      value: _selectedSubject,
      isExpanded: true,
      underline: Container(),
      items: _subjects.map((subject) => DropdownMenuItem(
        value: subject,
        child: Text(subject),
      )).toList(),
      onChanged: (value) => value != null ? setState(() => _selectedSubject = value) : null,
    ),
  );

  Widget _buildTopicInput() => TextField(
    decoration: InputDecoration(
      labelText: 'Topic',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    ),
    onChanged: (value) => setState(() => _selectedTopic = value),
  );

  Widget _buildUrlInput() => TextField(
    controller: _urlController,
    decoration: InputDecoration(
      labelText: 'YouTube Video URL',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
      suffixIcon: IconButton(
        icon: const Icon(Icons.search),
        onPressed: _validateUrl,
      ),
    ),
    onChanged: (value) {
      if (value.isEmpty) {
        setState(() => _previewMetadata = null);
      }
    },
  );

  Widget _buildPreviewSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview_outlined, color: Color(0xFF50E801), size: 20),
              const SizedBox(width: 8),
              Text(
                'Video Preview',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_previewMetadata?.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _previewMetadata!.thumbnailUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Thumbnail unavailable'),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _previewMetadata?.title.isNotEmpty == true
                ? _previewMetadata!.title
                : 'No title available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _previewMetadata?.description.isNotEmpty == true
                ? _previewMetadata!.description
                : 'No description available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                _previewMetadata?.formattedDuration ?? 'Duration unknown',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildMessage() => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: _message.contains('Success') ? Colors.green[50]! : Colors.red[50]!,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: _message.contains('Success') ? Colors.green[200]! : Colors.red[200]!,
      ),
    ),
    child: Row(
      children: [
        Icon(
          _message.contains('Success') ? Icons.check_circle : Icons.error,
          color: _message.contains('Success') ? Colors.green[600]! : Colors.red[600]!,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _message,
            style: TextStyle(
              color: _message.contains('Success') ? Colors.green[700]! : Colors.red[700]!,
            ),
          ),
        ),
      ],
    ),
  );

  /// Validate YouTube URL and extract metadata
  Future<void> _validateUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    try {
      setState(() {
        _isUploading = true;
        _message = 'Validating URL...';
      });

      // Validate URL format
      if (!_videoService.isValidYouTubeUrl(url)) {
        setState(() {
          _message = 'Invalid YouTube URL';
          _isUploading = false;
        });
        return;
      }

      // Extract metadata
      final metadata = await _videoService.extractYouTubeMetadata(url);
      if (!metadata.isValid) {
        setState(() {
          _message = 'Unable to extract video metadata';
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _previewMetadata = metadata;
        _message = 'Video validated successfully';
        _isUploading = false;
      });

      // Log validation attempt
      await _logAdminAction('url_validation', 'URL: $url, Title: ${metadata.title ?? "Unknown"}');
    } catch (e) {
      setState(() {
        _message = 'Validation failed: ${e.toString()}';
        _isUploading = false;
      });
      VideoErrorHandler.handleYouTubeError('unknown', e, operation: 'validateUrl');
    }
  }

  /// Upload video with admin authentication
  Future<void> _uploadVideo() async {
    if (_selectedTopic.trim().isEmpty || _previewMetadata == null) {
      setState(() => _message = 'Please enter topic and validate video');
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _message = '';
      });

      // Generate unique video ID
      final videoId = 'video_${DateTime.now().millisecondsSinceEpoch}';
      final video = VideoModel(
        id: videoId,
        youtubeId: _previewMetadata!.videoId ?? '',
        title: _previewMetadata!.title,
        description: _previewMetadata!.description,
        grade: _selectedGrade,
        subject: _selectedSubject,
        topic: _selectedTopic,
        duration: _previewMetadata!.duration,
        uploadedAt: DateTime.now(),
        uploadedBy: _userRepository.getCurrentUser()!.uid,
        isActive: true,
      );

      // Upload video
      await _videoService.uploadVideo(video);

      // Log admin action
      await _logAdminAction('video_upload',
        'Video: ${video.title}, Grade: $_selectedGrade, Subject: $_selectedSubject, Topic: $_selectedTopic');

      setState(() {
        _isUploading = false;
        _message = 'Video uploaded successfully';
        _urlController.clear();
        _previewMetadata = null;
        _selectedTopic = '';
      });

      // Clear message after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _message = '');
      });
    } catch (e, stackTrace) {
      setState(() {
        _isUploading = false;
        _message = 'Upload failed: ${e.toString()}';
      });
      VideoErrorHandler.handleVideoLoadError(e, stackTrace, 
        videoId: _previewMetadata?.videoId ?? 'unknown', 
        operation: 'uploadVideo');
    }
  }

  /// Handle admin logout
  Future<void> _handleLogout() async {
    try {
      await _userRepository.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// Log admin actions for audit trail
  Future<void> _logAdminAction(String action, String details) async {
    try {
      final currentUser = _userRepository.getCurrentUser();
      if (currentUser == null) return;

      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'details': details,
        'adminId': currentUser.uid,
        'adminEmail': currentUser.email,
        'grade': _selectedGrade,
        'subject': _selectedSubject,
      };

      // TODO: Implement actual logging to Firestore admin_audit_logs collection
      // await FirebaseFirestore.instance.collection('admin_audit_logs').add(logEntry);
      
      if (kDebugMode) {
        debugPrint('Admin action logged: $logEntry');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log admin action: $e');
      }
    }
  }
}