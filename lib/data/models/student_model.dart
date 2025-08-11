import 'package:equatable/equatable.dart';

// Student data model following Flutter Lite rules
class StudentModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String schoolName;
  final String contactMethod;
  final String contactValue;
  final String userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.schoolName,
    required this.contactMethod,
    required this.contactValue,
    required this.userType,
    this.createdAt,
    this.updatedAt,
  });

  // Create from map (Firestore document)
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      schoolName: map['schoolName'] ?? '',
      contactMethod: map['contactMethod'] ?? '',
      contactValue: map['contactValue'] ?? '',
      userType: map['userType'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  // Convert to map (Firestore document)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'schoolName': schoolName,
      'contactMethod': contactMethod,
      'contactValue': contactValue,
      'userType': userType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for immutability
  StudentModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? schoolName,
    String? contactMethod,
    String? contactValue,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      schoolName: schoolName ?? this.schoolName,
      contactMethod: contactMethod ?? this.contactMethod,
      contactValue: contactValue ?? this.contactValue,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        schoolName,
        contactMethod,
        contactValue,
        userType,
        createdAt,
        updatedAt,
      ];
}