import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

// Re-export all shared widgets from single entry point
export 'form_widgets.dart';
export 'form_builders.dart';
export 'form_migration_helpers.dart';
export 'selection_widgets.dart';
export 'common_header.dart';

// Main UI widgets following Flutter Lite rules
class BrandButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const BrandButton({super.key, required this.text, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.brandColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                )
              )
            : Text(
                text, 
                style: GoogleFonts.sora(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )
              ),
      ),
    );
  }
}