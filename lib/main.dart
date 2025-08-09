import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

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
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Mwanafunzi Academy',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
      // TODO: Avoid custom themes to save space
      // TODO: Use default Material colors and typography
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // TODO: Avoid AppBar if not needed (saves space)
      // TODO: Use basic layout widgets only
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mwanafunzi Academy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Kenya\'s Top Learning Platform',
              style: TextStyle(fontSize: 16),
            ),
            // TODO: Add your features here
            // TODO: Remember to check size impact of each addition
          ],
        ),
      ),
    );
  }
}