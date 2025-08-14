import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../core/services/storage_service.dart';

/// User service for managing user profiles and dynamic greetings
class UserService {
  final UserRepository _userRepository;
  final StorageService _storageService;

  UserService({
    required UserRepository userRepository,
    required StorageService storageService,
  }) : _userRepository = userRepository,
       _storageService = storageService;

  /// Get current user with dynamic name fetching
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user == null) return null;

      // Try to get fresh user data from Firestore
      final userDoc = await _userRepository.getUserById(user.uid);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: userData['fullName'] ?? userData['name'] ?? 'Student',
          role: userData['userType'] ?? 'student',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }

      // Fall back to basic user data
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: 'Student',
        role: 'student',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ UserService error in getCurrentUser: ${e.toString()}');
      return null;
    }
  }

  /// Get user name for greeting (with caching)
  Future<String> getUserNameForGreeting(String userId) async {
    try {
      // Try to get from cache first
      final cachedName = await _storageService.getCachedData<String>(
        key: 'user_name_$userId',
        fromJson: (json) => json as String,
        ttlSeconds: 3600, // Cache for 1 hour
      );

      if (cachedName != null) {
        return cachedName;
      }

      // Fetch fresh data
      final userDoc = await _userRepository.getUserById(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        String userName = userData['fullName'] ?? userData['displayName'] ?? 'Student';
        
        // Cache the name
        await _storageService.setCachedData(
          key: 'user_name_$userId',
          data: userName,
          toJson: (name) => {'name': name},
        );

        return userName;
      }

      // Return fallback
      return 'Learner';
    } catch (e) {
      debugPrint('❌ UserService error in getUserNameForGreeting: ${e.toString()}');
      return 'Learner';
    }
  }

  /// Get user greeting message
  Future<String> getUserGreeting(String userId) async {
    try {
      final userName = await getUserNameForGreeting(userId);
      return 'Welcome back, $userName!';
    } catch (e) {
      debugPrint('❌ UserService error in getUserGreeting: ${e.toString()}');
      return 'Welcome back, Learner!';
    }
  }

  /// Cache user greeting for offline use
  Future<bool> cacheUserGreeting({
    required String userId,
    required String greeting,
  }) async {
    try {
      return await _storageService.setCachedData(
        key: 'user_greeting_$userId',
        data: greeting,
        toJson: (greeting) => {'greeting': greeting},
      );
    } catch (e) {
      debugPrint('❌ UserService error in cacheUserGreeting: ${e.toString()}');
      return false;
    }
  }

  /// Get cached user greeting
  Future<String?> getCachedUserGreeting(String userId) async {
    try {
      return await _storageService.getCachedData<String>(
        key: 'user_greeting_$userId',
        fromJson: (json) => json['greeting'] as String,
        ttlSeconds: 86400, // Cache for 24 hours
      );
    } catch (e) {
      debugPrint('❌ UserService error in getCachedUserGreeting: ${e.toString()}');
      return null;
    }
  }

  /// Clear user cache
  Future<bool> clearUserCache(String userId) async {
    try {
      await _storageService.removeCachedData('user_name_$userId');
      await _storageService.removeCachedData('user_greeting_$userId');
      return true;
    } catch (e) {
      debugPrint('❌ UserService error in clearUserCache: ${e.toString()}');
      return false;
    }
  }
}