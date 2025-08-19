import 'dart:developer' as developer;
import '../data/models/teacher_model.dart';

/// Teacher Discovery Algorithm for fair and equal teacher visibility
/// 
/// This algorithm implements a fair ranking system that prioritizes verified teachers,
/// considers location proximity, ensures equal exposure through rotation, and boosts
/// available teachers while maintaining transparency through comprehensive logging.
class TeacherDiscoveryAlgorithm {
  
  /// Scoring weights for different ranking factors
  static const Map<String, double> _scoringWeights = {
    'verification': 0.4,      // 40% weight for verification status
    'availability': 0.3,      // 30% weight for current availability
    'proximity': 0.2,        // 20% weight for location proximity
    'engagement': 0.1,       // 10% weight for engagement metrics
  };

  /// Rank teachers based on various factors for fair discovery
  /// 
  /// This method implements the core ranking logic with comprehensive logging
  /// for transparency and debugging purposes.
  static List<TeacherModel> rankTeachers({
    required List<TeacherModel> teachers,
    required Map<String, dynamic> filters,
  }) {
    developer.log('TeacherDiscoveryAlgorithm: Starting teacher ranking with ${teachers.length} teachers');
    developer.log('TeacherDiscoveryAlgorithm: Applied filters: $filters');
    
    if (teachers.isEmpty) {
      developer.log('TeacherDiscoveryAlgorithm: No teachers to rank, returning empty list');
      return [];
    }

    // 1. Filter teachers based on provided criteria
    final filteredTeachers = _filterTeachers(teachers, filters);
    developer.log('TeacherDiscoveryAlgorithm: After filtering, ${filteredTeachers.length} teachers remain');
    
    if (filteredTeachers.isEmpty) {
      developer.log('TeacherDiscoveryAlgorithm: No teachers match filters, returning empty list');
      return [];
    }

    // 2. Score and rank teachers
    final rankedTeachers = _scoreAndRankTeachers(filteredTeachers, filters);
    developer.log('TeacherDiscoveryAlgorithm: Ranking completed, returning ${rankedTeachers.length} teachers');
    
    return rankedTeachers;
  }

  /// Filter teachers based on provided criteria
  static List<TeacherModel> _filterTeachers(List<TeacherModel> teachers, Map<String, dynamic> filters) {
    developer.log('TeacherDiscoveryAlgorithm: Starting teacher filtering process');
    
    return teachers.where((teacher) {
      // Filter by verification status if specified
      if (filters.containsKey('verificationStatus')) {
        final requiredStatus = filters['verificationStatus'] as String;
        if (teacher.verificationStatus != requiredStatus) {
          developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - verification status mismatch');
          return false;
        }
      }

      // Filter by subject if specified
      if (filters.containsKey('subject')) {
        final requiredSubject = filters['subject'] as String;
        if (!teacher.subjects.contains(requiredSubject)) {
          developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - subject mismatch');
          return false;
        }
      }

      // Filter by teaching type (online/home) if specified
      if (filters.containsKey('teachingType')) {
        final teachingType = filters['teachingType'] as String;
        if (teachingType == 'online' && !teacher.offersOnlineClasses) {
          developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - doesn\'t offer online classes');
          return false;
        }
        if (teachingType == 'home' && !teacher.offersHomeTutoring) {
          developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - doesn\'t offer home tutoring');
          return false;
        }
      }

      // Filter by availability if specified
      if (filters.containsKey('availableTimes')) {
        final requiredTimes = filters['availableTimes'] as List<String>;
        if (!requiredTimes.any(teacher.availableTimes.contains)) {
          developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - time availability mismatch');
          return false;
        }
      }

      // Filter by price range if specified
      if (filters.containsKey('maxPrice')) {
        final maxPrice = filters['maxPrice'] as double;
        if (teacher.price > maxPrice) {
          developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - price exceeds maximum');
          return false;
        }
      }

      // Only include available teachers
      if (!teacher.isAvailable) {
        developer.log('TeacherDiscoveryAlgorithm: Filtering out ${teacher.fullName} - not currently available');
        return false;
      }

      developer.log('TeacherDiscoveryAlgorithm: ${teacher.fullName} passes all filters');
      return true;
    }).toList();
  }

  /// Score and rank teachers based on multiple factors
  static List<TeacherModel> _scoreAndRankTeachers(List<TeacherModel> teachers, Map<String, dynamic> filters) {
    developer.log('TeacherDiscoveryAlgorithm: Starting teacher scoring and ranking');
    
    // Add rotation mechanism for equal exposure
    final rotatedTeachers = _applyRotationMechanism(teachers);
    developer.log('TeacherDiscoveryAlgorithm: Applied rotation mechanism, ${rotatedTeachers.length} teachers in new order');
    
    // Score each teacher
    final scoredTeachers = rotatedTeachers.map((teacher) {
      final score = _calculateTeacherScore(teacher, filters);
      developer.log('TeacherDiscoveryAlgorithm: ${teacher.fullName} scored $score');
      return MapEntry(teacher, score);
    }).toList();

    // Sort by score (descending)
    scoredTeachers.sort((a, b) => b.value.compareTo(a.value));
    
    // Extract teachers in ranked order
    final rankedTeachers = scoredTeachers.map((entry) => entry.key).toList();
    
    developer.log('TeacherDiscoveryAlgorithm: Final ranking order:');
    for (int i = 0; i < rankedTeachers.length; i++) {
      final teacher = rankedTeachers[i];
      developer.log('TeacherDiscoveryAlgorithm: Position ${i + 1}: ${teacher.fullName} (score: ${_calculateTeacherScore(teacher, filters)})');
    }
    
    return rankedTeachers;
  }

  /// Calculate a comprehensive score for a teacher
  static double _calculateTeacherScore(TeacherModel teacher, Map<String, dynamic> filters) {
    developer.log('TeacherDiscoveryAlgorithm: Calculating score for ${teacher.fullName}');
    
    double verificationScore = _calculateVerificationScore(teacher);
    double availabilityScore = _calculateAvailabilityScore(teacher);
    double proximityScore = _calculateProximityScore(teacher, filters);
    double engagementScore = _calculateEngagementScore(teacher);
    
    // Apply weights to get final score
    final finalScore = 
      (verificationScore * _scoringWeights['verification']!) +
      (availabilityScore * _scoringWeights['availability']!) +
      (proximityScore * _scoringWeights['proximity']!) +
      (engagementScore * _scoringWeights['engagement']!);
    
    developer.log('TeacherDiscoveryAlgorithm: ${teacher.fullName} - Verification: $verificationScore, '
        'Availability: $availabilityScore, Proximity: $proximityScore, '
        'Engagement: $engagementScore, Final: $finalScore');
    
    return finalScore;
  }

  /// Calculate verification status score
  static double _calculateVerificationScore(TeacherModel teacher) {
    developer.log('TeacherDiscoveryAlgorithm: Calculating verification score for ${teacher.fullName}');
    
    switch (teacher.verificationStatus) {
      case 'verified':
        return 1.0; // Highest score for verified teachers
      case 'pending':
        return 0.5; // Medium score for pending verification
      case 'rejected':
        return 0.0; // No score for rejected teachers
      default:
        return 0.0;
    }
  }

  /// Calculate availability score based on current status
  static double _calculateAvailabilityScore(TeacherModel teacher) {
    developer.log('TeacherDiscoveryAlgorithm: Calculating availability score for ${teacher.fullName}');
    
    if (!teacher.isAvailable) {
      return 0.0;
    }
    
    // Boost teachers who have been recently active
    if (teacher.lastBookingDate != null) {
      final daysSinceLastBooking = DateTime.now().difference(teacher.lastBookingDate!).inDays;
      if (daysSinceLastBooking <= 7) {
        return 1.0; // Recently active teachers get highest score
      } else if (daysSinceLastBooking <= 30) {
        return 0.8; // Moderately recent teachers get good score
      }
    }
    
    return 0.6; // Default score for available teachers
  }

  /// Calculate location proximity score for home tutoring
  static double _calculateProximityScore(TeacherModel teacher, Map<String, dynamic> filters) {
    developer.log('TeacherDiscoveryAlgorithm: Calculating proximity score for ${teacher.fullName}');
    
    // Only apply proximity for home tutoring
    if (filters.containsKey('teachingType') && filters['teachingType'] == 'home') {
      // This is a simplified proximity calculation
      // In a real implementation, this would use actual distance calculation
      if (filters.containsKey('userLocation')) {
        final userLocation = filters['userLocation'] as String;
        if (teacher.areaOfOperation.toLowerCase() == userLocation.toLowerCase()) {
          return 1.0; // Same area gets highest score
        }
      }
      return 0.7; // Default score for home tutoring teachers
    }
    
    return 1.0; // No proximity consideration for online classes
  }

  /// Calculate engagement score based on performance metrics
  static double _calculateEngagementScore(TeacherModel teacher) {
    developer.log('TeacherDiscoveryAlgorithm: Calculating engagement score for ${teacher.fullName}');
    
    // Calculate response rate score
    double responseRateScore = teacher.responseRate.clamp(0.0, 1.0);
    
    // Calculate booking completion rate
    double completionRate = teacher.totalBookings > 0 
        ? teacher.completedLessons / teacher.totalBookings 
        : 0.0;
    
    // Combine metrics with weights
    final engagementScore = (responseRateScore * 0.6) + (completionRate * 0.4);
    
    developer.log('TeacherDiscoveryAlgorithm: ${teacher.fullName} - Response rate: ${teacher.responseRate}, '
        'Completion rate: $completionRate, Engagement score: $engagementScore');
    
    return engagementScore;
  }

  /// Apply rotation mechanism to ensure equal teacher exposure
  static List<TeacherModel> _applyRotationMechanism(List<TeacherModel> teachers) {
    developer.log('TeacherDiscoveryAlgorithm: Applying rotation mechanism for ${teachers.length} teachers');
    
    if (teachers.length <= 1) {
      return teachers;
    }
    
    // Simple rotation: shift teachers based on current time
    final rotationOffset = DateTime.now().minute % teachers.length;
    final rotatedTeachers = List<TeacherModel>.empty(growable: true);
    
    for (int i = 0; i < teachers.length; i++) {
      final originalIndex = (i + rotationOffset) % teachers.length;
      rotatedTeachers.add(teachers[originalIndex]);
    }
    
    developer.log('TeacherDiscoveryAlgorithm: Rotation applied with offset $rotationOffset');
    return rotatedTeachers;
  }

  /// Get detailed ranking breakdown for a specific teacher (for debugging)
  static Map<String, dynamic> getTeacherRankingBreakdown(
    TeacherModel teacher, 
    List<TeacherModel> allTeachers, 
    Map<String, dynamic> filters
  ) {
    developer.log('TeacherDiscoveryAlgorithm: Getting ranking breakdown for ${teacher.fullName}');
    
    final score = _calculateTeacherScore(teacher, filters);
    final verificationScore = _calculateVerificationScore(teacher);
    final availabilityScore = _calculateAvailabilityScore(teacher);
    final proximityScore = _calculateProximityScore(teacher, filters);
    final engagementScore = _calculateEngagementScore(teacher);
    
    return {
      'teacherId': teacher.id,
      'teacherName': teacher.fullName,
      'totalScore': score,
      'verificationScore': verificationScore,
      'availabilityScore': availabilityScore,
      'proximityScore': proximityScore,
      'engagementScore': engagementScore,
      'scoringWeights': _scoringWeights,
      'totalTeachers': allTeachers.length,
      'rank': allTeachers.indexOf(teacher) + 1,
    };
  }
}