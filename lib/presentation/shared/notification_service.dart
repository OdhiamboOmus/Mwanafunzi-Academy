import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void showSuccessMessage(BuildContext context, String message) {
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF50E801),
      Icons.check_circle,
    );
  }

  void showErrorMessage(BuildContext context, String message) {
    _showOverlayMessage(
      context,
      message,
      const Color(0xFFEF4444),
      Icons.error,
    );
  }

  void showInfoMessage(BuildContext context, String message) {
    _showOverlayMessage(
      context,
      message,
      const Color(0xFF3B82F6),
      Icons.info,
    );
  }

  void _showOverlayMessage(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
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

class _NotificationOverlay extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;

  const _NotificationOverlay({
    required this.message,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
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