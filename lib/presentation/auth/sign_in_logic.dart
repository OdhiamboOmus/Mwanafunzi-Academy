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
      // Regular user login - this will work for all user types including admin
      final user = await _userRepository.signInUser(
        email: email,
        password: password,
      );

      if (user != null && context.mounted) {
        await _navigateBasedOnUserType(context, user.uid);
      } else {
        // Authentication failed
        if (context.mounted) {
          final errorMessage = ErrorHandler.getAuthErrorMessage('Invalid credentials');
          NotificationService().showErrorMessage(context, errorMessage);
        }
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
      
      debugPrint('🔍 DEBUG: User type detection for userId: $userId');
      debugPrint('🔍 DEBUG: Detected user type: $userType');
      
      if (!context.mounted) return;

      switch (userType) {
        case AppConstants.userTypeStudent:
          debugPrint('🔍 DEBUG: Navigating to student-home');
          debugPrint('🎉 SUCCESS: Student login successful');
          Navigator.pushReplacementNamed(context, '/student-home');
          break;
        case AppConstants.userTypeParent:
          debugPrint('🔍 DEBUG: Navigating to parent-home');
          debugPrint('🎉 SUCCESS: Parent login successful');
          Navigator.pushReplacementNamed(context, '/parent-home');
          break;
        case AppConstants.userTypeTeacher:
          debugPrint('🔍 DEBUG: Navigating to teacher-home');
          debugPrint('🎉 SUCCESS: Teacher login successful');
          Navigator.pushReplacementNamed(context, '/teacher-home');
          break;
        case AppConstants.userTypeAdmin:
          debugPrint('🔍 DEBUG: Navigating to admin-home');
          debugPrint('🎉 SUCCESS: Admin login successful - redirecting to admin dashboard');
          debugPrint('🔐 ADMIN: User has full administrative access');
          Navigator.pushReplacementNamed(context, '/admin-home');
          break;
        default:
          debugPrint('🔍 DEBUG: User type not found, defaulting to student-home');
          debugPrint('⚠️ WARNING: Unknown user type, defaulting to student');
          // Default to student if type not found
          Navigator.pushReplacementNamed(context, '/student-home');
      }
    } catch (e) {
      debugPrint('❌ DEBUG: Error in _navigateBasedOnUserType: ${e.toString()}');
      // Default navigation on error
      if (context.mounted) {
        debugPrint('🔍 DEBUG: Error occurred, defaulting to student-home');
        Navigator.pushReplacementNamed(context, '/student-home');
      }
    }
  }

  // Enhanced user type detection with admin_users collection check
  Future<String> _getUserType(String userId) async {
    // Check each collection to determine user type using hierarchical structure
    debugPrint('🔍 DEBUG: Checking user type for userId: $userId');
    
    try {
      // Check parents collection
      debugPrint('🔍 DEBUG: Checking parents collection');
      final parentDoc = await _firestore
          .collection('users')
          .doc('parents')
          .collection('users')
          .doc(userId)
          .get();
      
      if (parentDoc.exists) {
        debugPrint('🔍 DEBUG: User found in parents collection');
        return AppConstants.userTypeParent;
      }
      
      // Check students collection
      debugPrint('🔍 DEBUG: Checking students collection');
      final studentDoc = await _firestore
          .collection('users')
          .doc('students')
          .collection('users')
          .doc(userId)
          .get();
      
      if (studentDoc.exists) {
        debugPrint('🔍 DEBUG: User found in students collection');
        return AppConstants.userTypeStudent;
      }
      
      // Check teachers collection
      debugPrint('🔍 DEBUG: Checking teachers collection');
      final teacherDoc = await _firestore
          .collection('users')
          .doc('teachers')
          .collection('users')
          .doc(userId)
          .get();
      
      if (teacherDoc.exists) {
        debugPrint('🔍 DEBUG: User found in teachers collection');
        return AppConstants.userTypeTeacher;
      }
      
      // Check admin collection in users structure
      debugPrint('🔍 DEBUG: Checking admin collection');
      final adminDoc = await _firestore
          .collection('users')
          .doc('admin')
          .collection('users')
          .doc(userId)
          .get();
      
      if (adminDoc.exists) {
        debugPrint('🔍 DEBUG: User found in admins collection');
        debugPrint('🔐 ADMIN: User has administrative privileges');
        return AppConstants.userTypeAdmin;
      }
      
      debugPrint('🔍 DEBUG: User not found in any collection, defaulting to student');
      return AppConstants.userTypeStudent;
      
    } catch (e) {
      debugPrint('❌ DEBUG: Error checking user collections: ${e.toString()}');
      // Default to student on error
      return AppConstants.userTypeStudent;
    }
  }

}