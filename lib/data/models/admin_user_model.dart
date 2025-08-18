import 'package:equatable/equatable.dart';

// Admin user data model following Flutter Lite rules
class AdminUserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  // Create from map (Firestore document)
  factory AdminUserModel.fromMap(Map<String, dynamic> map) {
    return AdminUserModel(
      id: map['id'] ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'admin',
      permissions: List<String>.from(map['permissions'] ?? []),
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
      'role': role,
      'permissions': permissions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for immutability
  AdminUserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if admin has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('all');
  }

  // Check if admin has quiz management permission
  bool hasQuizManagementPermission() {
    return hasPermission('quiz_management') || hasPermission('all');
  }

  // Check if admin has lesson management permission
  bool hasLessonManagementPermission() {
    return hasPermission('lesson_management') || hasPermission('all');
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        role,
        permissions,
        createdAt,
        updatedAt,
      ];
}