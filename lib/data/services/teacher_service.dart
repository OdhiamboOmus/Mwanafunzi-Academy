import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';

// Teacher service with necessary operations and debugPrint logging
class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get teacher by ID
  Future<TeacherModel?> getTeacherById(String teacherId) async {
    developer.log('TeacherService: Getting teacher by ID: $teacherId');
    try {
      final doc = await _firestore.collection('teachers').doc(teacherId).get();
      if (doc.exists) {
        final teacher = TeacherModel.fromMap(doc.data()!);
        developer.log('TeacherService: Successfully retrieved teacher ${teacher.fullName}');
        return teacher;
      } else {
        developer.log('TeacherService: Teacher not found with ID: $teacherId');
        return null;
      }
    } catch (e) {
      developer.log('TeacherService: Error getting teacher by ID: $teacherId, Error: $e');
      return null;
    }
  }

  // Update teacher profile
  Future<bool> updateTeacherProfile(TeacherModel teacher) async {
    developer.log('TeacherService: Starting profile update for teacher ${teacher.id}');
    try {
      final teacherMap = teacher.toMap();
      teacherMap['updatedAt'] = DateTime.now();
      
      await _firestore.collection('teachers').doc(teacher.id).update(teacherMap);
      developer.log('TeacherService: Successfully updated profile for teacher ${teacher.fullName}');
      return true;
    } catch (e) {
      developer.log('TeacherService: Error updating profile for teacher ${teacher.id}, Error: $e');
      return false;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile, String teacherId) async {
    developer.log('TeacherService: Starting image upload for teacher $teacherId');
    try {
      final ref = _storage.ref().child('teachers/$teacherId/profile.jpg');
      final uploadTask = ref.putFile(imageFile);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.totalBytes != null 
            ? (snapshot.bytesTransferred / snapshot.totalBytes! * 100).toStringAsFixed(0)
            : '0';
        developer.log('TeacherService: Upload progress: $progress%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      developer.log('TeacherService: Successfully uploaded image for teacher $teacherId');
      return downloadUrl;
    } catch (e) {
      developer.log('TeacherService: Error uploading image for teacher $teacherId, Error: $e');
      return null;
    }
  }

  // Upload TSC certificate to Firebase Storage
  Future<String?> uploadTscCertificate(File certificateFile, String teacherId) async {
    developer.log('TeacherService: Starting TSC certificate upload for teacher $teacherId');
    try {
      final ref = _storage.ref().child('teachers/$teacherId/tsc_certificate.pdf');
      final uploadTask = ref.putFile(certificateFile);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.totalBytes != null 
            ? (snapshot.bytesTransferred / snapshot.totalBytes! * 100).toStringAsFixed(0)
            : '0';
        developer.log('TeacherService: Certificate upload progress: $progress%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      developer.log('TeacherService: Successfully uploaded TSC certificate for teacher $teacherId');
      return downloadUrl;
    } catch (e) {
      developer.log('TeacherService: Error uploading TSC certificate for teacher $teacherId, Error: $e');
      return null;
    }
  }

  // Update verification status
  Future<bool> updateVerificationStatus(String teacherId, String status, {String? rejectionReason}) async {
    developer.log('TeacherService: Updating verification status for teacher $teacherId to $status');
    try {
      final updateData = {
        'verificationStatus': status,
        'updatedAt': DateTime.now(),
      };
      
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      
      await _firestore.collection('teachers').doc(teacherId).update(updateData);
      developer.log('TeacherService: Successfully updated verification status for teacher $teacherId');
      return true;
    } catch (e) {
      developer.log('TeacherService: Error updating verification status for teacher $teacherId, Error: $e');
      return false;
    }
  }

  // Update teaching preferences
  Future<bool> updateTeachingPreferences(String teacherId, bool offersOnlineClasses, bool offersHomeTutoring, List<String> availableTimes) async {
    developer.log('TeacherService: Updating teaching preferences for teacher $teacherId');
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'offersOnlineClasses': offersOnlineClasses,
        'offersHomeTutoring': offersHomeTutoring,
        'availableTimes': availableTimes,
        'updatedAt': DateTime.now(),
      });
      developer.log('TeacherService: Successfully updated teaching preferences for teacher $teacherId');
      return true;
    } catch (e) {
      developer.log('TeacherService: Error updating teaching preferences for teacher $teacherId, Error: $e');
      return false;
    }
  }

  // Update availability status
  Future<bool> updateAvailabilityStatus(String teacherId, bool isAvailable) async {
    developer.log('TeacherService: Updating availability status for teacher $teacherId to $isAvailable');
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'isAvailable': isAvailable,
        'updatedAt': DateTime.now(),
      });
      developer.log('TeacherService: Successfully updated availability status for teacher $teacherId');
      return true;
    } catch (e) {
      developer.log('TeacherService: Error updating availability status for teacher $teacherId, Error: $e');
      return false;
    }
  }

  // Get teachers by verification status
  Future<List<TeacherModel>> getTeachersByVerificationStatus(String status) async {
    developer.log('TeacherService: Getting teachers with verification status: $status');
    try {
      final snapshot = await _firestore
          .collection('teachers')
          .where('verificationStatus', isEqualTo: status)
          .get();
      
      final teachers = snapshot.docs.map((doc) => TeacherModel.fromMap(doc.data())).toList();
      developer.log('TeacherService: Retrieved ${teachers.length} teachers with status: $status');
      return teachers;
    } catch (e) {
      developer.log('TeacherService: Error getting teachers with status: $status, Error: $e');
      return [];
    }
  }

  // Get available teachers
  Future<List<TeacherModel>> getAvailableTeachers() async {
    developer.log('TeacherService: Getting available teachers');
    try {
      final snapshot = await _firestore
          .collection('teachers')
          .where('isAvailable', isEqualTo: true)
          .where('verificationStatus', isEqualTo: 'verified')
          .get();
      
      final teachers = snapshot.docs.map((doc) => TeacherModel.fromMap(doc.data())).toList();
      developer.log('TeacherService: Retrieved ${teachers.length} available teachers');
      return teachers;
    } catch (e) {
      developer.log('TeacherService: Error getting available teachers, Error: $e');
      return [];
    }
  }

  // Update teacher statistics
  Future<bool> updateTeacherStatistics(String teacherId, int completedLessons, int totalBookings, double responseRate) async {
    developer.log('TeacherService: Updating statistics for teacher $teacherId');
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'completedLessons': completedLessons,
        'totalBookings': totalBookings,
        'responseRate': responseRate,
        'updatedAt': DateTime.now(),
      });
      developer.log('TeacherService: Successfully updated statistics for teacher $teacherId');
      return true;
    } catch (e) {
      developer.log('TeacherService: Error updating statistics for teacher $teacherId, Error: $e');
      return false;
    }
  }

  // Update last booking date
  Future<bool> updateLastBookingDate(String teacherId) async {
    developer.log('TeacherService: Updating last booking date for teacher $teacherId');
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'lastBookingDate': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      developer.log('TeacherService: Successfully updated last booking date for teacher $teacherId');
      return true;
    } catch (e) {
      developer.log('TeacherService: Error updating last booking date for teacher $teacherId, Error: $e');
      return false;
    }
  }
}