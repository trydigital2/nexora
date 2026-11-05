import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../budgets/providers/budget_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../shared/models/financial_summary.dart';

class DashboardData {
  final FinancialSummary summary;
  final List<TransactionModel> recentTransactions;
  final Map<String, double> budgetSummary;
  final double savingsProgressPct;
  final String? spotlightSavingsGoalTitle;
  final double spotlightSavingsGoalProgress;
  final List<double> weeklyIncome;
  final List<double> weeklyExpense;

  const DashboardData({
    required this.summary,
    required this.recentTransactions,
    required this.budgetSummary,
    required this.savingsProgressPct,
    this.spotlightSavingsGoalTitle,
    this.spotlightSavingsGoalProgress = 0.0,
    required this.weeklyIncome,
    required this.weeklyExpense,
  });
}

final dashboardProvider = Provider<DashboardData>((ref) {
  final auth = ref.watch(authProvider);
  final txState = ref.watch(transactionProvider);
  final budgetSummary = ref.watch(totalBudgetSummaryProvider);
  final savingsState = ref.watch(savingsProvider);

  final monthlyIncome = txState.currentMonthIncome > 0
      ? txState.currentMonthIncome
      : (auth.user?.monthlyIncome ?? 6500.0);
  final monthlyExpenses = txState.currentMonthExpenses;
  final totalBalance = txState.totalBalance;
  final totalSavings = savingsState.totalSavings;
  final netCashFlow = monthlyIncome - monthlyExpenses;
  final savingsRate = monthlyIncome > 0
      ? ((netCashFlow / monthlyIncome) * 100).clamp(-100.0, 100.0)
      : 0.0;

  final summary = FinancialSummary(
    totalBalance: totalBalance,
    monthlyIncome: monthlyIncome,
    monthlyExpenses: monthlyExpenses,
    totalSavings: totalSavings,
    savingsRate: savingsRate,
    netCashFlow: netCashFlow,
  );

  final recent = txState.transactions.take(5).toList();

  // Savings spotlight
  final activeGoals = savingsState.goals.where((g) => !g.isCompleted).toList();
  final spotlightGoal = activeGoals.isNotEmpty ? activeGoals.first : null;

  // Chart data: 7 days flow simulation from current transactions
  final now = DateTime.now();
  final weeklyInc = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    return txState.transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  });

  final weeklyExp = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    return txState.transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  });

  return DashboardData(
    summary: summary,
    recentTransactions: recent,
    budgetSummary: budgetSummary,
    savingsProgressPct: savingsState.totalTarget > 0
        ? (savingsState.totalSavings / savingsState.totalTarget).clamp(0.0, 1.0)
        : 0.0,
    spotlightSavingsGoalTitle: spotlightGoal?.title,
    spotlightSavingsGoalProgress: spotlightGoal?.progressPercentage ?? 0.0,
    weeklyIncome: weeklyInc,
    weeklyExpense: weeklyExp,
  );
});

