class TransactionModel {
  final String id;
  final String familyId;
  final String? userId;
  final String? categoryId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime? createdAt;
  // Joined from categories table
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIconName;
  // Joined from profiles table
  final String? username;
  final String? fullName;

  const TransactionModel({
    required this.id,
    required this.familyId,
    this.userId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    this.createdAt,
    this.categoryName,
    this.categoryColor,
    this.categoryIconName,
    this.username,
    this.fullName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final cat = map['categories'] as Map<String, dynamic>?;
    final prof = map['profiles'] as Map<String, dynamic>?;
    return TransactionModel(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      userId: map['user_id'] as String?,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      categoryName: cat?['name'] as String?,
      categoryColor: cat?['color'] as String?,
      categoryIconName: cat?['icon_name'] as String?,
      username: prof?['username'] as String?,
      fullName: prof?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'family_id': familyId,
        'user_id': userId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'description': description ?? '',
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      };

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  String get memberDisplayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!.trim();
    if (username != null && username!.trim().isNotEmpty) return '@${username!.trim()}';
    return 'Member';
  }

  String get displayCategory => categoryName ?? 'Uncategorised';
}
