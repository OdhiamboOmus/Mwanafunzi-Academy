import 'package:flutter/material.dart';
import '../../data/repositories/user_repository.dart';
import '../shared/grade_selector_widget.dart';
import '../shared/lesson_cards_widget.dart';
import '../shared/competition_cards_widget.dart';
import '../shared/bottom_navigation_widget.dart';

// Student home screen following Flutter Lite rules (<150 lines)
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final UserRepository _userRepository = UserRepository();
  String _studentName = 'Loading...';
  String _selectedGrade = '';
  bool _isLoading = true;
  int _selectedBottomNavIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Student Dashboard',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF50E801)),
          onPressed: _refreshData,
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshData,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                return Column(
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(),
                    const SizedBox(height: 16),
                    
                    // Grade Selector
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                      ),
                      child: GradeSelectorWidget(
                        selectedGrade: _selectedGrade,
                        onGradeChanged: (grade) => setState(() => _selectedGrade = grade),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Lesson Cards
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                        ),
                        children: [
                          const LessonCardsWidget(selectedGrade: ''),
                          const SizedBox(height: 32),
                          const CompetitionCardsWidget(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
    ),
  );

  Widget _buildWelcomeSection() => LayoutBuilder(
    builder: (context, constraints) {
      final isTablet = constraints.maxWidth > 600;
      return Container(
        margin: EdgeInsets.all(isTablet ? 24 : 16),
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          color: const Color(0x1A50E801),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, $_studentName!',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Continue your learning journey',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            if (isTablet)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickLink(
                      title: 'Leaderboard',
                      icon: Icons.leaderboard,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickLink(
                      title: 'My Ranking',
                      icon: Icons.emoji_events,
                      onTap: () {},
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildQuickLink(
                      title: 'Leaderboard',
                      icon: Icons.leaderboard,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickLink(
                      title: 'My Ranking',
                      icon: Icons.emoji_events,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );

  Widget _buildQuickLink({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF50E801),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _loadUserData() async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        setState(() {
          _studentName = 'Student Name';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up any controllers if needed
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    
    await _loadUserData();
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
}