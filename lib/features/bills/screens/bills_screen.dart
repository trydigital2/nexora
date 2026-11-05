import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/bills_provider.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  void _showAddBillDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));
    String selectedCategory = 'Bills & Utilities';
    String selectedFrequency = 'Monthly';

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
                      'Add Recurring Bill',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Bill Name / Service',
                      hint: 'e.g. Internet, Electricity, Rent, Spotify',
                      controller: titleController,
                      validator: (v) => Validators.validateRequired(v, 'Bill Name'),
                      prefixIcon: const Icon(Icons.receipt_outlined),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Amount Due',
                      hint: '85.00',
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.validateAmount,
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                    const SizedBox(height: 14),

                    // Due Date Picker
                    Text(
                      'Due Date',
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
                          initialDate: selectedDueDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDueDate = picked);
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
                              DateFormatter.formatShort(selectedDueDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Frequency Dropdown
                    Text(
                      'Billing Frequency',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedFrequency,
                          isExpanded: true,
                          items: AppConstants.billFrequencies.map((f) {
                            return DropdownMenuItem(value: f, child: Text(f));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedFrequency = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      text: 'Set Bill Reminder',
                      width: double.infinity,
                      onPressed: () {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (titleController.text.trim().isEmpty || amt <= 0) return;

                        ref.read(billsProvider.notifier).addBill(
                              title: titleController.text.trim(),
                              amount: amt,
                              category: selectedCategory,
                              dueDate: selectedDueDate,
                              frequency: selectedFrequency,
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bill reminder created')),
                        );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billsState = ref.watch(billsProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Bill Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Bill',
            onPressed: () => _showAddBillDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddBillDialog(context, ref),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(billsProvider.notifier).loadBills(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upcoming Unpaid Summary
                AppCard(
                  padding: const EdgeInsets.all(20),
                  gradient: AppColors.cardGradient,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Bills Due',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(
                              billsState.totalUnpaidAmount,
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
                          const SizedBox(height: 4),
                          Text(
                            '${billsState.unpaidBills.length} payments awaiting settlement',
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
                          Icons.notifications_active_rounded,
                          color: AppColors.warning,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Upcoming Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                if (billsState.bills.isEmpty)
                  EmptyStateView(
                    icon: Icons.calendar_month_outlined,
                    title: 'No Recurring Bills',
                    message: 'Add fixed expenses like Internet, Rent, and Subscriptions to track due dates.',
                    buttonText: 'Add Bill',
                    onButtonPressed: () => _showAddBillDialog(context, ref),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: billsState.bills.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = billsState.bills[index];
                      final isOverdue = bill.isOverdue;

                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Paid checkbox button
                            IconButton(
                              icon: Icon(
                                bill.isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: bill.isPaid ? AppColors.accent : AppColors.textMuted,
                                size: 26,
                              ),
                              onPressed: () {
                                ref.read(billsProvider.notifier).togglePaidStatus(bill.id);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                                      color: isDark ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormatter.formatBillDue(bill.dueDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                                          color: isOverdue
                                              ? AppColors.expense
                                              : (isDark ? AppColors.textDarkMuted : AppColors.textSecondary),
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
                                        bill.frequency,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    bill.amount,
                                    symbol: settings.currencySymbol,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.primary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  onPressed: () {
                                    ref.read(billsProvider.notifier).deleteBill(bill.id);
                                  },
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
