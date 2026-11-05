import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/category_icon.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txState = ref.watch(transactionProvider);
    final settings = ref.watch(appSettingsProvider);

    final tx = txState.transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => TransactionModel(
        id: 'not_found',
        userId: '',
        title: 'Transaction Not Found',
        amount: 0,
        type: TransactionType.expense,
        category: 'Other',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    if (tx.id == 'not_found') {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Transaction record not found')),
      );
    }

    final isIncome = tx.type == TransactionType.income;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/transactions/edit/${tx.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
            onPressed: () => _confirmDelete(context, ref, tx.id),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Amount Header Card
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    CategoryIconWidget(
                      category: tx.category,
                      size: 64,
                      iconSize: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tx.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(
                        tx.amount,
                        currencyCode: settings.currencyCode,
                        symbol: settings.currencySymbol,
                        hideBalance: settings.hideBalance,
                        showSign: true,
                      ),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? AppColors.income : AppColors.expense,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tx.type.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isIncome ? AppColors.income : AppColors.expense,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Detailed Attributes
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow(isDark, 'Category', tx.category, Icons.category_outlined),
                    _divider(isDark),
                    _detailRow(isDark, 'Date', DateFormatter.formatShort(tx.date), Icons.calendar_today_outlined),
                    _divider(isDark),
                    _detailRow(isDark, 'Time', DateFormatter.formatTime(tx.date), Icons.access_time_rounded),
                    _divider(isDark),
                    _detailRow(isDark, 'Payment Method', tx.paymentMethod, Icons.credit_card_rounded),
                    if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                      _divider(isDark),
                      _detailRow(isDark, 'Notes', tx.notes!, Icons.notes_rounded),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Attachment View
              if (tx.receiptUrl != null && tx.receiptUrl!.isNotEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_rounded, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Receipt Proof',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: tx.receiptUrl!.startsWith('http')
                            ? Image.network(
                                tx.receiptUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(tx.receiptUrl!),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(bool isDark, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will remove the transaction from your ledger and recalculate all budgets and analytics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(transactionProvider.notifier).deleteTransaction(id);
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

