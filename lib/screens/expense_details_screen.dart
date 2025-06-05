import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
  });

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  User? _paidByUser;
  List<ExpenseSplit> _splits = [];
  Map<String, User> _users = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _databaseService.getUsers();
    final paidByUser = users.firstWhere(
      (user) => user.id == widget.expense.paidBy,
      orElse: () => User(name: 'Unknown User'),
    );
    final splits =
        await _databaseService.getExpenseSplitsForExpense(widget.expense.id!);

    setState(() {
      _paidByUser = paidByUser;
      _splits = splits;
      _users = {for (var user in users) user.id: user};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.expense.description,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Paid by: ${_paidByUser?.name ?? 'Loading...'}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Split between:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._splits.map((split) {
            final user = _users[split.userId];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(user?.name ?? 'Loading...'),
                trailing: Text(
                  '\$${split.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
