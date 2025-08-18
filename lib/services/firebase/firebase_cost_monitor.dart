import 'package:shared_preferences/shared_preferences.dart';

/// Simple Firebase cost monitoring service
class FirebaseCostMonitor {
  static const String _firebaseReadKey = 'firebase_reads';
  static const String _firebaseWriteKey = 'firebase_writes';
  
  /// Record Firebase read operation
  static Future<void> recordRead() async {
    await _incrementCounter(_firebaseReadKey);
  }
  
  /// Record Firebase write operation
  static Future<void> recordWrite() async {
    await _incrementCounter(_firebaseWriteKey);
  }
  
  /// Increment counter in SharedPreferences
  static Future<void> _incrementCounter(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, currentCount + 1);
    } catch (e) {
      print('Error incrementing counter: $e');
    }
  }
  
  /// Get Firebase operation counts
  static Future<Map<String, int>> getOperationCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'reads': prefs.getInt(_firebaseReadKey) ?? 0,
        'writes': prefs.getInt(_firebaseWriteKey) ?? 0,
      };
    } catch (e) {
      print('Error getting Firebase operation counts: $e');
      return {'reads': 0, 'writes': 0};
    }
  }
  
  /// Reset all counters
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_firebaseReadKey);
      await prefs.remove(_firebaseWriteKey);
    } catch (e) {
      print('Error resetting counters: $e');
    }
  }
}