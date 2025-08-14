import 'package:flutter/material.dart';
import 'parent_home_screen.dart';
import 'parent_find_teachers_screen.dart';
import 'widgets/parent_bottom_navigation.dart';

class ParentMainScreen extends StatefulWidget {
  const ParentMainScreen({super.key});

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ParentHomeContent(),
    const ParentGradesScreen(),
    const ParentScheduleScreen(),
    const ParentFindTeachersScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _selectedIndex, children: _screens),
    bottomNavigationBar: ParentBottomNavigation(
      selectedIndex: _selectedIndex,
      onTabChanged: (index) => setState(() => _selectedIndex = index),
    ),
  );
}

// Wrapper for the existing parent home screen content
class ParentHomeContent extends StatelessWidget {
  const ParentHomeContent({super.key});

  @override
  Widget build(BuildContext context) => const ParentHomeScreen();
}

// Placeholder screens for other tabs
class ParentGradesScreen extends StatelessWidget {
  const ParentGradesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Child Grades',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade, size: 80, color: Color(0xFF50E801)),
          SizedBox(height: 16),
          Text(
            'Grades & Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View your child\'s academic progress\nand report cards here',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class ParentScheduleScreen extends StatelessWidget {
  const ParentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Schedule & Attendance',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Color(0xFF50E801)),
          SizedBox(height: 16),
          Text(
            'Schedule & Attendance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your child\'s class schedule\nand attendance records',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
