import 'dart:developer' as developer;

// Booking model for weekly booking system
class BookingModel {
  final String id;
  final String teacherId;
  final String parentId;
  final String studentId;
  
  // Booking details
  final String subject;
  final int numberOfWeeks;
  final double weeklyRate;
  final double totalAmount;
  final double platformFee; // 20% of total
  final double teacherPayout; // totalAmount - platformFee
  
  // Schedule
  final String dayOfWeek; // "Monday", "Tuesday", etc.
  final String startTime; // "14:00"
  final int duration; // 120 minutes
  final DateTime startDate;
  final DateTime endDate;
  
  // Status tracking
  final String status; // "draft" | "payment_pending" | "paid" | "active" | "completed" | "cancelled"
  final String? paymentId;
  final String? zoomLink;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;

  const BookingModel({
    required this.id,
    required this.teacherId,
    required this.parentId,
    required this.studentId,
    required this.subject,
    required this.numberOfWeeks,
    required this.weeklyRate,
    required this.totalAmount,
    required this.platformFee,
    required this.teacherPayout,
    required this.dayOfWeek,
    required this.startTime,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paymentId,
    this.zoomLink,
    required this.createdAt,
    this.paidAt,
    this.completedAt,
  });

  // Create from map (Firestore document)
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    developer.log('BookingModel: Creating from map for booking ${map['id']}');
    return BookingModel(
      id: map['id'] ?? '',
      teacherId: map['teacherId'] ?? '',
      parentId: map['parentId'] ?? '',
      studentId: map['studentId'] ?? '',
      subject: map['subject'] ?? '',
      numberOfWeeks: map['numberOfWeeks'] ?? 0,
      weeklyRate: (map['weeklyRate'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      teacherPayout: (map['teacherPayout'] ?? 0).toDouble(),
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: map['startTime'] ?? '',
      duration: map['duration'] ?? 0,
      startDate: map['startDate']?.toDate() ?? DateTime.now(),
      endDate: map['endDate']?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'draft',
      paymentId: map['paymentId'],
      zoomLink: map['zoomLink'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      paidAt: map['paidAt']?.toDate(),
      completedAt: map['completedAt']?.toDate(),
    );
  }

  // Convert to map (Firestore document)
  Map<String, dynamic> toMap() {
    developer.log('BookingModel: Converting to map for booking $id');
    return {
      'id': id,
      'teacherId': teacherId,
      'parentId': parentId,
      'studentId': studentId,
      'subject': subject,
      'numberOfWeeks': numberOfWeeks,
      'weeklyRate': weeklyRate,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'teacherPayout': teacherPayout,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'duration': duration,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'paymentId': paymentId,
      'zoomLink': zoomLink,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'completedAt': completedAt,
    };
  }

  // Copy with method for immutability
  BookingModel copyWith({
    String? id,
    String? teacherId,
    String? parentId,
    String? studentId,
    String? subject,
    int? numberOfWeeks,
    double? weeklyRate,
    double? totalAmount,
    double? platformFee,
    double? teacherPayout,
    String? dayOfWeek,
    String? startTime,
    int? duration,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? paymentId,
    String? zoomLink,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? completedAt,
  }) {
    developer.log('BookingModel: Copying with changes for booking $id');
    return BookingModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      subject: subject ?? this.subject,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      weeklyRate: weeklyRate ?? this.weeklyRate,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      teacherPayout: teacherPayout ?? this.teacherPayout,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      zoomLink: zoomLink ?? this.zoomLink,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Check if booking is paid
  bool get isPaid => status == 'paid';
  
  // Check if booking is active
  bool get isActive => status == 'active';
  
  // Check if booking is completed
  bool get isCompleted => status == 'completed';
  
  // Check if booking is cancelled
  bool get isCancelled => status == 'cancelled';
  
  // Get status display text
  String get statusText {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'payment_pending':
        return 'Payment Pending';
      default:
        return 'Draft';
    }
  }

  // Calculate total lessons (number of weeks)
  int get totalLessons => numberOfWeeks;
  
  // Get display date range
  String get dateRangeDisplay {
    final startDateFormat = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endDateFormat = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startDateFormat - $endDateFormat';
  }
}