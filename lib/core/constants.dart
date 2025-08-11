import 'dart:convert';
import 'package:flutter/services.dart';

// Consolidated app constants following Flutter Lite rules
class AppConstants {
  // Brand color
  static const Color brandColor = Color(0xFF50E801);

  // User types
  static const String userTypeStudent = 'student';
  static const String userTypeParent = 'parent';
  static const String userTypeTeacher = 'teacher';
  static const String userTypeAdmin = 'admin';

  // Form validation patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[\d\s-]{10,15}$';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double formFieldHeight = 56.0;
  static const double borderRadius = 8.0;

  // Gender options
  static const List<String> genders = ['Male', 'Female'];

  // Days of the week
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // JSON asset paths
  static const String subjectsJsonPath = 'assets/data/subjects.json';
  static const String constituenciesJsonPath =
      'assets/data/constituencies.json';

  // Load subjects from JSON
  static Future<List<String>> loadSubjects() async {
    try {
      final String response = await rootBundle.loadString(subjectsJsonPath);
      final List<dynamic> data = json.decode(response);
      return data.cast<String>();
    } catch (e) {
      print('Error loading subjects: $e');
      return ['Mathematics', 'English', 'Kiswahili', 'Science']; // Fallback
    }
  }

  // Load counties from constituencies JSON (counties are the keys)
  static Future<List<String>> loadCounties() async {
    try {
      final constituencies = await loadConstituencies();
      return constituencies.keys.toList()..sort();
    } catch (e) {
      print('Error loading counties: $e');
      return ['Nairobi', 'Kiambu', 'Nakuru', 'Mombasa']; // Fallback
    }
  }

  // Load constituencies from JSON (organized by county)
  static Future<Map<String, List<String>>> loadConstituencies() async {
    try {
      final String response = await rootBundle.loadString(
        constituenciesJsonPath,
      );
      final Map<String, dynamic> data = json.decode(response);
      return data.map((key, value) => MapEntry(key, List<String>.from(value)));
    } catch (e) {
      print('Error loading constituencies: $e');
      return {
        'Nairobi': ['Westlands', 'Starehe', 'Langata'],
        'Kiambu': ['Kiambu', 'Ruiru', 'Thika Town'],
      }; // Fallback
    }
  }

  // Get constituencies for a specific county
  static Future<List<String>> getConstituenciesForCounty(String county) async {
    try {
      final constituencies = await loadConstituencies();
      return constituencies[county] ?? [];
    } catch (e) {
      print('Error loading constituencies for county: $e');
      return [];
    }
  }
}
