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
      
      print('🔍 DEBUG: User type detection for userId: $userId');
      print('🔍 DEBUG: Detected user type: $userType');
      
      if (!context.mounted) return;

      switch (userType) {
        case AppConstants.userTypeStudent:
          print('🔍 DEBUG: Navigating to student-home');
          Navigator.pushReplacementNamed(context, '/student-home');
          break;
        case AppConstants.userTypeParent:
          print('🔍 DEBUG: Navigating to parent-home');
          Navigator.pushReplacementNamed(context, '/parent-home');
          break;
        case AppConstants.userTypeTeacher:
          print('🔍 DEBUG: Navigating to teacher-home');
          Navigator.pushReplacementNamed(context, '/teacher-home');
          break;
        case AppConstants.userTypeAdmin:
          print('🔍 DEBUG: Navigating to admin-home');
          Navigator.pushReplacementNamed(context, '/admin-home');
          break;
        default:
          print('🔍 DEBUG: User type not found, defaulting to student-home');
          // Default to student if type not found
          Navigator.pushReplacementNamed(context, '/student-home');
      }
    } catch (e) {
      print('❌ DEBUG: Error in _navigateBasedOnUserType: ${e.toString()}');
      // Default navigation on error
      if (context.mounted) {
        print('🔍 DEBUG: Error occurred, defaulting to student-home');
        Navigator.pushReplacementNamed(context, '/student-home');
      }
    }
  }

  Future<String> _getUserType(String userId) async {
    // Check each collection to determine user type using hierarchical structure
    print('🔍 DEBUG: Checking user type for userId: $userId');
    
    try {
      // Check parents collection
      print('🔍 DEBUG: Checking parents collection');
      final parentDoc = await _firestore
          .collection('users')
          .doc('parents')
          .collection('users')
          .doc(userId)
          .get();
      
      if (parentDoc.exists) {
        print('🔍 DEBUG: User found in parents collection');
        return AppConstants.userTypeParent;
      }
      
      // Check students collection
      print('🔍 DEBUG: Checking students collection');
      final studentDoc = await _firestore
          .collection('users')
          .doc('students')
          .collection('users')
          .doc(userId)
          .get();
      
      if (studentDoc.exists) {
        print('🔍 DEBUG: User found in students collection');
        return AppConstants.userTypeStudent;
      }
      
      // Check teachers collection
      print('🔍 DEBUG: Checking teachers collection');
      final teacherDoc = await _firestore
          .collection('users')
          .doc('teachers')
          .collection('users')
          .doc(userId)
          .get();
      
      if (teacherDoc.exists) {
        print('🔍 DEBUG: User found in teachers collection');
        return AppConstants.userTypeTeacher;
      }
      
      // Check admins collection
      print('🔍 DEBUG: Checking admins collection');
      final adminDoc = await _firestore
          .collection('users')
          .doc('admins')
          .collection('users')
          .doc(userId)
          .get();
      
      if (adminDoc.exists) {
        print('🔍 DEBUG: User found in admins collection');
        return AppConstants.userTypeAdmin;
      }
      
      print('🔍 DEBUG: User not found in any collection, defaulting to student');
      return AppConstants.userTypeStudent;
      
    } catch (e) {
      print('❌ DEBUG: Error checking user collections: ${e.toString()}');
      // Default to student on error
      return AppConstants.userTypeStudent;
    }
  }
}