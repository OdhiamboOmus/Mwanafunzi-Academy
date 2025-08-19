import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Dispute management tab following Flutter Lite rules (<150 lines)
class DisputeManagementTab extends StatelessWidget {
  const DisputeManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('DisputeManagementTab: Building dispute management');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dispute Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildDisputeStats(),
          const SizedBox(height: 24),
          const Text(
            'Active Disputes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildDisputeList(),
        ],
      ),
    );
  }

  Widget _buildDisputeStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Open Disputes', '12', Colors.red),
          const SizedBox(height: 8),
          _buildSummaryRow('Resolved This Month', '8', Colors.green),
          const SizedBox(height: 8),
          _buildSummaryRow('Avg Resolution Time', '2.5 days', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDisputeList() {
    return Expanded(
      child: ListView.builder(
        itemCount: 3, // Sample data
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: const Text('Dispute #1234'),
              subtitle: const Text('Teacher: John Doe • Parent: Jane Smith'),
              trailing: const Chip(
                label: Text('Pending'),
                backgroundColor: Colors.orange,
              ),
              onTap: () {
                developer.log('DisputeManagementTab: Dispute item tapped');
                // Navigate to dispute details
              },
            ),
          );
        },
      ),
    );
  }
}