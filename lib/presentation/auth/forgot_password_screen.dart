import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants.dart';
import '../shared/error_handler.dart';
import '../shared/widgets.dart';
import '../shared/validators.dart';

// Forgot password screen following Flutter Lite rules
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: _emailSent ? _buildSuccessView() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Forgot your password?',
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: GoogleFonts.sora(
            fontSize: 14,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        CustomFormField(
          labelText: 'Email Address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 24),
        BrandButton(
          text: 'Send Reset Link',
          onPressed: _submitForm,
          isLoading: _isLoading,
        ),
      ],
    ),
  );

  Widget _buildSuccessView() => Column(
    children: [
      const SizedBox(height: 48),
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppConstants.brandColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.email_outlined,
          size: 40,
          color: AppConstants.brandColor,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Check your email',
        style: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1F2937),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'We\'ve sent a password reset link to\n${_emailController.text}',
        style: GoogleFonts.sora(
          fontSize: 14,
          color: const Color(0xFF6B7280),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      BrandButton(
        text: 'Back to Sign In',
        onPressed: () => Navigator.pop(context),
        isLoading: false,
      ),
    ],
  );

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
      await _userRepository.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _emailSent = true);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandler.getAuthErrorMessage(e.toString());
        ErrorHandler.showErrorDialog(context, 'Error', errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
