import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// File picker utility following Flutter Lite rules (<150 lines)
class FilePickerUtil {
  /// Pick JSON file from device and return parsed content
  static Future<List<Map<String, dynamic>>> pickJsonFile(BuildContext context) async {
    try {
      debugPrint('🔍 DEBUG: FilePickerUtil.pickJsonFile - Starting file picker');
      // Use file picker from storage
      debugPrint('🔍 DEBUG: Opening file picker dialog...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      debugPrint('🔍 DEBUG: File picker result: ${result?.toString() ?? "null"}');

      if (result == null || result.files.isEmpty) {
        debugPrint('🔍 DEBUG: FilePickerUtil - No file selected');
        throw Exception('No file selected');
      }

      final file = result.files.first;
      debugPrint('🔍 DEBUG: FilePickerUtil - File selected: ${file.name}');
      debugPrint('🔍 DEBUG: File size: ${file.size} bytes');
      debugPrint('🔍 DEBUG: File bytes available: ${file.bytes != null}');
      
      if (file.bytes == null) {
        debugPrint('🔍 DEBUG: FilePickerUtil - File content is empty');
        throw Exception('File content is empty');
      }

      // Parse JSON content
      debugPrint('🔍 DEBUG: Decoding file content...');
      final content = utf8.decode(file.bytes!);
      debugPrint('🔍 DEBUG: Decoded content length: ${content.length}');
      debugPrint('🔍 DEBUG: First 200 chars: ${content.substring(0, content.length > 200 ? 200 : content.length)}');
      
      try {
        debugPrint('🔍 DEBUG: Parsing JSON...');
        final jsonData = jsonDecode(content) as List;
        debugPrint('🔍 DEBUG: FilePickerUtil - JSON decoded successfully with ${jsonData.length} items');

        if (jsonData.isEmpty) {
          debugPrint('🔍 DEBUG: JSON array is empty');
          throw Exception('JSON file is empty');
        }

        debugPrint('🔍 DEBUG: First item keys: ${jsonData.first.keys}');
        debugPrint('🔍 DEBUG: First item preview: ${jsonData.first.toString().substring(0, jsonData.first.toString().length > 200 ? 200 : jsonData.first.toString().length)}');

        return jsonData.cast<Map<String, dynamic>>();
      } catch (jsonError) {
        debugPrint('🔍 DEBUG: FilePickerUtil - JSON decode error: $jsonError');
        debugPrint('🔍 DEBUG: FilePickerUtil - Content preview: ${content.substring(0, content.length > 200 ? 200 : content.length)}');
        throw Exception('Invalid JSON format: ${jsonError.toString()}');
      }
    } catch (e) {
      debugPrint('🔍 DEBUG: FilePickerUtil - Error: $e');
      debugPrint('🔍 DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Error reading file: ${e.toString()}');
    }
  }

  /// Validate JSON structure for quiz questions
  static List<Map<String, dynamic>> validateQuizJson(List<Map<String, dynamic>> jsonData) {
    final validData = <Map<String, dynamic>>[];

    for (int i = 0; i < jsonData.length; i++) {
      final question = jsonData[i];
      
      // Validate required fields
      if (question['question'] == null || question['question'] is! String) {
        throw Exception('Invalid question text at index $i');
      }
      
      if (question['options'] == null || question['options'] is! List) {
        throw Exception('Invalid options at index $i');
      }
      
      final options = question['options'] as List;
      if (options.length != 4 || !options.every((opt) => opt is String)) {
        throw Exception('Each question must have exactly 4 string options at index $i');
      }
      
      if (question['correctAnswerIndex'] == null ||
          question['correctAnswerIndex'] is! int ||
          question['correctAnswerIndex'] < 0 ||
          question['correctAnswerIndex'] >= 4) {
        throw Exception('Invalid correctAnswerIndex at index $i');
      }
      
      if (question['explanation'] == null || question['explanation'] is! String) {
        throw Exception('Invalid explanation at index $i');
      }

      validData.add(question);
    }

    return validData;
  }
}