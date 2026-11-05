import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../models/savings_goal.dart';
import '../providers/savings_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final targetAmountController = TextEditingController();
    final initialDepositController = TextEditingController(text: '0');
    DateTime selectedTargetDate = DateTime.now().add(const Duration(days: 180));
    String selectedIcon = 'savings';
    String selectedColor = '#7257E8';

    final colors = ['#7257E8', '#35C99A', '#FF7A00', '#38BDF8', '#EC4899'];

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
              child: SingleChildScrollView(
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
                      'Create Savings Target',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Goal Title',
                      hint: 'e.g. MacBook Pro M4, Vacation in Tokyo',
                      controller: titleController,
                      validator: (v) => Validators.validateRequired(v, 'Goal Title'),
                      prefixIcon: const Icon(Icons.flag_rounded),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Target Amount',
                            hint: '5000',
                            controller: targetAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.validateAmount,
                            prefixIcon: const Icon(Icons.attach_money_rounded),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Initial Deposit',
                            hint: '0',
                            controller: initialDepositController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: const Icon(Icons.savings_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Target Date picker
                    Text(
                      'Target Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedTargetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => selectedTargetDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatShort(selectedTargetDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color palette
                    Text(
                      'Accent Color',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: colors.map((c) {
                        final isSel = selectedColor == c;
                        final color = Color(int.parse(c.replaceAll('#', '0xFF')));
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSel
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      text: 'Create Target',
                      width: double.infinity,
                      onPressed: () {
                        final targetAmt = double.tryParse(targetAmountController.text.trim()) ?? 0.0;
                        final initialAmt = double.tryParse(initialDepositController.text.trim()) ?? 0.0;
                        if (titleController.text.trim().isEmpty || targetAmt <= 0) return;

                        ref.read(savingsProvider.notifier).addGoal(
                              title: titleController.text.trim(),
                              targetAmount: targetAmt,
                              initialAmount: initialAmt,
                              targetDate: selectedTargetDate,
                              iconName: selectedIcon,
                              colorHex: selectedColor,
                            );
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddContributionDialog(BuildContext context, WidgetRef ref, SavingsGoalModel goal) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add to "${goal.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Deposit Amount',
                hint: '250',
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.validateAmount,
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Note (Optional)',
                hint: 'e.g. Paycheck bonus contribution',
                controller: noteController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                Navigator.pop(ctx);
                await ref.read(savingsProvider.notifier).addContribution(
                      goalId: goal.id,
                      amount: amt,
                      note: noteController.text.trim(),
                    );

                final updatedState = ref.read(savingsProvider);
                if (updatedState.recentlyCompletedGoal != null && context.mounted) {
                  _showCelebrationDialog(context, updatedState.recentlyCompletedGoal!);
                  ref.read(savingsProvider.notifier).clearRecentlyCompleted();
                }
              },
              child: const Text('Deposit'),
            ),
          ],
        );
      },
    );
  }

  void _showCelebrationDialog(BuildContext context, SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 44,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 Goal Accomplished!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Congratulations! You fully funded "${goal.title}" with a total of \$${goal.currentAmount.toStringAsFixed(2)}.',
              style: const TextStyle(fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: AppButton(
              text: 'Brilliant!',
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingsState = ref.watch(savingsProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Goal',
            onPressed: () => _showAddGoalDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddGoalDialog(context, ref),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(savingsProvider.notifier).loadGoals(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Hero Card
                AppCard(
                  padding: const EdgeInsets.all(20),
                  gradient: AppColors.cardGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Accumulated Savings',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        CurrencyFormatter.format(
                          savingsState.totalSavings,
                          currencyCode: settings.currencyCode,
                          symbol: settings.currencySymbol,
                          hideBalance: settings.hideBalance,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Across ${savingsState.goals.length} target milestones (Target: ${CurrencyFormatter.format(savingsState.totalTarget, symbol: settings.currencySymbol)})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Active Milestones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                if (savingsState.goals.isEmpty)
                  EmptyStateView(
                    icon: Icons.savings_outlined,
                    title: 'No Savings Goals Yet',
                    message: 'Create a target milestone like an Emergency Fund or New Laptop to track your wealth accumulation.',
                    buttonText: 'Create Goal',
                    onButtonPressed: () => _showAddGoalDialog(context, ref),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: savingsState.goals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final goal = savingsState.goals[index];
                      final pct = (goal.progressPercentage * 100).toStringAsFixed(0);
                      final goalColor = Color(int.tryParse(goal.colorHex.replaceAll('#', '0xFF')) ?? 0xFF7257E8);

                      return AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: goalColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    goal.isCompleted ? Icons.check_circle_rounded : Icons.savings_rounded,
                                    color: goalColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        goal.isCompleted
                                            ? 'Goal Completed! 🏆'
                                            : '${goal.daysRemaining} days left • ${DateFormatter.formatMonthShort(goal.targetDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: goal.isCompleted
                                              ? AppColors.accent
                                              : (isDark ? AppColors.textDarkMuted : AppColors.textSecondary),
                                          fontWeight: goal.isCompleted ? FontWeight.w700 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: goalColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: goal.progressPercentage,
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${CurrencyFormatter.format(goal.currentAmount, symbol: settings.currencySymbol)} of ${CurrencyFormatter.format(goal.targetAmount, symbol: settings.currencySymbol)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                                  ),
                                ),
                                if (!goal.isCompleted)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      backgroundColor: goalColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _showAddContributionDialog(context, ref, goal),
                                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                    label: const Text(
                                      'Contribute',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
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
