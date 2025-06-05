import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _databaseService = DatabaseService();
  List<User> _users = [];
  User? _selectedPayer;
  List<User> _selectedSplitters = [];
  bool _isEqualSplit = true;
  Map<String, double> _customSplits = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _amountController.addListener(_updateEqualSplits);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateEqualSplits);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await _databaseService.getGroupMembers(widget.groupId);
    setState(() {
      _users = users;
      if (users.isNotEmpty) {
        _selectedPayer = users.first;
        _selectedSplitters = List.from(users);
      }
    });
  }

  Future<void> _scanReceipt() async {
    // TODO: Implement receipt scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt scanning coming soon!'),
      ),
    );
  }

  void _updateEqualSplits() {
    if (_isEqualSplit && _selectedSplitters.isNotEmpty) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final splitAmount = amount / _selectedSplitters.length;
      setState(() {
        _customSplits = Map.fromEntries(
          _selectedSplitters.map(
            (user) => MapEntry(user.id, splitAmount),
          ),
        );
      });
    }
  }

  void _updateCustomSplit(String userId, String value) {
    if (value.isEmpty) {
      _customSplits.remove(userId);
    } else {
      final amount = double.tryParse(value) ?? 0.0;
      _customSplits[userId] = amount;
    }
    setState(() {}); // Trigger rebuild to update validation
  }

  String? _validateCustomSplits() {
    if (!_isEqualSplit) {
      final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      final splitSum = _customSplits.values.fold<double>(
        0.0,
        (sum, amount) => sum + amount,
      );

      if (splitSum == 0) {
        return 'Please enter split amounts';
      }

      if ((splitSum - totalAmount).abs() > 0.01) {
        return 'Split amounts must sum up to \$${totalAmount.toStringAsFixed(2)}';
      }
    }
    return null;
  }

  void _updateSplitType(bool isEqual) {
    setState(() {
      _isEqualSplit = isEqual;
      if (isEqual) {
        _updateEqualSplits();
      } else {
        // Clear custom splits when switching to custom mode
        _customSplits.clear();
      }
    });
  }

  void _updateSelectedSplitters(User user, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedSplitters.add(user);
        if (_isEqualSplit) {
          _updateEqualSplits();
        }
      } else {
        _selectedSplitters.remove(user);
        _customSplits.remove(user.id);
        if (_isEqualSplit) {
          _updateEqualSplits();
        }
      }
    });
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final customSplitsError = _validateCustomSplits();
      if (customSplitsError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customSplitsError),
          ),
        );
        return;
      }

      if (_selectedPayer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select who paid'),
          ),
        );
        return;
      }

      if (_selectedSplitters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select who to split with'),
          ),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final expense = Expense(
        id: const Uuid().v4(),
        groupId: widget.groupId,
        amount: amount,
        description: _descriptionController.text,
        paidBy: _selectedPayer!.id,
        splitBetween: _selectedSplitters.map((u) => u.id).toList(),
        splitType: _isEqualSplit ? 'equal' : 'custom',
        customSplits: _isEqualSplit ? null : _customSplits,
        createdAt: DateTime.now(),
      );

      await _databaseService.insertExpense(expense);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'What was this expense for?',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid by',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<User>(
                        value: _selectedPayer,
                        items: _users.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text(user.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPayer = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Select who paid',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split between',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._users.map((user) {
                        return CheckboxListTile(
                          title: Text(user.name),
                          value: _selectedSplitters.contains(user),
                          onChanged: (value) =>
                              _updateSelectedSplitters(user, value),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Equal'),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('Custom'),
                          ),
                        ],
                        selected: {_isEqualSplit},
                        onSelectionChanged: (value) =>
                            _updateSplitType(value.first),
                      ),
                      if (!_isEqualSplit) ...[
                        const SizedBox(height: 16),
                        ..._selectedSplitters.map((user) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextFormField(
                              initialValue:
                                  _customSplits[user.id]?.toString() ?? '',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: user.name,
                                prefixText: '\$ ',
                              ),
                              onChanged: (value) => _updateCustomSplit(
                                user.id,
                                value,
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Split Summary',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ..._selectedSplitters.map((user) {
                                  final amount = _customSplits[user.id] ?? 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(user.name),
                                        Text(
                                          '\$${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: amount > 0
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total'),
                                    Text(
                                      '\$${_customSplits.values.fold<double>(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveExpense,
                icon: const Icon(Icons.save),
                label: const Text('Save Expense'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanReceipt,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Receipt'),
      ),
    );
  }
}
