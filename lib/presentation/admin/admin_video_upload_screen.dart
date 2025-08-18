import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/utils/youtube_utils.dart';
import 'widgets/video_upload_form.dart';
import '../../data/models/video_model.dart';
import '../../data/models/video_metadata.dart';
import '../../core/service_locator.dart';
import '../shared/widgets.dart';

// Admin video upload screen following Flutter Lite rules (<150 lines)
class AdminVideoUploadScreen extends StatefulWidget {
  const AdminVideoUploadScreen({super.key});

  @override
  State<AdminVideoUploadScreen> createState() => _AdminVideoUploadScreenState();
}

class _AdminVideoUploadScreenState extends State<AdminVideoUploadScreen> {
  String _selectedGrade = 'Grade 1';
  String _selectedSubject = 'Mathematics';
  String _selectedTopic = '';
  final TextEditingController _urlController = TextEditingController();
  VideoMetadata? _previewMetadata;
  bool _isUploading = false;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Video Content',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VideoUploadForm(
              selectedGrade: _selectedGrade,
              selectedSubject: _selectedSubject,
              selectedTopic: _selectedTopic,
              onGradeChanged: _handleGradeChanged,
              onSubjectChanged: _handleSubjectChanged,
              onTopicChanged: _handleTopicChanged,
              urlController: _urlController,
              previewMetadata: _previewMetadata,
              onUrlValidate: _validateUrl,
              message: _message,
            ),
            const SizedBox(height: 16),
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

  void _handleGradeChanged(String grade) {
    setState(() => _selectedGrade = grade);
  }

  void _handleSubjectChanged(String subject) {
    setState(() => _selectedSubject = subject);
  }

  void _handleTopicChanged(String topic) {
    setState(() => _selectedTopic = topic);
  }

  void _validateUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _message = 'Validating URL...';
    });

    try {
      final videoId = YouTubeUtils.extractVideoId(url);
      if (videoId == null) {
        setState(() {
          _message = 'Invalid YouTube URL';
          _previewMetadata = null;
        });
        return;
      }

      final metadata = await VideoMetadata.fromYouTubeUrl(url);
      setState(() {
        _previewMetadata = metadata;
        _message = metadata.isValid ? 'URL validated successfully' : 'Invalid video';
      });
    } catch (e) {
      setState(() {
        _message = 'Error validating URL: ${e.toString()}';
        _previewMetadata = null;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedTopic.trim().isEmpty) {
      setState(() => _message = 'Please enter a topic');
      return;
    }

    if (_urlController.text.trim().isEmpty) {
      setState(() => _message = 'Please enter a YouTube URL');
      return;
    }

    if (_previewMetadata == null || !_previewMetadata!.isValid) {
      setState(() => _message = 'Please validate a valid YouTube URL first');
      return;
    }

    setState(() {
      _isUploading = true;
      _message = '';
    });

    try {
      final videoService = ServiceLocator().videoService;
      final video = VideoModel(
        id: 'video_${DateTime.now().millisecondsSinceEpoch}',
        youtubeId: _previewMetadata!.videoId!,
        title: _previewMetadata!.title.isNotEmpty ? _previewMetadata!.title : 'Untitled Video',
        description: _previewMetadata!.description,
        grade: _selectedGrade,
        subject: _selectedSubject,
        topic: _selectedTopic,
        duration: _previewMetadata!.duration,
        uploadedAt: DateTime.now(),
        uploadedBy: 'admin_user', // This should come from actual user authentication
        isActive: true,
      );

      await videoService.uploadVideo(video);

      setState(() {
        _isUploading = false;
        _message = 'Video uploaded successfully';
        _urlController.clear();
        _previewMetadata = null;
        _selectedTopic = '';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _message = '');
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _message = 'Upload failed: ${e.toString()}';
      });
    }
  }
}