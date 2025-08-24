// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import '../../core/services/cost_monitoring_service.dart';

/// Admin dashboard for viewing performance metrics and cost optimization data
class AdminPerformanceDashboard extends StatefulWidget {
  const AdminPerformanceDashboard({super.key});

  @override
  State<AdminPerformanceDashboard> createState() => _AdminPerformanceDashboardState();
}

class _AdminPerformanceDashboardState extends State<AdminPerformanceDashboard> {
  late Future<double> _cacheHitRate;
  late Future<Map<String, dynamic>> _performanceSummary;
  late Future<Map<String, dynamic>> _costMetrics;
  final CostMonitoringService _costService = CostMonitoringService();
  
  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }
  
  void _loadMetrics() {
    setState(() {
      _cacheHitRate = _getCacheHitRate();
      _performanceSummary = _generatePerformanceSummary();
      _costMetrics = _costService.getCostEstimates();
    });
  }
  
  Future<double> _getCacheHitRate() async {
    // Simulate cache hit rate from lesson service
    return 0.85; // 85% cache hit rate
  }
  
  Future<Map<String, dynamic>> _generatePerformanceSummary() async {
    final hitRate = await _getCacheHitRate();
    final costMetrics = await _costService.getCostEstimates();
    
    return {
      'cacheHitRate': hitRate,
      'cacheHitPercentage': (hitRate * 100).toStringAsFixed(1),
      'firebaseReads': 25000,
      'firebaseWrites': 8000,
      'totalFirebaseOps': 33000,
      'isCacheEfficient': hitRate >= 0.90,
      'estimatedDailyCost': costMetrics['total_daily_cost'],
      'estimatedMonthlyCost': costMetrics['total_monthly_cost'],
      'costOptimizationScore': _calculateOptimizationScore(costMetrics),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  double _calculateOptimizationScore(Map<String, dynamic> costMetrics) {
    final dailyCost = costMetrics['total_daily_cost'] ?? 0.0;
    final readStatus = costMetrics['read_threshold_status'] ?? 'normal';
    final writeStatus = costMetrics['write_threshold_status'] ?? 'normal';
    final storageStatus = costMetrics['storage_threshold_status'] ?? 'normal';
    
    double score = 100.0;
    
    // Deduct points for warnings
    if (readStatus == 'warning') score -= 20;
    if (writeStatus == 'warning') score -= 20;
    if (storageStatus == 'warning') score -= 20;
    
    // Deduct points for high costs
    if (dailyCost > 10) score -= 30;
    else if (dailyCost > 5) score -= 15;
    else if (dailyCost > 2) score -= 5;
    
    return score.clamp(0, 100);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsOverview(),
            const SizedBox(height: 24),
            _buildCostMetrics(),
            const SizedBox(height: 24),
            _buildCachePerformance(),
            const SizedBox(height: 24),
            _buildFirebaseCosts(),
            const SizedBox(height: 24),
            _buildOptimizationRecommendations(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _performanceSummary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Error loading metrics');
                }
                
                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildMetricRow(
                      'Cache Hit Rate',
                      '${data['cacheHitPercentage']}%',
                      data['isCacheEfficient'] ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Firebase Operations',
                      '${data['totalFirebaseOps']} total',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Firebase Reads',
                      '${data['firebaseReads']}',
                      Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Firebase Writes',
                      '${data['firebaseWrites']}',
                      Colors.red,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCachePerformance() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<double>(
              future: _cacheHitRate,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError) {
                  return const Text('Error loading cache metrics');
                }
                
                final hitRate = snapshot.data ?? 0.0;
                final isEfficient = hitRate >= 0.90;
                
                return Column(
                  children: [
                    _buildProgressBar(
                      'Cache Hit Rate',
                      hitRate,
                      isEfficient ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: >90% (Current: ${(hitRate * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: isEfficient ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCostMetrics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _costMetrics,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Error loading cost metrics');
                }
                
                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildMetricRow(
                      'Estimated Daily Cost',
                      'KES ${data['estimatedDailyCost']?.toStringAsFixed(2) ?? '0.00'}',
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Estimated Monthly Cost',
                      'KES ${data['estimatedMonthlyCost']?.toStringAsFixed(2) ?? '0.00'}',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Cost Optimization Score',
                      '${data['costOptimizationScore']?.toStringAsFixed(1) ?? '0.0'}%',
                      data['costOptimizationScore'] >= 80 ? Colors.green :
                      data['costOptimizationScore'] >= 60 ? Colors.orange : Colors.red,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseCosts() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Cost Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _performanceSummary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Error loading Firebase metrics');
                }
                
                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildMetricRow(
                      'Read Operations',
                      '${data['firebaseReads']}',
                      Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Write Operations',
                      '${data['firebaseWrites']}',
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Total Operations',
                      '${data['totalFirebaseOps']}',
                      Colors.blue,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptimizationRecommendations() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optimization Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<double>(
              future: _cacheHitRate,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                final hitRate = snapshot.data ?? 0.0;
                final recommendations = <String>[];
                
                if (hitRate < 0.90) {
                  recommendations.add('Increase cache TTL to reduce Firebase reads');
                }
                
                if (hitRate > 0.95) {
                  recommendations.add('Cache performance is excellent! Consider extending cache duration');
                }
                
                if (recommendations.isEmpty) {
                  recommendations.add('No optimization recommendations at this time');
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMetrics,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh Metrics'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _loadMetrics();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset Metrics'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 20,
        ),
      ],
    );
  }
}