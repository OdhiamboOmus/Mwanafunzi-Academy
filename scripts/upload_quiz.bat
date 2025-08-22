@echo off
REM Simple Quiz Uploader Batch File for Mwanafunzi Academy
REM Uses Firebase REST API with API key authentication

echo 📚 Mwanafunzi Academy - Simple Quiz Uploader
echo ===========================================

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if file exists
if "%~2"=="" (
    echo 🎯 Usage: upload_quiz.bat [grade] [quiz-file]
    echo.
    echo 📝 Arguments:
    echo    grade        - Grade level (e.g., 5, 6, 7, 8)
    echo    quiz-file    - Path to quiz JSON file
    echo.
    echo 💡 Examples:
    echo    upload_quiz.bat 5 quiz.json
    echo    upload_quiz.bat 6 .\quizzes\math_quiz.json
    echo    upload_quiz.bat 7 "C:\quizzes\science.json"
    echo.
    pause
    exit /b 1
)

set GRADE=%~1
set QUIZ_FILE=%~2

REM Check if quiz file exists
if not exist "%QUIZ_FILE%" (
    echo ❌ Quiz file not found: %QUIZ_FILE%
    pause
    exit /b 1
)

echo 📖 Reading quiz file: %QUIZ_FILE%
echo 🎓 Grade: %GRADE%
echo.

REM Run the quiz uploader
node simple_quiz_uploader.js %GRADE% "%QUIZ_FILE%"

if %errorlevel% equ 0 (
    echo.
    echo ✅ Quiz upload completed successfully!
    echo 🎯 Quiz is now available to students in the app!
) else (
    echo.
    echo ❌ Quiz upload failed. Please check the error messages above.
)

echo.
pause