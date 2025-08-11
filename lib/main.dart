import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'routes.dart';

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
    routes: AppRoutes.routes,
    debugShowCheckedModeBanner: false,
  );
}