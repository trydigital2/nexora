import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../models/ai_insight.dart';
import '../providers/ai_provider.dart';

class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiState = ref.watch(aiProvider);
    final insights = aiState.insights;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('AI Smart Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(aiProvider.notifier).refreshInsights();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insights refreshed from latest transactions')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: insights.isEmpty
            ? EmptyStateView(
                icon: Icons.auto_awesome_rounded,
                title: 'No Active Insights',
                message: 'Add more transactions and category budgets to allow NEXORA to spot financial patterns.',
                buttonText: 'Add Transaction',
                onButtonPressed: () => context.push('/transactions/new'),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.read(aiProvider.notifier).refreshInsights();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: insights.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final insight = insights[index];
                    return _insightCard(context, insight, isDark);
                  },
                ),
              ),
      ),
    );
  }

  Widget _insightCard(BuildContext context, AiInsightModel insight, bool isDark) {
    Color typeColor;
    IconData icon;

    switch (insight.type) {
      case InsightType.anomaly:
        typeColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case InsightType.comparison:
        typeColor = AppColors.secondary;
        icon = Icons.compare_arrows_rounded;
        break;
      case InsightType.budgetWarning:
        typeColor = AppColors.expense;
        icon = Icons.error_outline_rounded;
        break;
      case InsightType.savingTip:
        typeColor = AppColors.accent;
        icon = Icons.savings_outlined;
        break;
      case InsightType.summary:
        typeColor = const Color(0xFF38BDF8);
        icon = Icons.insights_rounded;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      border: Border.all(
        color: typeColor.withValues(alpha: 0.35),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.type.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: typeColor,
                      ),
                    ),
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 12, color: AppColors.warning),
                    Text(
                      '${(insight.score * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (insight.actionLabel != null && insight.actionRoute != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(insight.actionRoute!),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  insight.actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
