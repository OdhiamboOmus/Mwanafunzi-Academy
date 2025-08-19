import 'dart:developer' as developer;

// Lesson model for individual lesson tracking
class LessonModel {
  final String id;
  final String bookingId;
  final String teacherId;
  final String studentId;
  
  // Lesson details
  final int weekNumber; // 1, 2, 3, etc.
  final DateTime scheduledDate;
  final int duration; // 120 minutes
  final String zoomLink;
  
  // Status
  final String status; // "scheduled" | "completed" | "missed" | "cancelled"
  final DateTime? completedAt;
  final String? teacherNotes;
  
  // Timestamps
  final DateTime createdAt;

  const LessonModel({
    required this.id,
    required this.bookingId,
    required this.teacherId,
    required this.studentId,
    required this.weekNumber,
    required this.scheduledDate,
    required this.duration,
    required this.zoomLink,
    required this.status,
    this.completedAt,
    this.teacherNotes,
    required this.createdAt,
  });

  // Create from map (Firestore document)
  factory LessonModel.fromMap(Map<String, dynamic> map) {
    developer.log('LessonModel: Creating from map for lesson ${map['id']}');
    return LessonModel(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      studentId: map['studentId'] ?? '',
      weekNumber: map['weekNumber'] ?? 0,
      scheduledDate: map['scheduledDate']?.toDate() ?? DateTime.now(),
      duration: map['duration'] ?? 0,
      zoomLink: map['zoomLink'] ?? '',
      status: map['status'] ?? 'scheduled',
      completedAt: map['completedAt']?.toDate(),
      teacherNotes: map['teacherNotes'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to map (Firestore document)
  Map<String, dynamic> toMap() {
    developer.log('LessonModel: Converting to map for lesson $id');
    return {
      'id': id,
      'bookingId': bookingId,
      'teacherId': teacherId,
      'studentId': studentId,
      'weekNumber': weekNumber,
      'scheduledDate': scheduledDate,
      'duration': duration,
      'zoomLink': zoomLink,
      'status': status,
      'completedAt': completedAt,
      'teacherNotes': teacherNotes,
      'createdAt': createdAt,
    };
  }

  // Copy with method for immutability
  LessonModel copyWith({
    String? id,
    String? bookingId,
    String? teacherId,
    String? studentId,
    int? weekNumber,
    DateTime? scheduledDate,
    int? duration,
    String? zoomLink,
    String? status,
    DateTime? completedAt,
    String? teacherNotes,
    DateTime? createdAt,
  }) {
    developer.log('LessonModel: Copying with changes for lesson $id');
    return LessonModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      weekNumber: weekNumber ?? this.weekNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      duration: duration ?? this.duration,
      zoomLink: zoomLink ?? this.zoomLink,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if lesson is completed
  bool get isCompleted => status == 'completed';
  
  // Check if lesson is scheduled
  bool get isScheduled => status == 'scheduled';
  
  // Check if lesson is missed
  bool get isMissed => status == 'missed';
  
  // Check if lesson is cancelled
  bool get isCancelled => status == 'cancelled';
  
  // Get status display text
  String get statusText {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'missed':
        return 'Missed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  // Get display date
  String get displayDate {
    return '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
  }
  
  // Get display time
  String get displayTime {
    return '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
  }
  
  // Get display date and time
  String get displayDateTime {
    return '$displayDate at $displayTime';
  }
  
  // Check if lesson is in the past
  bool get isPast => scheduledDate.isBefore(DateTime.now());
  
  // Check if lesson is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
           scheduledDate.month == now.month &&
           scheduledDate.day == now.day;
  }
  
  // Check if lesson is in the future
  bool get isFuture => scheduledDate.isAfter(DateTime.now());
}