# Mwanafunzi Academy

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

install wireless ADB and run the command

adb connect <phone ip>:5555
flutter attach -d <phone ip>:5555 and this is after looking for your ip address in the phone settings

$env:JAVA_HOME="C:\Program Files\Java\jdk-22"; flutter build apk --debug