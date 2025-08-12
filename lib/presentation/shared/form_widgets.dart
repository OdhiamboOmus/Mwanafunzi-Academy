import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

// Form-specific widgets following Flutter Lite rules

class CustomFormField extends StatefulWidget {
  final String labelText;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? helperText;

  const CustomFormField({
    super.key,
    required this.labelText,
    this.validator,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.helperText,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          validator: widget.validator,
          style: GoogleFonts.sora(
            fontSize: 16,
            color: const Color(0xFF1F2937),
          ),
          decoration: _buildInputDecoration(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _buildInputDecoration() => InputDecoration(
        hintText: _getHintText(),
        hintStyle: GoogleFonts.sora(
          fontSize: 16,
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          _getIconForField(),
          color: const Color(0xFF9CA3AF),
          size: 20,
        ),
        suffixIcon: widget.obscureText ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF9CA3AF),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: _buildBorder(),
        enabledBorder: _buildBorder(const Color(0xFFE5E7EB)),
        focusedBorder: _buildBorder(AppConstants.brandColor, 2),
        errorBorder: _buildBorder(Colors.red),
        focusedErrorBorder: _buildBorder(Colors.red, 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  String _getHintText() {
    if (widget.labelText.toLowerCase().contains('name')) return 'Enter your full name';
    if (widget.labelText.toLowerCase().contains('email')) return 'Enter your email';
    if (widget.labelText.toLowerCase().contains('password')) return 'Enter your password';
    if (widget.labelText.toLowerCase().contains('confirm')) return 'Confirm your password';
    if (widget.labelText.toLowerCase().contains('phone')) return 'Enter your phone number';
    if (widget.labelText.toLowerCase().contains('school')) return 'Enter your school name';
    return 'Enter ${widget.labelText.toLowerCase()}';
  }

  IconData _getIconForField() {
    if (widget.labelText.toLowerCase().contains('name')) return Icons.person_outline;
    if (widget.labelText.toLowerCase().contains('email')) return Icons.email_outlined;
    if (widget.labelText.toLowerCase().contains('password')) return Icons.lock_outline;
    if (widget.labelText.toLowerCase().contains('phone')) return Icons.phone_outlined;
    if (widget.labelText.toLowerCase().contains('school')) return Icons.school_outlined;
    if (widget.labelText.toLowerCase().contains('age')) return Icons.cake_outlined;
    if (widget.labelText.toLowerCase().contains('tsc')) return Icons.badge_outlined;
    if (widget.labelText.toLowerCase().contains('rate') || widget.labelText.toLowerCase().contains('price')) return Icons.attach_money_outlined;
    if (widget.labelText.toLowerCase().contains('time') || widget.labelText.toLowerCase().contains('availability')) return Icons.schedule_outlined;
    return Icons.edit_outlined;
  }

  OutlineInputBorder _buildBorder([Color? color, double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: color != null ? BorderSide(color: color, width: width) : BorderSide.none,
      );
}

class EmailPhoneToggle extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;

  const EmailPhoneToggle({
    super.key,
    required this.controller,
    required this.validator,
  });

  @override
  State<EmailPhoneToggle> createState() => _EmailPhoneToggleState();
}

class _EmailPhoneToggleState extends State<EmailPhoneToggle> {
  bool _isEmail = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Contact Method', 
                style: GoogleFonts.sora(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                )
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip('Email', _isEmail, (selected) => _toggleMethod(selected)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip('Phone', !_isEmail, (selected) => _toggleMethod(!selected)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomFormField(
          labelText: _isEmail ? 'Email Address' : 'Phone Number',
          validator: widget.validator,
          controller: widget.controller,
          keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
        ),
      ],
    );
  }

  ChoiceChip _buildChoiceChip(String label, bool selected, Function(bool) onSelected) =>
      ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: const Color(0xFFF9FAFB),
        selectedColor: AppConstants.brandColor,
        side: BorderSide(
          color: selected ? AppConstants.brandColor : const Color(0xFFE5E7EB),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );

  void _toggleMethod(bool isEmail) {
    setState(() {
      _isEmail = isEmail;
      widget.controller.clear();
    });
  }
}