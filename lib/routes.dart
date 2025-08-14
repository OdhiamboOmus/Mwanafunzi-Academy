import 'package:flutter/material.dart';
import 'presentation/auth/sign_in_screen.dart';
import 'presentation/auth/sign_up_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/auth/admin_login_screen.dart';
import 'presentation/admin/admin_home_screen.dart';
import 'presentation/student/student_home_screen.dart';
import 'presentation/student/settings_screen.dart';
import 'presentation/parent/parent_home_screen.dart';
import 'presentation/teacher/teacher_home_screen.dart';

class AppRoutes {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String adminLogin = '/admin-login';
  static const String adminHome = '/admin-home';
  static const String studentHome = '/student-home';
  static const String settings = '/settings';
  static const String parentHome = '/parent-home';
  static const String teacherHome = '/teacher-home';

  static Map<String, WidgetBuilder> get routes => {
    signIn: (context) => const SignInScreen(),
    signUp: (context) => const SignUpScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    adminLogin: (context) => const AdminLoginScreen(),
    adminHome: (context) => const AdminHomeScreen(),
    studentHome: (context) => const StudentHomeScreen(),
    settings: (context) => const SettingsScreen(),
    parentHome: (context) => const ParentHomeScreen(),
    teacherHome: (context) => const TeacherHomeScreen(),
  };
}