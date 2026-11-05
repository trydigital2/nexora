class RecurringBillModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final DateTime dueDate;
  final String frequency; // Monthly, Weekly, Quarterly, Yearly
  final bool isPaid;
  final int reminderDaysBefore;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringBillModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    this.category = 'Bills & Utilities',
    required this.dueDate,
    this.frequency = 'Monthly',
    this.isPaid = false,
    this.reminderDaysBefore = 2,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  RecurringBillModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? dueDate,
    String? frequency,
    bool? isPaid,
    int? reminderDaysBefore,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringBillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      isPaid: isPaid ?? this.isPaid,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency,
      'is_paid': isPaid,
      'reminder_days_before': reminderDaysBefore,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RecurringBillModel.fromMap(Map<String, dynamic> map) {
    return RecurringBillModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Bill',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? 'Bills & Utilities',
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      frequency: map['frequency']?.toString() ?? 'Monthly',
      isPaid: map['is_paid'] == true,
      reminderDaysBefore: (map['reminder_days_before'] as num?)?.toInt() ?? 2,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

