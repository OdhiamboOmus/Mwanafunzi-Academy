# Mwanafunzi Academy
running my applications on my device use this command

 $env:JAVA_HOME = "C:\Program Files\Java\jdk-22"; flutter run -d 042673706I006643 

 Also this command works
  $env:JAVA_HOME = "C:\Program Files\Java\jdk-22"; 
flutter attach -d 042672596J002254

This command to install it in the phone adb install build\app\outputs\flutter-apk\app-debug.apk

command that has actually worked
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"; flutter run -d 042672596J002254 --no-build

Option 4: Manual install + Hot reload

Install APK manually: adb install -r build\app\outputs\flutter-apk\app-debug.apk
Then run: flutter attach -d 042672596J002254

lib/
├── core/
│   ├── constants/     # App constants, API endpoints, etc.
│   ├── utils/         # Helper functions, validators
│   ├── theme/         # Material Design 3 theme config
│   └── extensions/    # Dart extensions for cleaner code
│
├── data/
│   ├── models/        # Data models for all entities
│   ├── repositories/  # Data access layer implementations
│   └── datasources/   # Firebase, local storage interfaces
│
├── services/
│   ├── firebase/      # Firebase auth, firestore, functions
│   ├── mpesa/         # M-Pesa payment integration
│   ├── cache/         # Offline-first caching logic
│   └── sync/          # Data synchronization services
│
├── presentation/
│   ├── shared/        # Reusable widgets across all user types
│   ├── auth/          # Login/signup screens
│   ├── student/       # Student-specific screens
│   ├── parent/        # Parent dashboard and features
│   ├── teacher/       # Teacher profile and class management
│   ├── admin/         # Admin verification and management
│   └── routing/       # App navigation logic
│
└── main.dart



