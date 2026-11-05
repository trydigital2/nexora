class SavingsContribution {
  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const SavingsContribution({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingsContribution.fromMap(Map<String, dynamic> map) {
    return SavingsContribution(
      id: map['id']?.toString() ?? '',
      goalId: map['goal_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      note: map['note']?.toString(),
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String iconName;
  final String colorHex;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SavingsContribution> contributions;

  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.iconName = 'savings',
    this.colorHex = '#7257E8',
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.contributions = const [],
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  int get daysRemaining => targetDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? iconName,
    String? colorHex,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SavingsContribution>? contributions,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_completed': isCompleted,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SavingsGoalModel.fromMap(
    Map<String, dynamic> map, {
    List<SavingsContribution> contributions = const [],
  }) {
    final current = (map['current_amount'] as num?)?.toDouble() ?? 0.0;
    final target = (map['target_amount'] as num?)?.toDouble() ?? 1000.0;

    return SavingsGoalModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Goal',
      targetAmount: target,
      currentAmount: current,
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'].toString()) ??
              DateTime.now().add(const Duration(days: 180))
          : DateTime.now().add(const Duration(days: 180)),
      iconName: map['icon_name']?.toString() ?? 'savings',
      colorHex: map['color_hex']?.toString() ?? '#7257E8',
      isCompleted: map['is_completed'] == true || current >= target,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      contributions: contributions,
    );
  }
}

