import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/services/motivation_service.dart' show MotivationService;
import 'package:mwanafunzi_academy/services/user_service.dart' show UserService;

/// User greeting widget with dynamic name and motivational message
class UserGreetingWidget extends StatefulWidget {
  final String userId;
  final UserService userService;
  final MotivationService motivationService;
  final int userPoints;

  const UserGreetingWidget({
    super.key,
    required this.userId,
    required this.userService,
    required this.motivationService,
    required this.userPoints,
  });

  @override
  State<UserGreetingWidget> createState() => _UserGreetingWidgetState();
}

class _UserGreetingWidgetState extends State<UserGreetingWidget> {
  late UserService _userService;
  late MotivationService _motivationService;
  
  String _greeting = 'Welcome back, Learner!';
  String _motivationalMessage = 'Loading...';
  int _userPoints = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _userService = widget.userService;
    _motivationService = widget.motivationService;
    _loadGreetingAndMessage();
  }

  Future<void> _loadGreetingAndMessage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load user greeting
      final greeting = await _userService.getUserGreeting(widget.userId);
      
      // Load motivational message
      final message = await _motivationService.getMotivationalMessage();

      if (mounted) {
        setState(() {
          _greeting = greeting;
          _motivationalMessage = message;
          _userPoints = widget.userPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _greeting = 'Welcome back, Learner!';
          _motivationalMessage = 'Keep learning and growing!';
          _userPoints = 0;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User greeting
          if (_isLoading)
            const SizedBox(
              width: double.infinity,
              height: 20,
              child: LinearProgressIndicator(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    _greeting,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Points badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF50E801).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFF50E801),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_userPoints',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF50E801),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
           
           const SizedBox(height: 8),
           
           // Motivational message
          if (_isLoading)
            const SizedBox(
              width: double.infinity,
              height: 16,
              child: LinearProgressIndicator(),
            )
          else
            Text(
              _motivationalMessage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(UserGreetingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadGreetingAndMessage();
    }
  }
}