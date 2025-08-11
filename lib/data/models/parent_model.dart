import 'package:equatable/equatable.dart';

// Parent data model following Flutter Lite rules
class ParentModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String contactMethod;
  final String contactValue;
  final String studentName;
  final String? studentContact;
  final String userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ParentModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.contactMethod,
    required this.contactValue,
    required this.studentName,
    this.studentContact,
    required this.userType,
    this.createdAt,
    this.updatedAt,
  });

  // Create from map (Firestore document)
  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      contactMethod: map['contactMethod'] ?? '',
      contactValue: map['contactValue'] ?? '',
      studentName: map['studentName'] ?? '',
      studentContact: map['studentContact'],
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
      'contactMethod': contactMethod,
      'contactValue': contactValue,
      'studentName': studentName,
      'studentContact': studentContact,
      'userType': userType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for immutability
  ParentModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? contactMethod,
    String? contactValue,
    String? studentName,
    String? studentContact,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      contactMethod: contactMethod ?? this.contactMethod,
      contactValue: contactValue ?? this.contactValue,
      studentName: studentName ?? this.studentName,
      studentContact: studentContact ?? this.studentContact,
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
        contactMethod,
        contactValue,
        studentName,
        studentContact,
        userType,
        createdAt,
        updatedAt,
      ];
}