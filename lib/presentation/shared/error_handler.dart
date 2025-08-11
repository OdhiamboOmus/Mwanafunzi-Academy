import 'package:flutter/material.dart';
import 'toast_service.dart';

// Error handling utility following Flutter Lite rules
class ErrorHandler {
  // Handle Firebase authentication errors with user-friendly messages
  static String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'timeout':
        return 'Request timed out. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Handle Firestore errors with user-friendly messages
  static String getFirestoreErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'This resource already exists.';
      case 'invalid-argument':
        return 'Invalid input provided.';
      case 'deadline-exceeded':
        return 'Request took too long to complete.';
      case 'unavailable':
        return 'Service is temporarily unavailable.';
      case 'resource-exhausted':
        return 'Quota exceeded. Please try again later.';
      default:
        return 'Failed to save data. Please try again.';
    }
  }

  // Show error dialog with user-friendly message
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show network error toast
  static void showNetworkError(BuildContext context) {
    ToastService.showError(context, 'Network error. Please check your connection.');
  }

  // Show loading indicator with message
  static Widget buildLoadingOverlay(BuildContext context, {String message = 'Loading...'}) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: ModalBarrier(
            dismissible: false,
            color: Colors.grey,
          ),
        ),
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Validate network connectivity
  static Future<bool> hasNetworkConnection() async {
    // In a real app, you would check actual network connectivity
    // For now, we'll assume network is available
    return true;
  }
}