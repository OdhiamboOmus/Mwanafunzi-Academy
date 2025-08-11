import 'package:flutter/material.dart';

// Custom toast notification service following Flutter Lite rules
class ToastService {
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF50E801),
      icon: Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFEF4444),
      icon: Icons.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFF59E0B),
      icon: Icons.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF3B82F6),
      icon: Icons.info,
    );
  }

  static void _showToast({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
      ),
    );

    overlay.insert(overlayEntry);
    
    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

class _ToastOverlay extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;

  const _ToastOverlay({
    required this.message,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}