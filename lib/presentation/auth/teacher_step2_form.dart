import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../shared/form_widgets.dart';
import '../shared/form_builders.dart';

// Teacher signup step 2: Professional Information (<100 lines)
class TeacherStep2Form extends StatefulWidget {
  final List<String> selectedSubjects;
  final String? selectedConstituency;
  final TextEditingController tscController;
  final Function(String) onSubjectToggle;
  final Function(String?) onConstituencyChanged;

  const TeacherStep2Form({
    super.key,
    required this.selectedSubjects,
    required this.selectedConstituency,
    required this.tscController,
    required this.onSubjectToggle,
    required this.onConstituencyChanged,
  });

  @override
  State<TeacherStep2Form> createState() => _TeacherStep2FormState();
}

class _TeacherStep2FormState extends State<TeacherStep2Form> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Professional Information', 'Step 2 of 3'),
          const SizedBox(height: 32),
          _buildSubjectsSelector(),
          const SizedBox(height: 16),
          _buildAreaOfOperation(),
          const SizedBox(height: 16),
          CustomFormField(
            labelText: 'TSC Number (Optional)',
            controller: widget.tscController,
            helperText: 'Teachers Service Commission registration number',
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

  Widget _buildSubjectsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subjects',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
          future: AppConstants.loadSubjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading subjects: ${snapshot.error}');
            }
            final subjects = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((subject) {
                  final isSelected = widget.selectedSubjects.contains(subject);
                  return GestureDetector(
                    onTap: () => widget.onSubjectToggle(subject),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppConstants.brandColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAreaOfOperation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Area of Operation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        FormBuilder.buildCountyConstituencyDropdowns(
          selectedCounty: _getSelectedCounty(),
          selectedConstituency: _getSelectedConstituency(),
          onCountyChanged: (county) {
            if (county != null) {
              // Store just the county initially, constituency will be selected separately
              widget.onConstituencyChanged(county);
            }
          },
          onConstituencyChanged: (constituency) {
            if (constituency != null) {
              // Store county,constituency format
              final county = _getSelectedCounty();
              widget.onConstituencyChanged('$county,$constituency');
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Please select your area of operation';
            }
            return null;
          },
        ),
      ],
    );
  }

  String? _getSelectedCounty() {
    if (widget.selectedConstituency == null) return null;
    if (widget.selectedConstituency!.contains(',')) {
      return widget.selectedConstituency!.split(',')[0];
    }
    return widget.selectedConstituency; // Just county selected
  }

  String? _getSelectedConstituency() {
    if (widget.selectedConstituency == null) return null;
    if (widget.selectedConstituency!.contains(',')) {
      return widget.selectedConstituency!.split(',')[1];
    }
    return null; // Only county selected, no constituency yet
  }


}