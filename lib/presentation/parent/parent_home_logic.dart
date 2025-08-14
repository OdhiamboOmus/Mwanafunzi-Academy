import 'package:flutter/material.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/service_locator.dart';
import '../../data/models/child_summary_model.dart';
import '../../services/parent_service.dart';

/// Business logic for ParentHomeScreen
/// Following Flutter Lite rules with separation of concerns
class ParentHomeLogic {
  final UserRepository _userRepository = UserRepository();
  final ParentService _parentService = ServiceLocator().parentService;
  
  String _parentName = 'Loading...';
  List<ChildSummary> _linkedChildren = [];
  bool _isLoading = true;
  bool _isCheckingLinks = false;
  
  // Getters
  String get parentName => _parentName;
  List<ChildSummary> get linkedChildren => _linkedChildren;
  bool get isLoading => _isLoading;
  bool get isCheckingLinks => _isCheckingLinks;
  
  /// Initialize and load user data
  Future<void> initialize() async {
    await _loadUserData();
    await checkLinkedChildren();
  }
  
  /// Load user data
  Future<void> _loadUserData() async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        _parentName = 'Parent Name'; // This would come from Firestore in real app
        _isLoading = false;
      }
    } catch (e) {
      _isLoading = false;
    }
  }
  
  /// Check for linked children
  Future<void> checkLinkedChildren() async {
    try {
      _isCheckingLinks = true;
      
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        _linkedChildren = await _parentService.getLinkedChildren(parentUserId: user.uid);
      }
    } catch (e) {
      // Error will be handled by UI
    } finally {
      _isCheckingLinks = false;
    }
  }
  
  /// Link a child by email
  Future<bool> linkChildByEmail(String email, BuildContext context) async {
    try {
      _isCheckingLinks = true;
      
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final success = await _parentService.linkChildByEmail(
          parentUserId: user.uid,
          childEmail: email,
          createdByIp: 'unknown', // In real app, get from device
        );
        
        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Child linked successfully!')),
            );
          }
          await checkLinkedChildren();
          return true;
        }
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error linking child: ${e.toString()}')),
        );
      }
      return false;
    } finally {
      _isCheckingLinks = false;
    }
  }
  
  /// Unlink a child
  Future<bool> unlinkChild(ChildSummary child, BuildContext context) async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        // For now, we'll use a simplified approach since we don't have direct access to link IDs
        // In a real app, you'd add a method to get link IDs by child ID
        final linkedChildren = await _parentService.getLinkedChildren(parentUserId: user.uid);
        final isLinked = linkedChildren.any((c) => c.childId == child.childId);
        
        if (!isLinked) {
          return false;
        }
        
        // For now, we'll use a placeholder link ID
        // In a real implementation, you'd need to get the actual link ID
        final success = await _parentService.unlinkChild(
          parentUserId: user.uid,
          linkId: 'placeholder_link_id', // This should be retrieved from the database
        );
        
        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Child unlinked successfully')),
            );
          }
          await checkLinkedChildren();
          return true;
        }
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking child: ${e.toString()}')),
        );
      }
      return false;
    }
  }
  
  /// Show link student dialog
  void showLinkStudentDialog(BuildContext context, Function(String) onLink) {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Your Child'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your child\'s email address to link their account:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Child Email',
                hintText: 'child@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onLink(emailController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }
  
  /// View child progress (placeholder)
  void viewChildProgress(ChildSummary child, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing progress for ${child.childName}')),
    );
  }
  
  /// View child comments (placeholder)
  void viewChildComments(ChildSummary child, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing comments for ${child.childName}')),
    );
  }
}