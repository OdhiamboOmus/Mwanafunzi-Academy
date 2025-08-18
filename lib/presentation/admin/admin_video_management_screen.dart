import 'package:flutter/material.dart';
import '../../data/models/video_model.dart';
import '../../core/service_locator.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/widgets.dart';
import 'widgets/video_list_widget.dart';
import 'widgets/empty_video_state.dart';
import 'widgets/video_message_widget.dart';
import 'widgets/video_welcome_section.dart';

// Admin video management screen following Flutter Lite rules (<150 lines)
class AdminVideoManagementScreen extends StatefulWidget {
  const AdminVideoManagementScreen({super.key});

  @override
  State<AdminVideoManagementScreen> createState() => _AdminVideoManagementScreenState();
}

class _AdminVideoManagementScreenState extends State<AdminVideoManagementScreen> {
  String _selectedGrade = 'Grade 1';
  String _selectedSubject = 'Mathematics';
  List<VideoModel> _videos = [];
  bool _isLoading = false;
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
          'Manage Videos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VideoWelcomeSection(),
            const SizedBox(height: 24),
            GradeSelectorWidget(
              selectedGrade: _selectedGrade,
              onGradeChanged: _handleGradeChanged,
            ),
            const SizedBox(height: 16),
            _buildSubjectDropdown(),
            const SizedBox(height: 16),
            BrandButton(
              text: 'Load Videos',
              onPressed: _loadVideos,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty) VideoMessageWidget(message: _message),
            const SizedBox(height: 16),
            if (_videos.isNotEmpty) VideoListWidget(
              videos: _videos,
              onVideoAction: _handleVideoAction,
            ),
            if (_videos.isEmpty && !_isLoading && _message.isEmpty) const EmptyVideoState(),
          ],
        ),
      ),
    );
  }

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
      items: const [
        DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
        DropdownMenuItem(value: 'Science', child: Text('Science')),
        DropdownMenuItem(value: 'English', child: Text('English')),
        DropdownMenuItem(value: 'Social Studies', child: Text('Social Studies')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ].toList(),
      onChanged: (value) => setState(() => _selectedSubject = value!),
    ),
  );

  void _handleGradeChanged(String grade) {
    setState(() {
      _selectedGrade = grade;
      _videos = [];
      _message = '';
    });
  }

  void _loadVideos() async {
    setState(() {
      _isLoading = true;
      _message = '';
      _videos = [];
    });

    try {
      final videoService = ServiceLocator().videoService;
      final videos = await videoService.getVideosByGrade(_selectedGrade, subject: _selectedSubject);

      setState(() {
        _videos = videos.where((v) => v.isAvailable).toList();
        _isLoading = false;
        _message = _videos.isEmpty ? 'No videos found for this selection' : 'Loaded ${_videos.length} videos';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Failed to load videos: ${e.toString()}';
      });
    }
  }

  void _handleVideoAction(String action, VideoModel video) {
    switch (action) {
      case 'edit':
        _showEditDialog(video);
        break;
      case 'delete':
        _showDeleteConfirmation(video);
        break;
    }
  }

  void _showEditDialog(VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Video'),
        content: Text('Edit functionality for "${video.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement edit functionality
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVideo(video);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(VideoModel video) async {
    try {
      final videoService = ServiceLocator().videoService;
      
      await videoService.deleteVideo(video.id, video.grade, video.subject, video.topic);

      setState(() {
        _videos.removeWhere((v) => v.id == video.id);
        _message = 'Video deleted successfully';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _message = '');
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to delete video: ${e.toString()}';
      });
    }
  }
}