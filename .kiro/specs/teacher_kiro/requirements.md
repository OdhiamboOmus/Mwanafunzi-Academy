# Requirements Document

## Introduction

This feature implements a comprehensive teacher verification and discovery system that allows teachers to upload their TSC certificates for verification, enables students and parents to find and book verified teachers, and provides administrators with tools to manage teacher verification. The system includes teacher profile management, verification workflows, teacher discovery algorithms, and booking functionality.

## Requirements

### Requirement 1: Teacher Profile Setup and Verification

**User Story:** As a teacher, I want to complete my profile setup and upload my TSC certificate, so that I can be verified and visible to students and parents.

#### Acceptance Criteria

1. WHEN a teacher logs in for the first time THEN the system SHALL redirect them to a profile completion screen
2. WHEN a teacher accesses their profile setup THEN the system SHALL display fields for uploading profile image and TSC certificate
3. WHEN a teacher uploads a TSC certificate THEN the system SHALL accept PDF, JPG, and PNG formats up to 10MB
4. WHEN a teacher completes profile setup THEN the system SHALL display two toggle switches for "Online Classes" and "Home Tutoring"
5. WHEN a teacher selects their teaching preferences THEN the system SHALL allow them to choose subjects from the existing filter categories (Mathematics, English, All Subjects)
6. WHEN a teacher submits their profile THEN the system SHALL set their status to "pendingVerification" in Firestore
7. WHEN a teacher's profile is created THEN the system SHALL generate a teacher card marked as "unverified"

### Requirement 2: Admin Verification Dashboard

**User Story:** As an admin, I want to review and verify teacher applications, so that only qualified teachers are approved on the platform.

#### Acceptance Criteria

1. WHEN an admin accesses the verification dashboard THEN the system SHALL display all teachers with pendingVerification status
2. WHEN an admin views a teacher application THEN the system SHALL display the uploaded TSC certificate image
3. WHEN an admin reviews a TSC certificate THEN the system SHALL provide options to "Approve" or "Reject"
4. WHEN an admin approves a teacher THEN the system SHALL set verified = true in Firestore and assign custom claims (role: teacher, verified: true) in Firebase Auth
5. WHEN an admin rejects a teacher THEN the system SHALL set status to "rejected" and allow adding a rejection reason
6. WHEN a teacher is rejected THEN the system SHALL allow them to re-upload their certificate and resubmit

### Requirement 3: Teacher Discovery and Display

**User Story:** As a student or parent, I want to find and view verified teachers based on my preferences, so that I can choose the best teacher for my needs.

#### Acceptance Criteria

1. WHEN students or parents access the find teachers screen THEN the system SHALL display teacher cards using a fair discovery algorithm
2. WHEN displaying teacher cards THEN the system SHALL show teacher image, name, subjects, verification badge, and pricing
3. WHEN a teacher is verified THEN the system SHALL display a "Verified" badge on their card
4. WHEN a teacher is unverified THEN the system SHALL display their card without the verification badge
5. WHEN users apply filters THEN the system SHALL update the teacher list based on subject, class size/pricing, and time preferences
6. WHEN users toggle between "Online Classes" and "Home Tutoring" THEN the system SHALL filter teachers accordingly

### Requirement 4: Teacher Discovery Algorithm

**User Story:** As a platform administrator, I want teachers to have equal opportunities for visibility, so that the system is fair and promotes healthy competition.

#### Acceptance Criteria

1. WHEN ranking teachers THEN the system SHALL prioritize verified teachers over unverified ones
2. WHEN teachers have the same verification status THEN the system SHALL consider location proximity for home tutoring
3. WHEN multiple teachers match filters THEN the system SHALL rotate teacher positions to ensure equal exposure
4. WHEN teachers have availability THEN the system SHALL boost teachers with current availability
5. WHEN calculating rankings THEN the system SHALL use a weighted scoring system that can be easily modified
6. WHEN the algorithm runs THEN the system SHALL log ranking decisions for transparency and debugging

### Requirement 5: Teacher Booking System

**User Story:** As a student or parent, I want to book a session with a verified teacher, so that I can schedule and pay for tutoring services.

#### Acceptance Criteria

1. WHEN a user clicks "Book" on a teacher card THEN the system SHALL navigate to a booking details screen
2. WHEN viewing booking details THEN the system SHALL display teacher name, session type, and total amount
3. WHEN a user confirms booking details THEN the system SHALL display a checkout button for payment
4. WHEN a booking is initiated THEN the system SHALL sync the lesson status to the teacher's dashboard
5. WHEN a booking is completed THEN the system SHALL update both student/parent and teacher records

### Requirement 6: Weekly Payment System

**User Story:** As a parent, I want to pay upfront for weekly lessons, so that my child can attend consistent tutoring sessions.

#### Acceptance Criteria

1. WHEN a parent selects a teacher THEN the system SHALL display weekly package options (number of weeks)
2. WHEN viewing booking details THEN the system SHALL show total cost as (weeklyRate × numberOfWeeks)
3. WHEN a parent confirms booking THEN the system SHALL process payment via M-Pesa Daraja STK Push
4. WHEN payment is successful THEN the system SHALL create booking with status "paid" and generate individual lesson records
5. WHEN payment webhook is received THEN the system SHALL verify payment and activate the weekly booking
6. WHEN booking is activated THEN the system SHALL send Zoom link and schedule details via in-app notification and email

### Requirement 7: Teacher Payout System

**User Story:** As a teacher, I want to receive payment after completing my weekly lessons, so that I can earn from my teaching services.

#### Acceptance Criteria

1. WHEN a teacher completes all weekly lessons THEN the system SHALL calculate payout amount (total payment - 20% platform fee)
2. WHEN payout is calculated THEN the system SHALL queue payout for processing via M-Pesa Daraja B2C
3. WHEN payout is processed THEN the system SHALL update teacher's payout status and send confirmation
4. WHEN payout fails THEN the system SHALL retry automatically and flag for admin review if needed
5. WHEN teacher marks final lesson complete THEN the system SHALL trigger payout within 24 hours

### Requirement 8: Financial Ledger and Admin Management

**User Story:** As an admin, I want to track all payments and manage disputes, so that the platform operates transparently and efficiently.

#### Acceptance Criteria

1. WHEN any payment occurs THEN the system SHALL create immutable transaction record with all details
2. WHEN admin accesses financial dashboard THEN the system SHALL display platform balance, pending payouts, and transaction history
3. WHEN a dispute is raised THEN the system SHALL allow admin to process refunds via M-Pesa or manual transfer
4. WHEN refund is processed THEN the system SHALL create refund record linked to original transaction
5. WHEN admin reviews transactions THEN the system SHALL provide filtering by date, teacher, amount, and status

### Requirement 9: Teacher Dashboard Integration

**User Story:** As a teacher, I want to see when students book my sessions, so that I can prepare for upcoming lessons.

#### Acceptance Criteria

1. WHEN a student books a session THEN the system SHALL notify the teacher in real-time
2. WHEN a teacher accesses their dashboard THEN the system SHALL display pending and confirmed bookings
3. WHEN viewing bookings THEN the system SHALL show student name, subject, date, and time
4. WHEN a booking status changes THEN the system SHALL update the teacher's dashboard accordingly
5. WHEN lessons are completed THEN the system SHALL allow teacher to mark attendance and trigger payout process

### Requirement 10: Development and Debugging Standards

**User Story:** As a developer, I want comprehensive logging throughout the application, so that I can easily debug issues and track system behavior.

#### Acceptance Criteria

1. WHEN any service method is called THEN the system SHALL log entry and exit points using debugPrint
2. WHEN any error occurs THEN the system SHALL log detailed error information with context using debugPrint
3. WHEN payment processing occurs THEN the system SHALL log all transaction steps and webhook responses
4. WHEN teacher verification status changes THEN the system SHALL log the change with timestamp and reason
5. WHEN booking status updates THEN the system SHALL log the status change with relevant details
6. WHEN algorithm calculations occur THEN the system SHALL log ranking decisions and scoring details