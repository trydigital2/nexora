enum InsightType {
  anomaly,
  comparison,
  budgetWarning,
  savingTip,
  summary;

  static InsightType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'anomaly':
        return InsightType.anomaly;
      case 'comparison':
        return InsightType.comparison;
      case 'budget_warning':
      case 'budgetwarning':
        return InsightType.budgetWarning;
      case 'saving_tip':
      case 'savingtip':
        return InsightType.savingTip;
      case 'summary':
      default:
        return InsightType.summary;
    }
  }

  String get displayName {
    switch (this) {
      case InsightType.anomaly:
        return 'Spending Anomaly';
      case InsightType.comparison:
        return 'Monthly Comparison';
      case InsightType.budgetWarning:
        return 'Budget Alert';
      case InsightType.savingTip:
        return 'Smart Savings';
      case InsightType.summary:
        return 'Executive Summary';
    }
  }
}

class AiInsightModel {
  final String id;
  final String userId;
  final InsightType type;
  final String title;
  final String message;
  final double score;
  final String? actionLabel;
  final String? actionRoute;
  final bool isDismissed;
  final DateTime createdAt;

  const AiInsightModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.score = 0.85,
    this.actionLabel,
    this.actionRoute,
    this.isDismissed = false,
    required this.createdAt,
  });

  AiInsightModel copyWith({
    String? id,
    String? userId,
    InsightType? type,
    String? title,
    String? message,
    double? score,
    String? actionLabel,
    String? actionRoute,
    bool? isDismissed,
    DateTime? createdAt,
  }) {
    return AiInsightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      score: score ?? this.score,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'score': score,
      'action_label': actionLabel,
      'action_route': actionRoute,
      'is_dismissed': isDismissed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AiInsightModel.fromMap(Map<String, dynamic> map) {
    return AiInsightModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      type: InsightType.fromString(map['type']?.toString() ?? 'summary'),
      title: map['title']?.toString() ?? 'Financial Insight',
      message: map['message']?.toString() ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.85,
      actionLabel: map['action_label']?.toString(),
      actionRoute: map['action_route']?.toString(),
      isDismissed: map['is_dismissed'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

