class FinancialSummary {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double totalSavings;
  final double savingsRate;
  final double netCashFlow;

  const FinancialSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.totalSavings,
    required this.savingsRate,
    required this.netCashFlow,
  });

  factory FinancialSummary.empty() {
    return const FinancialSummary(
      totalBalance: 0,
      monthlyIncome: 0,
      monthlyExpenses: 0,
      totalSavings: 0,
      savingsRate: 0,
      netCashFlow: 0,
    );
  }
}

