import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mwanafunzi_academy/data/models/video_model.dart';
import '../../../utils/video_error_handler.dart';
import '../../../utils/video_performance_manager.dart';

// VideoPlayerModal following Flutter Lite rules (<150 lines)
class VideoPlayerModal extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerModal({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  final VideoPerformanceManager _performanceManager = VideoPerformanceManager.instance;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _markAsWatched();
    _checkVideoAvailability();
  }

  @override
  void dispose() {
    // Clean up resources
    _performanceManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: EdgeInsets.zero,
    child: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.video.displayTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );

  Widget _buildContent() => _hasError ? _buildErrorState() : _buildVideoPreview();

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
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _hasError = false;
              _errorMessage = '';
            });
            _checkVideoAvailability();
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildVideoPreview() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(widget.video.optimizedThumbnailUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Video Details',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        widget.video.description.isNotEmpty 
            ? widget.video.description 
            : 'No description available',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 16),
      _buildVideoInfo(),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _openYouTubeVideo,
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open in YouTube'),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );

  Widget _buildVideoInfo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade50,
    ),
    child: Column(
      children: [
        _buildInfoRow('Subject', widget.video.displaySubject),
        const SizedBox(height: 8),
        _buildInfoRow('Duration', widget.video.formattedDuration),
        const SizedBox(height: 8),
        _buildInfoRow('Grade', widget.video.grade),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  void _openYouTubeVideo() {
    // In a real implementation, this would use url_launcher or similar
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${widget.video.title} in YouTube...'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _markAsWatched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedKey = 'video_watched_${widget.video.id}';
      await prefs.setBool(watchedKey, true);
      
      // Record cache access for performance tracking
      await _performanceManager.recordCacheAccess(watchedKey, 1);
      
      if (kDebugMode) {
        debugPrint('Video marked as watched: ${widget.video.title}');
      }
    } catch (e) {
      VideoErrorHandler.handleCacheError(e, operation: 'markAsWatched');
    }
  }

  Future<void> _checkVideoAvailability() async {
    try {
      final isUnavailable = await VideoErrorHandler.isVideoUnavailable(widget.video.youtubeId);
      if (isUnavailable) {
        setState(() {
          _hasError = true;
          _errorMessage = 'This video is currently unavailable. Please try again later.';
        });
        return;
      }
    } catch (e) {
      VideoErrorHandler.handleYouTubeError(widget.video.youtubeId, e, operation: 'checkVideoAvailability');
    }
  }

}