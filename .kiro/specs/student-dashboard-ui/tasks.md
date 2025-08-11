# Implementation Plan

- [ ] 1. Fix core infrastructure and asset management
  - Create separate routes file to clean up main.dart imports with const constructors
  - Fix pubspec.yaml asset declarations to resolve loading issues
  - Update splash screen to use logo.jpeg instead of school icon with const widgets
  - Ensure all files follow 150-line Flutter Lite rule
  - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [ ] 2. Create asset loading service for JSON data
  - Implement cached asset loading service for subjects and constituencies
  - Add error handling with fallback data for offline scenarios using const constructors
  - Ensure no additional dependencies and minimal memory usage
  - Keep file under 150 lines with proper code organization
  - _Requirements: 3.1, 3.2, 3.4, 3.5_

- [ ] 3. Implement grade selector widget
  - Create modal bottom sheet widget for grade selection (Grades 1-12)
  - Add visual selection indicator with brand green highlighting
  - Implement smooth animations and Material Design 3 styling
  - Use const constructors and keep under 150 lines
  - _Requirements: 1.4, 1.5, 1.6_

- [ ] 4. Build lesson cards horizontal scrolling widget
  - Create lesson card widget with subject info, progress, and continue button
  - Implement horizontal ListView.builder with infinite scroll simulation
  - Add Material Icons for subjects and proper card styling
  - Follow Flutter Lite rules with const constructors and 150-line limit
  - _Requirements: 1.6, 1.7, 1.8_

- [ ] 5. Create competition cards section widget
  - Build competition cards UI for "School vs School" and "Student vs Student"
  - Implement placeholder content with consistent card styling
  - Add proper spacing and layout for future quiz integration
  - Maintain Flutter Lite compliance with const widgets under 150 lines
  - _Requirements: 1.10_

- [ ] 6. Implement bottom navigation widget
  - Create four-tab bottom navigation (Home, Quiz, Video, Teachers)
  - Add proper tab selection state management and navigation
  - Use Material Icons and brand color theming
  - Apply const constructors and stay within 150-line limit
  - _Requirements: 1.12_

- [ ] 7. Build main student dashboard screen
  - Create main dashboard container that orchestrates all child widgets
  - Implement welcome section with student name and motivational text
  - Add quick links to leaderboard and student ranking below welcome message
  - Add top navigation bar (AppBar) with proper styling
  - Ensure Flutter Lite compliance with const constructors under 150 lines
  - _Requirements: 1.1, 1.2, 1.3, 1.11_

- [ ] 8. Fix authentication screen button sizing issues
  - Update sign up screen navigation buttons to 44px height (Sign In/Sign Up)
  - Resize user type selector buttons to 48px height (Parent/Student/Teacher)
  - Ensure proper button hierarchy and spacing throughout auth screens
  - Maintain existing Flutter Lite compliance and 150-line limits
  - _Requirements: 2.1, 2.2_

- [ ] 9. Fix sign in screen button styling and color theme
  - Update Sign In button to use brand green color instead of grey
  - Fix button highlighting to maintain green theme when pressed
  - Ensure consistent Sora font usage across all authentication buttons
  - Keep modifications within Flutter Lite rules and existing line limits
  - _Requirements: 2.3, 2.4, 2.5_

- [ ] 10. Integrate asset loading into teacher registration forms
  - Update teacher registration to load subjects from assets/data/subjects.json
  - Update area of operation selection to use assets/data/constituencies.json
  - Fix scrolling issues in teacher registration form
  - Maintain Flutter Lite compliance and 150-line limits for modified files
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 11. Implement responsive layout and final polish
  - Add proper responsive design for different screen sizes
  - Implement loading states and error handling throughout dashboard
  - Add smooth transitions and animations following Material Design guidelines
  - Ensure all implementations follow Flutter Lite rules with const constructors
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 12. Final Flutter Lite compliance verification
  - Ensure all files remain under 150 lines with proper code organization
  - Add const constructors throughout all widgets for performance
  - Verify no new dependencies added and APK size remains under 12MB
  - _Requirements: 6.5, 6.6_