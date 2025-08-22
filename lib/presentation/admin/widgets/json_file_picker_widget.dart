import 'package:flutter/material.dart';
import '../../../../shared/file_picker_util.dart';
import '../../../services/firebase/admin_lesson_service.dart';

// JSON file picker widget following Flutter Lite rules (<150 lines)
class JsonFilePickerWidget extends StatelessWidget {
  final Function(List<Map<String, dynamic>>) onFileSelected;
  final String currentMessage;

  const JsonFilePickerWidget({
    super.key,
    required this.onFileSelected,
    required this.currentMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.file_upload_outlined, color: Color(0xFF50E801), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Select JSON file with lesson content', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _pickJsonFile(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50E801),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Select JSON File'),
          ),
          if (currentMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(currentMessage, style: TextStyle(
              color: currentMessage.contains('Success') ? Colors.green[700]! : Colors.red[700]!,
              fontSize: 12,
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _pickJsonFile(BuildContext context) async {
    debugPrint('🔍 DEBUG: _pickJsonFile called');
    try {
      // Pick JSON file from device
      debugPrint('🔍 DEBUG: Calling FilePickerUtil.pickJsonFile...');
      final jsonData = await FilePickerUtil.pickJsonFile(context);
      debugPrint('🔍 DEBUG: FilePickerUtil returned ${jsonData.length} items');
      
      if (jsonData.isEmpty) {
        debugPrint('🔍 DEBUG: No valid JSON data returned');
        onFileSelected([]);
        return;
      }

      debugPrint('🔍 DEBUG: First item keys: ${jsonData.first.keys}');
      debugPrint('🔍 DEBUG: First item content: ${jsonData.first.toString()}');

      // Validate lesson JSON structure (use lesson validation instead of quiz validation)
      debugPrint('🔍 DEBUG: Validating lesson JSON...');
      final lesson = AdminLessonService.validateLessonJson(jsonData.first);
      debugPrint('🔍 DEBUG: Lesson validation successful: ${lesson['title']}');
      
      // Convert single lesson to list for compatibility
      onFileSelected([lesson]);
    } catch (e) {
      debugPrint('🔍 DEBUG: Error in _pickJsonFile: $e');
      debugPrint('🔍 DEBUG: Error type: ${e.runtimeType}');
      debugPrint('🔍 DEBUG: Error stack: ${e.toString()}');
      onFileSelected([]);
    }
  }
}