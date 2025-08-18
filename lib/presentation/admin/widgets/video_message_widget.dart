import 'package:flutter/material.dart';

// Video message widget following Flutter Lite rules (<150 lines)
class VideoMessageWidget extends StatelessWidget {
  final String message;

  const VideoMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: message.contains('Success') ? Colors.green[50]! : Colors.red[50]!,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: message.contains('Success') ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            message.contains('Success') ? Icons.check_circle : Icons.error,
            color: message.contains('Success') ? Colors.green[600]! : Colors.red[600]!,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: message.contains('Success') ? Colors.green[700]! : Colors.red[700]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}