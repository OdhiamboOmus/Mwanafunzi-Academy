import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants.dart';
import '../shared/error_handler.dart';
import '../shared/notification_service.dart';

// Sign-in business logic service following Flutter Lite rules
class SignInLogic {
  final UserRepository _userRepository = UserRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    // Check network connectivity
    if (!await ErrorHandler.hasNetworkConnection()) {
      if (context.mounted) {
        ErrorHandler.showNetworkError(context);
      }
      return;
    }

    try {
      final user = await _userRepository.signInUser(
        email: email,
        password: password,
      );

      if (user != null && context.mounted) {
        await _navigateBasedOnUserType(context, user.uid);
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = ErrorHandler.getAuthErrorMessage(e.toString());
        NotificationService().showErrorMessage(context, errorMessage);
      }
    }
  }

  Future<void> _navigateBasedOnUserType(BuildContext context, String userId) async {
    try {
      // Check user type by looking in each collection
      final userType = await _getUserType(userId);
      
      if (!context.mounted) return;

      switch (userType) {
        case AppConstants.userTypeStudent:
          Navigator.pushReplacementNamed(context, '/student-home');
          break;
        case AppConstants.userTypeParent:
          Navigator.pushReplacementNamed(context, '/parent-home');
          break;
        case AppConstants.userTypeTeacher:
          Navigator.pushReplacementNamed(context, '/teacher-home');
          break;
        case AppConstants.userTypeAdmin:
          Navigator.pushReplacementNamed(context, '/admin-home');
          break;
        default:
          // Default to student if type not found
          Navigator.pushReplacementNamed(context, '/student-home');
      }
    } catch (e) {
      // Default navigation on error
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/student-home');
      }
    }
  }

  Future<String> _getUserType(String userId) async {
    // Check each collection to determine user type
    final collections = [
      {'name': 'students', 'type': AppConstants.userTypeStudent},
      {'name': 'parents', 'type': AppConstants.userTypeParent},
      {'name': 'teachers', 'type': AppConstants.userTypeTeacher},
      {'name': 'admins', 'type': AppConstants.userTypeAdmin},
    ];

    for (final collection in collections) {
      try {
        final doc = await _firestore
            .collection(collection['name']!)
            .doc(userId)
            .get();
        
        if (doc.exists) {
          return collection['type']!;
        }
      } catch (e) {
        // Continue checking other collections
        continue;
      }
    }

    // Default to student if not found in any collection
    return AppConstants.userTypeStudent;
  }
}