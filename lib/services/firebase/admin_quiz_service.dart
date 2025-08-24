import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/quiz_model.dart';
import 'retry_service.dart';

// Simplified admin quiz service following Flutter Lite rules
class AdminQuizService {
  
  /// Upload quiz content to Firebase with proper structure
  static Future<void> uploadQuizContent({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    try {
      debugPrint('🔍 DEBUG: AdminQuizService.uploadQuizContent started');
      debugPrint('🔍 DEBUG: Grade: $grade, Subject: $subject, Topic: $topic');
      debugPrint('🔍 DEBUG: Questions count: ${questions.length}');
      
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please sign in first.');
      }
      
      debugPrint('🔐 DEBUG: User authenticated: ${user.email}');
      
      // Generate quiz ID from topic and grade
      final quizId = '${subject.toLowerCase().replaceAll(' ', '_')}_grade${grade}_${topic.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create quiz document directly (matching script structure)
      final quizDoc = FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId);
      
      debugPrint('🔍 DEBUG: Writing quiz to Firestore...');
      
      await quizDoc.set({
        'quizId': quizId,
        'title': '$subject - $topic Quiz',
        'subject': subject,
        'topic': topic,
        'grade': grade,
        'description': '$subject quiz on $topic for grade $grade',
        'questions': questions.map((q) => q.toJson()).toList(),
        'totalQuestions': questions.length,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': 1,
        'uploadedBy': user.email,
      });
      
      debugPrint('🔍 DEBUG: Quiz document written successfully');
      
      // Update quiz metadata
      await _updateQuizMeta(grade, subject, topic, questions, quizId);
      
      // Clear cache for this quiz
      await _clearQuizCache(grade, subject, topic);
      
      debugPrint('🔍 DEBUG: Upload completed successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Upload failed: $e');
      throw Exception('Failed to upload quiz content: $e');
    }
  }
  
  /// Update quiz metadata
  static Future<void> _updateQuizMeta(String grade, String subject, String topic, List<QuizQuestion> questions, String quizId) async {
    try {
      debugPrint('🔍 DEBUG: Updating quiz metadata for $grade/$subject/$topic');
      
      final metaDoc = FirebaseFirestore.instance
          .collection('quizMeta')
          .doc(grade);
      
      // Get existing quizzes
      final snapshot = await metaDoc.get();
      List<Map<String, dynamic>> existingQuizzes = [];
      
      if (snapshot.exists && snapshot.data()?['quizzes'] != null) {
        existingQuizzes = List<Map<String, dynamic>>.from(snapshot.data()!['quizzes']);
      }
      
      // Remove existing quiz with same topic
      existingQuizzes.removeWhere((q) => q['topic'] == topic);
      
      // Add new quiz metadata
      final quizMeta = {
        'id': quizId,
        'title': '$subject - $topic Quiz',
        'subject': subject,
        'topic': topic,
        'totalQuestions': questions.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      existingQuizzes.add(quizMeta);
      
      await metaDoc.set({
        'grade': grade,
        'quizzes': existingQuizzes,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('🔍 DEBUG: Quiz metadata updated successfully');
    } catch (e) {
      debugPrint('🔍 DEBUG: Failed to update quiz metadata: $e');
      throw Exception('Failed to update quiz metadata: $e');
    }
  }

  /// Validate quiz JSON structure
  static List<QuizQuestion> validateQuizJson(List<dynamic> jsonData) {
    final validQuestions = <QuizQuestion>[];
    
    for (int i = 0; i < jsonData.length; i++) {
      try {
        final questionData = jsonData[i] as Map<String, dynamic>;
        
        // Validate required fields
        if (questionData['question'] == null || questionData['question'] is! String) {
          throw Exception('Invalid question text at index $i');
        }
        
        if (questionData['options'] == null || questionData['options'] is! List) {
          throw Exception('Invalid options at index $i');
        }
        
        final options = questionData['options'] as List;
        if (options.length != 4 || !options.every((opt) => opt is String)) {
          throw Exception('Each question must have exactly 4 string options at index $i');
        }
        
        if (questionData['correctAnswerIndex'] == null || 
            questionData['correctAnswerIndex'] is! int ||
            questionData['correctAnswerIndex'] < 0 || 
            questionData['correctAnswerIndex'] >= 4) {
          throw Exception('Invalid correctAnswerIndex at index $i');
        }
        
        if (questionData['explanation'] == null || questionData['explanation'] is! String) {
          throw Exception('Invalid explanation at index $i');
        }
        
        // Create valid question
        validQuestions.add(QuizQuestion.fromJson(questionData));
      } catch (e) {
        throw Exception('Error validating question at index $i: ${e.toString()}');
      }
    }
    
    return validQuestions;
  }

  /// Get existing quiz topics for a grade and subject
  static Future<List<String>> getExistingTopics(String grade, String subject) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(grade)
          .collection(subject)
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete quiz content
  static Future<void> deleteQuizContent({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Deleting quiz content for $grade/$subject/$topic');
      
      // Find quiz ID from metadata
      final metaSnapshot = await FirebaseFirestore.instance
          .collection('quizMeta')
          .doc(grade)
          .get();
      
      if (metaSnapshot.exists && metaSnapshot.data()?['quizzes'] != null) {
        final quizzes = List<Map<String, dynamic>>.from(metaSnapshot.data()!['quizzes']);
        final quiz = quizzes.firstWhere((q) => q['topic'] == topic, orElse: () => {});
        
        if (quiz.isNotEmpty) {
          final quizId = quiz['id'];
          
          // Delete quiz document
          final quizDoc = FirebaseFirestore.instance
              .collection('quizzes')
              .doc(quizId);
          
          await quizDoc.delete();
          
          // Update metadata
          quizzes.removeWhere((q) => q['topic'] == topic);
          final metaDoc = FirebaseFirestore.instance
              .collection('quizMeta')
              .doc(grade);
          
          await metaDoc.update({
            'quizzes': quizzes,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          // Clear cache
          await _clearQuizCache(grade, subject, topic);
          
          debugPrint('🔍 DEBUG: Quiz content deleted successfully');
        }
      }
    } catch (e) {
      debugPrint('🔍 DEBUG: Failed to delete quiz content: $e');
      throw Exception('Failed to delete quiz content: $e');
    }
  }

  /// Update quiz content
  static Future<void> updateQuizContent({
    required String grade,
    required String subject,
    required String topic,
    required List<QuizQuestion> questions,
  }) async {
    try {
      await uploadQuizContent(
        grade: grade,
        subject: subject,
        topic: topic,
        questions: questions,
      );
    } catch (e) {
      throw Exception('Failed to update quiz content: $e');
    }
  }

  /// Clear cache for a specific quiz topic
  static Future<void> clearTopicCache({
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'quiz_${grade}_${subject}_$topic';
      
      // Clear cached questions
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');
      
      // Clear metadata cache
      await prefs.remove('quiz_metadata_${grade}_$subject');
      
      debugPrint('🔍 DEBUG: Cache cleared for $grade/$subject/$topic');
    } catch (e) {
      debugPrint('🔍 DEBUG: Warning: Failed to clear cache for $topic: $e');
    }
  }
  
  /// Clear quiz cache for a specific grade, subject, and topic
  static Future<void> _clearQuizCache(String grade, String subject, String topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'quiz_${grade}_${subject}_$topic';
      
      // Clear cached questions
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_timestamp');
      
      debugPrint('🔍 DEBUG: Quiz cache cleared for $grade/$subject/$topic');
    } catch (e) {
      debugPrint('🔍 DEBUG: Warning: Failed to clear quiz cache: $e');
    }
  }
}