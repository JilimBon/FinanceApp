class TransactionModel {
  final int? id;
  final int userId;
  final double amount;
  final int type; // 0 - доход, 1 - расход
  final String category;
  final String date; // ISO
  final String? description;

  TransactionModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    amount: map['amount'] as double,
    type: map['type'] as int,
    category: map['category'] as String,
    date: map['date'] as String,
    description: map['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date,
    'description': description,
  };
}