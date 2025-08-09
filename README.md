# Mwanafunzi Academy
running my applications on my device use this command

 $env:JAVA_HOME = "C:\Program Files\Java\jdk-22"; flutter run -d 042673706I006643 

This command to install it in the phone adb install build\app\outputs\flutter-apk\app-debug.apk

command that has actually worked
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"; flutter run -d 042672596J002254 --no-build

Option 4: Manual install + Hot reload

Install APK manually: adb install -r build\app\outputs\flutter-apk\app-debug.apk
Then run: flutter attach -d 042672596J002254


A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
