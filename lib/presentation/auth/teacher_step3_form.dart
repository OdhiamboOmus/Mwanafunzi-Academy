import 'package:flutter/material.dart';
import '../shared/validators.dart';
import '../shared/form_widgets.dart';

// Teacher signup step 3: Contact Information (<100 lines)
class TeacherStep3Form extends StatefulWidget {
  final TextEditingController mainPhoneController;
  final TextEditingController altPhoneController;
  final TextEditingController availabilityController;
  final TextEditingController priceController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const TeacherStep3Form({
    super.key,
    required this.mainPhoneController,
    required this.altPhoneController,
    required this.availabilityController,
    required this.priceController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<TeacherStep3Form> createState() => _TeacherStep3FormState();
}

class _TeacherStep3FormState extends State<TeacherStep3Form> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Contact Information', 'Step 3 of 3'),
          const SizedBox(height: 32),
          _buildContactFields(),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildContactFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormField(
          labelText: 'Main Phone',
          controller: widget.mainPhoneController,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
        ),
        CustomFormField(
          labelText: 'Alternative Phone (Optional)',
          controller: widget.altPhoneController,
          keyboardType: TextInputType.phone,
        ),
        CustomFormField(
          labelText: 'Available Time',
          controller: widget.availabilityController,
          helperText: 'e.g., Monday-Friday 4PM-7PM',
          validator: (value) => Validators.validateRequired(value, 'Available time'),
        ),
        CustomFormField(
          labelText: 'Hourly Rate (KSH)',
          controller: widget.priceController,
          keyboardType: TextInputType.number,
          helperText: 'Your hourly teaching rate in Kenyan Shillings',
          validator: (value) => Validators.validateRequired(value, 'Hourly rate'),
        ),

        CustomFormField(
          labelText: 'Email Address',
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        CustomFormField(
          labelText: 'Password',
          controller: widget.passwordController,
          obscureText: true,
          validator: Validators.validatePassword,
        ),
        CustomFormField(
          labelText: 'Confirm Password',
          controller: widget.confirmPasswordController,
          obscureText: true,
          validator: (value) => Validators.validateConfirmPassword(value, widget.passwordController.text),
        ),
      ],
    );
  }


}