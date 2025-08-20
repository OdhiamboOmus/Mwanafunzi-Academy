import 'package:flutter/material.dart';
import 'presentation/auth/sign_in_screen.dart';
import 'presentation/auth/sign_up_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/auth/admin_login_screen.dart';
import 'presentation/admin/admin_home_screen.dart';
import 'presentation/admin/admin_quiz_upload_screen.dart';
import 'presentation/student/student_home_screen.dart';
import 'presentation/student/settings_screen.dart';
import 'presentation/student/video_screen.dart';
import 'presentation/student/lesson_detail_screen.dart';
import 'presentation/student/quiz_challenge_screen.dart';
import 'presentation/student/find_teachers_screen.dart';
import 'presentation/parent/parent_home_screen.dart';
import 'presentation/teacher/teacher_home_screen.dart';

class AppRoutes {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String adminLogin = '/admin-login';
  static const String adminHome = '/admin-home';
  static const String adminQuizUpload = '/admin-quiz-upload';
  static const String studentHome = '/student-home';
  static const String settings = '/settings';
  static const String parentHome = '/parent-home';
  static const String teacherHome = '/teacher-home';
  static const String video = '/video';
  static const String quizChallenge = '/quiz-challenge';
  static const String findTeachers = '/find-teachers';
  static const String lessonDetail = '/lesson-detail';

  static Map<String, WidgetBuilder> get routes => {
    signIn: (context) => const SignInScreen(),
    signUp: (context) => const SignUpScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    adminLogin: (context) => const AdminLoginScreen(),
    adminHome: (context) => const AdminHomeScreen(),
    adminQuizUpload: (context) => const AdminQuizUploadScreen(),
    studentHome: (context) => const StudentHomeScreen(),
    settings: (context) => const SettingsScreen(),
    parentHome: (context) => const ParentHomeScreen(),
    teacherHome: (context) => const TeacherHomeScreen(),
    video: (context) => const VideoScreen(selectedGrade: 'Grade 1'),
    quizChallenge: (context) => const QuizChallengeScreen(),
    findTeachers: (context) => const FindTeachersScreen(),
    lessonDetail: (context) => const LessonDetailScreen(
      subject: 'Mathematics',
      grade: 'Grade 1',
      icon: Icons.calculate,
      progress: 0.5,
    ),
  };
}