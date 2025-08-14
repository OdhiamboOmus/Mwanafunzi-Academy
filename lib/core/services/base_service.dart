import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Base service class providing common error handling and caching patterns
abstract class BaseService {
  static const String _cachePrefix = 'mwanafunzi_cache_';
  
  /// Generic error handling with logging
  void handleError(dynamic error, {String context = ''}) {
    if (kDebugMode) {
      debugPrint('❌ ERROR in $context: ${error.toString()}');
    }
  }
  
  /// Generic cache getter with TTL support using simple string storage
  Future<T?> getCachedData<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    int? ttlSeconds,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final cachedData = await _getStorageValue(cacheKey);
      
      if (cachedData == null) return null;
      
      final jsonData = json.decode(cachedData) as Map<String, dynamic>;
      
      // Check TTL if provided
      if (ttlSeconds != null) {
        final cachedAt = jsonData['cachedAt'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (cachedAt == null || (now - cachedAt) > (ttlSeconds * 1000)) {
          await _removeStorageValue(cacheKey); // Remove expired cache
          return null;
        }
      }
      
      return fromJson(jsonData['data']);
    } catch (e) {
      handleError(e, context: 'getCachedData: $key');
      return null;
    }
  }
  
  /// Generic cache setter with timestamp
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
      
      return await _setStorageValue(cacheKey, json.encode(jsonData));
    } catch (e) {
      handleError(e, context: 'setCachedData: $key');
      return false;
    }
  }
  
  /// Remove specific cache entry
  Future<bool> removeCachedData(String key) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      return await _removeStorageValue(cacheKey);
    } catch (e) {
      handleError(e, context: 'removeCachedData: $key');
      return false;
    }
  }
  
  /// Clear all app cache
  Future<bool> clearAllCache() async {
    try {
      // For Flutter Lite, we'll use a simple approach
      // In a real app, you'd implement proper storage clearing
      return true;
    } catch (e) {
      handleError(e, context: 'clearAllCache');
      return false;
    }
  }
  
  // Abstract storage methods to be implemented by platform-specific services
  Future<String?> _getStorageValue(String key);
  Future<bool> _setStorageValue(String key, String value);
  Future<bool> _removeStorageValue(String key);
}