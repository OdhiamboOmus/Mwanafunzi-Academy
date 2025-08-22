import 'package:flutter/material.dart';
import 'presentation/auth/sign_in_screen.dart';
import 'presentation/auth/sign_up_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/auth/admin_login_screen.dart';
import 'presentation/admin/admin_home_screen.dart';
import 'presentation/admin/admin_quiz_upload_screen.dart';
import 'presentation/admin/admin_lesson_upload_screen.dart';
import 'presentation/student/student_home_screen.dart';
import 'presentation/student/settings_screen.dart';
import 'presentation/student/video_screen.dart';
import 'presentation/student/lesson_detail_screen.dart';
import 'presentation/student/quiz_challenge_screen.dart';
import 'presentation/student/find_teachers_screen.dart';
import 'presentation/student/quiz_interface_screen.dart';
import 'presentation/student/competition_quiz_screen.dart';
import 'presentation/parent/parent_main_screen.dart';
import 'presentation/teacher/teacher_main_screen.dart';

class AppRoutes {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String adminLogin = '/admin-login';
  static const String adminHome = '/admin-home';
  static const String adminQuizUpload = '/admin-quiz-upload';
  static const String adminLessonUpload = '/admin-lesson-upload';
  static const String studentHome = '/student-home';
  static const String settings = '/settings';
  static const String parentHome = '/parent-home';
  static const String teacherHome = '/teacher-home';
  static const String video = '/video';
  static const String quizChallenge = '/quiz-challenge';
  static const String findTeachers = '/find-teachers';
  static const String lessonDetail = '/lesson-detail';
  static const String quizInterface = '/quiz-interface';
  static const String competitionQuiz = '/competition-quiz';

  static Map<String, WidgetBuilder> get routes => {
    signIn: (context) => const SignInScreen(),
    signUp: (context) => const SignUpScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    adminLogin: (context) => const AdminLoginScreen(),
    adminHome: (context) => const AdminHomeScreen(),
    adminQuizUpload: (context) => const AdminQuizUploadScreen(),
    adminLessonUpload: (context) => const AdminLessonUploadScreen(),
    studentHome: (context) => const StudentHomeScreen(),
    settings: (context) => const SettingsScreen(),
    parentHome: (context) => const ParentMainScreen(),
    teacherHome: (context) => const TeacherMainScreen(),
    video: (context) => const VideoScreen(selectedGrade: 'Grade 1'),
    quizChallenge: (context) => const QuizChallengeScreen(),
    findTeachers: (context) => const FindTeachersScreen(),
    lessonDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return LessonDetailScreen(
        subject: args['subject'] ?? 'Mathematics',
        grade: args['grade'] ?? 'Grade 1',
        icon: args['icon'] ?? Icons.calculate,
        progress: args['progress'] ?? 0.5,
        lessonId: args['lessonId'] ?? 'default_lesson',
      );
    },
    quizInterface: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return QuizInterfaceScreen(
        subject: args['subject'],
        quizTitle: args['quizTitle'],
        grade: args['grade'],
        topic: args['topic'],
      );
    },
    competitionQuiz: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return CompetitionQuizScreen(
        competitionId: args['competitionId'],
        studentId: args['studentId'],
        questions: args['questions'],
        challenge: args['challenge'],
      );
    },
  };
}