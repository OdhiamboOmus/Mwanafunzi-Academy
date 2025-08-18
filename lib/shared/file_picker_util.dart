import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// File picker utility following Flutter Lite rules (<150 lines)
class FilePickerUtil {
  /// Pick JSON file from device and return parsed content
  static Future<List<Map<String, dynamic>>> pickJsonFile(BuildContext context) async {
    try {
      // Use file picker from storage
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('File content is empty');
      }

      // Parse JSON content
      final content = utf8.decode(file.bytes!);
      final jsonData = jsonDecode(content) as List;

      if (jsonData.isEmpty) {
        throw Exception('JSON file is empty');
      }

      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
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