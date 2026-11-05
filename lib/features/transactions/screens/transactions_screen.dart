import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txState = ref.watch(transactionProvider);
    final settings = ref.watch(appSettingsProvider);
    final filtered = txState.filteredTransactions;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Statement',
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(transactionProvider.notifier).updateFilter(
                          txState.filter.copyWith(searchQuery: val),
                        );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search transactions, notes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(transactionProvider.notifier).updateFilter(
                                    txState.filter.copyWith(searchQuery: ''),
                                  );
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Type Filter Chips (All, Income, Expense, Transfer)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _typeFilterChip(
                    label: 'All Types',
                    isSelected: txState.filter.selectedType == null,
                    onTap: () {
                      ref.read(transactionProvider.notifier).updateFilter(
                            txState.filter.copyWith(clearType: true),
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  _typeFilterChip(
                    label: 'Expenses',
                    isSelected: txState.filter.selectedType == TransactionType.expense,
                    onTap: () {
                      ref.read(transactionProvider.notifier).updateFilter(
                            txState.filter.copyWith(selectedType: TransactionType.expense),
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  _typeFilterChip(
                    label: 'Income',
                    isSelected: txState.filter.selectedType == TransactionType.income,
                    onTap: () {
                      ref.read(transactionProvider.notifier).updateFilter(
                            txState.filter.copyWith(selectedType: TransactionType.income),
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  _typeFilterChip(
                    label: 'Transfer',
                    isSelected: txState.filter.selectedType == TransactionType.transfer,
                    onTap: () {
                      ref.read(transactionProvider.notifier).updateFilter(
                            txState.filter.copyWith(selectedType: TransactionType.transfer),
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _categoryChip(
                    label: 'All Categories',
                    isSelected: txState.filter.selectedCategory == null,
                    onTap: () {
                      ref.read(transactionProvider.notifier).updateFilter(
                            txState.filter.copyWith(clearCategory: true),
                          );
                    },
                  ),
                  ...AppConstants.categories.map((c) {
                    final isSel = txState.filter.selectedCategory == c.name;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _categoryChip(
                        label: c.name,
                        isSelected: isSel,
                        onTap: () {
                          ref.read(transactionProvider.notifier).updateFilter(
                                txState.filter.copyWith(selectedCategory: c.name),
                              );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Transactions List
            Expanded(
              child: filtered.isEmpty
                  ? EmptyStateView(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Transactions Found',
                      message: 'Try adjusting your search criteria or add a new transaction.',
                      buttonText: 'Add Transaction',
                      onButtonPressed: () => context.push('/transactions/new'),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(transactionProvider.notifier).loadTransactions(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          final isIncome = tx.type == TransactionType.income;

                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => context.push('/transactions/detail/${tx.id}'),
                            child: Row(
                              children: [
                                CategoryIconWidget(category: tx.category),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            tx.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 3,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormatter.formatShort(tx.date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(
                                        tx.amount,
                                        currencyCode: settings.currencyCode,
                                        symbol: settings.currencySymbol,
                                        hideBalance: settings.hideBalance,
                                        showSign: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isIncome ? AppColors.income : AppColors.expense,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx.paymentMethod,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textDarkMuted : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

