import 'package:equatable/equatable.dart';

// Teacher data model following Flutter Lite rules
class TeacherModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String gender;
  final int age;
  final List<String> subjects;
  final String areaOfOperation;
  final String? tscNumber;
  final String phone;
  final String availability;
  final double price;
  final String userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeacherModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.age,
    required this.subjects,
    required this.areaOfOperation,
    this.tscNumber,
    required this.phone,
    required this.availability,
    required this.price,
    required this.userType,
    this.createdAt,
    this.updatedAt,
  });

  // Create from map (Firestore document)
  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      subjects: List<String>.from(map['subjects'] ?? []),
      areaOfOperation: map['areaOfOperation'] ?? '',
      tscNumber: map['tscNumber'],
      phone: map['phone'] ?? '',
      availability: map['availability'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
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
      'gender': gender,
      'age': age,
      'subjects': subjects,
      'areaOfOperation': areaOfOperation,
      'tscNumber': tscNumber,
      'phone': phone,
      'availability': availability,
      'price': price,
      'userType': userType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for immutability
  TeacherModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? gender,
    int? age,
    List<String>? subjects,
    String? areaOfOperation,
    String? tscNumber,
    String? phone,
    String? availability,
    double? price,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      subjects: subjects ?? this.subjects,
      areaOfOperation: areaOfOperation ?? this.areaOfOperation,
      tscNumber: tscNumber ?? this.tscNumber,
      phone: phone ?? this.phone,
      availability: availability ?? this.availability,
      price: price ?? this.price,
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
        gender,
        age,
        subjects,
        areaOfOperation,
        tscNumber,
        phone,
        availability,
        price,
        userType,
        createdAt,
        updatedAt,
      ];
}