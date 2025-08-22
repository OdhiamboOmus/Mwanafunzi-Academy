import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedGrade = '1';
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
            _buildGradeSelector(),
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

  Widget _buildGradeSelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
    ),
    child: InkWell(
      onTap: _showGradeSelector,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grade,
                color: Color(0xFF50E801),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Grade $_selectedGrade',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF6B7280),
            size: 24,
          ),
        ],
      ),
    ),
  );

  void _showGradeSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GradeSelectorBottomSheet(
        selectedGrade: _selectedGrade,
        onGradeSelected: _handleGradeSelected,
      ),
    );
  }

  void _handleGradeSelected(String grade) {
    print('🔍 CONSOLE: Grade selected: $grade'); // Using print instead of debugPrint
    debugPrint('🔍 DEBUG: Grade selected: $grade');
    setState(() {
      _selectedGrade = grade;
    });
    // Don't call Navigator.pop here - the bottom sheet will close automatically
    // The bottom sheet handles its own closing when onTap is called
  }

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
    print('🔍 CONSOLE: _handleFileSelected called with ${jsonData.length} items'); // Using print
    debugPrint('DEBUG: _handleFileSelected called with ${jsonData.length} items');
    
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
      print('🔍 CONSOLE: Lesson validated successfully: ${lesson['title']}'); // Using print
      debugPrint('DEBUG: Lesson validated successfully: ${lesson['title']}');
      
      setState(() {
        _previewLesson = lesson;
        _message = 'Validated lesson: ${lesson['title']}';
      });
    } catch (e) {
      print('🔍 CONSOLE: Lesson validation failed: $e'); // Using print
      debugPrint('DEBUG: Lesson validation failed: $e');
      setState(() {
        _message = 'Error: ${e.toString()}';
        _previewLesson = null;
      });
    }
  }

  Future<void> _uploadLessonContent() async {
    print('🔍 CONSOLE: _uploadLessonContent called'); // Using print
    debugPrint('DEBUG: _uploadLessonContent called');
    print('🔍 CONSOLE: Selected grade: $_selectedGrade'); // Using print
    debugPrint('DEBUG: Selected grade: $_selectedGrade');
    print('🔍 CONSOLE: Preview lesson: ${_previewLesson != null ? _previewLesson!['title'] : "null"}'); // Using print
    debugPrint('DEBUG: Preview lesson: ${_previewLesson != null ? _previewLesson!['title'] : "null"}');
    
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
      print('🔍 CONSOLE: Starting upload process...'); // Using print
      debugPrint('DEBUG: Starting upload process...');
      await AdminLessonService.uploadLessonContent(
        grade: _selectedGrade,
        lesson: _previewLesson!,
      );
      print('🔍 CONSOLE: Upload completed successfully'); // Using print
      debugPrint('DEBUG: Upload completed successfully');
      
      setState(() {
        _isUploading = false;
        _message = 'Successfully uploaded lesson: ${_previewLesson!['title']}';
        _previewLesson = null;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _message = '');
      });
    } catch (e) {
      print('🔍 CONSOLE: Upload failed: $e'); // Using print
      debugPrint('DEBUG: Upload failed: $e');
      setState(() {
        _isUploading = false;
        _message = 'Upload failed: ${e.toString()}';
      });
    }
  }
}

class _GradeSelectorBottomSheet extends StatelessWidget {
  final String selectedGrade;
  final Function(String) onGradeSelected;

  const _GradeSelectorBottomSheet({
    required this.selectedGrade,
    required this.onGradeSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Select Grade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            itemCount: 12,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final grade = (index + 1).toString();
              final isSelected = grade == selectedGrade;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0x1A50E801) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Grade $grade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF50E801) : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF50E801),
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onGradeSelected(grade);
                    Navigator.pop(context);
                  },
                  selected: isSelected,
                  selectedTileColor: Colors.transparent,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}