import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Transaction search and filter widget following Flutter Lite rules (<150 lines)
class TransactionSearchFilter extends StatefulWidget {
  final Function(String, String) onFilterChanged;
  final String currentSearch;
  final String currentFilter;

  const TransactionSearchFilter({
    super.key,
    required this.onFilterChanged,
    required this.currentSearch,
    required this.currentFilter,
  });

  @override
  State<TransactionSearchFilter> createState() => _TransactionSearchFilterState();
}

class _TransactionSearchFilterState extends State<TransactionSearchFilter> {
  late String _searchQuery;
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.currentSearch;
    _selectedFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    developer.log('TransactionSearchFilter: Building search and filter');
    
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 8),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Search transactions',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          widget.onFilterChanged(_searchQuery, _selectedFilter);
        });
      },
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('All', 'all', true),
        const SizedBox(width: 8),
        _buildFilterChip('Payments', 'payment', false),
        const SizedBox(width: 8),
        _buildFilterChip('Payouts', 'payout', false),
        const SizedBox(width: 8),
        _buildFilterChip('Refunds', 'refund', false),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          widget.onFilterChanged(_searchQuery, _selectedFilter);
        });
      },
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
    );
  }
}