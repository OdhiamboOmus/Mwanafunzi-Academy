import 'package:equatable/equatable.dart';

// Admin data model following Flutter Lite rules
class AdminModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final String userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.isAdmin = true,
    required this.userType,
    this.createdAt,
    this.updatedAt,
  });

  // Create from map (Firestore document)
  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      isAdmin: map['isAdmin'] ?? true,
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
      'isAdmin': isAdmin,
      'userType': userType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for immutability
  AdminModel copyWith({
    String? id,
    String? email,
    String? fullName,
    bool? isAdmin,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isAdmin: isAdmin ?? this.isAdmin,
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
        isAdmin,
        userType,
        createdAt,
        updatedAt,
      ];
}