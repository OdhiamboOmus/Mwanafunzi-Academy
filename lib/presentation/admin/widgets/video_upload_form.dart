import 'package:flutter/material.dart';
import '../../../data/models/video_metadata.dart';
import '../../shared/grade_selector_widget.dart';

// Video upload form component following Flutter Lite rules (<150 lines)
class VideoUploadForm extends StatefulWidget {
  final String selectedGrade;
  final String selectedSubject;
  final String selectedTopic;
  final Function(String) onGradeChanged;
  final Function(String) onSubjectChanged;
  final Function(String) onTopicChanged;
  final TextEditingController urlController;
  final VideoMetadata? previewMetadata;
  final Function() onUrlValidate;
  final String message;

  const VideoUploadForm({
    super.key,
    required this.selectedGrade,
    required this.selectedSubject,
    required this.selectedTopic,
    required this.onGradeChanged,
    required this.onSubjectChanged,
    required this.onTopicChanged,
    required this.urlController,
    required this.previewMetadata,
    required this.onUrlValidate,
    required this.message,
  });

  @override
  State<VideoUploadForm> createState() => _VideoUploadFormState();
}

class _VideoUploadFormState extends State<VideoUploadForm> {
  static const List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Social Studies', 'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(),
        const SizedBox(height: 24),
        GradeSelectorWidget(
          selectedGrade: widget.selectedGrade,
          onGradeChanged: widget.onGradeChanged,
        ),
        const SizedBox(height: 16),
        _buildSubjectDropdown(),
        const SizedBox(height: 16),
        _buildTopicInput(),
        const SizedBox(height: 16),
        _buildUrlInput(),
        const SizedBox(height: 16),
        if (widget.previewMetadata != null) _buildPreviewSection(),
        const SizedBox(height: 16),
        if (widget.message.isNotEmpty) _buildMessage(),
      ],
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
        'Upload YouTube videos organized by grade, subject, and topic',
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
      value: widget.selectedSubject,
      isExpanded: true,
      underline: Container(),
      items: _subjects.map((subject) => DropdownMenuItem(
        value: subject,
        child: Text(subject),
      )).toList(),
      onChanged: (value) => value != null ? widget.onSubjectChanged(value) : null,
    ),
  );

  Widget _buildTopicInput() => TextField(
    decoration: InputDecoration(
      labelText: 'Topic',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    ),
    onChanged: (value) => widget.onTopicChanged(value),
  );

  Widget _buildUrlInput() => TextField(
    controller: widget.urlController,
    decoration: InputDecoration(
      labelText: 'YouTube Video URL',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
      suffixIcon: IconButton(
        icon: const Icon(Icons.search),
        onPressed: widget.onUrlValidate,
      ),
    ),
    onChanged: (value) {
      if (value.isEmpty) {
        // Clear preview when URL is cleared
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
          if (widget.previewMetadata?.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.previewMetadata!.thumbnailUrl,
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
            widget.previewMetadata?.title.isNotEmpty == true
                ? widget.previewMetadata!.title
                : 'No title available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.previewMetadata?.description.isNotEmpty == true
                ? widget.previewMetadata!.description
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
                widget.previewMetadata?.formattedDuration ?? 'Duration unknown',
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
      color: widget.message.contains('Success') ? Colors.green[50]! : Colors.red[50]!,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: widget.message.contains('Success') ? Colors.green[200]! : Colors.red[200]!,
      ),
    ),
    child: Row(
      children: [
        Icon(
          widget.message.contains('Success') ? Icons.check_circle : Icons.error,
          color: widget.message.contains('Success') ? Colors.green[600]! : Colors.red[600]!,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.message,
            style: TextStyle(
              color: widget.message.contains('Success') ? Colors.green[700]! : Colors.red[700]!,
            ),
          ),
        ),
      ],
    ),
  );
}