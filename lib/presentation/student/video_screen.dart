import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/core/service_locator.dart' show ServiceLocator;
import 'package:mwanafunzi_academy/data/models/video_model.dart';
import 'package:mwanafunzi_academy/services/firebase/video_service.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/bottom_navigation_widget.dart';
import 'widgets/video_card.dart';
import 'widgets/video_player_modal.dart';

// VideoScreen following Flutter Lite rules (<150 lines)
class VideoScreen extends StatefulWidget {
  final String selectedGrade;

  const VideoScreen({
    super.key,
    required this.selectedGrade,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoService _videoService = ServiceLocator().videoService;
  List<VideoModel> _videos = [];
  String _selectedSubject = 'All';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Video Learning',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: _buildBody(),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: 2,
      onTabChanged: (index) => Navigator.popUntil(context, (route) => route.isFirst),
    ),
  );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_videos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildGradeSelector(),
        const SizedBox(height: 16),
        _buildSubjectFilter(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildVideoGrid(),
        ),
      ],
    );
  }

  Widget _buildGradeSelector() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GradeSelectorWidget(
      selectedGrade: widget.selectedGrade,
      onGradeChanged: (grade) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/video', arguments: grade);
      },
    ),
  );

  Widget _buildSubjectFilter() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Subject: $_selectedSubject',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
            onSelected: (subject) {
              setState(() {
                _selectedSubject = subject;
                _loadVideos();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Subjects')),
              ..._getAvailableSubjects().map((subject) =>
                PopupMenuItem(value: subject, child: Text(subject))
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildVideoGrid() => GridView.builder(
    key: const ValueKey('video_grid'),
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 16 / 9,
    ),
    itemCount: _videos.length,
    itemBuilder: (context, index) => VideoCard(
      video: _videos[index],
      onTap: () => _playVideo(_videos[index]),
    ),
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadVideos,
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.video_library_outlined,
          color: Color(0xFF6B7280),
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'No videos found',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try selecting a different subject or grade',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    ),
  );

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final videos = await _videoService.getVideosByGrade(
        widget.selectedGrade,
        subject: _selectedSubject == 'All' ? null : _selectedSubject,
      );
      
      if (mounted) {
        setState(() {
          _videos = videos.where((v) => v.isAvailable).toList();
          _isLoading = false;
        });
        
        if (_videos.isEmpty) {
          setState(() {
            _errorMessage = 'No videos available for this grade and subject.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load videos. Please try again.';
        });
      }
    }
  }

  List<String> _getAvailableSubjects() {
    final subjects = <String>{'All'};
    for (final video in _videos) {
      subjects.add(video.subject);
    }
    return subjects.toList()..sort();
  }

  void _playVideo(VideoModel video) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VideoPlayerModal(video: video),
    );
  }
}