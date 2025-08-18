# Design Document

## Architecture Overview

This system follows Flutter Lite principles with Firebase-only backend, minimal dependencies, and files under 150 lines. The teacher verification and booking system is designed for easy maintenance and future enhancements.

## Database Schema (Firestore)

### Collections Structure

#### `teachers/{teacherId}`
```dart
{
  // Basic teacher info (from existing TeacherModel)
  id: string,
  email: string,
  fullName: string,
  gender: string,
  age: number,
  subjects: string[],
  areaOfOperation: string,
  phone: string,
  availability: string,
  price: number, // Weekly rate for data collection only
  userType: "teacher",
  createdAt: timestamp,
  updatedAt: timestamp,
  
  // New verification fields
  profileImageUrl: string?, // Firebase Storage URL
  tscCertificateUrl: string?, // Firebase Storage URL
  verificationStatus: "pending" | "verified" | "rejected",
  rejectionReason: string?,
  
  // Teaching preferences
  offersOnlineClasses: boolean,
  offersHomeTutoring: boolean,
  availableTimes: string[], // ["Morning", "Afternoon", "Evening", "Weekend"]
  
  // Discovery algorithm fields
  isAvailable: boolean, // Currently accepting bookings
  lastBookingDate: timestamp?,
  completedLessons: number,
  totalBookings: number,
  responseRate: number, // For future algorithm improvements
}
```

#### `bookings/{bookingId}`
```dart
{
  id: string,
  teacherId: string,
  parentId: string,
  studentId: string,
  
  // Booking details
  subject: string,
  numberOfWeeks: number,
  weeklyRate: number,
  totalAmount: number,
  platformFee: number, // 20% of total
  teacherPayout: number, // totalAmount - platformFee
  
  // Schedule
  weeklySchedule: {
    dayOfWeek: string, // "Monday", "Tuesday", etc.
    startTime: string, // "14:00"
    duration: number, // 120 minutes
  },
  startDate: timestamp,
  endDate: timestamp,
  
  // Status tracking
  status: "draft" | "payment_pending" | "paid" | "active" | "completed" | "cancelled",
  paymentId: string?,
  zoomLink: string?,
  
  // Timestamps
  createdAt: timestamp,
  paidAt: timestamp?,
  completedAt: timestamp?,
}
```

#### `lessons/{lessonId}`
```dart
{
  id: string,
  bookingId: string,
  teacherId: string,
  studentId: string,
  
  // Lesson details
  weekNumber: number, // 1, 2, 3, etc.
  scheduledDate: timestamp,
  duration: number, // 120 minutes
  zoomLink: string,
  
  // Status
  status: "scheduled" | "completed" | "missed" | "cancelled",
  completedAt: timestamp?,
  teacherNotes: string?,
  
  createdAt: timestamp,
}
```

#### `transactions/{transactionId}`
```dart
{
  id: string,
  type: "payment" | "payout" | "refund",
  
  // Payment details
  bookingId: string?,
  teacherId: string?, // For payouts
  parentId: string?, // For payments
  amount: number,
  
  // M-Pesa details
  mpesaTransactionId: string,
  mpesaReceiptNumber: string,
  phoneNumber: string,
  
  // Status
  status: "pending" | "completed" | "failed",
  providerResponse: object,
  
  // Timestamps
  createdAt: timestamp,
  processedAt: timestamp?,
}
```

#### `platform_ledger/{entryId}`
```dart
{
  id: string,
  transactionId: string,
  type: "credit" | "debit",
  amount: number,
  balance: number, // Running balance
  description: string,
  createdAt: timestamp,
}
```

## File Structure (Flutter Lite Compliant)

```
lib/
├── core/
│   ├── constants.dart                    // App constants
│   └── utils.dart                       // Utility functions
├── data/
│   ├── models/
│   │   ├── teacher_model.dart           // Enhanced teacher model
│   │   ├── booking_model.dart           // Booking data model
│   │   ├── lesson_model.dart            // Individual lesson model
│   │   └── transaction_model.dart       // Payment transaction model
│   └── services/
│       ├── teacher_service.dart         // Teacher CRUD operations
│       ├── booking_service.dart         // Booking management
│       ├── payment_service.dart         // M-Pesa integration
│       ├── discovery_service.dart       // Teacher discovery algorithm
│       └── notification_service.dart    // In-app & email notifications
├── presentation/
│   ├── teacher/
│   │   ├── teacher_profile_setup_screen.dart      // Profile completion
│   │   ├── teacher_verification_screen.dart       // TSC upload
│   │   ├── teacher_availability_screen.dart       // Set availability
│   │   ├── teacher_bookings_screen.dart           // View bookings
│   │   └── widgets/
│   │       ├── profile_image_picker.dart          // Image upload widget
│   │       ├── tsc_upload_widget.dart             // Certificate upload
│   │       ├── availability_selector.dart         // Time selection
│   │       └── booking_card_widget.dart           // Booking display
│   ├── student/
│   │   ├── teacher_discovery_screen.dart          // Enhanced find teachers
│   │   ├── teacher_detail_screen.dart             // Teacher profile view
│   │   ├── booking_screen.dart                    // Weekly booking
│   │   └── widgets/
│   │       ├── teacher_card_widget.dart           // Teacher display card
│   │       ├── booking_form_widget.dart           // Booking form
│   │       └── payment_widget.dart                // M-Pesa payment
│   ├── admin/
│   │   ├── verification_dashboard_screen.dart     // Teacher verification
│   │   ├── financial_dashboard_screen.dart        // Payment management
│   │   └── widgets/
│   │       ├── verification_card_widget.dart      // Teacher review card
│   │       └── transaction_list_widget.dart       // Financial transactions
│   └── shared/
│       ├── loading_widget.dart                    // Loading states
│       ├── error_widget.dart                      // Error handling
│       └── success_widget.dart                    // Success messages
└── algorithms/
    └── teacher_discovery_algorithm.dart           // Separate algorithm file
```

## Cloud Functions Structure

### Payment Webhook Handler
```javascript
// functions/src/paymentWebhook.js
exports.handleMpesaWebhook = functions.https.onRequest(async (req, res) => {
  // Verify M-Pesa webhook signature
  // Update transaction status
  // Activate booking if payment successful
  // Send notifications
  // Update platform ledger
});
```

### Payout Processor
```javascript
// functions/src/payoutProcessor.js
exports.processPayout = functions.firestore
  .document('lessons/{lessonId}')
  .onUpdate(async (change, context) => {
    // Check if all lessons in booking are completed
    // Calculate teacher payout
    // Initiate M-Pesa B2C transfer
    // Update payout status
  });
```

## Key Components Design

### Teacher Discovery Algorithm (Separate File)

```dart
// algorithms/teacher_discovery_algorithm.dart
class TeacherDiscoveryAlgorithm {
  // Simple, modifiable algorithm for equal opportunities
  static List<TeacherModel> rankTeachers({
    required List<TeacherModel> teachers,
    required Map<String, dynamic> filters,
  }) {
    debugPrint('TeacherDiscoveryAlgorithm: Starting teacher ranking with ${teachers.length} teachers');
    debugPrint('TeacherDiscoveryAlgorithm: Applied filters: $filters');
    
    // 1. Filter by verification status (verified first)
    // 2. Filter by availability
    // 3. Filter by subject match
    // 4. Apply location proximity for home tutoring
    // 5. Rotate positions for equal exposure
    // 6. Return ranked list
    
    debugPrint('TeacherDiscoveryAlgorithm: Ranking completed, returning ${teachers.length} teachers');
    return teachers;
  }
  
  // Future enhancement hooks
  static double _calculateEngagementScore(TeacherModel teacher) {
    debugPrint('TeacherDiscoveryAlgorithm: Calculating engagement score for teacher ${teacher.id}');
    // Placeholder for future engagement metrics
    return 1.0;
  }
  
  static double _calculateProximityScore(TeacherModel teacher, String location) {
    debugPrint('TeacherDiscoveryAlgorithm: Calculating proximity score for teacher ${teacher.id} in $location');
    // Placeholder for location-based scoring
    return 1.0;
  }
}
```

### Teacher Profile Setup Screen

```dart
// presentation/teacher/teacher_profile_setup_screen.dart
class TeacherProfileSetupScreen extends StatefulWidget {
  // Profile completion with image and certificate upload
  // Toggle switches for online/home tutoring
  // Subject selection from existing filters
  // Availability time selection
  // Form validation and submission
  // Progress indicator for upload status
}
```

### Booking Flow Components

```dart
// presentation/student/booking_screen.dart
class BookingScreen extends StatefulWidget {
  // Weekly package selection (number of weeks)
  // Schedule selection (day/time)
  // Cost calculation display
  // M-Pesa STK Push integration
  // Booking confirmation
}

// presentation/student/widgets/payment_widget.dart
class PaymentWidget extends StatefulWidget {
  // M-Pesa phone number input
  // STK Push initiation
  // Payment status tracking
  // Success/failure handling
}
```

### Admin Dashboard Components

```dart
// presentation/admin/verification_dashboard_screen.dart
class VerificationDashboardScreen extends StatefulWidget {
  // List of pending teacher verifications
  // TSC certificate image viewer
  // Approve/reject buttons
  // Rejection reason input
  // Batch operations for efficiency
}

// presentation/admin/financial_dashboard_screen.dart
class FinancialDashboardScreen extends StatefulWidget {
  // Platform balance display
  // Transaction history with filters
  // Pending payouts list
  // Dispute management
  // Refund processing
}
```

## Service Layer Design

### Teacher Service
```dart
// data/services/teacher_service.dart
class TeacherService {
  // CRUD operations for teacher profiles with comprehensive logging
  Future<void> updateTeacherProfile(TeacherModel teacher) async {
    debugPrint('TeacherService: Starting profile update for teacher ${teacher.id}');
    // Implementation with debugPrint at key steps
    debugPrint('TeacherService: Profile update completed for teacher ${teacher.id}');
  }
  
  // Image upload to Firebase Storage with progress logging
  Future<String> uploadProfileImage(File imageFile, String teacherId) async {
    debugPrint('TeacherService: Starting image upload for teacher $teacherId');
    // Implementation with upload progress logging
    debugPrint('TeacherService: Image upload completed for teacher $teacherId');
  }
  
  // Verification status updates with detailed logging
  // Availability management with state change logging
  // Profile completion tracking with milestone logging
}
```

### Booking Service
```dart
// data/services/booking_service.dart
class BookingService {
  // Create weekly bookings with comprehensive logging
  Future<String> createWeeklyBooking(BookingModel booking) async {
    debugPrint('BookingService: Creating weekly booking for teacher ${booking.teacherId}');
    debugPrint('BookingService: Booking details - weeks: ${booking.numberOfWeeks}, amount: ${booking.totalAmount}');
    // Implementation with status change logging
    debugPrint('BookingService: Weekly booking created with ID: ${booking.id}');
  }
  
  // Generate individual lesson records with logging
  // Status management with state transition logging
  // Zoom link generation with confirmation logging
  // Booking cancellation with reason logging
}
```

### Payment Service
```dart
// data/services/payment_service.dart
class PaymentService {
  // M-Pesa STK Push initiation with request/response logging
  Future<Map<String, dynamic>> initiateSTKPush(double amount, String phoneNumber) async {
    debugPrint('PaymentService: Initiating STK Push for amount: $amount, phone: $phoneNumber');
    // Implementation with M-Pesa API request/response logging
    debugPrint('PaymentService: STK Push response received');
  }
  
  // Payment status checking with polling logging
  // Webhook processing with detailed payload logging
  // Payout initiation with B2C transaction logging
  // Transaction recording with immutable ledger logging
}
```

## UI/UX Design Principles

### Material Design 3 Components
- Use standard Material widgets only
- Consistent color scheme with brand colors
- Simple, clean layouts
- Proper loading states
- Error handling with user-friendly messages

### Navigation Flow
```
Teacher Flow:
Login → Profile Setup → Verification Upload → Dashboard → Bookings

Student/Parent Flow:
Find Teachers → Teacher Detail → Booking → Payment → Confirmation

Admin Flow:
Dashboard → Verification Queue → Financial Management
```

### State Management
- StatefulWidget with setState for UI updates
- Service classes for business logic
- SharedPreferences for simple caching
- No third-party state management packages

## Performance Considerations

### Firestore Optimization
- Composite indexes for teacher filtering
- Pagination for large teacher lists
- Efficient query structures
- Minimal data fetching

### Image Handling
- WebP format for all images
- Compression before upload
- Lazy loading for teacher cards
- Caching for frequently viewed images

### Memory Management
- Proper controller disposal
- ListView.builder for teacher lists
- Minimal data caching
- Regular cleanup of temporary data

## Security Considerations

### Data Validation
- Server-side validation for all inputs
- File type and size validation for uploads
- Payment amount verification
- User permission checks

### Firebase Security Rules
```javascript
// Firestore security rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Teachers can only edit their own profiles
    match /teachers/{teacherId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == teacherId;
    }
    
    // Bookings accessible to involved parties
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.teacherId || 
         request.auth.uid == resource.data.parentId ||
         request.auth.token.role == 'admin');
    }
  }
}
```

## Future Enhancement Hooks

### Algorithm Improvements
- Teacher response rate tracking
- Student satisfaction ratings
- Completion rate metrics
- Dynamic pricing suggestions

### Feature Additions
- In-app messaging system
- Calendar integration
- Automated scheduling
- Performance analytics

### Technical Enhancements
- Offline capability
- Push notifications
- Advanced search filters
- Multi-language support

## Testing Strategy

### Unit Testing
- Service layer testing
- Algorithm testing
- Model validation testing
- Utility function testing

### Integration Testing
- Payment flow testing
- Booking process testing
- Notification delivery testing
- Database operations testing

### User Acceptance Testing
- Teacher onboarding flow
- Student booking experience
- Admin verification process
- Payment and payout flows

## Deployment Considerations

### Firebase Configuration
- Production vs development environments
- Security rules deployment
- Cloud Functions deployment
- Storage bucket configuration

### App Store Optimization
- APK size monitoring
- Performance profiling
- User feedback integration
- Crash reporting setup