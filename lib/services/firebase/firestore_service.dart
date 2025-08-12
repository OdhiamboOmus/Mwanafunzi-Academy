import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Get appropriate collection based on user type
  CollectionReference _getUserCollection(String userType) {
    switch (userType) {
      case AppConstants.userTypeParent:
        return _parents;
      case AppConstants.userTypeStudent:
        return _students;
      case AppConstants.userTypeTeacher:
        return _teachers;
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
      print('🔍 DEBUG: Firestore - createStudentData called');
      print('🔍 DEBUG: User ID: $userId');
      print('🔍 DEBUG: Data to save - fullName: $fullName, schoolName: $schoolName, contactMethod: $contactMethod, contactValue: $contactValue');
      
      // Use hierarchical structure: users/students/users/{userId}
      final studentCollection = _students;
      
      // Check if document already exists
      final existingDoc = await studentCollection.doc(userId).get();
      
      if (existingDoc.exists) {
        print('🔍 DEBUG: Student document already exists, updating...');
        await studentCollection.doc(userId).update({
          'fullName': fullName,
          'schoolName': schoolName,
          'contactMethod': contactMethod,
          'contactValue': contactValue,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        print('🔍 DEBUG: Creating new student document...');
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
      
      print('✅ DEBUG: Firestore student data save completed');
    } catch (e) {
      print('❌ DEBUG: Firestore error in createStudentData: ${e.toString()}');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
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
      print('🔍 DEBUG: Firestore - createParentData called');
      print('🔍 DEBUG: User ID: $userId');
      
      // Use hierarchical structure: users/parents/users/{userId}
      final parentCollection = _parents;
      
      // Check if document already exists
      final existingDoc = await parentCollection.doc(userId).get();
      
      if (existingDoc.exists) {
        print('🔍 DEBUG: Parent document already exists, updating...');
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
        print('🔍 DEBUG: Creating new parent document...');
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
      
      print('✅ DEBUG: Firestore parent data save completed');
    } catch (e) {
      print('❌ DEBUG: Firestore error in createParentData: ${e.toString()}');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
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
      print('🔍 DEBUG: Firestore - createTeacherData called');
      print('🔍 DEBUG: User ID: $userId');
      
      // Use hierarchical structure: users/teachers/users/{userId}
      final teacherCollection = _teachers;
      
      // Check if document already exists
      final existingDoc = await teacherCollection.doc(userId).get();
      
      if (existingDoc.exists) {
        print('🔍 DEBUG: Teacher document already exists, updating...');
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
        print('🔍 DEBUG: Creating new teacher document...');
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
      
      print('✅ DEBUG: Firestore teacher data save completed');
    } catch (e) {
      print('❌ DEBUG: Firestore error in createTeacherData: ${e.toString()}');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to create teacher data: ${e.toString()}');
    }
  }

  // Create admin-specific data
  Future<void> createAdminData({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    try {
      print('🔍 DEBUG: Firestore - createAdminData called');
      print('🔍 DEBUG: User ID: $userId');
      
      // Use hierarchical structure: users/admins/users/{userId}
      final adminCollection = _users.doc('admins').collection('users');
      
      await adminCollection.doc(userId).set({
        'email': email,
        'userType': 'admin',
        'fullName': fullName,
        'isAdmin': true,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ DEBUG: Firestore admin data save completed');
    } catch (e) {
      print('❌ DEBUG: Firestore error in createAdminData: ${e.toString()}');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to create admin data: ${e.toString()}');
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
}