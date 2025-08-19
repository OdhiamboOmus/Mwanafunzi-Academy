import 'dart:developer' as developer;

// Teacher data model following Flutter Lite rules
class TeacherModel {
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
  
  // New verification fields
  final String? profileImageUrl;
  final String? tscCertificateUrl;
  final String verificationStatus; // "pending" | "verified" | "rejected"
  final String? rejectionReason;
  
  // Teaching preferences
  final bool offersOnlineClasses;
  final bool offersHomeTutoring;
  final List<String> availableTimes; // ["Morning", "Afternoon", "Evening", "Weekend"]
  
  // Discovery algorithm fields
  final bool isAvailable; // Currently accepting bookings
  final DateTime? lastBookingDate;
  final int completedLessons;
  final int totalBookings;
  final double responseRate; // For future algorithm improvements

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
    this.profileImageUrl,
    this.tscCertificateUrl,
    this.verificationStatus = 'pending',
    this.rejectionReason,
    this.offersOnlineClasses = false,
    this.offersHomeTutoring = false,
    this.availableTimes = const [],
    this.isAvailable = true,
    this.lastBookingDate,
    this.completedLessons = 0,
    this.totalBookings = 0,
    this.responseRate = 0.0,
  });

  // Create from map (Firestore document)
  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    developer.log('TeacherModel: Creating from map for teacher ${map['id']}');
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
      profileImageUrl: map['profileImageUrl'],
      tscCertificateUrl: map['tscCertificateUrl'],
      verificationStatus: map['verificationStatus'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      offersOnlineClasses: map['offersOnlineClasses'] ?? false,
      offersHomeTutoring: map['offersHomeTutoring'] ?? false,
      availableTimes: List<String>.from(map['availableTimes'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      lastBookingDate: map['lastBookingDate']?.toDate(),
      completedLessons: map['completedLessons'] ?? 0,
      totalBookings: map['totalBookings'] ?? 0,
      responseRate: (map['responseRate'] ?? 0).toDouble(),
    );
  }

  // Convert to map (Firestore document)
  Map<String, dynamic> toMap() {
    developer.log('TeacherModel: Converting to map for teacher $id');
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
      'profileImageUrl': profileImageUrl,
      'tscCertificateUrl': tscCertificateUrl,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
      'offersOnlineClasses': offersOnlineClasses,
      'offersHomeTutoring': offersHomeTutoring,
      'availableTimes': availableTimes,
      'isAvailable': isAvailable,
      'lastBookingDate': lastBookingDate,
      'completedLessons': completedLessons,
      'totalBookings': totalBookings,
      'responseRate': responseRate,
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
    String? profileImageUrl,
    String? tscCertificateUrl,
    String? verificationStatus,
    String? rejectionReason,
    bool? offersOnlineClasses,
    bool? offersHomeTutoring,
    List<String>? availableTimes,
    bool? isAvailable,
    DateTime? lastBookingDate,
    int? completedLessons,
    int? totalBookings,
    double? responseRate,
  }) {
    developer.log('TeacherModel: Copying with changes for teacher $id');
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      tscCertificateUrl: tscCertificateUrl ?? this.tscCertificateUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      offersOnlineClasses: offersOnlineClasses ?? this.offersOnlineClasses,
      offersHomeTutoring: offersHomeTutoring ?? this.offersHomeTutoring,
      availableTimes: availableTimes ?? this.availableTimes,
      isAvailable: isAvailable ?? this.isAvailable,
      lastBookingDate: lastBookingDate ?? this.lastBookingDate,
      completedLessons: completedLessons ?? this.completedLessons,
      totalBookings: totalBookings ?? this.totalBookings,
      responseRate: responseRate ?? this.responseRate,
    );
  }

  // Check if teacher is verified
  bool get isVerified => verificationStatus == 'verified';
  
  // Check if teacher is pending verification
  bool get isPending => verificationStatus == 'pending';
  
  // Check if teacher is rejected
  bool get isRejected => verificationStatus == 'rejected';
  
  // Get verification status display text
  String get verificationStatusText {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}