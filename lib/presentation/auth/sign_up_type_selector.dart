import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

// User type selection widget following Flutter Lite rules (<60 lines)
class SignUpTypeSelector extends StatefulWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const SignUpTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  State<SignUpTypeSelector> createState() => _SignUpTypeSelectorState();
}

class _SignUpTypeSelectorState extends State<SignUpTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildTypeButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Text(
      'I am a:',
      style: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildTypeButtons() {
    return Row(
      children: [
        _buildTypeButton(
          type: AppConstants.userTypeParent,
          label: 'Parent',
          icon: Icons.family_restroom,
        ),
        const SizedBox(width: 8),
        _buildTypeButton(
          type: AppConstants.userTypeStudent,
          label: 'Student',
          icon: Icons.school,
        ),
        const SizedBox(width: 8),
        _buildTypeButton(
          type: AppConstants.userTypeTeacher,
          label: 'Teacher',
          icon: Icons.person,
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = widget.selectedType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTypeChanged(type),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.brandColor : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppConstants.brandColor : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getModernIcon(type),
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModernIcon(String type) {
    switch (type) {
      case AppConstants.userTypeStudent:
        return Icons.school_outlined;
      case AppConstants.userTypeTeacher:
        return Icons.person_outline;
      case AppConstants.userTypeParent:
        return Icons.people_outline;
      default:
        return Icons.person_outline;
    }
  }
}