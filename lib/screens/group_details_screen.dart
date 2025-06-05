import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'add_expense_screen.dart';
import 'expense_details_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  List<User> _members = [];
  Map<String, User> _users = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _databaseService.getGroupExpenses(widget.group.id!);
    final users = await _databaseService.getUsers();
    setState(() {
      _expenses = expenses;
      _users = {for (var user in users) user.id.toString(): user};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: Column(
        children: [
          if (widget.group.description != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.group.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          Expanded(
            child: _expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add an expense to get started',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      final paidByUser = _users[expense.paidBy.toString()];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(expense.description),
                          subtitle: Text(
                            'Paid by: ${paidByUser?.name ?? 'Unknown User'}',
                          ),
                          trailing: Text(
                            '${expense.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailsScreen(
                                  expense: expense,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                groupId: widget.group.id!.toString(),
              ),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
