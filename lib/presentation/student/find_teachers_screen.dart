import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:mwanafunzi_academy/routes.dart';
import '../shared/bottom_navigation_widget.dart';
import 'home_tutoring_screen.dart';
import 'widgets/teacher_toggle_buttons.dart';
import 'widgets/teacher_filter_overlay.dart';
import 'widgets/teacher_card_widget.dart';
import '../../algorithms/teacher_discovery_algorithm.dart';
import '../../data/models/teacher_model.dart';
import '../../data/services/teacher_service.dart';

class FindTeachersScreen extends StatefulWidget {
  const FindTeachersScreen({super.key});

  @override
  State<FindTeachersScreen> createState() => _FindTeachersScreenState();
}

class _FindTeachersScreenState extends State<FindTeachersScreen>
    with TickerProviderStateMixin {
  bool _isOnlineClassesSelected = true;
  bool _showFilters = false;
  bool _isLoading = true;
  String _selectedSubject = 'English';
  String _selectedClassSize = '5 Students';
  String _selectedTime = 'Weekend (Flexible)';
  
  // Teacher discovery data
  final List<TeacherModel> _teachers = [];
  final List<TeacherModel> _filteredTeachers = [];
  bool _isTeachersLoading = false;
  final TeacherService _teacherService = TeacherService();

  late AnimationController _filterController;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _filterFadeAnimation;

  @override
  void initState() {
    super.initState();
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _filterSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _filterController, curve: Curves.easeOutBack),
        );

    _filterFadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeInOut),
    );

    developer.log('FindTeachersScreen: Initializing screen');
    _loadTeachers();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
    developer.log('FindTeachersScreen: Screen disposed');
  }

  // Load teachers from service
  Future<void> _loadTeachers() async {
    developer.log('FindTeachersScreen: Loading teachers');
    setState(() {
      _isTeachersLoading = true;
    });
    
    try {
      final teachers = await _teacherService.getAvailableTeachers();
      developer.log('FindTeachersScreen: Loaded ${teachers.length} teachers');
      
      setState(() {
        _teachers.clear();
        _teachers.addAll(teachers);
        _applyFilters();
      });
    } catch (e) {
      developer.log('FindTeachersScreen: Error loading teachers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTeachersLoading = false;
        });
      }
    }
  }

  // Apply filters and rank teachers
  void _applyFilters() {
    developer.log('FindTeachersScreen: Applying filters');
    developer.log('FindTeachersScreen: Selected subject: $_selectedSubject');
    developer.log('FindTeachersScreen: Selected class size: $_selectedClassSize');
    developer.log('FindTeachersScreen: Selected time: $_selectedTime');
    
    // Build filter map for discovery algorithm
    final filters = <String, dynamic>{
      'teachingType': _isOnlineClassesSelected ? 'online' : 'home',
    };
    
    // Add subject filter
    if (_selectedSubject != 'All Subjects') {
      filters['subject'] = _selectedSubject;
    }
    
    // Add time filter
    if (_selectedTime != 'Weekend (Flexible)') {
      // Extract time period from selected time
      String timePeriod = 'Weekend';
      if (_selectedTime.contains('Morning')) {
        timePeriod = 'Morning';
      } else if (_selectedTime.contains('Afternoon')) timePeriod = 'Afternoon';
      else if (_selectedTime.contains('Evening')) timePeriod = 'Evening';
      
      filters['availableTimes'] = [timePeriod];
    }
    
    // Add price filter based on class size
    double maxPrice = 4000; // Default for 1 student
    if (_selectedClassSize.contains('3 Students')) {
      maxPrice = 3000;
    } else if (_selectedClassSize.contains('5 Students')) maxPrice = 2000;
    
    filters['maxPrice'] = maxPrice;
    
    // Apply discovery algorithm
    try {
      final rankedTeachers = TeacherDiscoveryAlgorithm.rankTeachers(
        teachers: List<TeacherModel>.from(_teachers),
        filters: filters,
      );
      
      developer.log('FindTeachersScreen: Algorithm returned ${rankedTeachers.length} teachers');
      
      setState(() {
        _filteredTeachers.clear();
        _filteredTeachers.addAll(rankedTeachers);
      });
    } catch (e) {
      developer.log('FindTeachersScreen: Error applying discovery algorithm: $e');
      setState(() {
        _filteredTeachers.clear();
        _filteredTeachers.addAll(_teachers);
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
        'Mwanafunzi Academy',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF50E801)),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],
    ),
    body: Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            TeacherToggleButtons(
              isOnlineSelected: _isOnlineClassesSelected,
              onToggle: (isOnline) =>
                  setState(() => _isOnlineClassesSelected = isOnline),
            ),
            const SizedBox(height: 20),
            if (_isOnlineClassesSelected) _buildFiltersButton(),
            Expanded(
              child: _isOnlineClassesSelected
                  ? _buildOnlineContent()
                  : const HomeTutoringScreen(),
            ),
          ],
        ),
        if (_showFilters)
          TeacherFilterOverlay(
            slideAnimation: _filterSlideAnimation,
            fadeAnimation: _filterFadeAnimation,
            selectedSubject: _selectedSubject,
            selectedClassSize: _selectedClassSize,
            selectedTime: _selectedTime,
            onSubjectChanged: (value) {
              developer.log('FindTeachersScreen: Subject filter changed to: $value');
              setState(() => _selectedSubject = value);
              _applyFilters();
            },
            onClassSizeChanged: (value) {
              developer.log('FindTeachersScreen: Class size filter changed to: $value');
              setState(() => _selectedClassSize = value);
              _applyFilters();
            },
            onTimeChanged: (value) {
              developer.log('FindTeachersScreen: Time filter changed to: $value');
              setState(() => _selectedTime = value);
              _applyFilters();
            },
            onClose: _closeFilters,
          ),
      ],
    ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: 3, // Teachers tab is selected
      onTabChanged: (index) {
        if (index == 0) { // Home tab
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 1) { // Quiz tab
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushNamed(context, AppRoutes.quizChallenge);
        } else if (index == 2) { // Video tab
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushNamed(context, AppRoutes.video);
        }
        // If it's the teachers tab, just update the local state
        setState(() {});
      },
    ),
  );

  Widget _buildFiltersButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showFilters = true);
        _filterController.forward();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF50E801)),
          color: Colors.white,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, color: Color(0xFF50E801), size: 20),
            SizedBox(width: 8),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF50E801),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Color(0xFF50E801), size: 20),
          ],
        ),
      ),
    ),
  );

  Widget _buildOnlineContent() {
    if (_isTeachersLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF50E801)),
            SizedBox(height: 16),
            Text(
              'Finding teachers...',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }
    
    if (_filteredTeachers.isEmpty) {
      return const Center(
        child: Text(
          'No teachers found matching your criteria',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTeachers.length,
      itemBuilder: (context, index) {
        final teacher = _filteredTeachers[index];
        developer.log('FindTeachersScreen: Building teacher card for ${teacher.fullName} at position $index');
        return TeacherCardWidget(
          teacher: teacher,
          index: index,
          onTap: () {
            developer.log('FindTeachersScreen: Teacher card tapped for ${teacher.fullName}');
            Navigator.pushNamed(context, '/teacher-detail', arguments: teacher.id);
          },
          onBook: () {
            developer.log('FindTeachersScreen: Book button tapped for ${teacher.fullName}');
            Navigator.pushNamed(context, '/booking', arguments: teacher.id);
          },
        );
      },
    );
  }


  void _closeFilters() {
    HapticFeedback.lightImpact();
    _filterController.reverse().then((_) {
      if (mounted) setState(() => _showFilters = false);
    });
  }
}
