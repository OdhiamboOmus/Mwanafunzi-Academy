import 'package:flutter/material.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/widgets.dart';
import '../../services/firebase/admin_lesson_service.dart';
import 'widgets/json_file_picker_widget.dart';

// Admin lesson upload screen following Flutter Lite rules (<150 lines)
class AdminLessonUploadScreen extends StatefulWidget {
  const AdminLessonUploadScreen({super.key});

  @override
  State<AdminLessonUploadScreen> createState() => _AdminLessonUploadScreenState();
}

class _AdminLessonUploadScreenState extends State<AdminLessonUploadScreen> {
  String _selectedGrade = 'Grade 1';
  Map<String, dynamic>? _previewLesson;
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
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text(
          'Upload Lesson Content', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)
        ),
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
            JsonFilePickerWidget(
              onFileSelected: _handleFileSelected,
              currentMessage: _message,
            ),
            const SizedBox(height: 16),
            if (_previewLesson != null) _buildPreviewSection(),
            const SizedBox(height: 16),
            BrandButton(
              text: 'Upload Lesson Content',
              onPressed: _uploadLessonContent,
              isLoading: _isUploading,
            ),
            if (_message.isNotEmpty && !_message.contains('Validated')) _buildMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Lesson Management', 
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)
      ),
      const SizedBox(height: 8),
      Text(
        'Upload lesson content in JSON format', 
        style: TextStyle(fontSize: 16, color: Colors.grey[600])
      ),
    ],
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
                'Lesson Preview', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLessonInfo(),
          const SizedBox(height: 16),
          _buildSectionsList(),
        ],
      ),
    ),
  );

  Widget _buildLessonInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Lesson ID: ${_previewLesson!['lessonId']}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Title: ${_previewLesson!['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Subject: ${_previewLesson!['subject']}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Topic: ${_previewLesson!['topic']}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Sections: ${(_previewLesson!['sections'] as List).length}', style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildSectionsList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Sections:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...(_previewLesson!['sections'] as List).asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Section ${index + 1}: ${section['type']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (section['title']?.isNotEmpty == true) Text('Title: ${section['title']}'),
                  if (section['content']?.isNotEmpty == true) Text('Content: ${(section['content'] as String).substring(0, (section['content'] as String).length > 50 ? 50 : (section['content'] as String).length)}...'),
                  if (section['media']?.isNotEmpty == true) Text('Media: ${(section['media'] as List).join(', ')}'),
                ],
              ),
            ),
          ),
        );
      }),
    ],
  );

  Widget _buildMessage() => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: _message.contains('Success') ? Colors.green[50]! : Colors.red[50]!,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _message.contains('Success') ? Colors.green[200]! : Colors.red[200]!),
    ),
    child: Row(
      children: [
        Icon(
          _message.contains('Success') ? Icons.check_circle : Icons.error, 
          color: _message.contains('Success') ? Colors.green[600]! : Colors.red[600]!, 
          size: 20
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _message, 
            style: TextStyle(
              color: _message.contains('Success') ? Colors.green[700]! : Colors.red[700]!
            )
          ),
        ),
      ],
    ),
  );

  void _handleFileSelected(List<Map<String, dynamic>> jsonData) {
    if (jsonData.isEmpty) {
      setState(() {
        _message = 'Error: Invalid file format';
        _previewLesson = null;
      });
      return;
    }

    try {
      // Validate lesson content
      final lesson = AdminLessonService.validateLessonJson(jsonData.first);
      
      setState(() {
        _previewLesson = lesson;
        _message = 'Validated lesson: ${lesson['title']}';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _previewLesson = null;
      });
    }
  }

  Future<void> _uploadLessonContent() async {
    if (_previewLesson == null) {
      setState(() => _message = 'Please validate lesson content first');
      return;
    }

    setState(() {
      _isUploading = true;
      _message = '';
    });

    try {
      // Use AdminLessonService for upload
      await AdminLessonService.uploadLessonContent(
        grade: _selectedGrade,
        lesson: _previewLesson!,
      );
      
      setState(() {
        _isUploading = false;
        _message = 'Successfully uploaded lesson: ${_previewLesson!['title']}';
        _previewLesson = null;
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