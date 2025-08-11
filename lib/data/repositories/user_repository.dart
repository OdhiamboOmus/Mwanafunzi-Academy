import '../models/teacher_model.dart';
import '../models/student_model.dart';
import '../models/parent_model.dart';
import '../models/admin_model.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/firebase/firestore_service.dart';
import '../../core/constants.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// User repository following Flutter Lite rules
class UserRepository {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Stream for current user authentication state
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Create student user
  Future<StudentModel> createStudentUser({
    required String email,
    required String password,
    required String fullName,
    required String schoolName,
    required String contactMethod,
    required String contactValue,
  }) async {
    try {
      // Create user with Firebase Auth
      User? user = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        userType: AppConstants.userTypeStudent,
      );

      if (user == null) {
        throw Exception('Failed to create student account');
      }

      // Save user data to Firestore
      await _firestoreService.createStudentData(
        userId: user.uid,
        fullName: fullName,
        schoolName: schoolName,
        contactMethod: contactMethod,
        contactValue: contactValue,
      );

      return StudentModel(
        id: user.uid,
        email: email,
        fullName: fullName,
        schoolName: schoolName,
        contactMethod: contactMethod,
        contactValue: contactValue,
        userType: AppConstants.userTypeStudent,
      );
    } catch (e) {
      throw Exception('Failed to create student user: ${e.toString()}');
    }
  }

  // Create parent user
  Future<ParentModel> createParentUser({
    required String email,
    required String password,
    required String fullName,
    required String contactMethod,
    required String contactValue,
    required String studentName,
    String? studentContact,
  }) async {
    try {
      // Create user with Firebase Auth
      User? user = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        userType: AppConstants.userTypeParent,
      );

      if (user == null) {
        throw Exception('Failed to create parent account');
      }

      // Save user data to Firestore
      await _firestoreService.createParentData(
        userId: user.uid,
        fullName: fullName,
        contactMethod: contactMethod,
        contactValue: contactValue,
        studentName: studentName,
        studentContact: studentContact,
      );

      return ParentModel(
        id: user.uid,
        email: email,
        fullName: fullName,
        contactMethod: contactMethod,
        contactValue: contactValue,
        studentName: studentName,
        studentContact: studentContact,
        userType: AppConstants.userTypeParent,
      );
    } catch (e) {
      throw Exception('Failed to create parent user: ${e.toString()}');
    }
  }

  // Create teacher user
  Future<TeacherModel> createTeacherUser({
    required String email,
    required String password,
    required String fullName,
    required String gender,
    required int age,
    required List<String> subjects,
    required String areaOfOperation,
    String? tscNumber,
    required String phone,
    required String availability,
    required double price,
  }) async {
    try {
      // Create user with Firebase Auth
      User? user = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        userType: AppConstants.userTypeTeacher,
      );

      if (user == null) {
        throw Exception('Failed to create teacher account');
      }

      // Save user data to Firestore
      await _firestoreService.createTeacherData(
        userId: user.uid,
        email: email,
        fullName: fullName,
        gender: gender,
        age: age,
        subjects: subjects,
        areaOfOperation: areaOfOperation,
        tscNumber: tscNumber,
        phone: phone,
        availability: availability,
        price: price,
      );

      return TeacherModel(
        id: user.uid,
        email: email,
        fullName: fullName,
        gender: gender,
        age: age,
        subjects: subjects,
        areaOfOperation: areaOfOperation,
        tscNumber: tscNumber,
        phone: phone,
        availability: availability,
        price: price,
        userType: AppConstants.userTypeTeacher,
      );
    } catch (e) {
      throw Exception('Failed to create teacher user: ${e.toString()}');
    }
  }

  // Create admin user
  Future<AdminModel> createAdminUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user with Firebase Auth
      User? user = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        userType: AppConstants.userTypeAdmin,
      );

      if (user == null) {
        throw Exception('Failed to create admin account');
      }

      // Save user data to Firestore
      await _firestoreService.createAdminData(
        userId: user.uid,
        fullName: fullName,
        email: email,
      );

      return AdminModel(
        id: user.uid,
        email: email,
        fullName: fullName,
        userType: AppConstants.userTypeAdmin,
      );
    } catch (e) {
      throw Exception('Failed to create admin user: ${e.toString()}');
    }
  }

  // Sign in user
  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign in admin
  Future<User?> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signInAdmin(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in admin: ${e.toString()}');
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  // Get user ID
  String? getUserId() {
    return _authService.getUserId();
  }

  // Get user email
  String? getUserEmail() {
    return _authService.getUserEmail();
  }

  // Check if user is authenticated
  bool isUserAuthenticated() {
    return _authService.isUserAuthenticated();
  }

  // Get user document by ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      return await _firestoreService.getUserById(userId);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Get user document by email
  Future<QuerySnapshot> getUserByEmail(String email) async {
    try {
      return await _firestoreService.getUserByEmail(email);
    } catch (e) {
      throw Exception('Failed to get user by email: ${e.toString()}');
    }
  }

  // Update user data
  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestoreService.updateUser(
        userId: userId,
        updates: updates,
      );
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Check if profile is completed
  Future<bool> isProfileCompleted(String userId) async {
    try {
      return await _firestoreService.isProfileCompleted(userId);
    } catch (e) {
      throw Exception('Failed to check profile completion: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }
}