import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint;
import '../../core/constants.dart';

// Firestore database service following Flutter Lite rules
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to users collection
  CollectionReference get _users => _firestore.collection('users');

  // Get subcollection references
  CollectionReference get _parents => _users.doc('parents').collection('users');
  CollectionReference get _students => _users.doc('students').collection('users');
  CollectionReference get _teachers => _users.doc('teachers').collection('users');
  CollectionReference get _admins => _users.doc('admins').collection('users');

  // Parent-child linking collections
  CollectionReference get _parentLinks => _firestore.collection('parentLinks');
  CollectionReference get _audit => _firestore.collection('audit');

  // Lesson collections
  CollectionReference get _lessonsMeta => _firestore.collection('lessonsMeta');
  DocumentReference get _lessonsMetaDoc => _lessonsMeta.doc('grades');

  // Get appropriate collection based on user type
  CollectionReference _getUserCollection(String userType) {
    switch (userType) {
      case AppConstants.userTypeParent:
        return _parents;
      case AppConstants.userTypeStudent:
        return _students;
      case AppConstants.userTypeTeacher:
        return _teachers;
      case AppConstants.userTypeAdmin:
        return _admins;
      default:
        throw Exception('Unknown user type: $userType');
    }
  }

  // Create or update user document
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userCollection = _getUserCollection(userType);
      await userCollection.doc(userId).set({
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...userData,
      });
    } catch (e) {
      throw Exception('Failed to save user data: ${e.toString()}');
    }
  }

  // Get user document by ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      // Check each collection to find the user
      final parentDoc = await _parents.doc(userId).get();
      if (parentDoc.exists) return parentDoc;
      
      final studentDoc = await _students.doc(userId).get();
      if (studentDoc.exists) return studentDoc;
      
      final teacherDoc = await _teachers.doc(userId).get();
      if (teacherDoc.exists) return teacherDoc;
      
      final adminDoc = await _admins.doc(userId).get();
      if (adminDoc.exists) return adminDoc;
      
      throw Exception('User not found in any collection');
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Get user document by email
  Future<QuerySnapshot> getUserByEmail(String email) async {
    try {
      // Search across all collections
      final parentResults = await _parents.where('email', isEqualTo: email).get();
      if (parentResults.docs.isNotEmpty) {
        return parentResults;
      }
      
      final studentResults = await _students.where('email', isEqualTo: email).get();
      if (studentResults.docs.isNotEmpty) {
        return studentResults;
      }
      
      final teacherResults = await _teachers.where('email', isEqualTo: email).get();
      if (teacherResults.docs.isNotEmpty) {
        return teacherResults;
      }
      
      final adminResults = await _admins.where('email', isEqualTo: email).get();
      if (adminResults.docs.isNotEmpty) {
        return adminResults;
      }
      
      throw Exception('User not found with email: $email');
    } catch (e) {
      throw Exception('Failed to get user by email: ${e.toString()}');
    }
  }

  // Update user document
  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // Find which collection the user is in
      final userDoc = await getUserById(userId);
      final userType = userDoc.get('userType');
      final userCollection = _getUserCollection(userType);
      
      await userCollection.doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Delete user document
  Future<void> deleteUser(String userId) async {
    try {
      // Find which collection the user is in
      final userDoc = await getUserById(userId);
      final userType = userDoc.get('userType');
      final userCollection = _getUserCollection(userType);
      
      await userCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Get all users (admin function)
  Future<QuerySnapshot> getAllUsers() async {
    try {
      // Return users from parent collection as primary (can be expanded as needed)
      return await _parents.get();
    } catch (e) {
      throw Exception('Failed to get all users: ${e.toString()}');
    }
  }

  // Get users by type
  Future<QuerySnapshot> getUsersByType(String userType) async {
    try {
      final userCollection = _getUserCollection(userType);
      return await userCollection.get();
    } catch (e) {
      throw Exception('Failed to get users by type: ${e.toString()}');
    }
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final userDoc = await getUserById(userId);
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Create student-specific data
  Future<void> createStudentData({
    required String userId,
    required String fullName,
    required String schoolName,
    required String contactMethod,
    required String contactValue,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - createStudentData called');
      debugPrint('🔍 DEBUG: User ID: $userId');
      debugPrint('🔍 DEBUG: Data to save - fullName: $fullName, schoolName: $schoolName, contactMethod: $contactMethod, contactValue: $contactValue');
      
      // Use hierarchical structure: users/students/users/{userId}
      final studentCollection = _students;
      
      // Check if document already exists
      final existingDoc = await studentCollection.doc(userId).get();
      
      if (existingDoc.exists) {
        debugPrint('🔍 DEBUG: Student document already exists, updating...');
        await studentCollection.doc(userId).update({
          'fullName': fullName,
          'schoolName': schoolName,
          'contactMethod': contactMethod,
          'contactValue': contactValue,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('🔍 DEBUG: Creating new student document...');
        await studentCollection.doc(userId).set({
          'email': '', // Will be set by auth service
          'userType': 'student',
          'fullName': fullName,
          'schoolName': schoolName,
          'contactMethod': contactMethod,
          'contactValue': contactValue,
          'profileCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('✅ DEBUG: Firestore student data save completed');
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in createStudentData: ${e.toString()}');
      debugPrint('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to create student data: ${e.toString()}');
    }
  }

  // Create parent-specific data
  Future<void> createParentData({
    required String userId,
    required String fullName,
    required String contactMethod,
    required String contactValue,
    required String studentName,
    String? studentContact,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - createParentData called');
      debugPrint('🔍 DEBUG: User ID: $userId');
      
      // Use hierarchical structure: users/parents/users/{userId}
      final parentCollection = _parents;
      
      // Check if document already exists
      final existingDoc = await parentCollection.doc(userId).get();
      
      if (existingDoc.exists) {
        debugPrint('🔍 DEBUG: Parent document already exists, updating...');
        await parentCollection.doc(userId).update({
          'fullName': fullName,
          'contactMethod': contactMethod,
          'contactValue': contactValue,
          'studentName': studentName,
          'studentContact': studentContact,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('🔍 DEBUG: Creating new parent document...');
        await parentCollection.doc(userId).set({
          'email': '', // Will be set by auth service
          'userType': 'parent',
          'fullName': fullName,
          'contactMethod': contactMethod,
          'contactValue': contactValue,
          'studentName': studentName,
          'studentContact': studentContact,
          'profileCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('✅ DEBUG: Firestore parent data save completed');
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in createParentData: ${e.toString()}');
      debugPrint('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to create parent data: ${e.toString()}');
    }
  }

  // Create teacher-specific data
  Future<void> createTeacherData({
    required String userId,
    required String fullName,
    required String gender,
    required int age,
    required List<String> subjects,
    required String areaOfOperation,
    String? tscNumber,
    required String phone,
    required String availability,
    required double price,
    required String email,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - createTeacherData called');
      debugPrint('🔍 DEBUG: User ID: $userId');
      
      // Use hierarchical structure: users/teachers/users/{userId}
      final teacherCollection = _teachers;
      
      // Check if document already exists
      final existingDoc = await teacherCollection.doc(userId).get();
      
      if (existingDoc.exists) {
        debugPrint('🔍 DEBUG: Teacher document already exists, updating...');
        await teacherCollection.doc(userId).update({
          'fullName': fullName,
          'gender': gender,
          'age': age,
          'subjects': subjects,
          'areaOfOperation': areaOfOperation,
          'tscNumber': tscNumber,
          'phone': phone,
          'availability': availability,
          'price': price,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('🔍 DEBUG: Creating new teacher document...');
        await teacherCollection.doc(userId).set({
          'email': email,
          'userType': 'teacher',
          'fullName': fullName,
          'gender': gender,
          'age': age,
          'subjects': subjects,
          'areaOfOperation': areaOfOperation,
          'tscNumber': tscNumber,
          'phone': phone,
          'availability': availability,
          'price': price,
          'profileCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('✅ DEBUG: Firestore teacher data save completed');
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in createTeacherData: ${e.toString()}');
      debugPrint('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to create teacher data: ${e.toString()}');
    }
  }

  // Create admin-specific data
  Future<void> createAdminData({
    required String userId,
    required String fullName,
    required String email,
    List<String> permissions = const ['quiz_management', 'lesson_management'],
  }) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - createAdminData called');
      debugPrint('🔍 DEBUG: User ID: $userId');
      
      // Use existing users/admins structure
      final adminCollection = _admins;
      
      await adminCollection.doc(userId).set({
        'email': email,
        'userType': 'admin',
        'fullName': fullName,
        'permissions': permissions,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ DEBUG: Firestore admin data save completed');
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in createAdminData: ${e.toString()}');
      debugPrint('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to create admin data: ${e.toString()}');
    }
  }

  // Get admin user data from users/admins collection
  Future<DocumentSnapshot> getAdminData(String userId) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - getAdminData called');
      debugPrint('🔍 DEBUG: User ID: $userId');
      
      final adminDoc = await _admins.doc(userId).get();
      
      debugPrint('✅ DEBUG: Firestore admin data retrieved successfully');
      return adminDoc;
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in getAdminData: ${e.toString()}');
      debugPrint('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to get admin data: ${e.toString()}');
    }
  }

  // Update admin user permissions
  Future<void> updateAdminPermissions({
    required String userId,
    required List<String> permissions,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - updateAdminPermissions called');
      
      await _admins.doc(userId).update({
        'permissions': permissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ DEBUG: Firestore admin permissions updated successfully');
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in updateAdminPermissions: ${e.toString()}');
      debugPrint('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to update admin permissions: ${e.toString()}');
    }
  }

  // Check if user is admin by email
  Future<bool> isAdminUser(String email) async {
    try {
      debugPrint('🔍 DEBUG: Firestore - isAdminUser called');
      debugPrint('🔍 DEBUG: Email: $email');
      
      final adminDoc = await _admins
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      final isAdmin = adminDoc.docs.isNotEmpty;
      debugPrint('🔍 DEBUG: Admin status check result: $isAdmin');
      
      return isAdmin;
    } catch (e) {
      debugPrint('❌ DEBUG: Firestore error in isAdminUser: ${e.toString()}');
      return false;
    }
  }

  // Get user profile completion status
  Future<bool> isProfileCompleted(String userId) async {
    try {
      DocumentSnapshot doc = await getUserById(userId);
      return doc.get('profileCompleted') ?? false;
    } catch (e) {
      throw Exception('Failed to check profile completion: ${e.toString()}');
    }
  }

  // Lesson management methods
  /// Get lessons metadata for a specific grade
  Future<QuerySnapshot> getLessonsForGrade(String grade) async {
    try {
      return await _lessonsMeta
          .doc('grades')
          .collection(grade)
          .get();
    } catch (e) {
      throw Exception('Failed to get lessons for grade $grade: ${e.toString()}');
    }
  }

  /// Get lesson metadata by grade and lesson ID
  Future<DocumentSnapshot> getLessonById(String grade, String lessonId) async {
    try {
      return await _lessonsMeta
          .doc('grades')
          .collection(grade)
          .doc(lessonId)
          .get();
    } catch (e) {
      throw Exception('Failed to get lesson $lessonId for grade $grade: ${e.toString()}');
    }
  }

  /// Get all lessons metadata (admin function)
  Future<DocumentSnapshot> getAllLessonsMeta() async {
    try {
      return await _lessonsMetaDoc.get();
    } catch (e) {
      throw Exception('Failed to get all lessons metadata: ${e.toString()}');
    }
  }

  /// Update lesson metadata
  Future<void> updateLessonMetadata({
    required String grade,
    required String lessonId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _lessonsMeta
          .doc('grades')
          .collection(grade)
          .doc(lessonId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update lesson metadata: ${e.toString()}');
    }
  }

  /// Create lesson metadata
  Future<void> createLessonMetadata({
    required String grade,
    required String lessonId,
    required Map<String, dynamic> lessonData,
  }) async {
    try {
      await _lessonsMeta
          .doc('grades')
          .collection(grade)
          .doc(lessonId)
          .set({
        ...lessonData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create lesson metadata: ${e.toString()}');
    }
  }

  // Parent-child linking methods
  /// Create a parent-child link
  Future<void> createParentLink({
    required String linkId,
    required String parentId,
    required String childId,
    required String status,
    String? createdByIp,
  }) async {
    try {
      await _parentLinks.doc(linkId).set({
        'linkId': linkId,
        'parentId': parentId,
        'childId': childId,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByIp': createdByIp,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create parent link: ${e.toString()}');
    }
  }

  /// Get parent links for a specific parent
  Future<QuerySnapshot> getParentLinks({required String parentId}) async {
    try {
      return await _parentLinks
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: 'linked_by_parent')
          .get();
    } catch (e) {
      throw Exception('Failed to get parent links: ${e.toString()}');
    }
  }

  /// Get a specific parent link by ID
  Future<DocumentSnapshot> getParentLinkById(String linkId) async {
    try {
      return await _parentLinks.doc(linkId).get();
    } catch (e) {
      throw Exception('Failed to get parent link: ${e.toString()}');
    }
  }

  /// Update parent link status
  Future<void> updateParentLinkStatus({
    required String linkId,
    required String status,
  }) async {
    try {
      await _parentLinks.doc(linkId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update parent link status: ${e.toString()}');
    }
  }

  /// Log parent action for audit trail
  Future<void> logParentAction({
    required String parentId,
    required String action,
    required String targetUserId,
    required String targetUserName,
    required Map<String, dynamic> details,
    String? ipAddress,
  }) async {
    try {
      await _audit.doc('parentActions').collection('actions').add({
        'parentId': parentId,
        'action': action,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'details': details,
        'ipAddress': ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to log parent action: ${e.toString()}');
    }
  }

  /// Get child comment activity (pre-computed)
  Future<DocumentSnapshot?> getChildCommentActivity({required String childId}) async {
    try {
      return await _firestore
          .collection('childCommentActivity')
          .doc(childId)
          .get();
    } catch (e) {
      // Return null if document doesn't exist or there's an error
      return null;
    }
  }

  /// Get users by IDs
  Future<List<DocumentSnapshot>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];
      
      // Get users from all collections
      final futures = userIds.map((id) => getUserById(id)).toList();
      return await Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to get users by IDs: ${e.toString()}');
    }
  }

  /// Lesson-quiz progress management methods
  /// Get lesson progress document for a student
  Future<DocumentSnapshot> getLessonProgress(String studentId) async {
    try {
      return await _firestore
          .collection('lesson_progress')
          .doc(studentId)
          .get();
    } catch (e) {
      throw Exception('Failed to get lesson progress: ${e.toString()}');
    }
  }

  /// Create or update lesson progress document
  Future<void> createOrUpdateLessonProgress({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
    required Map<String, dynamic> progressData,
  }) async {
    try {
      await _firestore
          .collection('lesson_progress')
          .doc(studentId)
          .set({
        grade: {
          subject: {
            topic: FieldValue.arrayUnion([progressData]),
          },
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update lesson progress: ${e.toString()}');
    }
  }

  /// Update lesson progress with quiz completion
  Future<void> updateLessonProgressWithQuiz({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
    required String lessonId,
    required Map<String, dynamic> quizData,
  }) async {
    try {
      final progressData = {
        'lessonId': lessonId,
        'quizCompleted': true,
        'quizData': quizData,
        'completedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('lesson_progress')
          .doc(studentId)
          .update({
        grade: {
          subject: {
            topic: FieldValue.arrayUnion([progressData]),
          },
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update lesson progress with quiz: ${e.toString()}');
    }
  }

  /// Get lesson progress for a specific grade and subject
  Future<Map<String, dynamic>> getLessonProgressByGradeSubject({
    required String studentId,
    required String grade,
    required String subject,
  }) async {
    try {
      final doc = await _firestore
          .collection('lesson_progress')
          .doc(studentId)
          .get();

      if (!doc.exists) {
        return {};
      }

      final data = doc.data() as Map<String, dynamic>;
      final gradeData = data[grade] as Map<String, dynamic>?;
      
      return gradeData?[subject] ?? {};
    } catch (e) {
      throw Exception('Failed to get lesson progress by grade/subject: ${e.toString()}');
    }
  }

  /// Check if student has completed any lesson or quiz for a topic
  Future<bool> hasCompletedLessonOrQuiz({
    required String studentId,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      final doc = await _firestore
          .collection('lesson_progress')
          .doc(studentId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final gradeData = data[grade] as Map<String, dynamic>?;
      
      if (gradeData == null) {
        return false;
      }

      final subjectData = gradeData[subject] as Map<String, dynamic>?;
      
      if (subjectData == null) {
        return false;
      }

      final topicData = subjectData[topic] as List?;
      
      if (topicData == null) {
        return false;
      }

      // Check if any entry indicates completion
      return topicData.any((entry) {
        if (entry is Map) {
          return entry['lessonCompleted'] == true ||
                 (entry['quizCompleted'] as bool?) == true;
        }
        return false;
      });
    } catch (e) {
      debugPrint('❌ Error checking lesson/quiz completion: $e');
      return false;
    }
  }
}