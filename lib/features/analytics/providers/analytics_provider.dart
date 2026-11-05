import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';

enum AnalyticsTimeframe { weekly, monthly, yearly }

class AnalyticsData {
  final AnalyticsTimeframe timeframe;
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;
  final Map<String, double> categoryDistribution;
  final List<ChartBarPoint> barChartPoints;
  final List<double> trendPoints;

  const AnalyticsData({
    required this.timeframe,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
    required this.categoryDistribution,
    required this.barChartPoints,
    required this.trendPoints,
  });
}

class ChartBarPoint {
  final String label;
  final double income;
  final double expense;

  const ChartBarPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

final analyticsTimeframeProvider = StateProvider<AnalyticsTimeframe>((ref) {
  return AnalyticsTimeframe.monthly;
});

final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  final timeframe = ref.watch(analyticsTimeframeProvider);
  final txState = ref.watch(transactionProvider);
  final now = DateTime.now();

  List<TransactionModel> relevantTx;
  List<ChartBarPoint> barPoints = [];

  switch (timeframe) {
    case AnalyticsTimeframe.weekly:
      final weekStart = now.subtract(const Duration(days: 6));
      relevantTx = txState.transactions.where((t) => t.date.isAfter(weekStart.subtract(const Duration(seconds: 1)))).toList();

      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 0; i < 7; i++) {
        final target = now.subtract(Duration(days: 6 - i));
        final dayTx = relevantTx.where((t) => t.date.day == target.day && t.date.month == target.month);
        final inc = dayTx.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
        final exp = dayTx.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
        barPoints.add(ChartBarPoint(label: days[target.weekday - 1], income: inc, expense: exp));
      }
      break;

    case AnalyticsTimeframe.monthly:
      relevantTx = txState.transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
      // Divide current month into 4 weeks
      for (int w = 1; w <= 4; w++) {
        final weekTx = relevantTx.where((t) {
          final weekNum = ((t.date.day - 1) ~/ 7) + 1;
          return weekNum == w || (w == 4 && weekNum >= 4);
        });
        final inc = weekTx.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
        final exp = weekTx.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
        barPoints.add(ChartBarPoint(label: 'Wk $w', income: inc, expense: exp));
      }
      break;

    case AnalyticsTimeframe.yearly:
      relevantTx = txState.transactions.where((t) => t.date.year == now.year).toList();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int m = 1; m <= 12; m++) {
        final mTx = relevantTx.where((t) => t.date.month == m);
        final inc = mTx.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
        final exp = mTx.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
        barPoints.add(ChartBarPoint(label: months[m - 1], income: inc, expense: exp));
      }
      break;
  }

  final totalInc = relevantTx.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
  final totalExp = relevantTx.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
  final net = totalInc - totalExp;
  final rate = totalInc > 0 ? ((net / totalInc) * 100).clamp(-100.0, 100.0) : 0.0;

  final catDist = <String, double>{};
  for (final t in relevantTx.where((t) => t.type == TransactionType.expense)) {
    catDist[t.category] = (catDist[t.category] ?? 0.0) + t.amount;
  }

  // Trend points
  final trend = barPoints.map((p) => p.expense).toList();

  return AnalyticsData(
    timeframe: timeframe,
    totalIncome: totalInc,
    totalExpenses: totalExp,
    netSavings: net,
    savingsRate: rate,
    categoryDistribution: catDist,
    barChartPoints: barPoints,
    trendPoints: trend,
  );
});

