import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';

/// Motivation service for AI-powered inspirational messages
class MotivationService {
  final StorageService _storageService;
  static const String _cacheKey = 'motivation_messages';
  static const int _maxCachedMessages = 5;

  // Fallback motivational messages for offline use
  static const List<String> _fallbackMessages = [
    'Every great achievement starts with a single step!',
    'Your potential is endless. Keep learning and growing!',
    'Education is the most powerful weapon you can use to change the world!',
    'The future belongs to those who believe in the beauty of their dreams!',
    'Success is not final, failure is not fatal: it is the courage to continue that counts!',
    'Believe you can and you\'re halfway there!',
    'The only way to do great work is to love what you do!',
    'Don\'t watch the clock; do what it does. Keep going!',
    'The expert in anything was once a beginner!',
    'Your limitation—it\'s only your imagination!',
  ];

  MotivationService({required StorageService storageService})
      : _storageService = storageService;

  /// Get motivational message (AI or fallback)
  Future<String> getMotivationalMessage() async {
    try {
      // Try to get from cache first
      final cachedMessage = await _getCachedMessage();
      if (cachedMessage != null) {
        return cachedMessage;
      }

      // Try AI-generated message
      final aiMessage = await _getAIMotivationalMessage();
      if (aiMessage != null) {
        await _cacheMessage(aiMessage);
        return aiMessage;
      }

      // Fall back to random cached message
      return _getRandomFallbackMessage();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ MotivationService error: $e');
      }
      return _getRandomFallbackMessage();
    }
  }

  /// Get AI motivational message from Gemma API
  Future<String?> _getAIMotivationalMessage() async {
    try {
      // For Flutter Lite compliance, we'll simulate AI response
      // In a real implementation, this would call the actual Gemma API
      final responses = [
        '🌟 You are capable of amazing things! Keep pushing forward!',
        '🚀 Every lesson you complete brings you closer to your dreams!',
        '💪 Your hard today will make your tomorrow better!',
        '🎯 Focus on progress, not perfection. You\'re doing great!',
        '⭐ Believe in yourself! You have what it takes to succeed!',
        '🌈 Learning is your superpower. Use it wisely!',
        '🏆 Every small step counts towards your big goals!',
        '🌱 Growth happens outside your comfort zone. Embrace it!',
        '🎨 You are painting your future with every lesson you learn!',
        '🔥 Your passion for learning will light up your path!',
      ];

      return responses[DateTime.now().second % responses.length];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AI motivation error: $e');
      }
      return null;
    }
  }

  /// Get random fallback message
  String _getRandomFallbackMessage() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % _fallbackMessages.length;
    return _fallbackMessages[index];
  }

  /// Cache motivational message
  Future<void> _cacheMessage(String message) async {
    try {
      // Get current cached messages
      final cachedMessages = await _getCachedMessagesList();
      
      // Add new message
      cachedMessages.insert(0, message);
      
      // Keep only the latest 5 messages
      if (cachedMessages.length > _maxCachedMessages) {
        cachedMessages.removeRange(_maxCachedMessages, cachedMessages.length);
      }

      // Save to cache
      await _storageService.setCachedData(
        key: _cacheKey,
        data: cachedMessages,
        toJson: (messages) => {'messages': messages},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache message error: $e');
      }
    }
  }

  /// Get cached motivational message
  Future<String?> _getCachedMessage() async {
    try {
      final cachedMessages = await _getCachedMessagesList();
      return cachedMessages.isNotEmpty ? cachedMessages.first : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get cached message error: $e');
      }
      return null;
    }
  }

  /// Get list of cached messages
  Future<List<String>> _getCachedMessagesList() async {
    try {
      final cached = await _storageService.getCachedData<List<String>>(
        key: _cacheKey,
        fromJson: (json) {
          final messages = json['messages'] as List?;
          return messages?.cast<String>() ?? [];
        },
        ttlSeconds: 86400 * 7, // Cache for 7 days
      );

      return cached ?? [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get cached messages list error: $e');
      }
      return [];
    }
  }

  /// Get random cached message for offline use
  Future<String> getRandomCachedMessage() async {
    try {
      final cachedMessages = await _getCachedMessagesList();
      if (cachedMessages.isNotEmpty) {
        final random = DateTime.now().millisecondsSinceEpoch;
        final index = random % cachedMessages.length;
        return cachedMessages[index];
      }
      return _getRandomFallbackMessage();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get random cached message error: $e');
      }
      return _getRandomFallbackMessage();
    }
  }

  /// Clear cached messages
  Future<void> clearCachedMessages() async {
    try {
      await _storageService.removeCachedData(_cacheKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear cached messages error: $e');
      }
    }
  }

  /// Get fallback messages count
  int getFallbackMessagesCount() {
    return _fallbackMessages.length;
  }
}