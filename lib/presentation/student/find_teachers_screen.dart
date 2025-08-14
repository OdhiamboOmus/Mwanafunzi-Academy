import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/bottom_navigation_widget.dart';
import 'home_tutoring_screen.dart';
import 'widgets/teacher_toggle_buttons.dart';
import 'widgets/teacher_filter_overlay.dart';

class FindTeachersScreen extends StatefulWidget {
  const FindTeachersScreen({super.key});

  @override
  State<FindTeachersScreen> createState() => _FindTeachersScreenState();
}

class _FindTeachersScreenState extends State<FindTeachersScreen>
    with TickerProviderStateMixin {
  int _selectedBottomNavIndex = 3;
  bool _isOnlineClassesSelected = true;
  bool _showFilters = false;
  bool _isLoading = true;
  String _selectedSubject = 'English';
  String _selectedClassSize = '5 Students';
  String _selectedTime = 'Weekend (Flexible)';

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

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Find Teachers',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
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
            onSubjectChanged: (value) =>
                setState(() => _selectedSubject = value),
            onClassSizeChanged: (value) =>
                setState(() => _selectedClassSize = value),
            onTimeChanged: (value) => setState(() => _selectedTime = value),
            onClose: _closeFilters,
          ),
      ],
    ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
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

  Widget _buildOnlineContent() => _isLoading
      ? const Center(
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
        )
      : const Center(
          child: Text(
            'Online teachers will be displayed here',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        );

  void _closeFilters() {
    HapticFeedback.lightImpact();
    _filterController.reverse().then((_) {
      if (mounted) setState(() => _showFilters = false);
    });
  }
}
