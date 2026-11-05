enum TransactionType {
  income,
  expense,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? notes;
  final DateTime date;
  final String paymentMethod;
  final String? receiptUrl;
  final bool isRecurring;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.notes,
    required this.date,
    this.paymentMethod = 'Debit Card',
    this.receiptUrl,
    this.isRecurring = false,
    required this.createdAt,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? notes,
    DateTime? date,
    String? paymentMethod,
    String? receiptUrl,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'notes': notes,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.fromString(map['type']?.toString() ?? 'expense'),
      category: map['category']?.toString() ?? 'Other',
      notes: map['notes']?.toString(),
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: map['payment_method']?.toString() ?? 'Debit Card',
      receiptUrl: map['receipt_url']?.toString(),
      isRecurring: map['is_recurring'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

