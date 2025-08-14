# Requirements Document

## Introduction

This specification outlines the core functionality for Mwanafunzi Academy's Flutter app, focusing on implementing a comprehensive learning platform with offline capabilities, motivational AI messages, lesson management, progress tracking, settings with leaderboard, and parent-child linking features. The implementation must strictly adhere to Flutter Lite rules to maintain APK size under 12MB while providing essential educational functionality for Kenyan students with limited internet access.

## Requirements

### Requirement 1: Dynamic User Greeting and Motivational Messages

**User Story:** As a student, I want to be greeted by my actual name and see inspiring AI-generated motivational messages that change each time I navigate to the home screen, so that I feel personally connected and stay motivated with my learning journey.

#### Acceptance Criteria

1. WHEN a student navigates to the home screen THEN the system SHALL display the student's actual name from their user profile instead of hardcoded "Student Name"
2. WHEN student name is not available THEN the system SHALL display "Welcome back, Learner!" as fallback
3. WHEN a student navigates to the home screen THEN the system SHALL display a new AI-generated motivational message from Gemma API
4. WHEN the API call fails THEN the system SHALL display a fallback message from a cached collection of 10 hardcoded motivational messages
5. WHEN the system receives a new message THEN it SHALL cache the last 5 messages in SharedPreferences for offline fallback
6. WHEN the student is offline THEN the system SHALL display a random message from the cached collection
7. WHEN the message is displayed THEN it SHALL replace the current hardcoded message with a super inspiring, motivational message that encourages learning excellence

### Requirement 2: Offline-First Duolingo-Style Lesson System

**User Story:** As a student with limited internet access, I want to access lessons in small, digestible sections with embedded questions (like Duolingo), so that I can learn effectively even without consistent internet connectivity.

#### Acceptance Criteria

1. WHEN a student selects a grade THEN the system SHALL fetch lesson metadata for that grade from Firestore in a single query
2. WHEN lesson metadata is fetched THEN the system SHALL cache it indefinitely in local storage using SharedPreferences
3. WHEN a student wants to access a lesson THEN the system SHALL check if the lesson content exists locally with matching version
4. IF lesson content is not cached or version mismatches THEN the system SHALL automatically download the lesson content in the background
5. WHEN automatic download starts THEN the system SHALL show a subtle loading indicator and download gzipped lesson content from Firebase Storage regardless of connection type (WiFi or mobile data)
6. WHEN download fails THEN the system SHALL display user-friendly error messages such as "Unable to download lesson. Please check your connection and try again."
7. WHEN lesson content is downloaded THEN the system SHALL store it locally using path_provider and update the cached version
8. WHEN lesson content is cached THEN the system SHALL serve it immediately without network requests
9. WHEN lesson is displayed THEN the system SHALL break content into small sections with navigation between sections
10. WHEN lesson sections contain questions THEN the system SHALL display multiple choice questions with 4 options embedded between content sections
11. WHEN student answers a question THEN the system SHALL show the correct answer with explanation but NOT award points
12. WHEN storage space is low THEN the system SHALL implement LRU (Least Recently Used) cache eviction for lesson content

### Requirement 3: Progress Tracking and Points System

**User Story:** As a student, I want to earn points when I complete lessons and see my progress tracked, so that I feel rewarded for my learning achievements and can monitor my advancement.

#### Acceptance Criteria

1. WHEN a student completes a lesson THEN the system SHALL immediately award 10 points and update the local points display
2. WHEN points are awarded THEN the system SHALL queue the progress record locally with unique progressRecordId
3. WHEN the device has internet connectivity THEN the system SHALL batch sync all queued progress records to Firestore
4. WHEN syncing progress THEN the system SHALL use a single Firestore transaction to read current points and write all progress updates
5. WHEN duplicate progressRecordId is detected THEN the system SHALL skip that record to prevent double-counting
6. WHEN sync is successful THEN the system SHALL clear the local queue and update user points in Firestore
7. WHEN sync fails THEN the system SHALL retain queued records for next sync attempt
8. WHEN student views their profile THEN the system SHALL display current points from local cache with last sync timestamp

### Requirement 4: Settings Screen with Leaderboard

**User Story:** As a student, I want to access a settings screen that shows my points and ranking compared to other students, so that I can track my performance and stay motivated through friendly competition.

#### Acceptance Criteria

1. WHEN student taps the settings button (replacing refresh button) THEN the system SHALL navigate to the settings screen
2. WHEN settings screen loads THEN the system SHALL display current user points from local cache immediately
3. WHEN settings screen loads THEN the system SHALL check if cached leaderboard data is older than 12 hours
4. IF leaderboard cache is expired THEN the system SHALL fetch updated leaderboard from Firestore
5. WHEN leaderboard is fetched THEN the system SHALL cache it locally with 12-hour TTL
6. WHEN leaderboard is displayed THEN the system SHALL show user's rank for their grade if present in leaderboard
7. WHEN leaderboard is displayed THEN the system SHALL show a countdown timer for next leaderboard update
8. WHEN user is not in leaderboard THEN the system SHALL display "Keep learning to appear on leaderboard" message


### Requirement 5: Section-Based Comment System with Cost Optimization

**User Story:** As a student, I want to comment on specific lesson sections and interact with other students' comments through likes and dislikes, so that I can engage with the learning community and get help on specific topics.

#### Acceptance Criteria

1. WHEN a student views a lesson section THEN the system SHALL display a comment button with the number of cached comments for that section
2. WHEN student taps the comment button THEN the system SHALL show all comments for that specific section (not the entire lesson)
3. WHEN comment section loads THEN the system SHALL load ALL comments for the section in one Firestore read and cache for 24 hours
4. WHEN student posts a comment THEN the system SHALL add it to local cache immediately and queue for batch sync
5. WHEN student likes or dislikes a comment THEN the system SHALL update local cache immediately and queue action for batch sync
6. WHEN student wants to delete their own comment THEN the system SHALL remove from local cache and queue deletion for batch sync
7. WHEN 24 hours pass OR app closes THEN the system SHALL batch sync all queued comment actions (posts, likes, dislikes, deletes) to Firestore
8. WHEN comments are synced THEN the system SHALL update the cached comment data with server response
9. WHEN network is unavailable THEN the system SHALL show cached comments and queue all user actions for next sync

### Requirement 6: Enhanced Parent-Child Linking with Comment Monitoring

**User Story:** As a parent, I want to link my account to my child's student account and monitor their comment activity, so that I can support their learning and ensure appropriate online behavior.

#### Acceptance Criteria

1. WHEN a parent accesses the parent dashboard THEN the system SHALL display a "Link Student" button if no children are linked
2. WHEN parent taps "Link Student" THEN the system SHALL show a modal with email input field
3. WHEN parent enters student email and submits THEN the system SHALL verify a student account exists with that email
4. IF student account exists THEN the system SHALL create a parentLinks document with status 'linked_by_parent'
5. WHEN parent link is created THEN the system SHALL log the action in audit/parentActions with IP and timestamp
6. WHEN parent views dashboard THEN the system SHALL display linked children with their aggregated progress data
7. WHEN parent selects a child THEN the system SHALL show child's points, lessons completed, recent activity, and comment activity
8. WHEN parent views child's comment activity THEN the system SHALL display recent comments posted by child with lesson section context
9. WHEN parent wants to unlink THEN the system SHALL update parentLinks status to 'revoked' and remove access
10. WHEN parent accesses child data THEN the system SHALL only read pre-computed childSummaries, childLessonStats, and childCommentActivity documents

### Requirement 7: Enhanced Lesson Content Management with Section Support

**User Story:** As a content administrator, I want to bulk upload lesson content with section-based structure and embedded questions, so that students can access Duolingo-style learning materials efficiently.

#### Acceptance Criteria

1. WHEN administrator runs the batch upload script THEN the system SHALL validate JSON structure for each lesson including sections and embedded questions
2. WHEN lesson JSON is valid THEN the system SHALL compress it using gzip compression
3. WHEN lesson is compressed THEN the system SHALL upload it to Firebase Storage with path lessons/{grade}/{lessonId}.json.gz
4. WHEN uploading to Storage THEN the system SHALL set Cache-Control header to 'public, max-age=2592000' (30 days) to balance content freshness with caching efficiency
5. WHEN lesson has media files (images, audio) THEN the system SHALL compress and upload them to media/{grade}/{lessonId}/ with same cache headers
6. WHEN lesson content references images THEN the system SHALL use relative paths like "refer to image above" that map to cached media files
7. WHEN lesson contains sections THEN the system SHALL validate each section has sectionId, type (content/question), and required fields
8. WHEN lesson contains questions THEN the system SHALL validate question structure with 4 options, correct answer index, and explanation
9. WHEN upload is complete THEN the system SHALL write lessonsMeta document with id, title, grade, subject, sizeBytes, contentPath, version, totalSections
10. WHEN script encounters errors THEN the system SHALL log detailed error information and continue with next lesson
11. WHEN script completes THEN the system SHALL provide summary report of uploaded lessons, total bytes, and section count

### Requirement 8: Caching and Performance Optimization

**User Story:** As a student using the app on a low-end device with limited data, I want the app to efficiently cache content and minimize data usage, so that I can have a smooth learning experience without excessive data consumption.

#### Acceptance Criteria

1. WHEN app starts THEN the system SHALL implement aggressive caching for all static content with appropriate TTL values
2. WHEN making Firestore queries THEN the system SHALL include limit clauses to prevent expensive unbounded reads
3. WHEN caching lesson content THEN the system SHALL implement version-based cache invalidation without TTL deletion
4. WHEN syncing progress THEN the system SHALL batch writes with maximum 500 records per transaction
5. WHEN downloading media THEN the system SHALL leverage CDN caching through Firebase Storage cache headers
6. WHEN app detects low storage THEN the system SHALL implement intelligent cache cleanup prioritizing frequently accessed content
7. WHEN network is slow THEN the system SHALL show appropriate loading states and allow graceful degradation
8. WHEN telemetry is collected THEN the system SHALL capture cache hit/miss ratios, read/write counts, and download frequencies for optimization