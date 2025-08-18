# Design Document

## Overview

This design document outlines the implementation approach for the admin quiz management system. The system will provide hidden admin authentication, dynamic quiz loading with aggressive caching, student-vs-student competitions, parent visibility, and admin interfaces for both quiz and lesson management. The design prioritizes Firebase cost reduction through 30-day caching strategies and batch operations.

## Architecture Overview

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Student App   │    │   Parent App    │    │   Admin App     │
│                 │    │                 │    │                 │
│ • Quiz Taking   │    │ • Progress View │    │ • Quiz Upload   │
│ • Competitions  │    │ • Analytics     │    │ • Lesson Upload │
│ • Progress      │    │ • Child Linking │    │ • Management    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Shared Services │
                    │                 │
                    │ • Auth Service  │
                    │ • Cache Service │
                    │ • Firebase API  │
                    └─────────────────┘
```

### Data Flow Architecture

```
┌─────────────────┐    30-day Cache    ┌─────────────────┐
│ SharedPreferences│ ◄──────────────── │   Firebase      │
│                 │                    │                 │
│ • Quiz Questions│    Batch Writes    │ • /quizzes/     │
│ • Quiz Attempts │ ──────────────────►│ • /quiz_attempts│
│ • Lesson Meta   │                    │ • /lessons/     │
│ • User Progress │                    │ • /admin_users/ │
└─────────────────┘                    └─────────────────┘
```

## Firebase Data Structure

### Collections Design

```
/admin_users/
  {adminId}/
    email: string
    role: "admin"
    permissions: ["quiz_management", "lesson_management"]
    createdAt: timestamp

/quizzes/
  {grade}/
    {subject}/
      {topic}/
        questions: [
          {
            id: string
            question: string
            options: [string, string, string, string]
            correctAnswerIndex: number
            explanation: string
          }
        ]
        metadata: {
          totalQuestions: number
          lastUpdated: timestamp
          createdBy: adminId
        }

/quiz_attempts/
  {studentId}/
    regular/
      {attemptId}/
        grade: string
        subject: string
        topic: string
        questions: array
        answers: array
        score: number
        totalQuestions: number
        completedAt: timestamp
    competition/
      {challengeId}/
        opponentId: string
        questions: array
        answers: array
        score: number
        status: "pending" | "completed"
        completedAt: timestamp

/student_challenges/
  {challengeId}/
    challenger: {
      studentId: string
      name: string
      school: string
    }
    challenged: {
      studentId: string
      name: string
      school: string
    }
    topic: string
    subject: string
    grade: string
    status: "pending" | "accepted" | "completed"
    questions: array
    results: {
      challengerScore: number
      challengedScore: number
      winner: string | "draw"
      pointsAwarded: {
        challenger: number
        challenged: number
      }
    }
    createdAt: timestamp
    completedAt: timestamp

/lessons/
  {grade}/
    {lessonId}.json.gz (Firebase Storage)
    
/lessonsMeta/
  {grade}/
    lessons: [
      {
        id: string
        title: string
        subject: string
        topic: string
        sizeBytes: number
        contentPath: string
        version: number
        totalSections: number
        hasQuestions: boolean
        lastUpdated: timestamp
      }
    ]
```

## Component Design

### 1. Authentication System

#### AdminAuthService
```dart
class AdminAuthService {
  static const String _adminCollectionPath = 'admin_users';
  
  Future<bool> isAdminUser(String email) async {
    // Check against Firebase admin_users collection
    final adminDoc = await FirebaseFirestore.instance
        .collection(_adminCollectionPath)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    return adminDoc.docs.isNotEmpty;
  }
  
  Future<AdminUser?> authenticateAdmin(String email, String password) async {
    // First authenticate with Firebase Auth
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    
    // Then verify admin status
    if (await isAdminUser(email)) {
      return AdminUser.fromFirestore(userCredential.user!.uid, email);
    }
    
    return null;
  }
}
```

### 2. Quiz Management System

#### QuizService with 30-day Caching
```dart
class QuizService {
  static const String _cachePrefix = 'quiz_';
  static const int _cacheTTLDays = 30;
  
  Future<List<QuizQuestion>> getQuizQuestions({
    required String grade,
    required String subject, 
    required String topic,
  }) async {
    final cacheKey = '${_cachePrefix}${grade}_${subject}_${topic}';
    
    // Try cache first (30-day TTL)
    final cached = await _getCachedQuestions(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // Fetch from Firebase
    final questions = await _fetchQuestionsFromFirebase(grade, subject, topic);
    
    // Cache for 30 days
    await _cacheQuestions(cacheKey, questions);
    
    return questions;
  }
  
  Future<void> batchRecordAttempts(List<QuizAttempt> attempts) async {
    // Batch write up to 50 attempts at once
    final batch = FirebaseFirestore.instance.batch();
    
    for (int i = 0; i < attempts.length; i += 50) {
      final batchAttempts = attempts.skip(i).take(50);
      
      for (final attempt in batchAttempts) {
        final docRef = FirebaseFirestore.instance
            .collection('quiz_attempts')
            .doc(attempt.studentId)
            .collection('regular')
            .doc();
        
        batch.set(docRef, attempt.toJson());
      }
      
      await batch.commit();
    }
  }
}
```

### 3. Admin Quiz Upload Interface

#### AdminQuizUploadScreen
```dart
class AdminQuizUploadScreen extends StatefulWidget {
  @override
  State<AdminQuizUploadScreen> createState() => _AdminQuizUploadScreenState();
}

class _AdminQuizUploadScreenState extends State<AdminQuizUploadScreen> {
  String _selectedGrade = 'Grade 1';
  String _selectedSubject = 'Mathematics';
  String _selectedTopic = '';
  File? _selectedJsonFile;
  List<QuizQuestion> _previewQuestions = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Quiz Content')),
      body: Column(
        children: [
          // Reuse existing GradeSelectorWidget
          GradeSelectorWidget(
            selectedGrade: _selectedGrade,
            onGradeChanged: (grade) => setState(() => _selectedGrade = grade),
          ),
          
          // Subject dropdown
          _buildSubjectDropdown(),
          
          // Topic input
          _buildTopicInput(),
          
          // JSON file picker
          _buildJsonFilePicker(),
          
          // Preview section
          if (_previewQuestions.isNotEmpty) _buildPreviewSection(),
          
          // Upload button
          _buildUploadButton(),
        ],
      ),
    );
  }
  
  Future<void> _uploadQuizContent() async {
    try {
      // Validate JSON structure
      final questions = await _validateJsonFile(_selectedJsonFile!);
      
      // Batch write to Firebase
      await _batchWriteQuestions(questions);
      
      // Clear cache for this topic
      await _clearTopicCache(_selectedGrade, _selectedSubject, _selectedTopic);
      
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }
}
```

### 4. Competition System

#### StudentChallengeService
```dart
class StudentChallengeService {
  Future<String> createRandomChallenge({
    required String challengerId,
    required String topic,
    required String subject,
    required String grade,
  }) async {
    // Find random opponent (exclude challenger)
    final randomOpponent = await _findRandomOpponent(challengerId, grade);
    
    if (randomOpponent == null) {
      throw Exception('No opponents available for challenge');
    }
    
    // Create challenge document
    final challengeId = _generateChallengeId();
    final challenge = StudentChallenge(
      id: challengeId,
      challenger: await _getStudentInfo(challengerId),
      challenged: randomOpponent,
      topic: topic,
      subject: subject,
      grade: grade,
      status: 'pending',
      questions: await _getRandomQuestionsForTopic(topic, subject, grade),
      createdAt: DateTime.now(),
    );
    
    await FirebaseFirestore.instance
        .collection('student_challenges')
        .doc(challengeId)
        .set(challenge.toJson());
    
    // Send notification (to be implemented)
    await _sendChallengeNotification(randomOpponent.studentId, challenge);
    
    return challengeId;
  }
  
  Future<void> completeChallenge({
    required String challengeId,
    required String studentId,
    required List<int> answers,
  }) async {
    final challengeDoc = await FirebaseFirestore.instance
        .collection('student_challenges')
        .doc(challengeId)
        .get();
    
    final challenge = StudentChallenge.fromJson(challengeDoc.data()!);
    
    // Calculate score
    final score = _calculateScore(answers, challenge.questions);
    
    // Update challenge with results
    final updatedChallenge = challenge.copyWith(
      results: _calculateChallengeResults(challenge, studentId, score),
      status: _bothStudentsCompleted(challenge, studentId) ? 'completed' : 'in_progress',
    );
    
    await FirebaseFirestore.instance
        .collection('student_challenges')
        .doc(challengeId)
        .update(updatedChallenge.toJson());
  }
  
  ChallengeResults _calculateChallengeResults(
    StudentChallenge challenge, 
    String completingStudentId, 
    int score
  ) {
    // Scoring: 1 point per correct answer + 3 bonus for winner + 1 each for draw
    final basePoints = score;
    
    if (challenge.results?.challengerScore != null && 
        challenge.results?.challengedScore != null) {
      // Both completed, determine winner
      final challengerTotal = challenge.results!.challengerScore;
      final challengedTotal = challenge.results!.challengedScore;
      
      if (challengerTotal > challengedTotal) {
        return ChallengeResults(
          challengerScore: challengerTotal,
          challengedScore: challengedTotal,
          winner: challenge.challenger.studentId,
          pointsAwarded: {
            'challenger': challengerTotal + 3, // Winner bonus
            'challenged': challengedTotal,     // No bonus
          },
        );
      } else if (challengedTotal > challengerTotal) {
        return ChallengeResults(
          challengerScore: challengerTotal,
          challengedScore: challengedTotal,
          winner: challenge.challenged.studentId,
          pointsAwarded: {
            'challenger': challengerTotal,     // No bonus
            'challenged': challengedTotal + 3, // Winner bonus
          },
        );
      } else {
        // Draw
        return ChallengeResults(
          challengerScore: challengerTotal,
          challengedScore: challengedTotal,
          winner: 'draw',
          pointsAwarded: {
            'challenger': challengerTotal + 1, // Draw bonus
            'challenged': challengedTotal + 1, // Draw bonus
          },
        );
      }
    }
    
    // First completion, just record score
    return ChallengeResults(
      challengerScore: completingStudentId == challenge.challenger.studentId ? score : null,
      challengedScore: completingStudentId == challenge.challenged.studentId ? score : null,
      winner: null,
      pointsAwarded: {},
    );
  }
}
```

### 5. Parent Dashboard Integration

#### ParentQuizAnalyticsService
```dart
class ParentQuizAnalyticsService {
  Future<ChildQuizAnalytics> getChildQuizAnalytics(String childId) async {
    // Get all quiz attempts for child
    final attemptsSnapshot = await FirebaseFirestore.instance
        .collection('quiz_attempts')
        .doc(childId)
        .collection('regular')
        .orderBy('completedAt', descending: true)
        .get();
    
    final attempts = attemptsSnapshot.docs
        .map((doc) => QuizAttempt.fromJson(doc.data()))
        .toList();
    
    // Calculate analytics
    return ChildQuizAnalytics(
      totalQuizzesTaken: attempts.length,
      averageScore: _calculateAverageScore(attempts),
      topicsCompleted: _getUniqueTopics(attempts),
      recentAttempts: attempts.take(10).toList(),
      subjectPerformance: _calculateSubjectPerformance(attempts),
      improvementTrends: _calculateImprovementTrends(attempts),
      strongestTopics: _getStrongestTopics(attempts),
      weakestTopics: _getWeakestTopics(attempts),
    );
  }
  
  Map<String, double> _calculateSubjectPerformance(List<QuizAttempt> attempts) {
    final subjectScores = <String, List<double>>{};
    
    for (final attempt in attempts) {
      subjectScores.putIfAbsent(attempt.subject, () => []);
      subjectScores[attempt.subject]!.add(attempt.score / attempt.totalQuestions);
    }
    
    return subjectScores.map((subject, scores) => 
        MapEntry(subject, scores.reduce((a, b) => a + b) / scores.length));
  }
}
```

### 6. Admin Lesson Upload Interface

#### AdminLessonUploadScreen
```dart
class AdminLessonUploadScreen extends StatefulWidget {
  @override
  State<AdminLessonUploadScreen> createState() => _AdminLessonUploadScreenState();
}

class _AdminLessonUploadScreenState extends State<AdminLessonUploadScreen> {
  String _selectedGrade = 'Grade 1';
  File? _selectedJsonFile;
  LessonContent? _previewLesson;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Lesson Content')),
      body: Column(
        children: [
          // Grade selector (same as quiz upload)
          GradeSelectorWidget(
            selectedGrade: _selectedGrade,
            onGradeChanged: (grade) => setState(() => _selectedGrade = grade),
          ),
          
          // JSON file picker
          _buildJsonFilePicker(),
          
          // Preview section
          if (_previewLesson != null) _buildLessonPreview(),
          
          // Upload button
          _buildUploadButton(),
        ],
      ),
    );
  }
  
  Future<void> _uploadLessonContent() async {
    try {
      // Validate JSON matches existing script structure
      final lesson = await _validateLessonJson(_selectedJsonFile!);
      
      // Compress with gzip (same as script)
      final compressedContent = await _compressLessonContent(lesson);
      
      // Upload to Firebase Storage with 30-day cache headers
      final storagePath = 'lessons/${_selectedGrade}/${lesson.lessonId}.json.gz';
      await _uploadToFirebaseStorage(compressedContent, storagePath);
      
      // Create lessonsMeta document
      await _createLessonMetaDocument(_selectedGrade, lesson);
      
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }
  
  Future<void> _createLessonMetaDocument(String grade, LessonContent lesson) async {
    final metaDoc = FirebaseFirestore.instance
        .collection('lessonsMeta')
        .doc(grade);
    
    await metaDoc.update({
      'lessons': FieldValue.arrayUnion([{
        'id': lesson.lessonId,
        'title': lesson.title,
        'subject': lesson.subject,
        'topic': lesson.topic,
        'sizeBytes': lesson.toJson().toString().length,
        'contentPath': 'lessons/${grade}/${lesson.lessonId}.json.gz',
        'version': 1,
        'totalSections': lesson.sections.length,
        'hasQuestions': lesson.sections.any((s) => s.type == 'question'),
        'lastUpdated': FieldValue.serverTimestamp(),
      }])
    });
  }
}
```

## Cost Optimization Strategies

### 1. Aggressive Caching Strategy
```dart
class CostOptimizedCacheService {
  static const int _cacheTTLSeconds = 30 * 24 * 60 * 60; // 30 days
  
  Future<T?> getCachedData<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(key);
    final cacheTimestamp = prefs.getInt('${key}_timestamp') ?? 0;
    
    if (cachedJson != null && _isCacheValid(cacheTimestamp)) {
      return fromJson(jsonDecode(cachedJson));
    }
    
    return null;
  }
  
  bool _isCacheValid(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - timestamp) < _cacheTTLSeconds;
  }
}
```

### 2. Batch Operations
```dart
class BatchOperationService {
  static const int _maxBatchSize = 50;
  final List<QuizAttempt> _pendingAttempts = [];
  
  Future<void> queueQuizAttempt(QuizAttempt attempt) async {
    _pendingAttempts.add(attempt);
    
    if (_pendingAttempts.length >= _maxBatchSize) {
      await _flushBatch();
    }
  }
  
  Future<void> _flushBatch() async {
    if (_pendingAttempts.isEmpty) return;
    
    final batch = FirebaseFirestore.instance.batch();
    
    for (final attempt in _pendingAttempts) {
      final docRef = FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(attempt.studentId)
          .collection('regular')
          .doc();
      
      batch.set(docRef, attempt.toJson());
    }
    
    await batch.commit();
    _pendingAttempts.clear();
  }
}
```

## Security Implementation

### Firebase Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin users collection - only admins can read/write
    match /admin_users/{adminId} {
      allow read, write: if isAdmin();
    }
    
    // Quiz collections - admins can write, students can read their grade
    match /quizzes/{grade}/{subject}/{topic} {
      allow read: if isAuthenticated() && 
                     (isAdmin() || resource.data.grade == getUserGrade());
      allow write: if isAdmin();
    }
    
    // Quiz attempts - students can only access their own
    match /quiz_attempts/{studentId}/{collection}/{attemptId} {
      allow read, write: if isAuthenticated() && 
                            (request.auth.uid == studentId || isAdmin());
    }
    
    // Student challenges - participants can read/write their challenges
    match /student_challenges/{challengeId} {
      allow read, write: if isAuthenticated() && 
                            (request.auth.uid in resource.data.participants || isAdmin());
    }
    
    // Lessons - admins can write, students can read their grade
    match /lessonsMeta/{grade} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
    }
    
    function getUserGrade() {
      return get(/databases/$(database)/documents/users/students/users/$(request.auth.uid)).data.grade;
    }
  }
}
```

## Performance Considerations

### 1. Lazy Loading
- Admin screens only load when admin user is detected
- Quiz questions load on-demand with aggressive caching
- Competition features load only when accessed

### 2. Memory Management
- Implement LRU cache eviction for quiz questions
- Clear unused cached data after 30 days
- Use pagination for large quiz lists

### 3. Network Optimization
- Batch all Firebase operations
- Use gzip compression for all uploads
- Implement retry logic with exponential backoff

## Testing Strategy

### 1. Unit Tests
- Quiz validation logic
- Caching mechanisms
- Scoring calculations
- Batch operations

### 2. Integration Tests
- Firebase operations
- Admin authentication flow
- Competition system end-to-end
- Parent dashboard data flow

### 3. Performance Tests
- Cache hit rate validation (target >90%)
- Firebase cost monitoring
- App size impact measurement
- Load testing with multiple concurrent users

This design provides a comprehensive, cost-optimized solution that maintains the app's lightweight nature while adding powerful admin and competition features.