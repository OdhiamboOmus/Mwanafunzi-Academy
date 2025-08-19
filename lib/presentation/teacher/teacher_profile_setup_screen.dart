import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/teacher_service.dart';
import 'widgets/profile_image_picker.dart';
import 'widgets/tsc_upload_widget.dart';
import 'widgets/availability_selector.dart';

// Teacher profile setup screen following Flutter Lite rules (<150 lines)
class TeacherProfileSetupScreen extends StatefulWidget {
  const TeacherProfileSetupScreen({super.key});

  @override
  State<TeacherProfileSetupScreen> createState() => _TeacherProfileSetupScreenState();
}

class _TeacherProfileSetupScreenState extends State<TeacherProfileSetupScreen> {
  final TeacherService _teacherService = TeacherService();
  final _formKey = GlobalKey<FormState>();
  
  // Form state
  File? _profileImage;
  File? _tscCertificate;
  bool _offersOnlineClasses = false;
  bool _offersHomeTutoring = false;
  List<String> _selectedTimes = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    _buildSectionTitle('Profile Photo'),
                    const SizedBox(height: 8),
                    ProfileImagePicker(
                      onImageSelected: (image) {
                        developer.log('TeacherProfileSetupScreen: Profile image selected');
                        setState(() => _profileImage = image);
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // TSC Certificate Section
                    _buildSectionTitle('TSC Certificate'),
                    const SizedBox(height: 8),
                    TscUploadWidget(
                      onCertificateSelected: (certificate) {
                        developer.log('TeacherProfileSetupScreen: TSC certificate selected');
                        setState(() => _tscCertificate = certificate);
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Teaching Preferences Section
                    _buildSectionTitle('Teaching Preferences'),
                    const SizedBox(height: 8),
                    _buildTeachingPreferences(),
                    const SizedBox(height: 24),
                    
                    // Availability Section
                    _buildSectionTitle('Available Times'),
                    const SizedBox(height: 8),
                    AvailabilitySelector(
                      selectedTimes: _selectedTimes,
                      onTimesChanged: (times) {
                        developer.log('TeacherProfileSetupScreen: Availability times changed: $times');
                        setState(() => _selectedTimes = List.from(times));
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    _buildSubmitButton(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTeachingPreferences() {
    return Column(
      children: [
        _buildPreferenceToggle(
          'Online Classes',
          _offersOnlineClasses,
          (value) {
            developer.log('TeacherProfileSetupScreen: Online classes preference changed to $value');
            setState(() => _offersOnlineClasses = value);
          },
        ),
        const SizedBox(height: 12),
        _buildPreferenceToggle(
          'Home Tutoring',
          _offersHomeTutoring,
          (value) {
            developer.log('TeacherProfileSetupScreen: Home tutoring preference changed to $value');
            setState(() => _offersHomeTutoring = value);
          },
        ),
      ],
    );
  }

  Widget _buildPreferenceToggle(String title, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: value ? Colors.blue[50] : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
                color: value ? Colors.blue : Colors.white,
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Complete Profile Setup',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    developer.log('TeacherProfileSetupScreen: Starting profile submission');
    
    if (!_formKey.currentState!.validate()) {
      developer.log('TeacherProfileSetupScreen: Form validation failed');
      return;
    }

    if (_profileImage == null) {
      developer.log('TeacherProfileSetupScreen: Profile image is required');
      setState(() => _errorMessage = 'Please upload a profile photo');
      return;
    }

    if (_tscCertificate == null) {
      developer.log('TeacherProfileSetupScreen: TSC certificate is required');
      setState(() => _errorMessage = 'Please upload your TSC certificate');
      return;
    }

    if (_selectedTimes.isEmpty) {
      developer.log('TeacherProfileSetupScreen: At least one availability time is required');
      setState(() => _errorMessage = 'Please select at least one available time');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Upload profile image
      developer.log('TeacherProfileSetupScreen: Uploading profile image');
      final profileImageUrl = await _teacherService.uploadProfileImage(_profileImage!, 'current_teacher_id');
      if (profileImageUrl == null) {
        throw Exception('Failed to upload profile image');
      }

      // Upload TSC certificate
      developer.log('TeacherProfileSetupScreen: Uploading TSC certificate');
      final tscCertificateUrl = await _teacherService.uploadTscCertificate(_tscCertificate!, 'current_teacher_id');
      if (tscCertificateUrl == null) {
        throw Exception('Failed to upload TSC certificate');
      }

      // Update teaching preferences
      developer.log('TeacherProfileSetupScreen: Updating teaching preferences');
      await _teacherService.updateTeachingPreferences(
        'current_teacher_id',
        _offersOnlineClasses,
        _offersHomeTutoring,
        _selectedTimes,
      );

      // Update verification status to pending
      developer.log('TeacherProfileSetupScreen: Setting verification status to pending');
      await _teacherService.updateVerificationStatus('current_teacher_id', 'pending');

      developer.log('TeacherProfileSetupScreen: Profile setup completed successfully');
      
      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed! Awaiting verification.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('TeacherProfileSetupScreen: Error during profile submission: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }
}