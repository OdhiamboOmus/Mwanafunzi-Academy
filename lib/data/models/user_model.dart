/// User model for student, parent, and teacher profiles
class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'student', 'parent', 'teacher', 'admin'
  final String? grade; // For students
  final int points;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.grade,
    this.points = 0,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Create from JSON (Firestore document)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'student',
      grade: json['grade'],
      points: json['points'] ?? 0,
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      lastLoginAt: json['lastLoginAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'grade': grade,
      'points': points,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  /// Get display name (first name only for greeting)
  String get displayName {
    final nameParts = name.split(' ');
    return nameParts.isNotEmpty ? nameParts[0] : 'Learner';
  }

  /// Get greeting fallback
  String get greetingFallback {
    return role == 'student' ? 'Welcome back, Learner!' : 'Welcome back!';
  }

  /// Create copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? grade,
    int? points,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}