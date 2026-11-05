import 'package:flutter/foundation.dart';
import '../../features/ai_assistant/models/ai_insight.dart';
import '../../features/budgets/models/budget.dart';
import '../../features/transactions/models/transaction.dart';
import '../../features/savings/models/savings_goal.dart';
import 'supabase_service.dart';

class AiService {
  static const String disclaimerText =
      'Educational suggestions only. Not guaranteed financial or investment advice.';

  /// Generates conversational answers based on the user's live financial data
  static Future<Map<String, String>> askAssistant({
    required String question,
    required double monthlyIncome,
    required double monthlyExpenses,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<SavingsGoalModel> savingsGoals,
    required String currencySymbol,
  }) async {
    // 1. Try Remote Supabase Edge Function if connected
    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        final session = client.auth.currentSession;
        if (session != null) {
          final topCategories = _computeTopCategories(transactions);
          final response = await client.functions.invoke(
            'ai-advisor',
            body: {
              'prompt': question,
              'context': {
                'monthlyIncome': monthlyIncome,
                'monthlyExpenses': monthlyExpenses,
                'topCategories': topCategories,
                'budgetAlerts': budgets.where((b) => b.isOverBudget || b.isNearLimit).map((b) => b.category).toList(),
                'recentTransactionsSummary': transactions.take(5).map((t) => '${t.title}: ${t.amount}').join(', '),
              },
            },
          );

          if (response.status == 200 && response.data != null) {
            final data = response.data;
            return {
              'reply': data['reply']?.toString() ?? 'Analysis completed.',
              'disclaimer': data['disclaimer']?.toString() ?? disclaimerText,
            };
          }
        }
      } catch (e) {
        debugPrint('Edge function error, continuing with local financial intelligence: $e');
      }
    }

    // 2. Local Intelligent Financial AI Engine (Context-grounded)
    final reply = _generateLocalAiResponse(
      question: question.toLowerCase().trim(),
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      currencySymbol: currencySymbol,
    );

    return {
      'reply': reply,
      'disclaimer': disclaimerText,
    };
  }

  /// Evaluates real transactions to produce Smart Insights (Anomalies, Comparisons, Budget warnings)
  static List<AiInsightModel> generateInsights({
    required String userId,
    required double monthlyIncome,
    required double monthlyExpenses,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required String currencySymbol,
  }) {
    final List<AiInsightModel> list = [];
    final now = DateTime.now();

    // 1. Check Budgets for overspending / near limit
    for (final b in budgets) {
      if (b.isOverBudget) {
        final over = b.spentAmount - b.amount;
        list.add(AiInsightModel(
          id: 'insight-budget-over-${b.category}',
          userId: userId,
          type: InsightType.budgetWarning,
          title: 'Budget Exceeded in ${b.category}',
          message:
              'You have exceeded your ${b.category} budget by $currencySymbol${over.toStringAsFixed(2)}. Consider pausing non-essential purchases in this category.',
          score: 0.98,
          actionLabel: 'Adjust Budget',
          actionRoute: '/budgets',
          createdAt: now,
        ));
      } else if (b.isNearLimit) {
        final pct = (b.progressPercentage * 100).toStringAsFixed(0);
        list.add(AiInsightModel(
          id: 'insight-budget-near-${b.category}',
          userId: userId,
          type: InsightType.budgetWarning,
          title: 'Approaching Limit: ${b.category}',
          message:
              'You have utilized $pct% of your $currencySymbol${b.amount.toStringAsFixed(0)} allocation for ${b.category}. Only $currencySymbol${b.remainingAmount.toStringAsFixed(2)} remains this month.',
          score: 0.88,
          actionLabel: 'View Budget',
          actionRoute: '/budgets',
          createdAt: now,
        ));
      }
    }

    // 2. Spending Category Comparisons & Anomaly
    final thisMonthExpenses = transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.month == now.month &&
        t.date.year == now.year);

    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final lastMonthExpenses = transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.month == lastMonth &&
        t.date.year == lastMonthYear);

    final thisMonthCategories = <String, double>{};
    for (final t in thisMonthExpenses) {
      thisMonthCategories[t.category] = (thisMonthCategories[t.category] ?? 0) + t.amount;
    }

    final lastMonthCategories = <String, double>{};
    for (final t in lastMonthExpenses) {
      lastMonthCategories[t.category] = (lastMonthCategories[t.category] ?? 0) + t.amount;
    }

    // Compare each category
    thisMonthCategories.forEach((cat, currentAmount) {
      final prevAmount = lastMonthCategories[cat] ?? 0;
      if (prevAmount > 0) {
        final diff = currentAmount - prevAmount;
        final pctChange = ((diff / prevAmount) * 100).round();
        if (pctChange >= 15) {
          list.add(AiInsightModel(
            id: 'insight-comparison-$cat',
            userId: userId,
            type: InsightType.comparison,
            title: '$cat Spending Increased',
            message:
                'You spent $pctChange% more on $cat this month ($currencySymbol${currentAmount.toStringAsFixed(2)}) compared to last month ($currencySymbol${prevAmount.toStringAsFixed(2)}).',
            score: 0.90,
            actionLabel: 'View Transactions',
            actionRoute: '/transactions',
            createdAt: now,
          ));
        } else if (pctChange <= -15) {
          list.add(AiInsightModel(
            id: 'insight-savings-$cat',
            userId: userId,
            type: InsightType.savingTip,
            title: 'Great Progress in $cat',
            message:
                'You reduced your $cat expenses by ${pctChange.abs()}% compared to last month, saving approximately $currencySymbol${(prevAmount - currentAmount).toStringAsFixed(2)}!',
            score: 0.92,
            actionLabel: 'Analyze',
            actionRoute: '/analytics',
            createdAt: now,
          ));
        }
      }
    });

    // 3. Overall Savings Opportunity / Rate Insight
    if (monthlyIncome > 0) {
      final savings = monthlyIncome - monthlyExpenses;
      final rate = ((savings / monthlyIncome) * 100).clamp(-100.0, 100.0);

      if (rate >= 25) {
        list.add(AiInsightModel(
          id: 'insight-high-savings',
          userId: userId,
          type: InsightType.summary,
          title: 'Strong Financial Health',
          message:
              'Your current savings rate is ${rate.toStringAsFixed(1)}% of your income. You are retaining $currencySymbol${savings.toStringAsFixed(2)} this month, well above the 20% benchmark.',
          score: 0.95,
          actionLabel: 'Add to Goals',
          actionRoute: '/savings',
          createdAt: now,
        ));
      } else if (rate < 10 && rate >= 0) {
        list.add(AiInsightModel(
          id: 'insight-low-savings',
          userId: userId,
          type: InsightType.anomaly,
          title: 'Savings Opportunity Detected',
          message:
              'Your net savings rate is ${rate.toStringAsFixed(1)}%. Reviewing recurring subscriptions and dining out could safely boost your monthly buffer by 8-12%.',
          score: 0.86,
          actionLabel: 'Review Bills',
          actionRoute: '/bills',
          createdAt: now,
        ));
      }
    }

    return list;
  }

  static String _generateLocalAiResponse({
    required String question,
    required double monthlyIncome,
    required double monthlyExpenses,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<SavingsGoalModel> savingsGoals,
    required String currencySymbol,
  }) {
    final topCategories = _computeTopCategories(transactions);
    final netSavings = monthlyIncome - monthlyExpenses;
    final savingsRate = monthlyIncome > 0
        ? ((netSavings / monthlyIncome) * 100).clamp(-100.0, 100.0).toStringAsFixed(1)
        : '0.0';

    // 1. "Where am I spending the most?" / "biggest expenses"
    if (question.contains('spending the most') ||
        question.contains('biggest') ||
        question.contains('most money') ||
        question.contains('highest')) {
      if (topCategories.isEmpty) {
        return 'You do not have enough expense transactions recorded this month to identify peak categories yet.';
      }
      final top = topCategories.first;
      final buffer = StringBuffer();
      buffer.writeln('Your highest spending category this month is **${top['category']}**, totaling **$currencySymbol${(top['amount'] as double).toStringAsFixed(2)}**.');
      if (topCategories.length > 1) {
        final second = topCategories[1];
        buffer.writeln('This is followed closely by **${second['category']}** at **$currencySymbol${(second['amount'] as double).toStringAsFixed(2)}**.');
      }
      buffer.writeln('Together, these represent your primary cash outflows. Optimizing here will have the highest immediate impact on your savings.');
      return buffer.toString();
    }

    // 2. "How can I save more?" / "saving tips" / "suggestions"
    if (question.contains('save more') ||
        question.contains('how to save') ||
        question.contains('saving suggestions') ||
        question.contains('cut cost')) {
      final top = topCategories.isNotEmpty ? topCategories.first['category'] : 'Dining & Entertainment';
      return 'Here are three high-impact ways tailored to your profile:\n\n'
          '1. **Benchmark $top**: Trimming just 10% off your largest category could free up $currencySymbol${((topCategories.isNotEmpty ? (topCategories.first['amount'] as double) * 0.1 : 120.0)).toStringAsFixed(2)} monthly.\n'
          '2. **Audit Recurring Subscriptions**: Review your active recurring bills to eliminate unused services.\n'
          '3. **Automate 50/30/20**: Route $currencySymbol${(monthlyIncome * 0.2).toStringAsFixed(0)} automatically on payday directly to your active savings goals.';
    }

    // 3. "Am I overspending?" / "over budget"
    if (question.contains('overspending') || question.contains('over budget') || question.contains('spending too much')) {
      final overBudgets = budgets.where((b) => b.isOverBudget).toList();
      if (overBudgets.isNotEmpty) {
        final names = overBudgets.map((b) => b.category).join(', ');
        return 'Yes, you are currently over budget in: **$names**.\n\n'
            'Your total expenses are $currencySymbol${monthlyExpenses.toStringAsFixed(2)} against an income of $currencySymbol${monthlyIncome.toStringAsFixed(2)}. Reallocating funds from under-budget categories will help keep your monthly balance positive.';
      } else if (monthlyExpenses > monthlyIncome && monthlyIncome > 0) {
        return 'Your total monthly expenses ($currencySymbol${monthlyExpenses.toStringAsFixed(2)}) exceed your recorded income ($currencySymbol${monthlyIncome.toStringAsFixed(2)}) by $currencySymbol${(monthlyExpenses - monthlyIncome).toStringAsFixed(2)}. It is recommended to reduce discretionary outlays this week.';
      } else {
        return 'Good news! You are **not overspending overall** this month. You have spent $currencySymbol${monthlyExpenses.toStringAsFixed(2)} out of your $currencySymbol${monthlyIncome.toStringAsFixed(2)} income, maintaining a healthy **$savingsRate%** savings rate.';
      }
    }

    // 4. "How much can I save this month?" / "savings capacity"
    if (question.contains('how much can i save') || question.contains('savings potential') || question.contains('can i save')) {
      if (netSavings > 0) {
        return 'Based on your current trajectory, you are on track to save **$currencySymbol${netSavings.toStringAsFixed(2)}** this month (a **$savingsRate%** savings rate).\n\n'
            'If you transfer this amount into your active savings goals (${savingsGoals.map((g) => g.title).take(2).join(", ")}), you will accelerate your target completion by weeks.';
      } else {
        return 'Currently your expenses equal or exceed your income for this period. To establish positive cash flow, consider setting category caps on your top discretionary areas.';
      }
    }

    // 5. General summary / Overview
    return 'Here is your real-time financial snapshot:\n\n'
        '• **Monthly Inflow**: $currencySymbol${monthlyIncome.toStringAsFixed(2)}\n'
        '• **Monthly Outflow**: $currencySymbol${monthlyExpenses.toStringAsFixed(2)}\n'
        '• **Net Cashflow**: $currencySymbol${netSavings.toStringAsFixed(2)} ($savingsRate%)\n'
        '• **Top Expense**: ${topCategories.isNotEmpty ? topCategories.first['category'] : "N/A"}\n\n'
        'Feel free to ask me to analyze specific categories, simulate budget limits, or inspect your savings velocity!';
  }

  static List<Map<String, dynamic>> _computeTopCategories(List<TransactionModel> txs) {
    final now = DateTime.now();
    final expenses = txs.where((t) =>
        t.type == TransactionType.expense &&
        t.date.month == now.month &&
        t.date.year == now.year);

    final map = <String, double>{};
    for (final t in expenses) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }

    final list = map.entries
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList();
    list.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return list;
  }
}
