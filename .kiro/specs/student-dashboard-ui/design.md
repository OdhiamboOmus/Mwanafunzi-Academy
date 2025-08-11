# Design Document

## Overview

This design implements a comprehensive student dashboard UI with modern Material Design 3 principles while strictly adhering to Flutter Lite rules. The solution addresses critical UX issues in authentication screens and creates an engaging student learning interface with personalized content, grade selection, horizontal lesson cards, and competition features. The architecture prioritizes performance, maintainability, and minimal app size impact.

## Architecture

### Component Structure
```
StudentDashboard
├── TopNavigation (AppBar)
├── WelcomeSection
│   ├── UserAvatar
│   ├── GreetingText
│   └── QuickLinks (Leaderboard/Ranking)
├── GradeSelector
├── LessonCardsSection
│   └── HorizontalScrollView
├── CompetitionSection
│   ├── SchoolVsSchool
│   └── StudentVsStudent
└── BottomNavigation
```

### File Organization Strategy
Following the 150-line rule, components are split into focused, single-responsibility files:

- **Main Container**: `student_home_screen.dart` (140 lines)
- **Grade Selection**: `grade_selector_widget.dart` (80 lines)
- **Lesson Cards**: `lesson_cards_widget.dart` (120 lines)
- **Competition UI**: `competition_cards_widget.dart` (90 lines)
- **Navigation**: `bottom_navigation_widget.dart` (70 lines)

## Components and Interfaces

### 1. Student Home Screen (Main Container)
```dart
class StudentHomeScreen extends StatefulWidget {
  // Main dashboard orchestrator
  // Manages state for grade selection and user data
  // Coordinates between child widgets
}
```

**Responsibilities:**
- User data loading and state management
- Grade selection state coordination
- Navigation between dashboard sections
- Error handling and loading states

### 2. Grade Selector Widget
```dart
class GradeSelectorWidget extends StatelessWidget {
  final String selectedGrade;
  final Function(String) onGradeChanged;
  
  // Modal-based grade selection (Grades 1-12)
  // Material Design 3 bottom sheet implementation
}
```

**Features:**
- Modal bottom sheet with grade list
- Visual selection indicator (green highlight)
- Smooth animations and transitions
- Accessibility support

### 3. Lesson Cards Widget
```dart
class LessonCardsWidget extends StatelessWidget {
  final String selectedGrade;
  
  // Horizontal scrolling lesson cards
  // Infinite scroll simulation
}
```

**Card Structure:**
- Subject icon (Material Icons)
- Subject name and description
- Lesson count and duration
- Progress indicator
- "Continue Learning" button

### 4. Competition Cards Widget
```dart
class CompetitionCardsWidget extends StatelessWidget {
  // Competition UI placeholders
  // School vs School and Student vs Student
}
```

**Design Elements:**
- Card-based layout with competition types
- Placeholder content for future quiz integration
- Consistent styling with lesson cards

### 5. Bottom Navigation Widget
```dart
class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  
  // Four-tab navigation: Home, Quiz, Video, Teachers
}
```

## Data Models

### Student Dashboard Data
```dart
class StudentDashboardData {
  final String studentName;
  final String schoolName;
  final String selectedGrade;
  final List<LessonCard> lessons;
  final StudentRanking ranking;
}

class LessonCard {
  final String subject;
  final String description;
  final int lessonCount;
  final String duration;
  final double progress;
  final String iconName; // Material Icon name
}

class StudentRanking {
  final int position;
  final int totalStudents;
  final String leaderboardType;
}
```

### Asset Loading Service
```dart
class AssetLoaderService {
  static Future<List<String>> loadSubjects();
  static Future<Map<String, List<String>>> loadConstituencies();
  // Cached loading with fallback data
}
```

## Error Handling

### Asset Loading Errors
- Graceful fallback to hardcoded data
- User-friendly error messages
- Retry mechanisms for network-dependent data

### Navigation Errors
- Route validation before navigation
- Back button handling for modals
- State preservation during navigation

### Data Loading Errors
- Loading states with progress indicators
- Error states with retry options
- Offline capability considerations

## Testing Strategy

### Widget Testing
- Individual widget rendering tests
- User interaction simulation
- State management validation

### Integration Testing
- Full dashboard flow testing
- Navigation between screens
- Asset loading verification

### Performance Testing
- Scroll performance validation
- Memory usage monitoring
- Build size impact measurement

## UI Design Specifications

### Color Palette
- **Primary Green**: `Color(0xFF50E801)`
- **Background**: `Colors.white`
- **Text Primary**: `Colors.black`
- **Text Secondary**: `Color(0xFF6B7280)`
- **Card Background**: `Colors.white`
- **Border**: `Color(0xFFE5E7EB)`

### Typography (Sora Font Family)
- **Header**: 24px, FontWeight.bold
- **Subheader**: 18px, FontWeight.w600
- **Body**: 16px, FontWeight.w400
- **Caption**: 14px, FontWeight.w400

### Button Specifications
- **Navigation Buttons**: 44px height, 12px border radius
- **User Type Buttons**: 48px height, 12px border radius
- **Action Buttons**: 40px height, 8px border radius

### Card Design
- **Border Radius**: 12px
- **Elevation**: 2px shadow
- **Padding**: 16px internal
- **Margin**: 8px between cards

### Animation Specifications
- **Modal Transitions**: 300ms ease-in-out
- **Card Hover**: 150ms scale transform
- **Loading States**: Circular progress indicator
- **Scroll Physics**: iOS-style bounce

## Authentication Screen Improvements

### Button Hierarchy
1. **Primary Navigation** (Sign In/Sign Up): 44px height
2. **User Type Selection** (Parent/Student/Teacher): 48px height
3. **Form Actions**: 40px height

### Color Corrections
- Sign In button: Brand green (`Color(0xFF50E801)`)
- Inactive states: Light gray (`Color(0xFFF9FAFB)`)
- Text colors: Consistent with design system

## Asset Management Strategy

### Logo Implementation
- Replace icon-based splash with `assets/logo.jpeg`
- Maintain aspect ratio and center positioning
- Optimize image size for fast loading

### JSON Asset Loading
- Fix pubspec.yaml asset declarations
- Implement caching for subjects and constituencies
- Provide fallback data for offline scenarios

### Icon Strategy
- Use Material Icons exclusively (0KB size impact)
- Avoid custom SVG icons unless absolutely necessary
- Maintain consistent icon sizing (24px standard)

## Performance Optimizations

### Memory Management
- Dispose controllers properly
- Use const constructors throughout
- Implement lazy loading for lesson cards

### Build Optimizations
- Minimize widget rebuilds
- Use ListView.builder for scrolling content
- Cache expensive computations

### Size Optimizations
- No additional dependencies
- Compress assets to WebP format
- Remove unused code and imports

## Accessibility Considerations

### Screen Reader Support
- Semantic labels for all interactive elements
- Proper heading hierarchy
- Alternative text for images

### Touch Targets
- Minimum 44px touch targets
- Adequate spacing between interactive elements
- Visual feedback for all interactions

### Color Contrast
- WCAG AA compliance for text contrast
- Alternative indicators beyond color
- High contrast mode support