import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../data/models/teacher_model.dart';
import '../../data/services/teacher_service.dart';
import 'widgets/verification_card_widget.dart';

// Admin verification dashboard following Flutter Lite rules (<150 lines)
class VerificationDashboardScreen extends StatefulWidget {
  const VerificationDashboardScreen({super.key});

  @override
  State<VerificationDashboardScreen> createState() => _VerificationDashboardScreenState();
}

class _VerificationDashboardScreenState extends State<VerificationDashboardScreen> {
  final TeacherService _teacherService = TeacherService();
  List<TeacherModel> _pendingTeachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingTeachers();
  }

  Future<void> _loadPendingTeachers() async {
    developer.log('VerificationDashboardScreen: Loading pending teachers');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teachers = await _teacherService.getTeachersByVerificationStatus('pending');
      developer.log('VerificationDashboardScreen: Loaded ${teachers.length} pending teachers');
      
      setState(() {
        _pendingTeachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('VerificationDashboardScreen: Error loading pending teachers: $e');
      setState(() {
        _errorMessage = 'Error loading pending teachers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _pendingTeachers.isEmpty
                  ? _buildEmptyState()
                  : _buildTeacherList(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text(
      'Teacher Verification',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
    centerTitle: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.black),
        onPressed: _loadPendingTeachers,
      ),
    ],
  );

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingTeachers,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pending Verifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All teacher applications have been processed.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    return RefreshIndicator(
      onRefresh: _loadPendingTeachers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingTeachers.length,
        itemBuilder: (context, index) {
          final teacher = _pendingTeachers[index];
          return VerificationCardWidget(
            teacher: teacher,
            onTeacherUpdated: _loadPendingTeachers,
          );
        },
      ),
    );
  }
}