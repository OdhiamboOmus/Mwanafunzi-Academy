import 'dart:convert';
import 'package:flutter/services.dart';
import '../presentation/shared/data_constants.dart';

class AssetService {
  // Static method to load subjects using DataConstants
  static Future<List<String>> loadSubjects() async {
    // Return static data directly without async loading
    return Future.value(DataConstants.subjects);
  }

  // Static method to load constituencies using DataConstants
  static Future<Map<String, List<String>>> loadConstituencies() async {
    // Return static data directly without async loading
    return Future.value(DataConstants.constituencies);
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use loadSubjects() or loadConstituencies() instead')
  static Future<List<String>> loadSubjectsLegacy() async {
    try {
      final String response = await rootBundle.loadString('assets/data/subjects.json');
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      return List<String>.from(data);
    } catch (e) {
      return Future.value(DataConstants.subjects);
    }
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use loadSubjects() or loadConstituencies() instead')
  static Future<Map<String, List<String>>> loadConstituenciesLegacy() async {
    try {
      final String response = await rootBundle.loadString('assets/data/constituencies.json');
      final Map<String, dynamic> data = json.decode(response) as Map<String, dynamic>;
      return Map<String, List<String>>.from(
        data.map((key, value) => MapEntry(key, List<String>.from(value))),
      );
    } catch (e) {
      return Future.value(DataConstants.constituencies);
    }
  }
}