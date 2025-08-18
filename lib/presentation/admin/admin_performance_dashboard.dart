import 'package:flutter/material.dart';
import '../../services/firebase/cache_hit_tracker.dart';
import '../../services/firebase/firebase_cost_monitor.dart';

/// Admin dashboard for viewing performance metrics and cost optimization data
class AdminPerformanceDashboard extends StatefulWidget {
  const AdminPerformanceDashboard({super.key});

  @override
  State<AdminPerformanceDashboard> createState() => _AdminPerformanceDashboardState();
}

class _AdminPerformanceDashboardState extends State<AdminPerformanceDashboard> {
  late Future<double> _cacheHitRate;
  late Future<Map<String, int>> _firebaseOps;
  late Future<Map<String, dynamic>> _performanceSummary;
  
  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }
  
  void _loadMetrics() {
    setState(() {
      _cacheHitRate = CacheHitTracker.getHitRate();
      _firebaseOps = FirebaseCostMonitor.getOperationCounts();
      _performanceSummary = _generatePerformanceSummary();
    });
  }
  
  Future<Map<String, dynamic>> _generatePerformanceSummary() async {
    final hitRate = await CacheHitTracker.getHitRate();
    final firebaseOps = await FirebaseCostMonitor.getOperationCounts();
    
    return {
      'cacheHitRate': hitRate,
      'cacheHitPercentage': (hitRate * 100).toStringAsFixed(1),
      'firebaseReads': firebaseOps['reads'],
      'firebaseWrites': firebaseOps['writes'],
      'totalFirebaseOps': firebaseOps['reads']! + firebaseOps['writes']!,
      'isCacheEfficient': hitRate >= 0.90,
      'timestamp': DateTime.now().toIso8601String(),
    };
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
            FutureBuilder<Map<String, int>>(
              future: _firebaseOps,
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
                      '${data['reads']}',
                      Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Write Operations',
                      '${data['writes']}',
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Total Operations',
                      '${(data['reads'] ?? 0) + (data['writes'] ?? 0)}',
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
                CacheHitTracker.reset();
                FirebaseCostMonitor.reset();
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