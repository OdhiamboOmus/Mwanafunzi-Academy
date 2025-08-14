import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../shared/error_handler.dart';
import '../shared/toast_service.dart';
import 'teacher_step1_form.dart';
import 'teacher_step2_form.dart';
import 'teacher_step3_form.dart';

// Main teacher signup form following Flutter Lite rules (<120 lines)
class TeacherSignUpForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const TeacherSignUpForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TeacherSignUpForm> createState() => _TeacherSignUpFormState();
}

class _TeacherSignUpFormState extends State<TeacherSignUpForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 data
  final _nameController = TextEditingController();
  String _selectedGender = AppConstants.genders[0];
  final _ageController = TextEditingController();

  // Step 2 data
  final List<String> _selectedSubjects = [];
  String? _selectedConstituency;
  final _tscController = TextEditingController();

  // Step 3 data
  final _mainPhoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _priceController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _tscController.dispose();
    _mainPhoneController.dispose();
    _altPhoneController.dispose();
    _availabilityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7, // Give it bounded height
      child: Column(
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                TeacherStep1Form(
                  nameController: _nameController,
                  selectedGender: _selectedGender,
                  ageController: _ageController,
                  onGenderChanged: (gender) => setState(() => _selectedGender = gender),
                ),
                TeacherStep2Form(
                  selectedSubjects: _selectedSubjects,
                  selectedConstituency: _selectedConstituency,
                  tscController: _tscController,
                  onSubjectToggle: _toggleSubject,
                  onConstituencyChanged: (constituency) => setState(() => _selectedConstituency = constituency),
                ),
                TeacherStep3Form(
                  mainPhoneController: _mainPhoneController,
                  altPhoneController: _altPhoneController,
                  availabilityController: _availabilityController,
                  priceController: _priceController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                ),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
          decoration: BoxDecoration(
            color: i <= _currentStep ? AppConstants.brandColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Create Account' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSubject(String subject) {
    setState(() {
      _selectedSubjects.contains(subject)
          ? _selectedSubjects.remove(subject)
          : _selectedSubjects.add(subject);
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitForm();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
               _ageController.text.isNotEmpty &&
               int.tryParse(_ageController.text) != null;
      case 1:
        return _selectedSubjects.isNotEmpty && _selectedConstituency != null;
      case 2:
        return _mainPhoneController.text.isNotEmpty &&
               _availabilityController.text.isNotEmpty &&
               _emailController.text.isNotEmpty &&
               _passwordController.text.isNotEmpty &&
               _confirmPasswordController.text.isNotEmpty &&
               _passwordController.text == _confirmPasswordController.text;
      default:
        return false;
    }
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) {
      ToastService.showError(context, 'Please fill all required fields');
      return;
    }

    if (_tscController.text.trim().isEmpty) {
      final shouldContinue = await _showTscDialog();
      if (!shouldContinue) return;
    }

    // Check network connectivity
    if (!await ErrorHandler.hasNetworkConnection()) {
      if (mounted) {
        ErrorHandler.showNetworkError(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Form should only collect data, NOT create user
      // The user creation should be handled by the sign-up screen
      debugPrint('🔍 DEBUG: Teacher form validation successful, passing data to sign-up screen');

      widget.onSubmit({
        'userType': AppConstants.userTypeTeacher,
        'fullName': _nameController.text.trim(),
        'gender': _selectedGender,
        'age': int.parse(_ageController.text),
        'subjects': _selectedSubjects,
        'areaOfOperation': _selectedConstituency!,
        'tscNumber': _tscController.text.trim().isEmpty ? null : _tscController.text.trim(),
        'mainPhone': _mainPhoneController.text.trim(),
        'alternativePhone': _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      
      debugPrint('🔍 DEBUG: Teacher form data submitted successfully');
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      
      if (e.toString().contains('FirebaseAuthException')) {
        errorMessage = ErrorHandler.getAuthErrorMessage(e.toString().split(']')[1].trim());
      } else if (e.toString().contains('FirebaseFirestoreException')) {
        errorMessage = ErrorHandler.getFirestoreErrorMessage(e.toString().split(']')[1].trim());
      }
      
      if (mounted) {
        ToastService.showError(context, errorMessage);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showTscDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TSC Number'),
        content: const Text(
          'You have not entered your TSC number. This is optional but '
          'recommended for verification. Do you want to continue without it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }
}