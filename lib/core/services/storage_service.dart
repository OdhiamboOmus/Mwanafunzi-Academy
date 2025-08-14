import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple storage service for Flutter Lite compliance
/// Uses SharedPreferences with minimal dependencies
class StorageService {
  static const String _cachePrefix = 'mwanafunzi_cache_';
  
  /// Get stored value with error handling
  Future<String?> getValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.getValue error for $key: $e');
      }
      return null;
    }
  }
  
  /// Set stored value with error handling
  Future<bool> setValue(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.setValue error for $key: $e');
      }
      return false;
    }
  }
  
  /// Remove stored value with error handling
  Future<bool> removeValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.removeValue error for $key: $e');
      }
      return false;
    }
  }
  
  /// Get cached data with TTL support
  Future<T?> getCachedData<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    int? ttlSeconds,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final cachedData = await getValue(cacheKey);
      
      if (cachedData == null) return null;
      
      final jsonData = json.decode(cachedData) as Map<String, dynamic>;
      
      // Check TTL if provided
      if (ttlSeconds != null) {
        final cachedAt = jsonData['cachedAt'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (cachedAt == null || (now - cachedAt) > (ttlSeconds * 1000)) {
          await removeValue(cacheKey); // Remove expired cache
          return null;
        }
      }
      
      return fromJson(jsonData['data']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.getCachedData error for $key: $e');
      }
      return null;
    }
  }
  
  /// Set cached data with timestamp
  Future<bool> setCachedData<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final jsonData = {
        'data': toJson(data),
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      return await setValue(cacheKey, json.encode(jsonData));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.setCachedData error for $key: $e');
      }
      return false;
    }
  }
  
  /// Remove cached data
  Future<bool> removeCachedData(String key) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      return await removeValue(cacheKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.removeCachedData error for $key: $e');
      }
      return false;
    }
  }
  
  /// Get all stored keys
  Future<List<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.getAllKeys error: $e');
      }
      return [];
    }
  }

  /// Clear all cached data
  Future<bool> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_cachePrefix)).toList();
      
      bool allRemoved = true;
      for (final key in cacheKeys) {
        final removed = await prefs.remove(key);
        if (!removed) allRemoved = false;
      }
      
      return allRemoved;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ StorageService.clearAllCache error: $e');
      }
      return false;
    }
  }
}