import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../shared/validators.dart';
import '../shared/widgets.dart';
import '../shared/error_handler.dart';
import '../shared/toast_service.dart';

// Parent sign up form following Flutter Lite rules (<120 lines)
class ParentSignUpForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const ParentSignUpForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<ParentSignUpForm> createState() => _ParentSignUpFormState();
}

class _ParentSignUpFormState extends State<ParentSignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _studentContactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentContactController.dispose();
    _studentNameController.dispose();
    _studentContactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilder.buildSection('Parent Information', [
            CustomFormField(
              labelText: 'Parent Full Name',
              validator: (value) => Validators.validateRequired(value, 'Parent Full Name'),
              controller: _parentNameController,
            ),
            EmailPhoneToggle(
              controller: _parentContactController,
              validator: (value) => Validators.validateRequired(value, 'Parent Contact'),
            ),
          ]),
          FormBuilder.buildSection('Student Information', [
            CustomFormField(
              labelText: 'Student Full Name',
              validator: (value) => Validators.validateRequired(value, 'Student Full Name'),
              controller: _studentNameController,
            ),
            const Text(
              'Student Contact Information (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            EmailPhoneToggle(
              controller: _studentContactController,
              validator: (value) => null,
            ),
          ]),
          FormBuilder.buildSection('Password', [
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
          ]),
          const SizedBox(height: 24),
          BrandButton(
            text: 'Create Parent Account',
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
      // Form should only collect data, NOT create user
      // The user creation should be handled by the sign-up screen
      print('🔍 DEBUG: Parent form validation successful, passing data to sign-up screen');

      widget.onSubmit({
        'userType': AppConstants.userTypeParent,
        'parentName': _parentNameController.text.trim(),
        'parentContact': _parentContactController.text.trim(),
        'studentName': _studentNameController.text.trim(),
        'studentContact': _studentContactController.text.trim().isNotEmpty ? _studentContactController.text.trim() : null,
        'password': _passwordController.text,
      });
      
      print('🔍 DEBUG: Parent form data submitted successfully');
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      
      if (e.toString().contains('FirebaseAuthException')) {
        errorMessage = ErrorHandler.getAuthErrorMessage(e.toString().split(']')[1].trim());
      } else if (e.toString().contains('FirebaseFirestoreException')) {
        errorMessage = ErrorHandler.getFirestoreErrorMessage(e.toString().split(']')[1].trim());
      }
      
      if (mounted) {
        ToastService.showError(context, errorMessage);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}