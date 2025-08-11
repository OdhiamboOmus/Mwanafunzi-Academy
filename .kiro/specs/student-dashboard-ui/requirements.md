# Requirements Document

## Introduction

This feature focuses on implementing a comprehensive student dashboard UI that matches the provided design mockups, along with critical authentication screen improvements. The implementation must strictly follow Flutter Lite rules to maintain app size under 12MB while delivering a polished user experience. Key areas include creating a new student home screen with grade selection, horizontal scrolling lesson cards, bottom navigation, fixing authentication button sizing issues, implementing asset-based data loading for subjects and constituencies, and replacing the current icon-based splash screen with the logo.jpeg asset.

## Requirements

### Requirement 1: Student Dashboard UI Implementation

**User Story:** As a student, I want to see a personalized dashboard with my name, grade selector, lesson cards, and navigation options, so that I can easily access my learning materials and track my progress.

#### Acceptance Criteria

1. WHEN a student logs in THEN the system SHALL display a welcome section with the student's actual name
2. WHEN the welcome section is displayed THEN the system SHALL show a personalized greeting message with motivational text
3. WHEN the motivational message is displayed THEN the system SHALL show quick links to leaderboard and student ranking below it
4. WHEN the dashboard loads THEN the system SHALL display a grade selector dropdown showing "Grade X" format
4. WHEN the grade selector is tapped THEN the system SHALL show a modal with grades 1-12 in a scrollable list
5. WHEN a grade is selected THEN the system SHALL update the display and close the modal
6. WHEN the dashboard displays lesson cards THEN the system SHALL show horizontally scrolling cards with subject information
7. WHEN lesson cards are displayed THEN each card SHALL show subject name, description, lesson count, duration, and progress
8. WHEN lesson cards scroll THEN the system SHALL support infinite scrolling in both directions
9. WHEN lesson cards section is complete THEN the system SHALL display ongoing competitions section below
10. WHEN competitions section loads THEN the system SHALL show "School vs School" and "Student vs Student" competition cards
11. WHEN the dashboard loads THEN the system SHALL display top navigation bar
12. WHEN the dashboard loads THEN the system SHALL display bottom navigation with Home, Quiz, Video, and Teachers tabs

### Requirement 2: Authentication Screen Button Improvements

**User Story:** As a user, I want properly sized and styled authentication buttons that follow consistent design patterns, so that the interface appears professional and is easy to navigate.

#### Acceptance Criteria

1. WHEN the sign up screen loads THEN the Sign In and Sign Up navigation buttons SHALL have equal smaller sizes (height: 40px)
2. WHEN the user type selector is displayed THEN the Parent, Student, and Teacher buttons SHALL be larger than navigation buttons (height: 48px)
3. WHEN the sign in screen loads THEN the Sign In button SHALL use the brand green color theme
4. WHEN the Sign In button is pressed THEN the system SHALL maintain green highlighting instead of grey
5. WHEN authentication screens are displayed THEN all buttons SHALL use Sora font family consistently

### Requirement 3: Teacher Registration Data Integration

**User Story:** As a teacher, I want to select my subjects and area of operation from predefined lists during registration, so that I can accurately specify my qualifications and service area.

#### Acceptance Criteria

1. WHEN a teacher selects subjects during registration THEN the system SHALL load options from assets/data/subjects.json
2. WHEN a teacher selects area of operation THEN the system SHALL load constituency options from assets/data/constituencies.json
3. WHEN the teacher registration form loads THEN the system SHALL enable smooth scrolling through all form fields
4. WHEN subject selection is displayed THEN the system SHALL show all 18 subjects from the JSON file
5. WHEN area of operation selection is displayed THEN the system SHALL show counties and their constituencies hierarchically

### Requirement 4: Splash Screen Logo Implementation

**User Story:** As a user, I want to see the official Mwanafunzi Academy logo during app startup, so that I have a branded and professional first impression.

#### Acceptance Criteria

1. WHEN the app starts THEN the system SHALL display the logo.jpeg from assets folder instead of the school icon
2. WHEN the splash screen loads THEN the logo SHALL be properly sized and centered
3. WHEN the splash screen displays THEN the system SHALL maintain the 2-second duration before navigation
4. WHEN the logo is displayed THEN the system SHALL preserve the existing text and styling around it

### Requirement 5: Routes Separation and Code Organization

**User Story:** As a developer, I want clean code organization with separated route definitions, so that the main.dart file remains lightweight and maintainable.

#### Acceptance Criteria

1. WHEN the app initializes THEN the system SHALL load routes from a separate routes.dart file
2. WHEN routes are defined THEN the main.dart file SHALL have minimal imports and clean structure
3. WHEN route navigation occurs THEN the system SHALL maintain all existing navigation functionality
4. WHEN the routes file is created THEN the system SHALL follow Flutter Lite rules for minimal dependencies

### Requirement 6: Flutter Lite Compliance

**User Story:** As a user, I want a lightweight app that loads quickly and uses minimal device resources, so that I can use the app efficiently on any device.

#### Acceptance Criteria

1. WHEN any new code is implemented THEN the system SHALL comply with all Flutter Lite rules
2. WHEN widgets are created THEN the system SHALL use const constructors wherever possible
3. WHEN dependencies are considered THEN the system SHALL avoid adding any new packages
4. WHEN UI components are built THEN the system SHALL use basic Material widgets only
5. WHEN assets are added THEN the total asset size SHALL remain under the 1MB budget
6. WHEN the app is built THEN the APK size SHALL remain under 12MB target