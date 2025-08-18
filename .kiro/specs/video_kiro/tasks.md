# Implementation Plan

- [ ] 1. Set up core video data models and utilities
  - Create VideoModel class with YouTube integration helpers
  - Implement YouTube URL parsing and validation utilities
  - Add video metadata extraction functionality
  - Write unit tests for model serialization and URL parsing
  - _Requirements: 5.5, 6.1_

- [ ] 2. Implement VideoService with Firebase integration
  - Create VideoService class following existing service patterns
  - Implement CRUD operations for video management
  - Add Firestore collection structure for grade/subject/topic organization
  - Implement caching layer with SharedPreferences integration
  - Write unit tests for service operations and caching
  - _Requirements: 3.1, 3.5, 6.1, 6.4_

- [ ] 3. Build student video viewing interface
  - [ ] 3.1 Create VideoScreen with grade integration
    - Build VideoScreen using existing grade selection patterns
    - Integrate with ServiceLocator and existing navigation
    - Implement subject filtering within selected grade
    - Add loading states and error handling
    - _Requirements: 1.1, 1.2, 8.1, 8.4_

  - [ ] 3.2 Implement VideoCard component with animations
    - Create VideoCard widget with YouTube thumbnail display
    - Add duration badge, subject indicator, and watched status
    - Implement tap animations and haptic feedback
    - Add loading skeleton for thumbnail loading states
    - _Requirements: 1.3, 7.4, 8.5_

  - [ ] 3.3 Build VideoPlayerModal with WebView integration
    - Create modal video player using webview_flutter
    - Implement YouTube embed with loading and error states
    - Add fullscreen toggle and proper controller disposal
    - Implement viewing progress tracking with SharedPreferences
    - _Requirements: 1.4, 1.5, 5.1, 5.4, 7.5_

- [ ] 4. Implement admin video management interface
  - [ ] 4.1 Create AdminVideoUploadScreen with selectors
    - Build AdminVideoUploadScreen using existing GradeSelectorWidget pattern
    - Add subject dropdown and topic input fields
    - Implement YouTube URL input with real-time validation
    - Add video metadata preview functionality
    - _Requirements: 2.1, 2.2, 2.4, 8.2, 8.3_

  - [ ] 4.2 Implement video upload and management functionality
    - Add YouTube metadata extraction and validation
    - Implement batch video upload with progress indicators
    - Create video editing and deletion functionality with confirmations
    - Add admin video list management with filtering
    - _Requirements: 2.3, 2.6, 2.7, 3.6_

- [ ] 5. Add real-time synchronization and offline support
  - [ ] 5.1 Implement Firestore real-time listeners
    - Add real-time video list updates for student screens
    - Implement automatic refresh when admin uploads new content
    - Add incremental sync for optimal performance
    - Handle listener lifecycle and proper disposal
    - _Requirements: 3.1, 3.2, 3.5, 7.6_

  - [ ] 5.2 Enhance offline capability and caching
    - Implement LRU cache eviction for video metadata
    - Add offline indicators and messaging for video playback
    - Create background sync when connectivity is restored
    - Implement cache management with size limits
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 6. Integrate with existing app navigation and UI patterns
  - Add Video tab to bottom navigation widget
  - Update AppRoutes with video screen navigation
  - Integrate video screen with existing grade state management
  - Ensure consistent Material Design 3 styling and animations
  - _Requirements: 1.1, 8.4, 8.5_

- [ ] 7. Implement performance optimizations and error handling
  - [ ] 7.1 Add comprehensive error handling
    - Implement network error handling with offline fallbacks
    - Add YouTube integration error handling for invalid videos
    - Create Firestore error handling with retry mechanisms
    - Add WebView error handling and recovery
    - _Requirements: 6.4, 5.4, 7.6_

  - [ ] 7.2 Optimize performance and memory management
    - Implement ListView.builder for efficient video list rendering
    - Add proper WebView controller disposal and memory management
    - Optimize Firestore queries with batch operations
    - Ensure Flutter Lite compliance with file size limits
    - _Requirements: 7.1, 7.2, 7.3, 7.5, 7.7_

- [ ] 8. Add admin authentication integration and security
  - Integrate video management with existing hidden admin authentication
  - Add proper Firestore security rules for video collections
  - Implement admin action audit logging
  - Add content validation and URL sanitization
  - _Requirements: 8.2, 2.1_

- [ ] 9. Write comprehensive tests and documentation
  - [ ] 9.1 Create unit tests for all components
    - Write unit tests for VideoModel and YouTube utilities
    - Test VideoService CRUD operations and caching
    - Create widget tests for VideoCard and VideoScreen
    - Test admin upload functionality and validation
    - _Requirements: 7.7_

  - [ ] 9.2 Implement integration tests
    - Test end-to-end video upload and viewing flow
    - Verify real-time synchronization between admin and student
    - Test offline/online transition handling
    - Validate grade selection integration across screens
    - _Requirements: 1.2, 3.1, 6.5_

- [ ] 10. Final optimization and polish
  - Verify APK size increase stays under 200KB limit
  - Optimize video thumbnail loading and caching
  - Fine-tune animations and user experience
  - Conduct performance testing on mid-range devices
  - _Requirements: 7.1, 7.7, 5.2_