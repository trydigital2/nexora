import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/balance_card.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../ai_assistant/providers/ai_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/models/transaction.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final settings = ref.watch(appSettingsProvider);
    final data = ref.watch(dashboardProvider);
    final aiState = ref.watch(aiProvider);

    final userName = authState.user?.fullName.split(' ').first ?? 'Pioneer';
    final topInsight = aiState.insights.isNotEmpty ? aiState.insights.first : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(aiProvider.notifier).refreshInsights();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: User Greeting + Quick Access Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                          child: Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good day,',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Bill reminders shortcut
                        IconButton(
                          onPressed: () => context.push('/bills'),
                          tooltip: 'Bills & Subscriptions',
                          icon: Badge(
                            smallSize: 8,
                            backgroundColor: AppColors.warning,
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: isDark ? Colors.white70 : AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                        // Analytics shortcut
                        IconButton(
                          onPressed: () => context.push('/analytics'),
                          tooltip: 'Detailed Analytics',
                          icon: Icon(
                            Icons.bar_chart_rounded,
                            color: isDark ? Colors.white70 : AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Balance Hero Card
                BalanceCard(
                  totalBalance: data.summary.totalBalance,
                  monthlyIncome: data.summary.monthlyIncome,
                  monthlyExpenses: data.summary.monthlyExpenses,
                  savingsRate: data.summary.savingsRate,
                  currencyCode: settings.currencyCode,
                  currencySymbol: settings.currencySymbol,
                  hideBalance: settings.hideBalance,
                  onToggleHide: () {
                    ref.read(appSettingsProvider.notifier).toggleHideBalance();
                  },
                ),
                const SizedBox(height: 24),

                // 2. Quick Action Buttons (Add Expense, Add Income, Transfer, Analytics)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickAction(
                      context: context,
                      label: 'Expense',
                      icon: Icons.remove_rounded,
                      color: AppColors.expense,
                      onTap: () => context.push('/transactions/new?type=expense'),
                    ),
                    _quickAction(
                      context: context,
                      label: 'Income',
                      icon: Icons.add_rounded,
                      color: AppColors.accent,
                      onTap: () => context.push('/transactions/new?type=income'),
                    ),
                    _quickAction(
                      context: context,
                      label: 'Transfer',
                      icon: Icons.swap_horiz_rounded,
                      color: AppColors.secondary,
                      onTap: () => context.push('/transactions/new?type=transfer'),
                    ),
                    _quickAction(
                      context: context,
                      label: 'Analytics',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF38BDF8),
                      onTap: () => context.push('/analytics'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. AI Insights Banner Spotlight
                if (topInsight != null) ...[
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: isDark ? 0.25 : 0.10),
                        AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    onTap: () => context.push('/insights'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI FINANCIAL INSIGHT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? AppColors.secondaryLight : AppColors.secondary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          topInsight.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topInsight.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. Weekly Cash Flow Mini Chart
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weekly Cash Velocity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                          Row(
                            children: [
                              _legendDot(AppColors.accent, 'Inflow'),
                              const SizedBox(width: 12),
                              _legendDot(AppColors.expense, 'Outflow'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 140,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _calculateMaxBar(data.weeklyIncome, data.weeklyExpense),
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < labels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          labels[idx],
                                          style: TextStyle(
                                            color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.weeklyIncome[i],
                                    color: AppColors.accent,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  BarChartRodData(
                                    toY: data.weeklyExpense[i],
                                    color: AppColors.expense,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Budgets & Savings Progress Row
                Row(
                  children: [
                    // Budget Card
                    Expanded(
                      child: AppCard(
                        onTap: () => context.go('/budgets'),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Budget',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                                  ),
                                ),
                                const Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.secondary),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${((data.budgetSummary['percentage'] ?? 0) * 100).toStringAsFixed(0)}% used',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (data.budgetSummary['percentage'] ?? 0.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  (data.budgetSummary['percentage'] ?? 0) > 0.9
                                      ? AppColors.expense
                                      : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Savings Goal Card
                    Expanded(
                      child: AppCard(
                        onTap: () => context.push('/savings'),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Savings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                                  ),
                                ),
                                const Icon(Icons.savings_rounded, size: 18, color: AppColors.accent),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(data.savingsProgressPct * 100).toStringAsFixed(0)}% goal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: data.savingsProgressPct,
                                minHeight: 6,
                                backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. Recent Transactions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (data.recentTransactions.isEmpty)
                  AppCard(
                    child: Center(
                      child: Text(
                        'No transactions recorded yet.',
                        style: TextStyle(
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.recentTransactions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final tx = data.recentTransactions[index];
                        final isIncome = tx.type == TransactionType.income;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CategoryIconWidget(category: tx.category),
                          title: Text(
                            tx.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormatter.formatRelative(tx.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                            ),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(
                              tx.amount,
                              currencyCode: settings.currencyCode,
                              symbol: settings.currencySymbol,
                              hideBalance: settings.hideBalance,
                              showSign: true,
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isIncome ? AppColors.income : AppColors.expense,
                            ),
                          ),
                          onTap: () => context.push('/transactions/detail/${tx.id}'),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  double _calculateMaxBar(List<double> inList, List<double> outList) {
    double maxVal = 100.0;
    for (final v in inList) {
      if (v > maxVal) maxVal = v;
    }
    for (final v in outList) {
      if (v > maxVal) maxVal = v;
    }
    return maxVal * 1.2;
  }
}

