import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants.dart';
import '../shared/error_handler.dart';
import '../shared/notification_service.dart';
import 'sign_up_type_selector.dart';
import 'sign_up_form.dart';

// Main sign up screen following Flutter Lite rules (<120 lines)
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _selectedUserType = AppConstants.userTypeStudent;
  final UserRepository _userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTopNavigation(),
              const SizedBox(height: 32),
              SignUpTypeSelector(
                selectedType: _selectedUserType,
                onTypeChanged: _handleUserTypeChange,
              ),
              const SizedBox(height: 32),
              SignUpForm(
                userType: _selectedUserType,
                onSubmit: _handleFormSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
    children: [
      Text(
        'Mwanafunzi Academy',
        style: GoogleFonts.sora(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppConstants.brandColor,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Learn as if the world depends on you - because it does',
        style: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B7280),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildTopNavigation() => Row(
    children: [
      Expanded(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.sora(
                fontSize: 16,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppConstants.brandColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: null, // Already on sign up screen
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.brandColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sign Up',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  void _handleUserTypeChange(String userType) => setState(() => _selectedUserType = userType);

  void _handleFormSubmit(Map<String, dynamic> formData) async {
    try {
      await _handleUserCreation(formData);
      _showSuccessMessage(formData['userType']);
      _navigateToHomeScreen(formData['userType']);
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  Future<void> _handleUserCreation(Map<String, dynamic> formData) async {
    switch (formData['userType']) {
      case AppConstants.userTypeStudent:
        await _userRepository.createStudentUser(
          email: formData['email'],
          password: formData['password'],
          fullName: formData['fullName'],
          schoolName: formData['schoolName'],
          contactMethod: formData['contactMethod'],
          contactValue: formData['contactValue'],
        );
        break;
      case AppConstants.userTypeParent:
        await _userRepository.createParentUser(
          email: formData['email'],
          password: formData['password'],
          fullName: formData['fullName'],
          contactMethod: formData['contactMethod'],
          contactValue: formData['contactValue'],
          studentName: formData['studentName'],
          studentContact: formData['studentContact'],
        );
        break;
      case AppConstants.userTypeTeacher:
        await _userRepository.createTeacherUser(
          email: formData['email'],
          password: formData['password'],
          fullName: formData['fullName'],
          gender: formData['gender'],
          age: formData['age'],
          subjects: formData['subjects'],
          areaOfOperation: formData['areaOfOperation'],
          tscNumber: formData['tscNumber'],
          phone: formData['mainPhone'],
          availability: formData['availability'],
          price: formData['pricePerWeek'],
        );
        break;
    }
  }

  void _showSuccessMessage(String userType) => NotificationService().showSuccessMessage(
    context,
    'Account created for $userType!',
  );

  void _showErrorMessage(String error) {
    final errorMessage = ErrorHandler.getAuthErrorMessage(error.contains('FirebaseException') ? error.split(']')[1].trim() : error);
    ErrorHandler.showErrorDialog(context, 'Error', errorMessage);
  }

  void _navigateToHomeScreen(String userType) {
    switch (userType) {
      case AppConstants.userTypeStudent:
        Navigator.pushReplacementNamed(context, '/student-home');
        break;
      case AppConstants.userTypeParent:
        Navigator.pushReplacementNamed(context, '/parent-home');
        break;
      case AppConstants.userTypeTeacher:
        Navigator.pushReplacementNamed(context, '/teacher-home');
        break;
    }
  }
}