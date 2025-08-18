import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mwanafunzi_academy/data/models/video_model.dart';

// VideoCard widget following Flutter Lite rules (<150 lines)
class VideoCard extends StatefulWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final bool isWatched;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.isWatched = false,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scaleAnimation,
    builder: (context, child) => Transform.scale(
      scale: _scaleAnimation.value,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(),
                _buildOverlayContent(),
                if (widget.isWatched) _buildWatchedIndicator(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildThumbnail() => Image.network(
    widget.video.thumbnailUrl,
    fit: BoxFit.cover,
    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) return child;
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: child,
      );
    },
  );

  Widget _buildOverlayContent() => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.displayTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          _buildVideoInfo(),
        ],
      ),
    ),
  );

  Widget _buildVideoInfo() => Row(
    children: [
      Icon(
        Icons.schedule,
        color: Colors.white70,
        size: 12,
      ),
      const SizedBox(width: 4),
      Text(
        widget.video.formattedDuration,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF50E801).withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.video.displaySubject,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );

  Widget _buildWatchedIndicator() => Positioned(
    top: 8,
    right: 8,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 16,
      ),
    ),
  );

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }
}