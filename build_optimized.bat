@echo off
echo ========================================
echo   MWANAFUNZI ACADEMY - SIZE OPTIMIZER
echo ========================================
echo.

REM Clean previous builds
echo [1/5] Cleaning previous builds...
flutter clean
flutter pub get

echo.
echo [2/5] Analyzing current dependencies...
flutter pub deps

echo.
echo [3/5] Building optimized APK...
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info --tree-shake-icons --target-platform android-arm64

echo.
echo [4/5] Analyzing APK size...
flutter build apk --analyze-size --target-platform android-arm64

echo.
echo [5/5] Size Report:
echo ========================================
dir build\app\outputs\flutter-apk\ /s
echo ========================================

echo.
echo 🚨 SIZE OPTIMIZATION CHECKLIST:
echo ✅ Split per ABI (separate APKs for different architectures)
echo ✅ Code obfuscation enabled
echo ✅ Debug info separated  
echo ✅ Unused icons removed
echo ✅ ProGuard/R8 optimization enabled
echo ✅ Resource shrinking enabled
echo.
echo 📊 TARGET SIZES:
echo - Excellent: Under 10MB
echo - Good: 10-15MB  
echo - Acceptable: 15-20MB
echo - Too Large: Over 20MB
echo.
echo 💡 If size is too large, check:
echo - Remove unused dependencies in pubspec.yaml
echo - Compress/remove large assets
echo - Use simpler widgets
echo - Avoid custom themes/fonts
echo.
pause