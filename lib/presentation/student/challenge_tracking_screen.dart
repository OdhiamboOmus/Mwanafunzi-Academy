import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/bottom_navigation_widget.dart';
import '../../../services/firebase/student_challenge_service.dart';
import '../../../data/models/quiz_model.dart' as quiz;
import '../../../routes.dart';

class ChallengeTrackingScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ChallengeTrackingScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ChallengeTrackingScreen> createState() => _ChallengeTrackingScreenState();
}

class _ChallengeTrackingScreenState extends State<ChallengeTrackingScreen> {
  int _selectedBottomNavIndex = 1;
  int _selectedTab = 0; // 0: Active, 1: Completed
  
  final StudentChallengeService _challengeService = StudentChallengeService();
  
  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Challenge data
  List<quiz.StudentChallenge> _activeChallenges = [];
  List<quiz.StudentChallenge> _completedChallenges = [];

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load both active and completed challenges
      final activeChallenges = await _challengeService.getActiveChallenges(widget.studentId);
      final completedChallenges = await _challengeService.getCompletedChallenges(widget.studentId);
      final incomingChallenges = await _challengeService.getIncomingChallenges(widget.studentId);
      
      // Combine active and incoming challenges
      _activeChallenges = [...activeChallenges, ...incomingChallenges];
      
      _completedChallenges = completedChallenges;
      
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load challenges. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Remove back arrow
      title: const Text(
        'My Challenges',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    ),
    body: Column(
      children: [
        // Tab selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? const Color(0xFF50E801) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 0 ? Colors.white : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? const Color(0xFF50E801) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 1 ? Colors.white : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Content area
        Expanded(
          child: _buildContent(),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationWidget(
      selectedIndex: _selectedBottomNavIndex,
      onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
    ),
  );

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50E801)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading challenges...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChallenges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_selectedTab == 0) {
      // Active challenges tab
      if (_activeChallenges.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_esports,
                size: 64,
                color: Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Challenges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Challenge other students to start competing!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50E801),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Go Challenge'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeChallenges.length,
        itemBuilder: (context, index) => _buildChallengeCard(_activeChallenges[index]),
      );
    } else {
      // Completed challenges tab
      if (_completedChallenges.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 64,
                color: Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 16),
              Text(
                'No Completed Challenges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete some challenges to see your results here!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedChallenges.length,
        itemBuilder: (context, index) => _buildCompletedChallengeCard(_completedChallenges[index]),
      );
    }
  }

  Widget _buildChallengeCard(quiz.StudentChallenge challenge) {
    final isChallenger = challenge.challenger.studentId == widget.studentId;
    final opponent = isChallenger ? challenge.challenged : challenge.challenger;
    final status = challenge.status;
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusText = 'Pending';
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule;
        break;
      case 'in_progress':
        statusText = 'In Progress';
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.play_circle;
        break;
      case 'rejected':
        statusText = 'Rejected';
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = 'Unknown';
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${challenge.subject} - ${challenge.topic}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'vs ${opponent.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${challenge.questions.length} questions',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              if (status == 'pending') ...[
                TextButton(
                  onPressed: () => _acceptChallenge(challenge.id),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF50E801),
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _rejectChallenge(challenge.id),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                  child: const Text('Reject'),
                ),
              ] else if (status == 'in_progress' && isChallenger) ...[
                ElevatedButton(
                  onPressed: () => _startCompetition(challenge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50E801),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Start Quiz'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedChallengeCard(quiz.StudentChallenge challenge) {
    final isChallenger = challenge.challenger.studentId == widget.studentId;
    final opponent = isChallenger ? challenge.challenged : challenge.challenger;
    final results = challenge.results;
    
    String resultText;
    Color resultColor;
    
    if (results == null) {
      resultText = 'Completed';
      resultColor = const Color(0xFF6B7280);
    } else if (results.winner == 'draw') {
      resultText = 'Draw';
      resultColor = const Color(0xFFF59E0B);
    } else if (results.winner == widget.studentId) {
      resultText = 'You Won!';
      resultColor = const Color(0xFF50E801);
    } else {
      resultText = 'You Lost';
      resultColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  results != null ? Icons.emoji_events : Icons.check_circle,
                  color: resultColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${challenge.subject} - ${challenge.topic}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'vs ${opponent.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resultText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: resultColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (results != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Score: ${results.challengerScore ?? 0}/${challenge.questions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Opponent: ${results.challengedScore ?? 0}/${challenge.questions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Completed: ${challenge.completedAt?.toLocal().toString().split(' ')[0] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptChallenge(String challengeId) async {
    try {
      HapticFeedback.lightImpact();
      await _challengeService.acceptChallenge(challengeId);
      _loadChallenges();
    } catch (e) {
      debugPrint('Error accepting challenge: $e');
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _rejectChallenge(String challengeId) async {
    try {
      HapticFeedback.lightImpact();
      await _challengeService.rejectChallenge(challengeId);
      _loadChallenges();
    } catch (e) {
      debugPrint('Error rejecting challenge: $e');
      HapticFeedback.heavyImpact();
    }
  }

  void _startCompetition(quiz.StudentChallenge challenge) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      AppRoutes.competitionQuiz,
      arguments: {
        'competitionId': challenge.id,
        'studentId': widget.studentId,
        'questions': challenge.questions.map((q) => q.toJson()).toList(),
        'challenge': challenge,
      },
    );
  }
}