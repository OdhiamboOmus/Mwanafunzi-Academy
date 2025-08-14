import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/core/service_locator.dart' show ServiceLocator;
import 'package:mwanafunzi_academy/routes.dart';
import 'package:mwanafunzi_academy/services/user_service.dart' show UserService;
import 'package:mwanafunzi_academy/services/motivation_service.dart' show MotivationService;
import 'package:mwanafunzi_academy/services/progress_service.dart' show ProgressService;
import '../../data/repositories/user_repository.dart';
import '../shared/lesson_cards_widget.dart';
import '../shared/competition_cards_widget.dart';
import '../shared/bottom_navigation_widget.dart';
import '../shared/user_greeting_widget.dart';

// Student home screen following Flutter Lite rules (<150 lines)
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final UserRepository _userRepository = UserRepository();
  final UserService _userService = ServiceLocator().userService;
  final MotivationService _motivationService = ServiceLocator().motivationService;
  final ProgressService _progressService = ServiceLocator().progressService;
  
  String _studentName = 'Loading...';
  String _selectedGrade = '';
  bool _isLoading = true;
  int _selectedBottomNavIndex = 0;
  bool _isRefreshing = false;
  int _userPoints = 0;

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
          icon: const Icon(Icons.settings, color: Color(0xFF50E801)),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
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
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Welcome Section with dynamic greeting and motivational message
                      const SizedBox(height: 16),
                      _buildUserGreetingSection(),
                      const SizedBox(height: 24),

                      // Lesson Cards
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                        ),
                        child: Column(
                          children: [
                            const LessonCardsWidget(selectedGrade: ''),
                            const SizedBox(height: 32),
                            const CompetitionCardsWidget(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
    ),
  );


  Widget _buildQuickLink({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF50E801), size: 20),
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
  );

  Future<void> _loadUserData() async {
    try {
      debugPrint('🔍 DEBUG: Loading user data...');
      final user = _userRepository.getCurrentUser();
      debugPrint('🔍 DEBUG: Current user from repository: ${user?.toString() ?? 'null'}');
      
      if (user != null) {
        debugPrint('🔍 DEBUG: Attempting to fetch dynamic user name from UserService...');
        
        // Use UserService to get dynamic user greeting
        final greeting = await _userService.getUserGreeting(user.uid);
        setState(() {
          _studentName = greeting.replaceFirst('Welcome back, ', '').replaceFirst('!', '');
          _isLoading = false;
        });
        
        // Load user points from ProgressService
        final points = await _progressService.getLocalPoints(user.uid);
        setState(() {
          _userPoints = points;
        });
        
        debugPrint('🔍 DEBUG: Dynamic user name loaded: $_studentName');
        debugPrint('🔍 DEBUG: User points loaded: $_userPoints');
        debugPrint('🔍 DEBUG: Services initialized: ${ServiceLocator().isInitialized}');
        
      } else {
        debugPrint('🔍 DEBUG: No user found in repository');
        setState(() {
          _studentName = 'Learner';
          _isLoading = false;
          _userPoints = 0;
        });
      }
    } catch (e) {
      debugPrint('🔍 DEBUG: Error loading user data: $e');
      setState(() {
        _studentName = 'Learner';
        _isLoading = false;
        _userPoints = 0;
      });
    }
  }

  @override
  void dispose() {
    // Clean up any controllers if needed
    super.dispose();
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) => Expanded(
    child: GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );

  void _showGradeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Grade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: 12,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final grade = (index + 1).toString();
                  final isSelected = grade == _selectedGrade;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x1A50E801)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF50E801)
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        'Grade $grade',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF50E801)
                              : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF50E801),
                              size: 24,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedGrade = grade);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGreetingSection() {
    // For now, we'll use a placeholder user ID
    // In a real implementation, this would be handled through authentication
    const String placeholderUserId = 'demo_user_123';
    
    return UserGreetingWidget(
      userId: placeholderUserId,
      userService: _userService,
      motivationService: _motivationService,
      userPoints: _userPoints,
    );
  }

  Future<void> _refreshData() async {
    debugPrint('🔍 DEBUG: Refresh function called - SHOULD BE NAVIGATING TO SETTINGS');
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
