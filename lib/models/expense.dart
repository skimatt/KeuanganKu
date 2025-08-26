class Expense {
  final String id;
  final String userId;
  final double amount;
  final String? description;
  final String categoryId;
  final String? categoryName;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    this.description,
    required this.categoryId,
    this.categoryName,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      categoryId: json['category_id'] as String,
      categoryName:
          json['category_name'] as String?, // ✅ sesuai field dari Supabase
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
