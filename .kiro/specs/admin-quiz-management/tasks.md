# Implementation Plan

- [ ] 1. Set up admin authentication system with Firebase security
  - Create AdminAuthService class with Firebase admin_users collection validation
  - Implement hidden admin login detection in existing auth flow
  - Add admin user routing logic to redirect to admin screens after authentication
  - Create admin_users Firestore collection with proper security rules
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 2. Implement dynamic quiz system with 30-day caching
  - [ ] 2.1 Create QuizService with Firebase integration and SharedPreferences caching
    - Build QuizService class with 30-day TTL caching using SharedPreferences
    - Implement getQuizQuestions method with cache-first strategy
    - Create Firebase quiz data structure following /quizzes/{grade}/{subject}/{topic}/questions/ pattern
    - Add quiz question validation for 4 options, correct answer index, and explanation
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ] 2.2 Update existing quiz interface to use dynamic loading
    - Modify QuizInterfaceScreen to load questions from QuizService instead of hardcoded data
    - Replace QuizQuestionData.getQuestions() calls with dynamic Firebase loading
    - Implement offline quiz taking using cached questions from SharedPreferences
    - Add loading states and error handling for quiz question fetching
    - _Requirements: 2.1, 2.5, 2.6_

- [ ] 3. Build admin quiz management interface with JSON upload
  - [ ] 3.1 Create AdminQuizUploadScreen with grade selector integration
    - Build AdminQuizUploadScreen using existing GradeSelectorWidget pattern
    - Add subject dropdown and topic input fields for quiz organization
    - Implement JSON file picker for bulk quiz question upload
    - Create real-time preview section for uploaded quiz questions
    - _Requirements: 3.1, 3.2, 3.3, 3.5_

  - [ ] 3.2 Implement quiz JSON validation and Firebase batch operations
    - Create JSON validation logic for quiz question structure (4 options, correct answer, explanation)
    - Implement batch write operations to Firebase for cost optimization
    - Add quiz content preview functionality before final submission
    - Create individual question editing interface for existing quizzes
    - Add bulk JSON export functionality for quiz backup
    - _Requirements: 3.3, 3.4, 3.6, 3.7_

- [ ] 4. Implement student vs student competition system (SoloLearn-style)
  - [ ] 4.1 Create StudentChallengeService for random opponent matching
    - Build StudentChallengeService with random opponent selection logic
    - Implement createRandomChallenge method excluding challenger from opponent pool
    - Create student_challenges Firebase collection structure
    - Add challenge notification system integration (placeholder for settings notifications)
    - _Requirements: 4.1, 4.2, 4.6_

  - [ ] 4.2 Build individual competition quiz interface and scoring system
    - Create competition quiz taking interface without time limits
    - Implement challenge completion logic with proper scoring (1 point per correct, 3 bonus for winner, 1 each for draw)
    - Add challenge results calculation and winner determination
    - Ensure individual competition points contribute to personal leaderboard
    - _Requirements: 4.3, 4.4, 4.5, 4.6_

- [ ] 5. Implement school vs school competition system
  - [ ] 5.1 Create SchoolCompetitionService with question deduplication
    - Build SchoolCompetitionService for managing school competitions with deadline-based participation
    - Implement question deduplication logic to prevent students from receiving previously answered questions
    - Create school_competitions Firebase collection with question pools and participant tracking
    - Add school competition creation and management functionality for admins
    - _Requirements: 11.1, 11.3, 11.7_

  - [ ] 5.2 Build school competition interface and averaging system
    - Create school competition quiz interface where all students receive the same questions
    - Implement deadline-based participation allowing students to take quiz anytime before deadline
    - Add school score calculation using average of all participating students' scores
    - Ensure school competition points contribute to both individual leaderboard and school rankings
    - _Requirements: 11.2, 11.4, 11.5, 11.6_

- [ ] 6. Create dual leaderboard system
  - [ ] 6.1 Build individual leaderboard with comprehensive point aggregation
    - Create individual leaderboard including points from lessons, personal quizzes, student vs student challenges, and school competitions
    - Implement local point aggregation and sync summary statistics to minimize Firebase costs
    - Add leaderboard display with student rankings and point breakdowns
    - _Requirements: 12.1, 12.4_

  - [ ] 6.2 Build school leaderboard with top contributors display
    - Create school leaderboard showing averaged scores from school competitions only
    - Implement school card press functionality to display top contributors from that school
    - Add toggle between individual view and school view for easy navigation
    - Create school ranking recalculation based on participating students' averaged scores
    - _Requirements: 12.2, 12.3, 12.5, 12.6_

- [ ] 7. Integrate quiz progress into parent dashboard
  - [ ] 7.1 Create ParentQuizAnalyticsService for child progress tracking
    - Build ParentQuizAnalyticsService to fetch child quiz attempts from Firebase
    - Implement quiz analytics calculation (average scores, topics completed, performance trends)
    - Create child quiz progress aggregation by subject and topic
    - Add strongest/weakest topics analysis and improvement suggestions
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [ ] 7.2 Update ParentHomeScreen with quiz progress display
    - Integrate quiz statistics into existing parent dashboard layout
    - Add quiz progress cards showing completion rates and recent attempts
    - Implement detailed quiz attempt history with timestamps and scores
    - Ensure quiz data access respects parent-child linking and privacy settings
    - _Requirements: 5.1, 5.5, 5.6_

- [ ] 8. Implement lesson-quiz progress integration
  - Update lesson progress tracking to include quiz completion data
  - Modify /lesson_progress/{studentId}/{grade}/{subject}/{topic}/ structure to include quiz attempts
  - Create correlation analytics between lesson completion and quiz performance
  - Ensure all quizzes remain accessible without lesson completion prerequisites
  - Remove any existing quiz locking mechanisms to allow unrestricted access
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 9. Build admin lesson content management interface
  - [ ] 9.1 Create AdminLessonUploadScreen matching existing script functionality
    - Build AdminLessonUploadScreen with grade selector identical to quiz management
    - Implement JSON file upload matching existing lesson-uploader.js structure
    - Add lesson JSON validation for lessonId, title, sections, and embedded questions
    - Create lesson content preview functionality before upload
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ] 9.2 Implement lesson upload processing with gzip compression
    - Add gzip compression for lesson content matching script behavior
    - Implement Firebase Storage upload with 30-day cache headers
    - Create lessonsMeta document generation with id, title, grade, subject, sizeBytes, contentPath, version, totalSections
    - Support image URLs in JSON format maintaining existing relative path structure
    - _Requirements: 7.5, 7.6, 7.7_

- [ ] 10. Implement Firebase cost reduction strategies (90% optimization)
  - [ ] 10.1 Create aggressive caching system with SharedPreferences
    - Build CostOptimizedCacheService with 30-day TTL for quiz questions
    - Implement cache hit rate monitoring targeting >90% efficiency
    - Create indefinite caching for quiz metadata until admin updates occur
    - Add timestamp-based incremental sync for changed content only
    - _Requirements: 9.1, 9.3, 9.6, 9.8_

  - [ ] 10.2 Implement batch operations and background sync
    - Create BatchOperationService for queuing up to 50 quiz attempts
    - Implement background sync every 5 minutes or 10 attempts for quiz sessions
    - Add gzip compression for admin uploads with CDN-style cache headers
    - Create local aggregation for quiz analytics syncing summary statistics only
    - Use atomic document updates for competition challenges
    - _Requirements: 9.2, 9.4, 9.5, 9.7, 9.9, 9.10_

- [ ] 11. Configure Firebase security rules for quiz system
  - Create comprehensive Firestore security rules for admin_users, quizzes, and competition_quizzes collections
  - Implement grade-level access control for students reading quiz questions
  - Add student-only write access to their own quiz_attempts documents
  - Create parent access validation for linked children's quiz data
  - Implement admin status validation through Firebase rules
  - Add student_challenges access control for challenge participants only
  - Configure lesson content access rules for admin management and student reading
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

- [ ] 12. Optimize performance and maintain app size constraints
  - Implement lazy loading for admin screens to avoid impacting regular user performance
  - Add LRU cache eviction for quiz questions to prevent excessive storage usage
  - Create incremental sync mechanisms for quiz question updates
  - Ensure offline quiz functionality using SharedPreferences cache
  - Validate total app size increase remains under 200 KB
  - Optimize quiz loading and admin operations to complete within 2 seconds on mid-range devices
  - Implement retry logic with exponential backoff for network operations
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_