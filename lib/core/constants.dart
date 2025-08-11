import 'dart:convert';
import 'package:flutter/services.dart';
import '../presentation/shared/data_constants.dart';

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

  // Load subjects using DataConstants
  static Future<List<String>> loadSubjects() async {
    return Future.value(DataConstants.subjects);
  }

  // Load counties from DataConstants (counties are the keys)
  static Future<List<String>> loadCounties() async {
    final counties = DataConstants.constituencies.keys.toList()..sort();
    return Future.value(counties);
  }

  // Load constituencies using DataConstants
  static Future<Map<String, List<String>>> loadConstituencies() async {
    return Future.value(DataConstants.constituencies);
  }

  // Get constituencies for a specific county
  static Future<List<String>> getConstituenciesForCounty(String county) async {
    final constituencies = DataConstants.constituencies[county] ?? [];
    return Future.value(constituencies);
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use DataConstants directly or AppConstants.loadSubjects() instead')
  static Future<List<String>> loadSubjectsLegacy() async {
    try {
      final String response = await rootBundle.loadString('assets/data/subjects.json');
      final List<dynamic> data = json.decode(response);
      return data.cast<String>();
    } catch (e) {
      // Error loading subjects silently - fallback to static data
      return Future.value(DataConstants.subjects);
    }
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use DataConstants directly or AppConstants.loadConstituencies() instead')
  static Future<Map<String, List<String>>> loadConstituenciesLegacy() async {
    try {
      final String response = await rootBundle.loadString('assets/data/constituencies.json');
      final Map<String, dynamic> data = json.decode(response);
      return data.map((key, value) => MapEntry(key, List<String>.from(value)));
    } catch (e) {
      // Error loading constituencies silently - fallback to static data
      return Future.value(DataConstants.constituencies);
    }
  }
}
