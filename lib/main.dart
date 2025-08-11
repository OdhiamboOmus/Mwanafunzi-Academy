import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'presentation/auth/sign_in_screen.dart';
import 'presentation/auth/sign_up_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/auth/admin_login_screen.dart';
import 'presentation/admin/admin_home_screen.dart';
import 'presentation/student/student_home_screen.dart';
import 'presentation/parent/parent_home_screen.dart';
import 'presentation/teacher/teacher_home_screen.dart';

// 🚨 CRITICAL SIZE OPTIMIZATION TODOS 🚨
// TODO: AVOID importing entire packages - import specific classes only
// TODO: Use 'import 'package:flutter/material.dart' show Widget, StatelessWidget;' when possible
// TODO: Avoid StatefulWidget unless absolutely necessary (adds overhead)
// TODO: Use const constructors EVERYWHERE (marked with const keyword)
// TODO: Avoid creating custom themes (use default Material theme)
// TODO: Minimize widget tree depth - avoid unnecessary nesting
// TODO: Use basic widgets: Text, Container, Column, Row, Stack
// TODO: AVOID heavy widgets: ListView.builder for large lists, complex animations
// TODO: Test app size after every major feature addition

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MwanafunziAcademyApp());
}

class MwanafunziAcademyApp extends StatelessWidget {
  const MwanafunziAcademyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mwanafunzi Academy',
    home: const SplashScreen(),
    routes: _buildRoutes,
    debugShowCheckedModeBanner: false,
  );

  Map<String, WidgetBuilder> get _buildRoutes => {
    '/sign-in': (context) => const SignInScreen(),
    '/sign-up': (context) => const SignUpScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),
    '/admin-login': (context) => const AdminLoginScreen(),
    '/admin-home': (context) => const AdminHomeScreen(),
    '/student-home': (context) => const StudentHomeScreen(),
    '/parent-home': (context) => const ParentHomeScreen(),
    '/teacher-home': (context) => const TeacherHomeScreen(),
  };
}