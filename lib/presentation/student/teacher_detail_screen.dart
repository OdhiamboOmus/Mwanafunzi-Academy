import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../shared/bottom_navigation_widget.dart';
import 'widgets/teacher_profile_header.dart';
import 'widgets/teacher_verification_section.dart';
import 'widgets/teacher_teaching_info_section.dart';
import 'widgets/teacher_availability_section.dart';
import 'widgets/teacher_contact_section.dart';
import 'widgets/teacher_book_button.dart';
import '../../data/models/teacher_model.dart';
import '../../data/services/teacher_service.dart';

/// Teacher detail screen showing complete teacher profile with view tracking
/// and comprehensive logging for debugging and analytics.
class TeacherDetailScreen extends StatefulWidget {
  final String teacherId;

  const TeacherDetailScreen({
    super.key,
    required this.teacherId,
  });

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  int _selectedBottomNavIndex = 3;
  bool _isLoading = true;
  bool _isTeacherLoading = false;
  TeacherModel? _teacher;
  final TeacherService _teacherService = TeacherService();

  @override
  void initState() {
    super.initState();
    developer.log('TeacherDetailScreen: Initializing for teacher ID: ${widget.teacherId}');
    _loadTeacher();
  }

  @override
  void dispose() {
    developer.log('TeacherDetailScreen: Screen disposed for teacher ID: ${widget.teacherId}');
    super.dispose();
  }

  // Load teacher details
  Future<void> _loadTeacher() async {
    developer.log('TeacherDetailScreen: Loading teacher details for ID: ${widget.teacherId}');
    setState(() {
      _isTeacherLoading = true;
    });

    try {
      final teacher = await _teacherService.getTeacherById(widget.teacherId);
      developer.log('TeacherDetailScreen: Teacher loaded: ${teacher?.fullName ?? "null"}');
      
      setState(() {
        _teacher = teacher;
        _isLoading = false;
        _isTeacherLoading = false;
      });
    } catch (e) {
      developer.log('TeacherDetailScreen: Error loading teacher: $e');
      setState(() {
        _isLoading = false;
        _isTeacherLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Teacher Profile',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF50E801)),
                SizedBox(height: 16),
                Text(
                  'Loading teacher profile...',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          )
        : _teacher == null
            ? const Center(
                child: Text(
                  'Teacher not found',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              )
            : _buildTeacherProfile(),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
    ),
  );

  // Build complete teacher profile
  Widget _buildTeacherProfile() {
    developer.log('TeacherDetailScreen: Building profile for ${_teacher!.fullName}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher header section
          TeacherProfileHeader(teacher: _teacher!),
          
          const SizedBox(height: 24),
          
          // Verification status
          TeacherVerificationSection(teacher: _teacher!),
          
          const SizedBox(height: 24),
          
          // Teaching information
          TeacherTeachingInfoSection(teacher: _teacher!),
          
          const SizedBox(height: 24),
          
          // Availability and pricing
          TeacherAvailabilitySection(teacher: _teacher!),
          
          const SizedBox(height: 24),
          
          // Contact information
          TeacherContactSection(teacher: _teacher!),
          
          const SizedBox(height: 32),
          
          // Book button
          TeacherBookButton(
            teacherName: _teacher!.fullName,
            onPressed: () {
              developer.log('TeacherDetailScreen: Book button tapped for ${_teacher!.fullName}');
              // TODO: Navigate to booking screen
              Navigator.pushNamed(context, '/booking', arguments: _teacher!.id);
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}