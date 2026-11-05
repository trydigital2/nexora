import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _showAddEditBudgetDialog(BuildContext context, WidgetRef ref, [BudgetModel? budget]) {
    final isEditing = budget != null;
    final amountController = TextEditingController(
      text: isEditing ? budget.amount.toStringAsFixed(0) : '',
    );
    String selectedCategory = isEditing ? budget.category : AppConstants.categories[2].name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isEditing ? 'Edit Category Budget' : 'Set Category Budget',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.categories
                        .where((c) => !c.isIncome)
                        .map((c) {
                      final isSel = selectedCategory == c.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = c.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? c.color
                                : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : AppColors.textPrimary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Amount
                  AppTextField(
                    label: 'Monthly Limit Amount',
                    hint: '500',
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.validateAmount,
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    text: isEditing ? 'Save Changes' : 'Create Budget',
                    width: double.infinity,
                    onPressed: () {
                      final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (amt <= 0) return;

                      if (isEditing) {
                        ref.read(budgetRawProvider.notifier).updateBudget(
                              budget.copyWith(
                                category: selectedCategory,
                                amount: amt,
                              ),
                            );
                      } else {
                        ref.read(budgetRawProvider.notifier).addBudget(
                              category: selectedCategory,
                              amount: amt,
                            );
                      }
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgets = ref.watch(calculatedBudgetsProvider);
    final summary = ref.watch(totalBudgetSummaryProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Smart Budget Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Budget',
            onPressed: () => _showAddEditBudgetDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditBudgetDialog(context, ref),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(budgetRawProvider.notifier).loadBudgets(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Overall Monthly Budget Summary Card
                AppCard(
                  padding: const EdgeInsets.all(20),
                  gradient: AppColors.cardGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Budget Capacity',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${((summary['percentage'] ?? 0) * 100).toStringAsFixed(0)}% Utilized',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(
                                  summary['remaining'] ?? 0.0,
                                  currencyCode: settings.currencyCode,
                                  symbol: settings.currencySymbol,
                                  hideBalance: settings.hideBalance,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Remaining of ${CurrencyFormatter.format(summary['allocated'] ?? 0.0, currencyCode: settings.currencyCode, symbol: settings.currencySymbol)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.savings_outlined,
                              color: AppColors.accent,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (summary['percentage'] ?? 0.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (summary['percentage'] ?? 0.0) >= 0.95
                                ? AppColors.expense
                                : ((summary['percentage'] ?? 0.0) >= 0.8
                                    ? AppColors.warning
                                    : AppColors.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Category Budgets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Category Budgets List
                if (budgets.isEmpty)
                  EmptyStateView(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'No Budgets Created',
                    message: 'Set monthly limits on your categories to keep spending on track.',
                    buttonText: 'Add First Budget',
                    onButtonPressed: () => _showAddEditBudgetDialog(context, ref),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: budgets.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = budgets[index];
                      final isOver = b.isOverBudget;
                      final isNear = b.isNearLimit;
                      final pct = (b.progressPercentage * 100).toStringAsFixed(0);

                      Color barColor = AppColors.accent;
                      if (isOver) {
                        barColor = AppColors.expense;
                      } else if (isNear) {
                        barColor = AppColors.warning;
                      }

                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () => _showAddEditBudgetDialog(context, ref, b),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CategoryIconWidget(category: b.category),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.category,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isOver
                                            ? 'Over limit by ${CurrencyFormatter.format(b.spentAmount - b.amount, symbol: settings.currencySymbol)}'
                                            : '${CurrencyFormatter.format(b.remainingAmount, symbol: settings.currencySymbol)} left',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isOver
                                              ? AppColors.expense
                                              : (isDark ? AppColors.textDarkMuted : AppColors.textSecondary),
                                          fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$pct%',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: barColor,
                                      ),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(b.spentAmount, symbol: settings.currencySymbol)} / ${CurrencyFormatter.format(b.amount, symbol: settings.currencySymbol)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: b.progressPercentage.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

