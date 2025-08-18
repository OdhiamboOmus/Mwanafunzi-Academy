# Requirements Document

## Introduction

This feature introduces a comprehensive admin quiz management system that allows administrators to create, manage, and monitor quizzes across different grades, subjects, and topics. The system includes hidden admin authentication, dynamic quiz loading from Firebase, parent visibility into student quiz progress, and competition quiz management. The feature integrates seamlessly with the existing lesson system and maintains the app's size optimization goals.

## Requirements

### Requirement 1: Hidden Admin Authentication

**User Story:** As an app administrator, I want to access admin features through a hidden login mechanism, so that only authorized personnel can manage quizzes and view sensitive data.

#### Acceptance Criteria

1. WHEN an admin enters special credentials in the existing login screen THEN the system SHALL authenticate them as an admin user
2. WHEN admin authentication is successful THEN the system SHALL route the user to admin-specific screens instead of regular user screens
3. WHEN a non-admin user attempts to access admin features THEN the system SHALL deny access and redirect to appropriate user screens
4. WHEN admin credentials are stored THEN the system SHALL use a secure admin user collection in Firestore with proper access controls to prevent reverse engineering exploits
5. WHEN admin login is attempted THEN the system SHALL validate against Firebase-stored admin credentials collection for security

### Requirement 2: Dynamic Quiz System with Firebase Integration

**User Story:** As a student, I want to take quizzes that are dynamically loaded from the server with all topics available, so that I can access any quiz content without restrictions.

#### Acceptance Criteria

1. WHEN a student selects a quiz topic THEN the system SHALL load quiz questions from Firestore based on grade, subject, and topic
2. WHEN quiz questions are loaded THEN the system SHALL cache them locally using SharedPreferences with 30-day TTL for offline access
3. WHEN quiz structure is organized THEN the system SHALL follow the pattern: `/quizzes/{grade}/{subject}/{topic}/questions/`
4. WHEN quiz questions are stored THEN each question SHALL contain question text, 4 options, correct answer index, and explanation
5. WHEN quiz access is determined THEN ALL quizzes SHALL be available to students without any locking or prerequisite restrictions
6. WHEN students complete quizzes THEN the system SHALL batch write attempts to `/quiz_attempts/{studentId}/{quizType}/{attemptId}/` to minimize Firestore costs

### Requirement 3: Admin Quiz Management Interface

**User Story:** As an admin, I want to create, edit, and delete quiz questions through an intuitive interface with JSON upload capability, so that I can efficiently manage quiz content using the same grade selector pattern as students.

#### Acceptance Criteria

1. WHEN an admin accesses quiz management THEN the system SHALL display a grade selector dropdown identical to the student home screen pattern
2. WHEN an admin selects grade and subject THEN the system SHALL show existing quizzes organized by topic with JSON upload option
3. WHEN an admin uploads quiz content THEN the system SHALL accept JSON format files with batch validation for multiple questions
4. WHEN JSON quiz files are processed THEN the system SHALL validate that each question has exactly 4 options, one correct answer, and an explanation
5. WHEN quiz content is uploaded THEN the system SHALL provide real-time preview of questions before final submission
6. WHEN quiz changes are saved THEN the system SHALL batch write to Firebase to minimize costs and update SharedPreferences cache
7. WHEN an admin manages existing quizzes THEN the system SHALL allow individual question editing and bulk JSON export for backup

### Requirement 4: Student vs Student Competition System

**User Story:** As a student, I want to challenge other students to quiz competitions similar to SoloLearn's challenge system, so that I can engage in competitive learning without level restrictions.

#### Acceptance Criteria

1. WHEN a student wants to compete THEN the system SHALL provide a "Challenge Random Student" button that matches them with another student automatically
2. WHEN a challenge is initiated THEN the system SHALL send a challenge request via the settings notification system (to be implemented) with quiz topic selection
3. WHEN a challenge is accepted THEN both students SHALL take the same set of quiz questions from admin-configured question pools without time limits
4. WHEN challenge results are calculated THEN the system SHALL award 3 points to winner, 1 point each for draws, and 0 points for losing
5. WHEN students participate in challenges THEN they SHALL be able to take the quiz at any time they desire and results will be computed when both complete
6. WHEN individual competition points are awarded THEN they SHALL contribute to the student's personal leaderboard ranking

### Requirement 5: Parent Dashboard Quiz Visibility

**User Story:** As a parent, I want to see my child's quiz progress and performance, so that I can monitor their learning progress and provide appropriate support.

#### Acceptance Criteria

1. WHEN a parent views their dashboard THEN the system SHALL display linked children's quiz statistics including topics completed, average scores, and recent attempts
2. WHEN quiz progress is shown THEN the system SHALL organize data by subject and topic, showing completion rates and performance trends
3. WHEN parents view quiz details THEN the system SHALL show individual quiz attempts with timestamps, scores, and time taken
4. WHEN quiz analytics are displayed THEN the system SHALL provide insights such as strongest/weakest topics and improvement suggestions
5. WHEN parent-child linking exists THEN the system SHALL automatically update quiz progress data when students complete quizzes
6. WHEN quiz data is accessed THEN the system SHALL respect privacy settings and only show data for properly linked children

### Requirement 6: Lesson-Quiz Integration

**User Story:** As a student, I want quiz progress to be tracked alongside my lesson progress, so that I can see comprehensive learning analytics without any access restrictions.

#### Acceptance Criteria

1. WHEN students complete quizzes THEN the system SHALL record progress in relation to corresponding lesson topics for analytics
2. WHEN quiz progress is tracked THEN the system SHALL update `/lesson_progress/{studentId}/{grade}/{subject}/{topic}/` with quiz completion data
3. WHEN quizzes are displayed THEN ALL quizzes SHALL be available without any locking or prerequisite requirements
4. WHEN students access any quiz THEN the system SHALL allow immediate access regardless of lesson completion status
5. WHEN progress analytics are generated THEN the system SHALL show correlations between lesson completion and quiz performance
6. WHEN comprehensive tracking occurs THEN the system SHALL update both lesson and quiz completion status for learning insights

### Requirement 7: Admin Lesson Content Management

**User Story:** As an admin, I want to upload and manage lesson content through the mobile admin interface using the same JSON format as the existing script system, so that I can easily add new lessons with image URLs and maintain consistency with the current implementation.

#### Acceptance Criteria

1. WHEN an admin logs in with admin credentials THEN the system SHALL provide access to lesson content management alongside quiz management
2. WHEN an admin accesses lesson management THEN the system SHALL display a grade selector dropdown identical to the quiz management interface
3. WHEN an admin uploads lesson content THEN the system SHALL accept JSON format files matching the existing script structure with lessonId, title, sections, and embedded questions
4. WHEN lesson JSON is processed THEN the system SHALL validate the same structure as the current script: sections with sectionId, type (content/question), order, and required fields
5. WHEN lesson content includes media THEN the system SHALL support image URLs in the JSON format and maintain the existing relative path structure
6. WHEN lessons are uploaded THEN the system SHALL compress using gzip and upload to Firebase Storage with 30-day cache headers matching current script behavior
7. WHEN lesson upload completes THEN the system SHALL create lessonsMeta documents with id, title, grade, subject, sizeBytes, contentPath, version, and totalSections

### Requirement 8: Performance and Size Optimization

**User Story:** As a user, I want the app to remain fast and lightweight despite new admin features, so that the app continues to perform well on all devices and doesn't consume excessive storage.

#### Acceptance Criteria

1. WHEN admin features are added THEN the total app size increase SHALL not exceed 200 KB
2. WHEN quiz data is cached THEN the system SHALL implement LRU cache eviction to prevent excessive local storage usage
3. WHEN Firebase operations occur THEN the system SHALL batch reads and writes to minimize Firestore costs and improve performance
4. WHEN admin screens are loaded THEN the system SHALL lazy-load admin functionality to avoid impacting regular user performance
5. WHEN quiz questions are synchronized THEN the system SHALL use incremental sync to update only changed content
6. WHEN offline functionality is maintained THEN students SHALL be able to take cached quizzes without internet connectivity
7. WHEN app performance is measured THEN quiz loading and admin operations SHALL complete within 2 seconds on mid-range devices
###
 Requirement 9: Firebase Cost Reduction (90% Cost Optimization)

**User Story:** As a system administrator, I want to minimize Firebase costs by implementing aggressive caching and batching strategies, so that the app can scale to thousands of users while maintaining low operational costs.

#### Acceptance Criteria

1. WHEN quiz data is accessed THEN the system SHALL implement 30-day SharedPreferences caching with cache hit rate >90% to minimize Firestore reads
2. WHEN quiz attempts are recorded THEN the system SHALL batch write up to 50 attempts at once using Firestore batch operations to reduce write costs
3. WHEN quiz questions are synchronized THEN the system SHALL use timestamp-based incremental sync to download only changed content since last update
4. WHEN admin uploads occur THEN the system SHALL compress JSON quiz data using gzip before Firebase Storage upload with 30-day cache headers
5. WHEN student quiz sessions occur THEN the system SHALL queue quiz attempts locally and sync in background batches every 5 minutes or 10 attempts
6. WHEN quiz metadata is needed THEN the system SHALL cache quiz lists indefinitely in SharedPreferences until admin updates occur
7. WHEN Firebase Storage is used THEN the system SHALL implement CDN-style caching with "public, max-age=2592000" headers for all quiz content
8. WHEN offline mode is active THEN the system SHALL serve 100% of quiz content from SharedPreferences cache without any Firebase calls
9. WHEN quiz analytics are generated THEN the system SHALL aggregate data locally and sync summary statistics only, not individual attempt records
10. WHEN competition challenges occur THEN the system SHALL use single document writes with atomic updates instead of multiple separate operations
### Re
quirement 10: Firebase Security Rules

**User Story:** As a system administrator, I want to implement proper Firebase security rules for the quiz system, so that data access is properly controlled and unauthorized users cannot access or modify quiz content.

#### Acceptance Criteria

1. WHEN Firebase rules are configured THEN admin users SHALL have read/write access to `/quizzes/`, `/competition_quizzes/`, and `/admin_users/` collections
2. WHEN students access quiz data THEN they SHALL have read-only access to `/quizzes/{grade}/{subject}/{topic}/questions/` matching their grade level
3. WHEN quiz attempts are recorded THEN students SHALL only be able to write to their own `/quiz_attempts/{studentId}/` documents
4. WHEN parents access quiz data THEN they SHALL only be able to read quiz attempts for their linked children via proper parent-child relationship validation
5. WHEN admin authentication occurs THEN the system SHALL validate admin status through Firebase rules checking the `/admin_users/` collection
6. WHEN competition challenges are created THEN students SHALL be able to read/write to `/student_challenges/` only for challenges they participate in
7. WHEN lesson content is managed THEN admin users SHALL have full access to lesson-related collections while regular users have read-only access to their grade-appropriate content
#
## Requirement 11: School vs School Competition System

**User Story:** As a student, I want to participate in school vs school competitions where my school competes against other schools, so that I can contribute to my school's ranking while earning personal points.

#### Acceptance Criteria

1. WHEN a school competition is created THEN the system SHALL allow any number of students from each school to participate without minimum or maximum limits
2. WHEN school competition questions are generated THEN all students SHALL receive the same set of questions for fair comparison
3. WHEN students participate in school competitions THEN the system SHALL implement question deduplication to prevent students from receiving questions they have already answered
4. WHEN school competition results are calculated THEN the system SHALL average all participating students' scores to determine the school's final score
5. WHEN school competitions have deadlines THEN students SHALL be able to take the quiz at any time before the deadline
6. WHEN school competition points are awarded THEN students SHALL receive personal points that contribute to their individual leaderboard ranking
7. WHEN school competition data is stored THEN the system SHALL use `/school_competitions/{competitionId}/` structure with question pools and participant tracking

### Requirement 12: Dual Leaderboard System

**User Story:** As a student, I want to see both individual and school leaderboards, so that I can track my personal progress and my school's competitive standing.

#### Acceptance Criteria

1. WHEN individual leaderboards are displayed THEN the system SHALL include points from lessons, personal quizzes, student vs student challenges, and school competition participation
2. WHEN school leaderboards are displayed THEN the system SHALL show averaged scores from school competitions only
3. WHEN a school card is pressed on the leaderboard THEN the system SHALL display the top contributors from that school with their individual scores
4. WHEN leaderboard data is calculated THEN the system SHALL aggregate student points locally and sync summary statistics to minimize Firebase costs
5. WHEN school rankings are updated THEN the system SHALL recalculate averages based on all participating students' school competition scores
6. WHEN leaderboard displays are rendered THEN the system SHALL provide toggle between individual view and school view for easy navigation