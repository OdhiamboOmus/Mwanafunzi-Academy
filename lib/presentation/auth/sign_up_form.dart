import 'package:flutter/material.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants.dart';
import '../shared/validators.dart';
import '../shared/widgets.dart';
import '../shared/error_handler.dart';
import 'parent_sign_up_form.dart';
import 'teacher_sign_up_form.dart';

// Student sign up form following Flutter Lite rules
class SignUpForm extends StatefulWidget {
  final String userType;
  final Function(Map<String, dynamic>) onSubmit;

  const SignUpForm({
    super.key,
    required this.userType,
    required this.onSubmit,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.userType) {
      case AppConstants.userTypeParent:
        return ParentSignUpForm(onSubmit: (data) => _handleFormSubmit(data.cast<String, String>()));
      case AppConstants.userTypeTeacher:
        return TeacherSignUpForm(onSubmit: _handleTeacherFormSubmit);
      default:
        return _buildStudentForm();
    }
  }

  Widget _buildStudentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFormField(
            labelText: 'Full Name',
            validator: (value) => Validators.validateRequired(value, 'Full Name'),
            controller: _nameController,
          ),
          CustomFormField(
            labelText: 'School Name',
            validator: Validators.validateSchoolName,
            controller: _schoolController,
          ),
          EmailPhoneToggle(
            controller: _contactController,
            validator: (value) => Validators.validateRequired(value, 'Contact information'),
          ),
          CustomFormField(
            labelText: 'Password',
            validator: Validators.validatePassword,
            controller: _passwordController,
            obscureText: true,
          ),
          CustomFormField(
            labelText: 'Confirm Password',
            validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
            controller: _confirmPasswordController,
            obscureText: true,
          ),
          const SizedBox(height: 24),
          BrandButton(
            text: 'Create Account',
            onPressed: _submitForm,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check network connectivity
    if (!await ErrorHandler.hasNetworkConnection()) {
      if (mounted) {
        ErrorHandler.showNetworkError(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final student = await _userRepository.createStudentUser(
        email: _contactController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        schoolName: _schoolController.text.trim(),
        contactMethod: 'email', // EmailPhoneToggle handles this
        contactValue: _contactController.text.trim(),
      );

      widget.onSubmit({
        'userType': widget.userType,
        'name': _nameController.text.trim(),
        'school': _schoolController.text.trim(),
        'contact': _contactController.text.trim(),
        'password': _passwordController.text,
        'student': student.toMap(),
      });
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      
      if (e.toString().contains('FirebaseAuthException')) {
        errorMessage = ErrorHandler.getAuthErrorMessage(e.toString().split(']')[1].trim());
      } else if (e.toString().contains('FirebaseFirestoreException')) {
        errorMessage = ErrorHandler.getFirestoreErrorMessage(e.toString().split(']')[1].trim());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleFormSubmit(Map<String, String> formData) {
    widget.onSubmit(formData);
  }

  void _handleTeacherFormSubmit(Map<String, dynamic> formData) {
    widget.onSubmit(formData);
  }
}