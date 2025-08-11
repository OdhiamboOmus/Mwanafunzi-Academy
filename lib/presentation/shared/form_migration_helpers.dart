import 'package:flutter/material.dart';
import 'constants.dart';
import 'form_widgets.dart';
import 'data_constants.dart';

// Migration helpers for existing forms to use shared utilities
// This file helps transition from custom _buildFormField methods to shared FormField widget

class FormMigrationHelpers {
  // Helper method that matches the signature of existing _buildFormField methods
  static Widget buildFormField({
    required String labelText,
    required String? Function(String?) validator,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? helperText,
  }) {
    return CustomFormField(
      labelText: labelText,
      validator: validator,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      helperText: helperText,
    );
  }

  // Legacy dropdown builder for forms that haven't migrated to FormBuilder yet
  static Widget buildLegacyDropdown<T>({
    required String labelText,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppConstants.brandColor, width: 2),
          ),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item.toString()),
        )).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  // Helper for constituency dropdown that works with the new JSON structure
  static Widget buildConstituencyDropdown({
    required String? selectedConstituency,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return FutureBuilder<List<String>>(
      future: Future.value(_getAllConstituenciesSync()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppConstants.defaultPadding),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        return buildLegacyDropdown<String>(
          labelText: 'Constituency',
          hintText: 'Select constituency',
          value: selectedConstituency,
          items: snapshot.data!,
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }

  // Helper method to get all constituencies from DataConstants (synchronous)
  static List<String> _getAllConstituenciesSync() {
    final allConstituencies = <String>[];
    
    for (final countyConstituencies in DataConstants.constituencies.values) {
      allConstituencies.addAll(countyConstituencies);
    }
    
    allConstituencies.sort();
    return allConstituencies;
  }


  // Helper for subjects dropdown
  static Widget buildSubjectsDropdown({
    required List<String> selectedSubjects,
    required void Function(List<String>) onChanged,
    String? Function(List<String>?)? validator,
  }) {
    return FutureBuilder<List<String>>(
      future: Future.value(DataConstants.subjects),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppConstants.defaultPadding),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subjects',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: snapshot.data!.map((subject) {
                final isSelected = selectedSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newSelection = List<String>.from(selectedSubjects);
                    if (selected) {
                      newSelection.add(subject);
                    } else {
                      newSelection.remove(subject);
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
      },
    );
  }
}