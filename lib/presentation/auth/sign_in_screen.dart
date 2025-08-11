import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../shared/widgets.dart';
import '../shared/validators.dart';
import 'sign_in_logic.dart';
 
// Lightweight sign-in screen under 150 lines
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signInLogic = SignInLogic();
  bool _isLoading = false;

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildNavigation(),
              const SizedBox(height: 48),
              _buildForm(),
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
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Welcome back! Sign in to continue',
        style: GoogleFonts.sora(fontSize: 14, color: const Color(0xFF6B7280)),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildNavigation() => Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.brandColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Sign In',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/sign-up'),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF9FAFB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Sign Up',
            style: GoogleFonts.sora(
              fontSize: 16,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      children: [
        CustomFormField(
          labelText: 'Email Address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        CustomFormField(
          labelText: 'Password',
          controller: _passwordController,
          obscureText: true,
          validator: (value) => Validators.validateRequired(value, 'Password'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: AppConstants.brandColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        BrandButton(
          text: 'Sign In',
          onPressed: _submitForm,
          isLoading: _isLoading,
        ),
      ],
    ),
  );

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _signInLogic.signIn(
        context: context,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
