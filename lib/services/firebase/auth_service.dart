import 'package:firebase_auth/firebase_auth.dart';

// Firebase Authentication service following Flutter Lite rules
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create user with email and password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      print('🔍 DEBUG: AuthService - createUserWithEmailAndPassword called');
      print('🔍 DEBUG: Email: $email');
      print('🔍 DEBUG: User Type: $userType');
      
      // Check if user already exists with this email
      try {
        final signInResult = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (signInResult.user != null) {
          print('🔍 DEBUG: User already exists with email: $email');
          // User exists, return existing user
          return signInResult.user;
        }
      } catch (e) {
        // User doesn't exist, continue with account creation
        print('🔍 DEBUG: User does not exist, creating new account...');
      }
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('🔍 DEBUG: Auth creation successful');
      print('🔍 DEBUG: User ID: ${userCredential.user?.uid}');
      print('🔍 DEBUG: User email: ${userCredential.user?.email}');
      
      // Update user profile with custom claims
      await userCredential.user?.updateDisplayName(userType);
      print('🔍 DEBUG: Display name updated to: $userType');
      
      return userCredential.user;
    } catch (e) {
      print('❌ DEBUG: AuthService error: ${e.toString()}');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      throw _handleAuthError(e);
    }
  }

  // Sign in user with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in admin with special credentials
  Future<User?> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify admin status through custom claims or user document
      // This is a simplified version - in production, you'd verify admin status
      // through Firebase custom claims or a separate admin collection
      
      return userCredential.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔍 DEBUG: AuthService - sendPasswordResetEmail called');
      print('🔍 DEBUG: Email: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      print('🔍 DEBUG: Password reset email sent successfully');
    } catch (e) {
      print('❌ DEBUG: AuthService error in sendPasswordResetEmail: ${e.toString()}');
      throw _handleAuthError(e);
    }
  }

  // Handle and format authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  // Check if user is authenticated
  bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Stream for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 