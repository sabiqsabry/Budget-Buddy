class Expense {
  final String id;
  final String groupId;
  final double amount;
  final String description;
  final String paidBy;
  final List<String> splitBetween;
  final String splitType;
  final Map<String, double>? customSplits;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.description,
    required this.paidBy,
    required this.splitBetween,
    required this.splitType,
    this.customSplits,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'amount': amount,
      'description': description,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'splitType': splitType,
      'customSplits': customSplits,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      amount: map['amount'] as double,
      description: map['description'] as String,
      paidBy: map['paidBy'] as String,
      splitBetween: List<String>.from(map['splitBetween']),
      splitType: map['splitType'] as String,
      customSplits: map['customSplits'] != null
          ? Map<String, double>.from(map['customSplits'])
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
