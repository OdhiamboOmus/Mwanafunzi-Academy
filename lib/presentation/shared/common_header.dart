import 'package:flutter/material.dart';
import '../../core/constants.dart';

// Common header components following Flutter Lite rules (<80 lines)
class CommonHeader {
  // Brand header with tagline
  static Widget buildBrandHeader() => Column(
    children: [
      const Text(
        'MWANAFUNZI',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppConstants.brandColor,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Learn as if the world depends on you - because it does',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  // Top navigation with Sign In/Sign Up buttons
  static Widget buildTopNavigation(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      Expanded(
        child: ElevatedButton(
          onPressed: null, // Already on sign up screen
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.brandColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );

  // User type selector with Teacher selected
  static Widget buildUserTypeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'I am a:',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          _buildTypeButton('Student', false, Icons.school),
          const SizedBox(width: 8),
          _buildTypeButton('Teacher', true, Icons.person),
          const SizedBox(width: 8),
          _buildTypeButton('Parent', false, Icons.family_restroom),
        ],
      ),
    ],
  );

  static Widget _buildTypeButton(String label, bool isSelected, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppConstants.brandColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  );
}