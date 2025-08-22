import 'package:flutter/material.dart';
import 'teacher_home_screen.dart';
import 'teacher_payout_dashboard_screen.dart';
import 'teacher_profile_setup_screen.dart';
import 'widgets/teacher_bottom_navigation.dart';
import 'widgets/booking_card_widget.dart';
import '../../data/models/booking_model.dart';

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
    TeacherPayoutDashboardScreen(teacherId: 'current_teacher_id'), // TODO: Get actual teacherId
    const TeacherProfileSetupScreen(),
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

// Classes screen using existing booking widgets
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
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Classes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Using booking card widget to display classes
          BookingCardWidget(
            booking: BookingModel(
              id: 'class_1',
              teacherId: 'teacher_1',
              parentId: 'parent_1',
              studentId: 'student_1',
              subject: 'Mathematics',
              numberOfWeeks: 4,
              weeklyRate: 2500.0,
              totalAmount: 10000.0,
              platformFee: 2000.0,
              teacherPayout: 8000.0,
              dayOfWeek: 'Monday',
              startTime: '10:00',
              duration: 60,
              startDate: DateTime(2024, 1, 15),
              endDate: DateTime(2024, 2, 12),
              status: 'active',
              createdAt: DateTime(2024, 1, 10),
            ),
            onLessonCompleted: (lessonId) {
              // Handle lesson completion
            },
          ),
          const SizedBox(height: 12),
          BookingCardWidget(
            booking: BookingModel(
              id: 'class_2',
              teacherId: 'teacher_1',
              parentId: 'parent_2',
              studentId: 'student_2',
              subject: 'English',
              numberOfWeeks: 6,
              weeklyRate: 2000.0,
              totalAmount: 12000.0,
              platformFee: 2400.0,
              teacherPayout: 9600.0,
              dayOfWeek: 'Wednesday',
              startTime: '14:00',
              duration: 45,
              startDate: DateTime(2024, 1, 17),
              endDate: DateTime(2024, 2, 28),
              status: 'active',
              createdAt: DateTime(2024, 1, 12),
            ),
            onLessonCompleted: (lessonId) {
              // Handle lesson completion
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Upcoming Classes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          BookingCardWidget(
            booking: BookingModel(
              id: 'class_3',
              teacherId: 'teacher_1',
              parentId: 'parent_3',
              studentId: 'student_3',
              subject: 'Science',
              numberOfWeeks: 8,
              weeklyRate: 3000.0,
              totalAmount: 24000.0,
              platformFee: 4800.0,
              teacherPayout: 19200.0,
              dayOfWeek: 'Friday',
              startTime: '16:00',
              duration: 60,
              startDate: DateTime(2024, 2, 1),
              endDate: DateTime(2024, 3, 29),
              status: 'payment_pending',
              createdAt: DateTime(2024, 1, 20),
            ),
            onLessonCompleted: (lessonId) {
              // Handle lesson completion
            },
          ),
        ],
      ),
    ),
  );
}

