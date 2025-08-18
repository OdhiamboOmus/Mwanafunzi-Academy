import 'package:flutter/material.dart';
import '../../../../shared/file_picker_util.dart';

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
                child: Text('Select JSON file with quiz questions', style: TextStyle(fontSize: 14)),
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
    try {
      // Pick JSON file from device
      final jsonData = await FilePickerUtil.pickJsonFile(context);
      
      // Validate JSON structure
      final validJson = FilePickerUtil.validateQuizJson(jsonData);
      
      onFileSelected(validJson);
    } catch (e) {
      onFileSelected([]);
    }
  }
}