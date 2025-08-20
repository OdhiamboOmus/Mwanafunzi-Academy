import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'grade_selector_widget.dart';
import 'package:mwanafunzi_academy/services/motivation_service.dart' show MotivationService;
import 'package:mwanafunzi_academy/services/user_service.dart' show UserService;

// Global key for accessing navigator context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// User greeting widget with dynamic name, motivational message, and grade selection
class UserGreetingWidget extends StatefulWidget {
  final String userId;
  final UserService userService;
  final MotivationService motivationService;
  final int userPoints;
  final Function(String)? onGradeChanged;

  const UserGreetingWidget({
    super.key,
    required this.userId,
    required this.userService,
    required this.motivationService,
    required this.userPoints,
    this.onGradeChanged,
  });

  @override
  State<UserGreetingWidget> createState() => _UserGreetingWidgetState();
}

class _UserGreetingWidgetState extends State<UserGreetingWidget>
    with TickerProviderStateMixin {
  late UserService _userService;
  late MotivationService _motivationService;
  
  String _greeting = 'Welcome back, Learner!';
  String _motivationalMessage = 'Loading...';
  int _userPoints = 0;
  bool _isLoading = true;
  
  String _selectedGrade = '1';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _userService = widget.userService;
    _motivationService = widget.motivationService;
    
    // Initialize animations first
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Load data after animations are initialized
    _loadGreetingAndMessage();
    
    // Start animation after a short delay to ensure widget is built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGreetingAndMessage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
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
        });
      }
    }
  }

  void _showGradeSelector() {
    HapticFeedback.lightImpact();
    
    // Use the existing GradeSelectorWidget
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.grade,
                    color: const Color(0xFF50E801),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Grade',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: 12,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final grade = (index + 1).toString();
                    final isSelected = grade == _selectedGrade;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0x1A50E801) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          'Grade $grade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFF50E801) : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF50E801),
                                size: 24,
                              )
                            : null,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedGrade = grade;
                          });
                          if (widget.onGradeChanged != null) {
                            widget.onGradeChanged!(grade);
                          }
                          Navigator.pop(context);
                        },
                        selected: isSelected,
                        selectedTileColor: Colors.transparent,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF50E801).withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF50E801).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User greeting with subject selector
                  // TODO: Replace fallback motivational messages with Gemma API integration
                  // FIXME: Currently using hardcoded fallback messages, need to integrate with Gemma AI API
                  if (_isLoading)
                    const SizedBox(
                      width: double.infinity,
                      height: 24,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50E801)),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _greeting.replaceFirst('Welcome back, learner', 'Welcome back'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            // Points badge with animation
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF50E801),
                                    const Color(0xFF45D001),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF50E801).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_userPoints',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Grade selector button
                        GestureDetector(
                          onTap: _showGradeSelector,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF50E801).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF50E801),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Grade $_selectedGrade',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF50E801),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: const Color(0xFF50E801),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                   
                   const SizedBox(height: 16),
                   
                   // Motivational message with improved styling
                  if (_isLoading)
                    const SizedBox(
                      width: double.infinity,
                      height: 20,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50E801)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: const Color(0xFF50E801),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _motivationalMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                height: 1.4,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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