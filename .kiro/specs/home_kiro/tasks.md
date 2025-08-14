# Implementation Plan

- [ ] 1. Create core service infrastructure and data models




  - Set up base service classes with proper error handling and caching patterns
  - Implement data models for lessons, progress, and user data with JSON serialization
  - Create SharedPreferences helper for consistent local storage operations
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1, 7.1_

- [ ] 2. Implement User Service with dynamic greeting
  - [ ] 2.1 Create UserService class with profile data management
    - Implement getCurrentUserName() method to fetch user name from Firestore
    - Add caching mechanism using SharedPreferences for offline access
    - Create fallback logic for "Welcome back, Learner!" when name unavailable
    - _Requirements: 1.1, 1.2_

  - [ ] 2.2 Update StudentHomeScreen to use dynamic user greeting
    - Replace hardcoded "Student Name" with actual user name from UserService
    - Implement loading states and error handling for name fetching
    - Add proper disposal and lifecycle management
    - _Requirements: 1.1, 1.2_

- [ ] 3. Implement Motivation Service with AI integration
  - [ ] 3.1 Create MotivationService with Gemma API integration
    - Implement HTTP client for Gemma API calls with proper error handling
    - Create caching mechanism for last 5 messages in SharedPreferences
    - Add 10 super-inspiring hardcoded fallback messages
    - _Requirements: 1.3, 1.4, 1.5_

  - [ ] 3.2 Integrate motivational messages into home screen
    - Replace hardcoded motivational text with dynamic messages from service
    - Implement automatic message refresh on home screen navigation
    - Add offline fallback with random cached message selection
    - _Requirements: 1.3, 1.6, 1.7_

- [ ] 4. Create section-based lesson system with embedded questions
  - [ ] 4.1 Implement enhanced LessonService for section-based content
    - Create getLessonsForGrade() method with single Firestore query
    - Implement indefinite caching of lesson metadata in SharedPreferences
    - Add version-based cache validation logic
    - Create getLessonSection() method for individual section access
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 4.2 Build automatic lesson content downloading with section support
    - Implement downloadLessonContent() with gzip decompression
    - Create background download with subtle loading indicators
    - Add user-friendly error messages for download failures
    - Use path_provider for local file storage with proper directory structure
    - Parse downloaded content into sections for Duolingo-style navigation
    - _Requirements: 2.4, 2.5, 2.6, 2.7, 2.9_

  - [ ] 4.3 Implement lesson content caching and section serving
    - Create local file serving mechanism for cached lessons
    - Implement LRU cache eviction when storage exceeds limits
    - Add cache integrity verification and corruption handling
    - Create section-based content delivery for step-by-step learning
    - _Requirements: 2.8, 2.12, 8.6_

  - [ ] 4.4 Create embedded question system
    - Implement QuestionService for handling embedded questions
    - Create question widgets with 4 multiple choice options
    - Add immediate feedback with correct answer and explanation
    - Record question answers locally for parent dashboard (no points awarded)
    - _Requirements: 2.10, 2.11_

- [ ] 5. Build progress tracking and points system
  - [ ] 5.1 Create ProgressService for lesson completion tracking
    - Implement completeLesson() method with immediate local point updates
    - Create progress record queuing system with unique progressRecordId generation
    - Add local points display updates for instant user feedback
    - _Requirements: 3.1, 3.2, 3.8_

  - [ ] 5.2 Implement batch progress synchronization
    - Create syncProgress() method with Firestore transaction handling
    - Implement client-side deduplication using progressRecordId
    - Add retry logic with exponential backoff for failed syncs
    - Create queue management with proper error handling
    - _Requirements: 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 6. Implement Settings screen with leaderboard
  - [ ] 6.1 Create SettingsService for leaderboard management
    - Implement getLeaderboard() method with 12-hour cache TTL
    - Create getUserRank() method to find user position in leaderboard
    - Add countdown timer calculation for next leaderboard update
    - _Requirements: 4.3, 4.4, 4.5, 4.6, 4.7_

  - [ ] 6.2 Build Settings screen UI replacing refresh button
    - Replace refresh button in StudentHomeScreen AppBar with settings icon
    - Create Settings screen with user points display and leaderboard
    - Implement leaderboard UI with user rank highlighting
    - Add countdown timer display for next update
    - _Requirements: 4.1, 4.2, 4.8_

- [ ] 7. Implement section-based comment system with cost optimization
  - [ ] 7.1 Create CommentService with 24-hour caching strategy
    - Implement getCommentsForSection() method with single Firestore read per section per day
    - Create local caching mechanism for ALL comments per section in SharedPreferences
    - Add comment action queuing system (post, like, dislike, delete)
    - Implement batch sync of queued actions every 24 hours or on app close
    - _Requirements: 5.1, 5.2, 5.3, 5.7, 5.8_

  - [ ] 7.2 Build section-based comment UI components
    - Create SectionCommentSheet widget replacing existing CommentsBottomSheet
    - Implement like/dislike functionality with immediate local updates
    - Add delete comment functionality for user's own comments
    - Create comment posting with immediate local cache updates
    - _Requirements: 5.4, 5.5, 5.6, 5.9_

  - [ ] 7.3 Integrate comments into lesson sections
    - Update lesson content screen to show comment button per section
    - Display comment count from cached data
    - Link comment system to specific lesson sections (not entire lesson)
    - Add offline comment viewing with cached data
    - _Requirements: 5.1, 5.2, 5.9_

- [ ] 8. Implement enhanced parent-child linking with comment monitoring
  - [ ] 8.1 Create enhanced ParentService for child linking and monitoring
    - Implement linkChildByEmail() method with student verification
    - Create parentLinks document creation with audit logging
    - Add rate limiting for link attempts (max 5 per hour)
    - Implement getChildComments() method for parent monitoring
    - _Requirements: 6.2, 6.3, 6.4, 6.5_

  - [ ] 8.2 Build enhanced parent dashboard with comment monitoring
    - Update ParentHomeScreen to show "Link Student" button when no children linked
    - Create modal dialog for email input and student linking
    - Implement linked children display with aggregated progress data
    - Add child comment activity display with lesson section context
    - Add unlink functionality with status update to 'revoked'
    - _Requirements: 6.1, 6.6, 6.7, 6.8, 6.9, 6.10_

- [ ] 9. Create enhanced batch upload script for section-based lesson content
  - [ ] 9.1 Build Node.js script for section-based lesson processing
    - Create script to validate lesson JSON structure including sections and questions
    - Implement gzip compression for lesson content
    - Add Firebase Storage upload with proper cache headers (30-day TTL)
    - Validate section structure with sectionId, type, and required fields
    - _Requirements: 7.1, 7.2, 7.3, 7.7_

  - [ ] 9.2 Implement enhanced media handling and metadata creation
    - Add media file compression and upload to Storage
    - Create lessonsMeta document writing with totalSections and hasQuestions fields
    - Implement error logging and summary reporting with section count
    - Add support for relative image paths in lesson content
    - Validate embedded questions with 4 options, correct answer, and explanation
    - _Requirements: 7.4, 7.5, 7.6, 7.8, 7.9, 7.10, 7.11_

- [ ] 10. Implement caching optimization and performance monitoring
  - [ ] 10.1 Add comprehensive caching strategy with 24-hour cycles
    - Implement aggressive caching for all static content with appropriate TTL
    - Add Firestore query limits to prevent expensive unbounded reads
    - Create intelligent cache cleanup prioritizing frequently accessed content
    - Optimize comment caching for 90% cost reduction
    - _Requirements: 8.1, 8.2, 8.6_

  - [ ] 10.2 Add performance monitoring and telemetry
    - Implement cache hit/miss ratio tracking
    - Add read/write count monitoring for optimization
    - Create download frequency tracking for cache management
    - Add loading states and graceful degradation for slow networks
    - _Requirements: 8.7, 8.8_

- [ ] 11. Final integration and Flutter Lite compliance verification
  - Verify APK size remains under 12MB after all features implementation
  - Validate offline functionality works correctly across all features
  - Ensure parent-child linking workflow functions end-to-end
  - Confirm lesson download and caching performance on low-end devices
  - _Requirements: All requirements validation_