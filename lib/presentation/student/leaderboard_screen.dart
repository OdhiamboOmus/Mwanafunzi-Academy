import 'package:flutter/material.dart';
import '../../services/firebase/school_competition_service.dart';

// Dual leaderboard screen following Flutter Lite rules (<150 lines)
class LeaderboardScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String school;

  const LeaderboardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.school,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedView = 0; // 0: Individual, 1: School
  List<Map<String, dynamic>> _individualRankings = [];
  List<Map<String, dynamic>> _schoolRankings = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorMessage()
              : _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text(
      'Leaderboards',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
    actions: [
      IconButton(
        onPressed: _refreshData,
        icon: const Icon(Icons.refresh, color: Colors.black),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: _buildViewToggle(),
    ),
  );

  Widget _buildViewToggle() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedView = 0),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedView == 0 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Individual',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedView = 1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedView == 1 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'School',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMainContent() => Column(
    children: [
      if (_selectedView == 0) _buildIndividualLeaderboard()
      else _buildSchoolLeaderboard(),
    ],
  );

  Widget _buildIndividualLeaderboard() => Expanded(
    child: _individualRankings.isEmpty
        ? _buildEmptyState('No individual rankings available')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _individualRankings.length,
            itemBuilder: (context, index) => _buildIndividualRankingCard(
              _individualRankings[index],
              index + 1,
            ),
          ),
  );

  Widget _buildSchoolLeaderboard() => Expanded(
    child: _schoolRankings.isEmpty
        ? _buildEmptyState('No school rankings available')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _schoolRankings.length,
            itemBuilder: (context, index) => _buildSchoolRankingCard(
              _schoolRankings[index],
              index + 1,
            ),
          ),
  );

  Widget _buildIndividualRankingCard(Map<String, dynamic> ranking, int position) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildPositionBadge(position),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ranking['school'] ?? 'Unknown School'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildScoreDisplay(ranking['totalPoints']?.toString() ?? '0'),
        ],
      ),
    ),
  );

  Widget _buildSchoolRankingCard(Map<String, dynamic> ranking, int position) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () => _showSchoolContributors(ranking),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildPositionBadge(position),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking['school'] ?? 'Unknown School',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ranking['participantCount'] ?? 0} participants',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildScoreDisplay(ranking['averageScore']?.toStringAsFixed(1) ?? '0.0'),
          ],
        ),
      ),
    ),
  );

  Widget _buildPositionBadge(int position) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: position == 1
          ? const Color(0xFFFFD700) // Gold
          : position == 2
              ? const Color(0xFFC0C0C0) // Silver
              : position == 3
                  ? const Color(0xFFCD7F32) // Bronze
                  : Colors.grey[200],
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        '$position',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: position <= 3 ? Colors.white : Colors.grey[700],
        ),
      ),
    ),
  );

  Widget _buildScoreDisplay(String score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF50E801).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      score,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF50E801),
      ),
    ),
  );

  Widget _buildEmptyState(String message) => Container(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.emoji_events_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorMessage() => Container(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load rankings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _refreshData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF50E801),
            foregroundColor: Colors.white,
          ),
          child: const Text('Try Again'),
        ),
      ],
    ),
  );

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load individual rankings (aggregated from all sources)
      final individualRankings = await _calculateIndividualRankings();
      
      // Load school rankings from active competitions
      final schoolRankings = await SchoolCompetitionService.calculateSchoolRankings(
        competitionId: 'default', // This would be passed from active competition
      );

      setState(() {
        _individualRankings = individualRankings;
        _schoolRankings = schoolRankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load rankings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _calculateIndividualRankings() async {
    // This would aggregate points from:
    // - Lesson completions
    // - Personal quizzes
    // - Student vs student challenges
    // - School competitions
    
    // For now, return mock data
    return [
      {
        'name': widget.studentName,
        'school': widget.school,
        'totalPoints': 150,
      },
      {
        'name': 'Alex Johnson',
        'school': 'Riverside Academy',
        'totalPoints': 145,
      },
      {
        'name': 'Sarah Chen',
        'school': 'Maple High',
        'totalPoints': 138,
      },
    ];
  }

  void _showSchoolContributors(Map<String, dynamic> school) {
    // Show top contributors from selected school
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${school['school']} Contributors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top contributors from ${school['school']}'),
            const SizedBox(height: 16),
            // This would show actual contributors from the school
            const Text('• Student 1: 45 points'),
            const Text('• Student 2: 38 points'),
            const Text('• Student 3: 32 points'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }
}