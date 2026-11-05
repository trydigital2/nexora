class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final double spentAmount; // computed or cached from transactions
  final String period;
  final int month;
  final int year;
  final double alertThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    this.spentAmount = 0.0,
    this.period = 'monthly',
    required this.month,
    required this.year,
    this.alertThreshold = 0.8,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => (amount - spentAmount).clamp(0.0, double.infinity);
  double get progressPercentage => amount > 0 ? (spentAmount / amount).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => spentAmount > amount;
  bool get isNearLimit => progressPercentage >= alertThreshold && !isOverBudget;

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    double? spentAmount,
    String? period,
    int? month,
    int? year,
    double? alertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      month: month ?? this.month,
      year: year ?? this.year,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'period': period,
      'month': month,
      'year': year,
      'alert_threshold': alertThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, {double spent = 0.0}) {
    return BudgetModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: spent,
      period: map['period']?.toString() ?? 'monthly',
      month: (map['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      alertThreshold: (map['alert_threshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

