import 'package:flutter/material.dart';
import 'teacher_home_screen.dart';
import 'teacher_payout_dashboard_screen.dart';
import 'widgets/teacher_bottom_navigation.dart';

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TeacherHomeContent(),
    const TeacherClassesScreen(),
    const TeacherAssignmentsScreen(),
    const TeacherGradesScreen(),
    TeacherPayoutDashboardScreen(teacherId: 'default_teacher_id'), // TODO: Get actual teacherId
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _selectedIndex, children: _screens),
    bottomNavigationBar: TeacherBottomNavigationWidget(
      selectedIndex: _selectedIndex,
      onTabChanged: (index) => setState(() => _selectedIndex = index),
    ),
  );
}

// Wrapper for the existing teacher home screen content
class TeacherHomeContent extends StatelessWidget {
  const TeacherHomeContent({super.key});

  @override
  Widget build(BuildContext context) => const TeacherHomeScreen();
}

// Placeholder screens for other tabs
class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'My Classes',
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
          Icon(Icons.class_, size: 80, color: Color(0xFF50E801)),
          SizedBox(height: 16),
          Text(
            'My Classes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View and manage your teaching classes here',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class TeacherAssignmentsScreen extends StatelessWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Assignments',
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
          Icon(Icons.add_task, size: 80, color: Color(0xFF50E801)),
          SizedBox(height: 16),
          Text(
            'Assignments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create and manage student assignments here',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class TeacherGradesScreen extends StatelessWidget {
  const TeacherGradesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Grades',
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
            'Grades',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage student grades and performance here',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}