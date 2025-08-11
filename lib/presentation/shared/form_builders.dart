import 'package:flutter/material.dart';
import '../../core/constants.dart';

// Common form building patterns following Flutter Lite rules
class FormBuilder {
  static Widget buildDropdown<T>({
    required String labelText,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        ),
      ),
    );
  }

  static Widget buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppConstants.defaultPadding),
        ...children,
      ],
    );
  }

  static Widget buildCountyConstituencyDropdowns({
    required String? selectedCounty,
    required String? selectedConstituency,
    required void Function(String?) onCountyChanged,
    required void Function(String?) onConstituencyChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        FutureBuilder<List<String>>(
          future: AppConstants.loadCounties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading counties: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No counties available');
            }
            
            final counties = snapshot.data!;
            // Ensure selected county exists in the list
            final validSelectedCounty = counties.contains(selectedCounty) ? selectedCounty : null;
            
            return buildDropdown<String>(
              labelText: 'County',
              value: validSelectedCounty,
              items: counties,
              onChanged: (value) {
                onCountyChanged(value);
                // Clear constituency when county changes
                if (value != selectedCounty) {
                  onConstituencyChanged(null);
                }
              },
              validator: validator,
            );
          },
        ),
        if (selectedCounty != null)
          FutureBuilder<List<String>>(
            future: AppConstants.getConstituenciesForCounty(selectedCounty),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error loading constituencies: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final constituencies = snapshot.data!;
              // Ensure selected constituency exists in the list
              final validSelectedConstituency = constituencies.contains(selectedConstituency) ? selectedConstituency : null;
              
              return buildDropdown<String>(
                labelText: 'Constituency',
                value: validSelectedConstituency,
                items: constituencies,
                onChanged: onConstituencyChanged,
                validator: validator,
              );
            },
          ),
      ],
    );
  }

  static Widget buildSubjectDropdown({
    required String? selectedSubject,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return FutureBuilder<List<String>>(
      future: AppConstants.loadSubjects(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return buildDropdown<String>(
          labelText: 'Subject',
          value: selectedSubject,
          items: snapshot.data!,
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }
}