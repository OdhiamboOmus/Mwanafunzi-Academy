import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/payout_service.dart';
import '../../data/services/payout_retry_service.dart';
import '../../data/models/transaction_model.dart';
import 'widgets/payout_earnings_card.dart';
import 'widgets/payout_stats_card.dart';
import 'widgets/payout_history_section.dart';
import 'widgets/payout_retry_section.dart';

// Teacher payout dashboard with comprehensive debugPrint logging
class TeacherPayoutDashboardScreen extends StatefulWidget {
  final String teacherId;

  const TeacherPayoutDashboardScreen({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  _TeacherPayoutDashboardScreenState createState() => _TeacherPayoutDashboardScreenState();
}

class _TeacherPayoutDashboardScreenState extends State<TeacherPayoutDashboardScreen> {
  final PayoutService _payoutService = PayoutService();
  final PayoutRetryService _retryService = PayoutRetryService();
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic>? _earningsSummary;
  List<TransactionModel>? _payoutHistory;
  List<Map<String, dynamic>>? _retryHistory;
  Map<String, dynamic>? _retryStats;
  
  @override
  void initState() {
    super.initState();
    developer.log('TeacherPayoutDashboardScreen: Initializing dashboard for teacher ${widget.teacherId}');
    _loadDashboardData();
  }

  @override
  void dispose() {
    developer.log('TeacherPayoutDashboardScreen: Disposing dashboard for teacher ${widget.teacherId}');
    super.dispose();
  }

  // Load all dashboard data with comprehensive logging
  Future<void> _loadDashboardData() async {
    developer.log('TeacherPayoutDashboardScreen: Loading dashboard data for teacher ${widget.teacherId}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load earnings summary
      final earnings = await _payoutService.getTeacherEarningsSummary(widget.teacherId);
      
      // Load payout history
      final history = await _payoutService.getTeacherPayoutHistory(widget.teacherId);
      
      // Load retry history
      final retryHistory = await _retryService.getRetryHistory(teacherId: widget.teacherId);
      
      // Load retry statistics
      final retryStats = await _retryService.getRetryStatistics();

      setState(() {
        _earningsSummary = earnings;
        _payoutHistory = history;
        _retryHistory = retryHistory;
        _retryStats = retryStats;
        _isLoading = false;
      });

      developer.log('TeacherPayoutDashboardScreen: Dashboard data loaded successfully - TeacherID: ${widget.teacherId}');
    } catch (e) {
      developer.log('TeacherPayoutDashboardScreen: Error loading dashboard data - TeacherID: ${widget.teacherId}, Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Refresh dashboard data with logging
  Future<void> _refreshDashboard() async {
    developer.log('TeacherPayoutDashboardScreen: Refreshing dashboard data for teacher ${widget.teacherId}');
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadDashboardData();
      developer.log('TeacherPayoutDashboardScreen: Dashboard refreshed successfully for teacher ${widget.teacherId}');
    } catch (e) {
      developer.log('TeacherPayoutDashboardScreen: Error refreshing dashboard - TeacherID: ${widget.teacherId}, Error: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('TeacherPayoutDashboardScreen: Building UI for teacher ${widget.teacherId}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Payout Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshDashboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
    );
  }

  // Build main dashboard content with logging
  Widget _buildDashboardContent() {
    developer.log('TeacherPayoutDashboardScreen: Building dashboard content for teacher ${widget.teacherId}');
    
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_earningsSummary != null) PayoutEarningsCard(earnings: _earningsSummary!),
            SizedBox(height: 16),
            if (_retryStats != null) PayoutStatsCard(stats: _retryStats!),
            SizedBox(height: 16),
            PayoutHistorySection(transactions: _payoutHistory),
            SizedBox(height: 16),
            PayoutRetrySection(retryHistory: _retryHistory),
          ],
        ),
      ),
    );
  }
}