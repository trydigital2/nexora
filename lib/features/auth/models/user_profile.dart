class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String preferredCurrency;
  final double monthlyIncome;
  final bool notificationEnabled;
  final bool biometricEnabled;
  final bool isDarkMode;
  final bool hideBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.preferredCurrency = 'USD',
    this.monthlyIncome = 5000.0,
    this.notificationEnabled = true,
    this.biometricEnabled = false,
    this.isDarkMode = false,
    this.hideBalance = false,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? preferredCurrency,
    double? monthlyIncome,
    bool? notificationEnabled,
    bool? biometricEnabled,
    bool? isDarkMode,
    bool? hideBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hideBalance: hideBalance ?? this.hideBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'preferred_currency': preferredCurrency,
      'monthly_income': monthlyIncome,
      'notification_enabled': notificationEnabled,
      'biometric_enabled': biometricEnabled,
      'is_dark_mode': isDarkMode,
      'hide_balance': hideBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'Fintech Pioneer',
      avatarUrl: map['avatar_url']?.toString(),
      preferredCurrency: map['preferred_currency']?.toString() ?? 'USD',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 5000.0,
      notificationEnabled: map['notification_enabled'] != false,
      biometricEnabled: map['biometric_enabled'] == true,
      isDarkMode: map['is_dark_mode'] == true,
      hideBalance: map['hide_balance'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static UserProfile defaultDemoProfile() {
    return UserProfile(
      id: 'demo-user-1',
      email: 'alex.morgan@nexora.finance',
      fullName: 'Alex Morgan',
      avatarUrl: null,
      preferredCurrency: 'USD',
      monthlyIncome: 6500.0,
      notificationEnabled: true,
      biometricEnabled: false,
      isDarkMode: false,
      hideBalance: false,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    );
  }
}

