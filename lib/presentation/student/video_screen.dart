import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/core/service_locator.dart' show ServiceLocator;
import 'package:mwanafunzi_academy/data/models/video_model.dart';
import 'package:mwanafunzi_academy/services/firebase/video_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/bottom_navigation_widget.dart';
import 'widgets/video_card.dart';
import 'widgets/video_player_modal.dart';
import '../../utils/video_error_handler.dart';
import '../../utils/video_performance_manager.dart';

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
  final VideoPerformanceManager _performanceManager = VideoPerformanceManager.instance;
  List<VideoModel> _videos = [];
  String _selectedSubject = 'All';
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isOffline = false;
  StreamSubscription<List<VideoModel>>? _videoStreamSubscription;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _initializeVideoStream();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _videoStreamSubscription?.cancel();
    super.dispose();
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
        _buildOfflineIndicator(),
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

  Widget _buildVideoGrid() => VideoPerformanceManager.buildOptimizedVideoList(
    itemCount: _videos.length,
    itemBuilder: (context, index) => VideoCard(
      video: _videos[index],
      onTap: () => _playVideo(_videos[index]),
    ),
    padding: const EdgeInsets.all(16),
    shrinkWrap: false,
    physics: const AlwaysScrollableScrollPhysics(),
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

  /// Initialize real-time video stream
  void _initializeVideoStream() {
    _videoStreamSubscription = _videoService
        .watchVideosByGrade(
          widget.selectedGrade,
          subject: _selectedSubject == 'All' ? null : _selectedSubject,
        )
        .listen(
          (videos) {
            if (mounted) {
              setState(() {
                _videos = videos;
                _isLoading = false;
                _lastSyncTime = DateTime.now();
              });
              
              if (_videos.isEmpty) {
                _errorMessage = _isOffline
                    ? 'No cached videos available offline.'
                    : 'No videos available for this grade and subject.';
              } else {
                _errorMessage = '';
              }
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load videos. Please check your connection.';
              });
            }
            debugPrint('Video stream error: $error');
          },
        );
  }

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final wasOffline = _isOffline;
      _isOffline = connectivity == ConnectivityResult.none;
      
      if (mounted && wasOffline != _isOffline) {
        setState(() {});
        
        // If coming back online, refresh videos
        if (!_isOffline) {
          _loadVideos();
        }
      }
    } catch (e, stackTrace) {
      VideoErrorHandler.handleNetworkError(e, stackTrace, operation: 'checkConnectivity');
    }
  }

  /// Load videos with offline fallback
  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final videos = await _videoService.getVideosByGradeWithOfflineFallback(
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
            _errorMessage = _isOffline
                ? 'No cached videos available. Connect to internet to load videos.'
                : 'No videos available for this grade and subject.';
          });
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = VideoErrorHandler.getUserFriendlyErrorMessage(e);
        });
      }
      
      // Log error for debugging
      VideoErrorHandler.handleVideoLoadError(e, stackTrace,
        videoId: 'unknown',
        operation: 'loadVideos'
      );
    }
  }

  List<String> _getAvailableSubjects() {
    final subjects = <String>{'All'};
    for (final video in _videos) {
      subjects.add(video.subject);
    }
    return subjects.toList()..sort();
  }

  /// Build offline indicator
  Widget _buildOfflineIndicator() {
    if (!_isOffline) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEAA7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: Color(0xFF856404),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Showing cached videos.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF856404),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build last sync indicator
  Widget _buildSyncIndicator() {
    if (_lastSyncTime == null || _isOffline) return const SizedBox.shrink();
    
    final timeAgo = _getTimeAgo(_lastSyncTime!);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.sync,
            color: Color(0xFF50E801),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Last updated: $timeAgo',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Get human-readable time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _playVideo(VideoModel video) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VideoPlayerModal(video: video),
    );
  }
}