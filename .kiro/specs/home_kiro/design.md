# Design Document

## Overview

The Mwanafunzi Academy core features implementation focuses on creating an offline-first, Flutter Lite-compliant learning platform. The design emphasizes minimal APK size impact while delivering essential functionality including dynamic user greetings, AI-powered motivational messages, automatic lesson caching, progress tracking, settings with leaderboard, and parent-child linking. The architecture leverages existing Firebase infrastructure and follows the setState + Services pattern to maintain the current 6-8MB baseline.

## Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter UI    │    │   Service Layer  │    │  Data Sources   │
│                 │    │                  │    │                 │
│ • Home Screen   │◄──►│ • UserService    │◄──►│ • Firestore     │
│ • Settings      │    │ • LessonService  │    │ • Storage       │
│ • Parent Dash   │    │ • ProgressSvc    │    │ • SharedPrefs   │
│                 │    │ • MotivationSvc  │    │ • Local Files   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Data Flow Architecture
```
Internet Available:
User Action → Service → Firestore/Storage → Local Cache → UI Update

Offline Mode:
User Action → Service → Local Cache → UI Update → Queue for Sync
```

## Components and Interfaces

### 1. User Service
**Purpose:** Manages user authentication, profile data, and greeting personalization

**Interface:**
```dart
class UserService {
  Future<String> getCurrentUserName();
  Future<String> getUserGrade();
  Future<int> getUserPoints();
  Future<void> updateUserPoints(int points);
  Stream<User?> get userStream;
}
```

**Implementation Details:**
- Fetches user data from Firestore users collection
- Caches user profile in SharedPreferences with key `user_profile`
- Provides fallback greeting "Welcome back, Learner!" when name unavailable
- Updates local points immediately for UI responsiveness

### 2. Motivation Service
**Purpose:** Handles AI-generated motivational messages with offline fallback

**Interface:**
```dart
class MotivationService {
  Future<String> getMotivationalMessage();
  Future<void> cacheMessage(String message);
  String getFallbackMessage();
}
```

**Implementation Details:**
- Makes HTTP calls to Gemma API endpoint
- Caches last 5 messages in SharedPreferences with key `cached_messages`
- Maintains 10 hardcoded super-inspiring fallback messages
- Implements exponential backoff for API failures
- Message examples: "You're destined for greatness! Every lesson brings you closer to your dreams!", "Your brilliant mind is unstoppable! Keep pushing boundaries!"

### 3. Lesson Service
**Purpose:** Manages section-based lesson metadata, content downloading, and offline caching

**Interface:**
```dart
class LessonService {
  Future<List<LessonMeta>> getLessonsForGrade(String grade);
  Future<LessonContent> getLessonContent(String lessonId);
  Future<LessonSection> getLessonSection(String lessonId, String sectionId);
  Future<void> downloadLessonContent(String lessonId);
  bool isLessonCached(String lessonId);
  Future<void> clearOldCache();
}
```

**Implementation Details:**
- Single Firestore query: `lessonsMeta.where('grade', '==', grade).get()`
- Stores metadata in SharedPreferences with key `lessons_meta_{grade}`
- Downloads gzipped content from Storage path: `lessons/{grade}/{lessonId}.json.gz`
- Uses path_provider for local file storage: `/data/mwanafunzi/lessons/`
- Implements version-based cache validation
- LRU eviction when storage exceeds 100MB
- Automatic background downloads with subtle loading indicators
- Parses lesson content into sections for Duolingo-style navigation

### 4. Progress Service
**Purpose:** Tracks lesson completion, awards points, and syncs progress

**Interface:**
```dart
class ProgressService {
  Future<void> completeLesson(String lessonId);
  Future<void> syncProgress();
  int getLocalPoints();
  List<ProgressRecord> getQueuedProgress();
}
```

**Implementation Details:**
- Generates unique progressRecordId: `{uid}:{lessonId}:{timestamp}`
- Queues progress in SharedPreferences with key `progress_queue`
- Awards 10 points immediately to local cache
- Batch syncs up to 500 records per Firestore transaction
- Implements client-side deduplication
- Retries failed syncs with exponential backoff

### 5. Settings Service
**Purpose:** Manages settings screen data and leaderboard functionality

**Interface:**
```dart
class SettingsService {
  Future<LeaderboardData> getLeaderboard(String grade);
  Future<UserRank> getUserRank(String userId, String grade);
  Duration getTimeUntilNextUpdate();
  Future<void> refreshLeaderboard();
}
```

**Implementation Details:**
- Fetches from Firestore: `leaderboards/{grade}`
- Caches with 12-hour TTL in SharedPreferences
- Computes countdown timer from `nextUpdateAt` field
- Shows user rank if present in top 100
- Fallback message: "Keep learning to appear on leaderboard"

### 6. Comment Service
**Purpose:** Manages section-based comments with 24-hour caching and cost optimization

**Interface:**
```dart
class CommentService {
  Future<List<Comment>> getCommentsForSection(String lessonId, String sectionId);
  Future<void> postComment(String lessonId, String sectionId, String text);
  Future<void> likeComment(String commentId);
  Future<void> dislikeComment(String commentId);
  Future<void> deleteComment(String commentId);
  Future<void> syncQueuedActions();
}
```

**Implementation Details:**
- Single Firestore read per section per 24 hours: `comments/{lessonId}_{sectionId}`
- Caches ALL comments for section in SharedPreferences with key `comments_{lessonId}_{sectionId}`
- Queues user actions (post, like, dislike, delete) in local storage
- Batch syncs all queued actions once every 24 hours or on app close
- Implements immediate UI updates with local cache
- 90% cost reduction through aggressive caching strategy

### 7. Question Service
**Purpose:** Handles embedded questions within lesson sections

**Interface:**
```dart
class QuestionService {
  Future<Question> getQuestionForSection(String lessonId, String sectionId);
  void recordAnswer(String questionId, int selectedOption);
  bool isAnswerCorrect(String questionId, int selectedOption);
  String getExplanation(String questionId);
}
```

**Implementation Details:**
- Questions embedded in lesson content, no separate Firestore reads
- Records answers locally for parent dashboard reporting
- No points awarded for question answers (as requested)
- Provides immediate feedback with correct answer and explanation

### 8. Parent Service
**Purpose:** Handles parent-child linking and enhanced child monitoring including comments

**Interface:**
```dart
class ParentService {
  Future<bool> linkChildByEmail(String childEmail);
  Future<List<ChildSummary>> getLinkedChildren();
  Future<ChildProgress> getChildProgress(String childId);
  Future<List<ChildComment>> getChildComments(String childId);
  Future<void> unlinkChild(String linkId);
}
```

**Implementation Details:**
- Verifies student exists: `students.where('email', '==', email).get()`
- Creates parentLinks document with status 'linked_by_parent'
- Reads pre-computed childSummaries, childLessonStats, and childCommentActivity
- Shows child's comment activity with lesson section context
- Logs all actions to audit/parentActions with IP tracking
- Implements rate limiting: max 5 link attempts per hour

## Data Models

### Firestore Collections

**lessonsMeta/{grade}**
```json
{
  "lessons": [
    {
      "id": "math_grade5_lesson1",
      "title": "Introduction to Fractions",
      "subject": "Mathematics",
      "version": "1.2.0",
      "sizeBytes": 245760,
      "contentPath": "lessons/5/math_grade5_lesson1.json.gz",
      "mediaCount": 3,
      "totalSections": 8,
      "hasQuestions": true
    }
  ],
  "lastUpdated": "2025-01-15T10:30:00Z"
}
```

**comments/{lessonId}_{sectionId}**
```json
{
  "comments": [
    {
      "id": "comment_123",
      "userId": "user_456",
      "userName": "John D.",
      "text": "Great explanation of fractions!",
      "likes": 5,
      "dislikes": 0,
      "timestamp": "2025-01-15T10:30:00Z",
      "isDeleted": false
    }
  ],
  "lastUpdated": "2025-01-15T10:30:00Z",
  "totalComments": 12
}
```

**Enhanced Lesson Content Structure**
```json
{
  "lessonId": "math_grade5_lesson1",
  "title": "Introduction to Fractions",
  "sections": [
    {
      "sectionId": "section_1",
      "type": "content",
      "title": "What are fractions?",
      "content": "A fraction represents part of a whole...",
      "media": ["image1.webp"],
      "order": 1
    },
    {
      "sectionId": "section_2",
      "type": "question",
      "question": "Which fraction represents half?",
      "options": ["1/4", "1/2", "3/4", "2/3"],
      "correctAnswer": 1,
      "explanation": "1/2 means one part out of two equal parts.",
      "order": 2
    },
    {
      "sectionId": "section_3",
      "type": "content",
      "title": "Adding fractions",
      "content": "When adding fractions with same denominator...",
      "order": 3
    }
  ]
}
```

**users/{uid}/progress/{lessonId}**
```json
{
  "lessonId": "math_grade5_lesson1",
  "completed": true,
  "pointsEarned": 10,
  "completedAt": "2025-01-15T14:22:00Z",
  "progressRecordId": "user123:math_grade5_lesson1:1705327320"
}
```

**parentLinks/{linkId}**
```json
{
  "parentId": "parent_user_id",
  "childId": "student_user_id",
  "status": "linked_by_parent",
  "createdAt": "2025-01-15T09:15:00Z",
  "createdByIp": "192.168.1.100"
}
```

**leaderboards/{grade}**
```json
{
  "overall": [
    {"userId": "user1", "name": "John D.", "points": 450, "rank": 1},
    {"userId": "user2", "name": "Mary K.", "points": 380, "rank": 2}
  ],
  "subjects": {
    "Mathematics": [
      {"userId": "user1", "name": "John D.", "points": 180, "rank": 1}
    ]
  },
  "updatedAt": "2025-01-15T06:00:00Z",
  "nextUpdateAt": "2025-01-15T18:00:00Z"
}
```

### Local Storage Schema

**SharedPreferences Keys:**
- `user_profile`: User name, grade, points
- `cached_messages`: Last 5 motivational messages
- `lessons_meta_{grade}`: Lesson metadata for grade
- `progress_queue`: Pending progress records
- `leaderboard_{grade}`: Cached leaderboard data
- `lesson_versions`: Version tracking for cache validation
- `comments_{lessonId}_{sectionId}`: Cached comments per section
- `comment_actions_queue`: Queued comment actions for batch sync
- `child_comment_activity_{childId}`: Parent dashboard comment data

**Local File Structure:**
```
/data/mwanafunzi/
├── lessons/
│   ├── {lessonId}.json (decompressed content)
│   └── versions.json (version tracking)
└── media/
    └── {lessonId}/
        ├── image1.webp
        └── audio1.mp3
```

## Error Handling

### Network Error Handling
- **API Failures:** Graceful fallback to cached content
- **Download Failures:** User-friendly error messages with retry options
- **Sync Failures:** Queue retention with exponential backoff retry

### Storage Error Handling
- **Cache Full:** Automatic LRU eviction with user notification
- **File Corruption:** Re-download with integrity verification
- **Permission Errors:** Fallback to app-specific storage

### User Experience Error Handling
- **Loading States:** Subtle progress indicators for downloads
- **Offline Mode:** Clear indicators when content is cached
- **Sync Status:** Visual feedback for progress synchronization



## Security Considerations

### Data Protection
- No sensitive data in local cache
- Encrypted SharedPreferences for user data
- Secure parent-child linking with audit trails

### Access Control
- Firestore security rules for parent access
- Rate limiting for API calls and linking attempts
- IP logging for audit and abuse prevention

### Content Security
- Gzipped content integrity verification
- Version-based cache invalidation
- Secure Firebase Storage rules with proper CORS