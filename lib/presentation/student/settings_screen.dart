import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/core/service_locator.dart';
import 'package:mwanafunzi_academy/services/user_service.dart';
import 'package:mwanafunzi_academy/services/settings_service.dart';
import 'package:mwanafunzi_academy/services/progress_service.dart';

// Settings screen following Flutter Lite rules (<150 lines)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = ServiceLocator().userService;
  final SettingsService _settingsService = ServiceLocator().settingsService;
  final ProgressService _progressService = ServiceLocator().progressService;
  
  int _userPoints = 0;
  bool _isLoading = true;
  bool _showLeaderboard = true;
  String _countdownText = 'Loading...';
  String _userGrade = '5'; // Default grade
  
  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Settings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF50E801)),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // User Points Section
                  _buildUserPointsSection(),
                  const SizedBox(height: 32),
                  
                  // Leaderboard Section
                  if (_showLeaderboard) _buildLeaderboardSection(),
                  const SizedBox(height: 32),
                  
                  // Settings Options
                  _buildSettingsOptions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
  );

  Widget _buildUserPointsSection() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0x1A50E801),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF50E801),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '$_userPoints points',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildLeaderboardSection() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // Countdown Timer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFF6B7280), size: 16),
              const SizedBox(width: 8),
              Text(
                _countdownText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Leaderboard Placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            children: [
              Text(
                'Keep learning to appear on leaderboard',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Complete more lessons to earn points and climb the ranks!',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildSettingsOptions() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        _buildSettingOption(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            debugPrint('🔍 DEBUG: Notifications tapped');
          },
        ),
        const SizedBox(height: 12),
        _buildSettingOption(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help with the app',
          onTap: () {
            debugPrint('🔍 DEBUG: Help & Support tapped');
          },
        ),
        const SizedBox(height: 12),
        _buildSettingOption(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and information',
          onTap: () {
            debugPrint('🔍 DEBUG: About tapped');
          },
        ),
      ],
    ),
  );

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF50E801),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF9CA3AF),
            size: 16,
          ),
        ],
      ),
    ),
  );

  Future<void> _loadSettingsData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        // Load user points from ProgressService (local cache)
        _userPoints = await _progressService.getLocalPoints(user.id);
        
        // Get user grade (for leaderboard)
        _userGrade = user.grade ?? '5';
        
        // Load leaderboard data
        await _loadLeaderboardData();
        
        // Update countdown
        await _updateCountdown();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading settings data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCountdown() async {
    try {
      final timeUntilUpdate = await _settingsService.getTimeUntilNextUpdate();
      final hours = timeUntilUpdate.inHours;
      final minutes = timeUntilUpdate.inMinutes.remainder(60);
      
      setState(() {
        if (hours > 0) {
          _countdownText = 'Next update in $hours hours $minutes minutes';
        } else {
          _countdownText = 'Next update in $minutes minutes';
        }
      });
    } catch (e) {
      debugPrint('❌ Error updating countdown: $e');
      setState(() {
        _countdownText = 'Next update in 2 hours';
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Refresh leaderboard data
      await _settingsService.refreshLeaderboard(_userGrade);
      
      // Reload all data
      await _loadSettingsData();
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLeaderboardData() async {
    try {
      final leaderboard = await _settingsService.getLeaderboard(_userGrade);
      final userRank = await _settingsService.getUserRank(
        (await _userService.getCurrentUser())?.id ?? '',
        _userGrade,
      );
      
      setState(() {
        _showLeaderboard = userRank != null || leaderboard.overall.isNotEmpty;
      });
    } catch (e) {
      debugPrint('❌ Error loading leaderboard data: $e');
      setState(() {
        _showLeaderboard = false;
      });
    }
  }
}