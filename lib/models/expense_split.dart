class ExpenseSplit {
  final int? id;
  final int expenseId;
  final int userId;
  final double amount;
  final bool isPaid;

  ExpenseSplit({
    this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      id: map['id'] as int?,
      expenseId: map['expense_id'] as int,
      userId: map['user_id'] as int,
      amount: map['amount'] as double,
      isPaid: map['is_paid'] == 1,
    );
  }
}
