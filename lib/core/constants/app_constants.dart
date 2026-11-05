import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'NEXORA';
  static const String appTagline = 'Your Money. Your Intelligence.';
  static const String appVersion = '1.0.0';

  // Currency list
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CAD', 'symbol': 'CA\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'AU\$', 'name': 'Australian Dollar'},
    {'code': 'SGD', 'symbol': 'SG\$', 'name': 'Singapore Dollar'},
  ];

  // Transaction Categories
  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'salary',
      name: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
      isIncome: true,
    ),
    CategoryItem(
      id: 'investments',
      name: 'Investments',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF6366F1),
      isIncome: true,
    ),
    CategoryItem(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF7A00),
      isIncome: false,
    ),
    CategoryItem(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFEC4899),
      isIncome: false,
    ),
    CategoryItem(
      id: 'transportation',
      name: 'Transportation',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF3B82F6),
      isIncome: false,
    ),
    CategoryItem(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie_filter_rounded,
      color: Color(0xFF8B5CF6),
      isIncome: false,
    ),
    CategoryItem(
      id: 'healthcare',
      name: 'Healthcare',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFEF4444),
      isIncome: false,
    ),
    CategoryItem(
      id: 'education',
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF14B8A6),
      isIncome: false,
    ),
    CategoryItem(
      id: 'bills',
      name: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFF59E0B),
      isIncome: false,
    ),
    CategoryItem(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF06B6D4),
      isIncome: false,
    ),
    CategoryItem(
      id: 'other',
      name: 'Other',
      icon: Icons.category_rounded,
      color: Color(0xFF64748B),
      isIncome: false,
    ),
  ];

  static CategoryItem getCategory(String id) {
    return categories.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase() || c.name.toLowerCase() == id.toLowerCase(),
      orElse: () => const CategoryItem(
        id: 'other',
        name: 'Other',
        icon: Icons.category_rounded,
        color: Color(0xFF64748B),
        isIncome: false,
      ),
    );
  }

  // Payment methods
  static const List<String> paymentMethods = [
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
    'Cash',
    'UPI',
    'Crypto',
    'Other',
  ];

  // Bill Frequencies
  static const List<String> billFrequencies = [
    'Monthly',
    'Weekly',
    'Quarterly',
    'Yearly',
  ];

  // Notification channels
  static const String notificationChannelId = 'nexora_finance_alerts';
  static const String notificationChannelName = 'Nexora Financial Alerts';
  static const String notificationChannelDesc = 'Alerts for budgets, recurring bills, and AI insights';
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });
}

