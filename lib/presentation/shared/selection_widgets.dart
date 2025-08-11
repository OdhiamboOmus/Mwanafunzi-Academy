import 'package:flutter/material.dart';
import 'constants.dart';

// Selection and choice widgets following Flutter Lite rules

class TypeSelectionButton extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const TypeSelectionButton({
    super.key,
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppConstants.brandColor : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppConstants.brandColor.withValues(alpha: 0.1) : Colors.white,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? AppConstants.brandColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppConstants.brandColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.genders.map((gender) {
            final isSelected = selectedGender == gender;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(gender),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppConstants.brandColor : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      color: isSelected ? AppConstants.brandColor.withValues(alpha: 0.1) : Colors.white,
                    ),
                    child: Text(
                      gender,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppConstants.brandColor : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}

class MultiSelectChips extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final void Function(List<String>) onChanged;
  final String? Function(List<String>?)? validator;

  const MultiSelectChips({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onChanged(newSelection);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppConstants.brandColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}