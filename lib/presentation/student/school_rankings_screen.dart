import 'package:flutter/material.dart';
import '../../services/firebase/school_competition_service.dart';

// School rankings screen following Flutter Lite rules (<150 lines)
class SchoolRankingsScreen extends StatefulWidget {
  final String competitionId;

  const SchoolRankingsScreen({
    super.key,
    required this.competitionId,
  });

  @override
  State<SchoolRankingsScreen> createState() => _SchoolRankingsScreenState();
}

class _SchoolRankingsScreenState extends State<SchoolRankingsScreen> {
  List<Map<String, dynamic>> _rankings = [];
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
              : _buildRankingsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text(
      'School Rankings',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
    actions: [
      IconButton(
        onPressed: _refreshRankings,
        icon: const Icon(Icons.refresh, color: Colors.black),
      ),
    ],
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
          onPressed: _refreshRankings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF50E801),
            foregroundColor: Colors.white,
          ),
          child: const Text('Try Again'),
        ),
      ],
    ),
  );

  Widget _buildRankingsList() => _rankings.isEmpty
      ? _buildEmptyState()
      : Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _rankings.length,
                itemBuilder: (context, index) => _buildRankingCard(
                  _rankings[index],
                  index + 1,
                ),
              ),
            ),
          ],
        );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF50E801), Color(0xFF40C04A)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Text(
            'School Rankings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'Avg Score',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _buildRankingCard(Map<String, dynamic> ranking, int position) => Card(
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
                  ranking['school'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ranking['participantCount']} participants',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildScoreDisplay(ranking['averageScore']),
        ],
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

  Widget _buildScoreDisplay(double averageScore) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF50E801).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      '${averageScore.toStringAsFixed(1)}%',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF50E801),
      ),
    ),
  );

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.school_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No Rankings Available',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check back later when more schools have completed the competition',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final rankings = await SchoolCompetitionService.calculateSchoolRankings(
        competitionId: widget.competitionId,
      );

      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load rankings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _refreshRankings() {
    _loadRankings();
  }

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }
}