import 'package:flutter/material.dart';

// Video welcome section widget following Flutter Lite rules (<150 lines)
class VideoWelcomeSection extends StatelessWidget {
  const VideoWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage uploaded videos by grade and subject',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }
}