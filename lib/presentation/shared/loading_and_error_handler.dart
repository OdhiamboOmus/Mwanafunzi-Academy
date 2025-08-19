import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Comprehensive error handling and loading states service with logging
class LoadingAndErrorHandler {
  static final LoadingAndErrorHandler _instance = LoadingAndErrorHandler._internal();
  factory LoadingAndErrorHandler() => _instance;
  LoadingAndErrorHandler._internal();

  // Global loading state management
  bool _isLoading = false;
  String? _loadingMessage;
  final List<String> _activeOperations = [];

  // Error state management
  String? _errorMessage;
  String? _errorTitle;
  bool _hasError = false;

  // Loading state management
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String? get errorTitle => _errorTitle;

  // Start loading operation with logging
  void startLoading({
    String operation = 'Loading...',
    bool showOverlay = true,
  }) {
    developer.log('LoadingAndErrorHandler: Starting loading operation - Operation: $operation');
    
    if (!_isLoading) {
      _isLoading = true;
      _loadingMessage = operation;
    }
    
    _activeOperations.add(operation);
    
    if (showOverlay) {
      _showLoadingOverlay();
    }
  }

  // Stop loading operation with logging
  void stopLoading({
    String? operation,
    bool hideOverlay = true,
  }) {
    developer.log('LoadingAndErrorHandler: Stopping loading operation - Operation: ${operation ?? "Last operation"}');
    
    if (operation != null) {
      _activeOperations.remove(operation);
    } else if (_activeOperations.isNotEmpty) {
      _activeOperations.removeLast();
    }

    if (_activeOperations.isEmpty) {
      _isLoading = false;
      _loadingMessage = null;
    } else {
      _loadingMessage = _activeOperations.last;
    }

    if (hideOverlay) {
      _hideLoadingOverlay();
    }
  }

  // Show loading overlay
  void _showLoadingOverlay() {
    // In a real implementation, this would show a global loading overlay
    developer.log('LoadingAndErrorHandler: Showing loading overlay - Message: $_loadingMessage');
  }

  // Hide loading overlay
  void _hideLoadingOverlay() {
    // In a real implementation, this would hide the global loading overlay
    developer.log('LoadingAndErrorHandler: Hiding loading overlay');
  }

  // Handle error with logging
  void handleError({
    required String title,
    required String message,
    String? errorCode,
    StackTrace? stackTrace,
    bool showSnackBar = true,
    bool showDialog = false,
  }) {
    developer.log('LoadingAndErrorHandler: Handling error - Title: $title, Message: $message, ErrorCode: $errorCode');
    
    _hasError = true;
    _errorTitle = title;
    _errorMessage = message;

    if (stackTrace != null) {
      developer.log('LoadingAndErrorHandler: Error stack trace - $stackTrace');
    }

    if (showSnackBar) {
      _showErrorSnackBar(title, message);
    }

    if (showDialog) {
      _showErrorDialog(title, message);
    }
  }

  // Clear error state with logging
  void clearError() {
    developer.log('LoadingAndErrorHandler: Clearing error state');
    
    _hasError = false;
    _errorMessage = null;
    _errorTitle = null;
  }

  // Show error snackbar
  void _showErrorSnackBar(String title, String message) {
    developer.log('LoadingAndErrorHandler: Showing error snackbar - Title: $title');
    
    // In a real implementation, this would show a snackbar
    developer.log('LoadingAndErrorHandler: Error snackbar content - $title: $message');
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    developer.log('LoadingAndErrorHandler: Showing error dialog - Title: $title');
    
    // In a real implementation, this would show a dialog
    developer.log('LoadingAndErrorHandler: Error dialog content - $title: $message');
  }

  // Build loading widget with logging
  Widget buildLoadingWidget({
    String message = 'Loading...',
    bool showProgress = true,
  }) {
    developer.log('LoadingAndErrorHandler: Building loading widget - Message: $message');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress)
            const CircularProgressIndicator(
              color: Color(0xFF50E801),
              strokeWidth: 3,
            ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build error widget with logging
  Widget buildErrorWidget({
    required String title,
    required String message,
    required VoidCallback onRetry,
    String? retryButtonText,
  }) {
    developer.log('LoadingAndErrorHandler: Building error widget - Title: $title');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              developer.log('LoadingAndErrorHandler: Retry button pressed - Title: $title');
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50E801),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              retryButtonText ?? 'Try Again',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build empty state widget with logging
  Widget buildEmptyWidget({
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    developer.log('LoadingAndErrorHandler: Building empty state widget - Title: $title');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Colors.grey[400],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                developer.log('LoadingAndErrorHandler: Action button pressed - Title: $title');
                onAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build network error widget with logging
  Widget buildNetworkErrorWidget({
    required VoidCallback onRetry,
    String? retryButtonText,
  }) {
    developer.log('LoadingAndErrorHandler: Building network error widget');
    
    return buildErrorWidget(
      title: 'Network Error',
      message: 'Unable to connect to the internet. Please check your connection and try again.',
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? 'Retry',
    );
  }

  // Build permission error widget with logging
  Widget buildPermissionErrorWidget({
    required VoidCallback onRetry,
    String? retryButtonText,
  }) {
    developer.log('LoadingAndErrorHandler: Building permission error widget');
    
    return buildErrorWidget(
      title: 'Permission Denied',
      message: 'This app requires certain permissions to function properly. Please enable them in app settings.',
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? 'Grant Permissions',
    );
  }

  // Build server error widget with logging
  Widget buildServerErrorWidget({
    required VoidCallback onRetry,
    String? retryButtonText,
  }) {
    developer.log('LoadingAndErrorHandler: Building server error widget');
    
    return buildErrorWidget(
      title: 'Server Error',
      message: 'We\'re experiencing technical difficulties. Please try again later.',
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? 'Retry',
    );
  }

  // Wrap async operation with loading and error handling with logging
  Future<T> wrapAsyncOperation<T>({
    required Future<T> operation,
    String loadingMessage = 'Loading...',
    VoidCallback? onError,
    bool showLoading = true,
    bool showError = true,
  }) async {
    developer.log('LoadingAndErrorHandler: Wrapping async operation - LoadingMessage: $loadingMessage');
    
    try {
      if (showLoading) {
        startLoading(operation: loadingMessage);
      }

      final result = await operation;

      if (showLoading) {
        stopLoading(operation: loadingMessage);
      }

      return result;
    } catch (e, stackTrace) {
      developer.log('LoadingAndErrorHandler: Async operation failed - Error: $e, StackTrace: $stackTrace');
      
      if (showLoading) {
        stopLoading(operation: loadingMessage);
      }

      if (showError) {
        handleError(
          title: 'Operation Failed',
          message: e.toString(),
          stackTrace: stackTrace,
        );
      }

      if (onError != null) {
        onError();
      }

      rethrow;
    }
  }

  // Validate network connectivity with logging
  Future<bool> validateNetworkConnection() async {
    developer.log('LoadingAndErrorHandler: Validating network connection');
    
    try {
      // In a real implementation, this would check actual network connectivity
      // For now, we'll simulate a network check
      await Future.delayed(const Duration(milliseconds: 500));
      
      final isConnected = true; // Simulate network connection
      
      developer.log('LoadingAndErrorHandler: Network connection validation result - $isConnected');
      return isConnected;
    } catch (e) {
      developer.log('LoadingAndErrorHandler: Network connection validation failed - Error: $e');
      return false;
    }
  }

  // Show loading overlay with custom content
  Widget buildLoadingOverlay({
    required Widget child,
    String? message,
    bool isLoading = false,
  }) {
    developer.log('LoadingAndErrorHandler: Building loading overlay - IsLoading: $isLoading');
    
    if (isLoading) {
      return Stack(
        children: [
          child,
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF50E801),
                      strokeWidth: 3,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return child;
  }

  // Reset all states with logging
  void reset() {
    developer.log('LoadingAndErrorHandler: Resetting all states');
    
    _isLoading = false;
    _loadingMessage = null;
    _activeOperations.clear();
    _hasError = false;
    _errorMessage = null;
    _errorTitle = null;
  }

  // Get active operations count with logging
  int getActiveOperationsCount() {
    developer.log('LoadingAndErrorHandler: Getting active operations count - ${_activeOperations.length}');
    return _activeOperations.length;
  }

  // Check if specific operation is active with logging
  bool isOperationActive(String operation) {
    final isActive = _activeOperations.contains(operation);
    developer.log('LoadingAndErrorHandler: Checking if operation is active - Operation: $operation, IsActive: $isActive');
    return isActive;
  }
}