import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'splash_screen.dart';
import 'routes.dart';
import 'core/services/storage_service.dart';
import 'core/service_locator.dart';
import 'services/user_service.dart';
import 'services/motivation_service.dart';
import 'services/progress_service.dart';
import 'services/settings_service.dart';
import 'data/repositories/user_repository.dart';

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
  
  // Initialize services
  final storageService = StorageService();
  final userRepository = UserRepository();
  final userService = UserService(
    userRepository: userRepository,
    storageService: storageService,
  );
  final motivationService = MotivationService(storageService: storageService);
  final progressService = ProgressService(
    storageService: storageService,
    userRepository: userRepository,
  );
  final settingsService = SettingsService(
    storageService: storageService,
    userRepository: userRepository,
  );
  
  // Initialize service locator
  ServiceLocator().initializeServices(
    userService: userService,
    motivationService: motivationService,
    storageService: storageService,
    progressService: progressService,
    settingsService: settingsService,
  );
  
  // Check network connectivity and sync progress if available
  try {
    // Simple network check - attempt to make a lightweight HTTP request
    final request = await HttpClient().getUrl(Uri.parse('https://www.google.com'));
    final response = await request.close();
    await response.drain();
    
    // Network is available, sync any pending progress
    final user = userRepository.getCurrentUser();
    if (user != null) {
      await progressService.syncProgress();
    }
  } catch (e) {
    debugPrint('❌ Network unavailable or error syncing progress on startup: $e');
  }
  
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