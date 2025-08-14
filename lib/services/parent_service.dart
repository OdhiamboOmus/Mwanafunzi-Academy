import '../core/services/storage_service.dart';
import '../core/services/base_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/child_summary_model.dart';
import '../../services/firebase/firestore_service.dart';

/// Enhanced ParentService for child linking and comment monitoring
/// Following Flutter Lite rules with minimal dependencies
class ParentService extends BaseService {
  final UserRepository _userRepository;
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  // Rate limiting constants
  static const int _maxLinkAttemptsPerHour = 5;
  static const Duration _rateLimitWindow = Duration(hours: 1);
  static const String _rateLimitKey = 'parent_link_attempts';

  ParentService({
    required UserRepository userRepository,
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _userRepository = userRepository,
       _firestoreService = firestoreService,
       _storageService = storageService;

  /// Link a child to parent account by email with verification
  /// Requirements: 6.2, 6.3, 6.4
  Future<bool> linkChildByEmail({
    required String parentUserId,
    required String childEmail,
    String? createdByIp,
  }) async {
    try {
      // Check rate limiting
      if (!await _canAttemptLink(parentUserId)) {
        throw Exception('Maximum link attempts reached. Please try again later.');
      }

      // Verify student account exists
      final studentQuery = await _userRepository.getUserByEmail(childEmail);
      if (studentQuery.docs.isEmpty) {
        throw Exception('Student account with this email does not exist.');
      }

      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data() as Map<String, dynamic>;
      
      // Verify it's a student account
      if (studentData['userType'] != 'student') {
        throw Exception('This email is not associated with a student account.');
      }

      final studentId = studentDoc.id;
      final studentName = studentData['fullName'] ?? '';

      // Check if already linked
      final existingLinks = await _firestoreService.getParentLinks(parentId: parentUserId);
      final isAlreadyLinked = existingLinks.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['childId'] == studentId;
      });

      if (isAlreadyLinked) {
        throw Exception('This student is already linked to your account.');
      }

      // Generate unique link ID
      final linkId = 'parent_link_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';

      // Create parentLinks document
      await _firestoreService.createParentLink(
        linkId: linkId,
        parentId: parentUserId,
        childId: studentId,
        status: 'linked_by_parent',
        createdByIp: createdByIp,
      );

      // Log action to audit/parentActions
      await _firestoreService.logParentAction(
        parentId: parentUserId,
        action: 'link_child',
        targetUserId: studentId,
        targetUserName: studentName,
        details: {'childEmail': childEmail},
        ipAddress: createdByIp,
      );

      // Update rate limiting
      await _recordLinkAttempt(parentUserId);

      return true;
    } catch (e) {
      handleError(e, context: 'linkChildByEmail');
      rethrow;
    }
  }

  /// Get all linked children for a parent
  /// Requirements: 6.6
  Future<List<ChildSummary>> getLinkedChildren({
    required String parentUserId,
  }) async {
    try {
      final links = await _firestoreService.getParentLinks(parentId: parentUserId);
      
      if (links.docs.isEmpty) {
        return [];
      }

      final childIds = links.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['childId'] as String;
      }).toList();
      
      final children = await _firestoreService.getUsersByIds(childIds);

      return children.map((childDoc) {
        final childData = childDoc.data() as Map<String, dynamic>;
        return ChildSummary(
          childId: childDoc.id,
          childName: childData['fullName'] ?? '',
          grade: childData['grade'] ?? '',
          schoolName: childData['schoolName'] ?? '',
          totalPoints: childData['totalPoints'] ?? 0,
          completedLessons: childData['completedLessons'] ?? 0,
          completedSections: childData['completedSections'] ?? 0,
          lastActivity: childData['lastActivity']?.toDate() ?? DateTime.now(),
          profileImageUrl: childData['profileImageUrl'],
        );
      }).toList();
    } catch (e) {
      handleError(e, context: 'getLinkedChildren');
      return [];
    }
  }

  /// Get child progress summary
  /// Requirements: 6.7
  Future<ChildSummary?> getChildProgress({
    required String childId,
  }) async {
    try {
      final childDoc = await _userRepository.getUserById(childId);
      if (!childDoc.exists) return null;
      
      final childData = childDoc.data() as Map<String, dynamic>;

      return ChildSummary(
        childId: childId,
        childName: childData['fullName'] ?? '',
        grade: childData['grade'] ?? '',
        schoolName: childData['schoolName'] ?? '',
        totalPoints: childData['totalPoints'] ?? 0,
        completedLessons: childData['completedLessons'] ?? 0,
        completedSections: childData['completedSections'] ?? 0,
        lastActivity: childData['lastActivity']?.toDate() ?? DateTime.now(),
        profileImageUrl: childData['profileImageUrl'],
      );
    } catch (e) {
      handleError(e, context: 'getChildProgress');
      return null;
    }
  }

  /// Get child comments for monitoring
  /// Requirements: 6.8, 6.5
  Future<List<ChildCommentActivity>> getChildComments({
    required String childId,
    int? limit,
  }) async {
    try {
      // Read from pre-computed childCommentActivity document
      final commentActivityDoc = await _firestoreService.getChildCommentActivity(childId: childId);
      
      if (commentActivityDoc == null || !commentActivityDoc.exists) {
        return [];
      }

      final activityData = commentActivityDoc.data() as Map<String, dynamic>;
      final comments = (activityData['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      return comments.take(limit ?? comments.length).map((commentJson) {
        return ChildCommentActivity.fromJson(commentJson);
      }).toList();
    } catch (e) {
      handleError(e, context: 'getChildComments');
      return [];
    }
  }

  /// Unlink a child from parent account
  /// Requirements: 6.9
  Future<bool> unlinkChild({
    required String parentUserId,
    required String linkId,
  }) async {
    try {
      // Get link details first
      final linkDoc = await _firestoreService.getParentLinkById(linkId);
      if (!linkDoc.exists) {
        throw Exception('Invalid link or unauthorized access.');
      }

      final linkData = linkDoc.data() as Map<String, dynamic>;
      if (linkData['parentId'] != parentUserId) {
        throw Exception('Invalid link or unauthorized access.');
      }

      // Update link status to 'revoked'
      await _firestoreService.updateParentLinkStatus(
        linkId: linkId,
        status: 'revoked',
      );

      // Log the unlink action
      await _firestoreService.logParentAction(
        parentId: parentUserId,
        action: 'unlink_child',
        targetUserId: linkData['childId'],
        targetUserName: linkData['childId'], // Fallback to childId if name not available
        details: {'linkId': linkId},
        ipAddress: 'unknown', // Could be passed as parameter if needed
      );

      return true;
    } catch (e) {
      handleError(e, context: 'unlinkChild');
      return false;
    }
  }

  /// Check if parent has any linked children
  Future<bool> hasLinkedChildren({
    required String parentUserId,
  }) async {
    try {
      final links = await _firestoreService.getParentLinks(parentId: parentUserId);
      return links.docs.isNotEmpty;
    } catch (e) {
      handleError(e, context: 'hasLinkedChildren');
      return false;
    }
  }

  /// Get link details by ID
  Future<ParentLink?> getParentLink({
    required String linkId,
  }) async {
    try {
      final linkDoc = await _firestoreService.getParentLinkById(linkId);
      if (!linkDoc.exists) return null;

      final linkData = linkDoc.data() as Map<String, dynamic>;
      return ParentLink(
        linkId: linkData['linkId'] ?? '',
        parentId: linkData['parentId'] ?? '',
        childId: linkData['childId'] ?? '',
        status: linkData['status'] ?? '',
        createdAt: linkData['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: linkData['updatedAt']?.toDate(),
        createdByIp: linkData['createdByIp'],
      );
    } catch (e) {
      handleError(e, context: 'getParentLink');
      return null;
    }
  }

  /// Rate limiting helper methods
  Future<bool> _canAttemptLink(String parentUserId) async {
    try {
      final attemptsKey = '$_rateLimitKey:$parentUserId';
      final attemptsData = await _storageService.getValue(attemptsKey);
      
      if (attemptsData == null) {
        return true; // No previous attempts
      }

      final attemptsJson = _parseJson(attemptsData);
      final attempts = attemptsJson['attempts'] as int? ?? 0;
      final lastAttempt = attemptsJson['lastAttempt'] as int? ?? 0;

      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastAttempt = now - lastAttempt;

      // Reset counter if more than an hour has passed
      if (timeSinceLastAttempt > _rateLimitWindow.inMilliseconds) {
        await _storageService.removeValue(attemptsKey);
        return true;
      }

      return attempts < _maxLinkAttemptsPerHour;
    } catch (e) {
      handleError(e, context: '_canAttemptLink');
      return true; // Allow if rate limiting fails
    }
  }

  Future<void> _recordLinkAttempt(String parentUserId) async {
    try {
      final attemptsKey = '$_rateLimitKey:$parentUserId';
      final attemptsData = await _storageService.getValue(attemptsKey);
      
      Map<String, dynamic> attemptsJson;
      if (attemptsData == null) {
        attemptsJson = {
          'attempts': 1,
          'lastAttempt': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        attemptsJson = _parseJson(attemptsData);
        attemptsJson['attempts'] = (attemptsJson['attempts'] as int? ?? 0) + 1;
        attemptsJson['lastAttempt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _storageService.setValue(
        attemptsKey,
        _encodeJson(attemptsJson),
      );
    } catch (e) {
      handleError(e, context: '_recordLinkAttempt');
    }
  }

  /// Helper methods
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[random % chars.length];
    }
    return result;
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return jsonString as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  String _encodeJson(Map<String, dynamic> data) {
    try {
      return data.toString();
    } catch (e) {
      return '{}';
    }
  }
}