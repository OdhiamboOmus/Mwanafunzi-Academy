import 'package:flutter/material.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants.dart';
import '../shared/error_handler.dart';
import '../shared/widgets.dart';
import '../shared/validators.dart';

// Admin login screen following Flutter Lite rules
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeMessage(),
              const SizedBox(height: 32),
              _buildLoginForm(),
              const SizedBox(height: 24),
              BrandButton(
                text: 'Admin Login',
                onPressed: _submitForm,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              _buildBackToLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Admin Login',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
  );

  Widget _buildWelcomeMessage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Admin Portal',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Enter your admin credentials to access the management dashboard',
        style: TextStyle(
          fontSize: 16,
          color: const Color(0xFF757575),
        ),
      ),
    ],
  );

  Widget _buildLoginForm() => Column(
    children: [
      CustomFormField(
        labelText: 'Admin Email',
        validator: Validators.validateEmail,
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
      ),
      CustomFormField(
        labelText: 'Admin Password',
        validator: Validators.validatePassword,
        controller: _passwordController,
        obscureText: _obscurePassword,
        helperText: 'Special admin credentials required',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Text(
            _obscurePassword ? 'Show Password' : 'Hide Password',
            style: TextStyle(color: AppConstants.brandColor),
          ),
        ),
      ),
    ],
  );

  Widget _buildBackToLoginLink() => Center(
    child: TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        'Back to User Login',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _userRepository.signInAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        // Navigate to admin home screen
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else if (mounted) {
        ErrorHandler.showErrorDialog(context, 'Login Failed', 'Invalid admin credentials');
      }
    } catch (e) {
      final errorMessage = ErrorHandler.getAuthErrorMessage(e.toString());
      if (mounted) {
        ErrorHandler.showErrorDialog(context, 'Login Error', errorMessage);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}