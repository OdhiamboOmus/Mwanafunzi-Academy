import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'transaction_search_filter.dart';
import 'transaction_card.dart';
import 'transaction_empty_state.dart';
import '../../../../data/models/transaction_model.dart';

// Transaction list widget following Flutter Lite rules (<150 lines)
class TransactionListWidget extends StatefulWidget {
  const TransactionListWidget({super.key});

  @override
  State<TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    developer.log('TransactionListWidget: Loading transactions');
    
    setState(() {
      _isLoading = true;
    });

    // Simulate loading transactions
    await Future.delayed(const Duration(seconds: 1));
    
    // Sample data for demonstration
    _transactions = [
      TransactionModel(
        id: '1',
        type: 'payment',
        bookingId: 'booking1',
        parentId: 'parent1',
        amount: 5000.0,
        mpesaTransactionId: 'MP123456',
        mpesaReceiptNumber: 'REC123456',
        phoneNumber: '254712345678',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: '2',
        type: 'payout',
        teacherId: 'teacher1',
        amount: 4000.0,
        mpesaTransactionId: 'MP789012',
        mpesaReceiptNumber: 'REC789012',
        phoneNumber: '254723456789',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: '3',
        type: 'refund',
        bookingId: 'booking2',
        parentId: 'parent2',
        amount: 1000.0,
        mpesaTransactionId: 'MP345678',
        mpesaReceiptNumber: 'REC345678',
        phoneNumber: '254734567890',
        status: 'failed',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    _applyFilters();
    setState(() {
      _isLoading = false;
    });
  }

  void _applyFilters() {
    developer.log('TransactionListWidget: Applying filters - search: $_searchQuery, filter: $_selectedFilter');
    
    _filteredTransactions = _transactions.where((transaction) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          transaction.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transaction.mpesaTransactionId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transaction.phoneNumber.contains(_searchQuery);

      // Type filter
      final matchesFilter = _selectedFilter == 'all' || transaction.type == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TransactionSearchFilter(
          onFilterChanged: (search, filter) {
            setState(() {
              _searchQuery = search;
              _selectedFilter = filter;
              _applyFilters();
            });
          },
          currentSearch: _searchQuery,
          currentFilter: _selectedFilter,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTransactions.isEmpty
                  ? const TransactionEmptyState()
                  : _buildTransactionList(),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          return TransactionCard(
            transaction: transaction,
            onTap: () {
              developer.log('TransactionListWidget: Transaction ${transaction.id} tapped');
              // Navigate to transaction details
            },
          );
        },
      ),
    );
  }
}