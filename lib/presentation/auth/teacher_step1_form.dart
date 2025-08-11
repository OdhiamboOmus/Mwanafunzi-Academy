import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../shared/validators.dart';
import '../shared/form_widgets.dart';

// Teacher signup step 1: Personal Information (<80 lines)
class TeacherStep1Form extends StatefulWidget {
  final TextEditingController nameController;
  final String selectedGender;
  final TextEditingController ageController;
  final Function(String) onGenderChanged;

  const TeacherStep1Form({
    super.key,
    required this.nameController,
    required this.selectedGender,
    required this.ageController,
    required this.onGenderChanged,
  });

  @override
  State<TeacherStep1Form> createState() => _TeacherStep1FormState();
}

class _TeacherStep1FormState extends State<TeacherStep1Form> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Personal Information', 'Step 1 of 3'),
          const SizedBox(height: 32),
          CustomFormField(
            labelText: 'Full Name',
            controller: widget.nameController,
            validator: (value) => Validators.validateRequired(value, 'Full Name'),
          ),
          const SizedBox(height: 16),
          _buildGenderSelector(),
          const SizedBox(height: 16),
          CustomFormField(
            labelText: 'Age',
            controller: widget.ageController,
            keyboardType: TextInputType.number,
            validator: _validateAge,
          ),
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

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.genders.map((gender) => Expanded(
            child: GestureDetector(
              onTap: () => widget.onGenderChanged(gender),
              child: Container(
                margin: EdgeInsets.only(right: gender == AppConstants.genders.last ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: widget.selectedGender == gender
                      ? AppConstants.brandColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  gender,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.selectedGender == gender ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }



  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 18 || age > 70) return 'Please enter a valid age (18-70)';
    return null;
  }
}