import 'package:flutter/material.dart';
import '../../data/models/quiz_model.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/widgets.dart';
import '../../services/firebase/admin_quiz_service.dart';
import 'widgets/question_editor_widget.dart';
import 'widgets/json_file_picker_widget.dart';

// Simplified admin quiz upload screen following Flutter Lite rules (<150 lines)
class AdminQuizUploadScreen extends StatefulWidget {
  const AdminQuizUploadScreen({super.key});

  @override
  State<AdminQuizUploadScreen> createState() => _AdminQuizUploadScreenState();
}

class _AdminQuizUploadScreenState extends State<AdminQuizUploadScreen> {
  String _selectedGrade = 'Grade 1';
  String _selectedSubject = 'Mathematics';
  String _selectedTopic = '';
  List<QuizQuestion> _previewQuestions = [];
  bool _isUploading = false;
  String _message = '';

  static const List<String> _subjects = [
    'Mathematics', 'English', 'Science', 'Social Studies', 'Kiswahili', 'Creative Arts',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Upload Quiz Content', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
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
            JsonFilePickerWidget(
              onFileSelected: _handleFileSelected,
              currentMessage: _message,
            ),
            const SizedBox(height: 16),
            if (_previewQuestions.isNotEmpty) _buildPreviewSection(),
            const SizedBox(height: 16),
            BrandButton(
              text: 'Upload Quiz Content',
              onPressed: _uploadQuizContent,
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
      const Text('Quiz Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
      const SizedBox(height: 8),
      Text('Upload quiz questions in JSON format', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
      onChanged: (value) => setState(() => _selectedSubject = value!),
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
              Text('Preview (${_previewQuestions.length} questions)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _previewQuestions.length,
            itemBuilder: (context, index) => QuestionEditorWidget(
              question: _previewQuestions[index],
              index: index,
              onQuestionUpdated: (updatedQuestion) => setState(() => _previewQuestions[index] = updatedQuestion),
            ),
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
      border: Border.all(color: _message.contains('Success') ? Colors.green[200]! : Colors.red[200]!),
    ),
    child: Row(
      children: [
        Icon(_message.contains('Success') ? Icons.check_circle : Icons.error, 
              color: _message.contains('Success') ? Colors.green[600]! : Colors.red[600]!, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(_message, style: TextStyle(color: _message.contains('Success') ? Colors.green[700]! : Colors.red[700]!))),
      ],
    ),
  );

  void _handleFileSelected(List<Map<String, dynamic>> jsonData) {
    if (jsonData.isEmpty) {
      setState(() {
        _message = 'Error: Invalid file format';
        _previewQuestions = [];
      });
      return;
    }

    try {
      // Convert to QuizQuestion objects
      final validQuestions = jsonData.map((q) => QuizQuestion.fromJson(q)).toList();
      
      setState(() {
        _previewQuestions = validQuestions;
        _message = 'Validated ${validQuestions.length} questions';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _previewQuestions = [];
      });
    }
  }

  Future<void> _uploadQuizContent() async {
    if (_selectedTopic.trim().isEmpty || _previewQuestions.isEmpty) {
      setState(() => _message = 'Please enter topic and validate questions');
      return;
    }

    setState(() {
      _isUploading = true;
      _message = '';
    });

    try {
      // Use AdminQuizService for upload
      await AdminQuizService.uploadQuizContent(
        grade: _selectedGrade,
        subject: _selectedSubject,
        topic: _selectedTopic,
        questions: _previewQuestions,
      );
      
      // Clear cache for this topic
      await AdminQuizService.clearTopicCache(
        grade: _selectedGrade,
        subject: _selectedSubject,
        topic: _selectedTopic,
      );
      
      setState(() {
        _isUploading = false;
        _message = 'Successfully uploaded ${_previewQuestions.length} questions';
        _previewQuestions = [];
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