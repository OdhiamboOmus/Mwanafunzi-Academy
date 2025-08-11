import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore database service following Flutter Lite rules
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to users collection
  CollectionReference get _users => _firestore.collection('users');

  // Create or update user document
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _users.doc(userId).set({
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
      return await _users.doc(userId).get();
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Get user document by email
  Future<QuerySnapshot> getUserByEmail(String email) async {
    try {
      return await _users.where('email', isEqualTo: email).get();
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
      await _users.doc(userId).update({
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
      await _users.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Get all users (admin function)
  Future<QuerySnapshot> getAllUsers() async {
    try {
      return await _users.get();
    } catch (e) {
      throw Exception('Failed to get all users: ${e.toString()}');
    }
  }

  // Get users by type
  Future<QuerySnapshot> getUsersByType(String userType) async {
    try {
      return await _users.where('userType', isEqualTo: userType).get();
    } catch (e) {
      throw Exception('Failed to get users by type: ${e.toString()}');
    }
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      DocumentSnapshot doc = await _users.doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user existence: ${e.toString()}');
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
      await _users.doc(userId).update({
        'fullName': fullName,
        'schoolName': schoolName,
        'contactMethod': contactMethod,
        'contactValue': contactValue,
        'profileCompleted': true,
      });
    } catch (e) {
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
      await _users.doc(userId).update({
        'fullName': fullName,
        'contactMethod': contactMethod,
        'contactValue': contactValue,
        'studentName': studentName,
        'studentContact': studentContact,
        'profileCompleted': true,
      });
    } catch (e) {
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
      await _users.doc(userId).update({
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
      });
    } catch (e) {
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
      await _users.doc(userId).update({
        'fullName': fullName,
        'isAdmin': true,
        'profileCompleted': true,
      });
    } catch (e) {
      throw Exception('Failed to create admin data: ${e.toString()}');
    }
  }

  // Get user profile completion status
  Future<bool> isProfileCompleted(String userId) async {
    try {
      DocumentSnapshot doc = await _users.doc(userId).get();
      return doc.get('profileCompleted') ?? false;
    } catch (e) {
      throw Exception('Failed to check profile completion: ${e.toString()}');
    }
  }
}