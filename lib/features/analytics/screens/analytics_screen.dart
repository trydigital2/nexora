import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedPieIndex = -1;
  bool _isExporting = false;

  Future<void> _exportPdfReport() async {
    setState(() => _isExporting = true);
    try {
      final auth = ref.read(authProvider);
      final txState = ref.read(transactionProvider);
      final settings = ref.read(appSettingsProvider);
      final analytics = ref.read(analyticsDataProvider);

      final pdfBytes = await PdfReportService.generateFinancialReport(
        userName: auth.user?.fullName ?? 'Alex Morgan',
        currencyCode: settings.currencyCode,
        currencySymbol: settings.currencySymbol,
        totalIncome: analytics.totalIncome,
        totalExpenses: analytics.totalExpenses,
        netBalance: analytics.netSavings,
        transactions: txState.transactions,
        categoryBreakdown: analytics.categoryDistribution,
        periodName: analytics.timeframe.name.toUpperCase(),
      );

      await PdfReportService.shareOrPrintReport(
        pdfBytes,
        'NEXORA_Statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analytics = ref.watch(analyticsDataProvider);
    final settings = ref.watch(appSettingsProvider);
    final selectedTimeframe = ref.watch(analyticsTimeframeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Statement as PDF',
            onPressed: _isExporting ? null : _exportPdfReport,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe filter tabs (Weekly, Monthly, Yearly)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _timeframeTab(AnalyticsTimeframe.weekly, 'Weekly', selectedTimeframe),
                    _timeframeTab(AnalyticsTimeframe.monthly, 'Monthly', selectedTimeframe),
                    _timeframeTab(AnalyticsTimeframe.yearly, 'Yearly', selectedTimeframe),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Overview Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Cashflow',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.format(
                              analytics.netSavings,
                              symbol: settings.currencySymbol,
                              hideBalance: settings.hideBalance,
                              showSign: true,
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: analytics.netSavings >= 0 ? AppColors.income : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings Rate',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${analytics.savingsRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 1. Income vs Expense Bar Chart
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inflow vs Outflow',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                        Row(
                          children: [
                            _legendItem(AppColors.accent, 'Income'),
                            const SizedBox(width: 12),
                            _legendItem(AppColors.expense, 'Expenses'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _calcMaxY(analytics.barChartPoints),
                          barTouchData: BarTouchData(enabled: true),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < analytics.barChartPoints.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        analytics.barChartPoints[idx].label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(analytics.barChartPoints.length, (i) {
                            final point = analytics.barChartPoints[i];
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: point.income,
                                  color: AppColors.accent,
                                  width: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                BarChartRodData(
                                  toY: point.expense,
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

              // 2. Category Expense Breakdown (Pie Chart)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Spending Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (analytics.categoryDistribution.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No expense categories recorded in this timeframe.'),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex =
                                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: _buildPieSections(analytics.categoryDistribution),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Breakdown list
                      ...analytics.categoryDistribution.entries.map((e) {
                        final catItem = AppConstants.getCategory(e.key);
                        final pct = analytics.totalExpenses > 0
                            ? ((e.value / analytics.totalExpenses) * 100).toStringAsFixed(1)
                            : '0';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: catItem.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$pct% • ${CurrencyFormatter.format(e.value, symbol: settings.currencySymbol)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export statement CTA
              AppButton(
                text: 'Generate PDF Financial Statement',
                width: double.infinity,
                variant: AppButtonVariant.primary,
                icon: Icons.download_rounded,
                isLoading: _isExporting,
                onPressed: _exportPdfReport,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeframeTab(AnalyticsTimeframe tf, String label, AnalyticsTimeframe current) {
    final isSel = tf == current;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(analyticsTimeframeProvider.notifier).state = tf;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
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

  List<PieChartSectionData> _buildPieSections(Map<String, double> categories) {
    final entries = categories.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 48.0 : 40.0;
      final entry = entries[i];
      final catItem = AppConstants.getCategory(entry.key);

      return PieChartSectionData(
        color: catItem.color,
        value: entry.value,
        title: '',
        radius: radius,
      );
    });
  }

  double _calcMaxY(List<ChartBarPoint> points) {
    double m = 100.0;
    for (final p in points) {
      if (p.income > m) m = p.income;
      if (p.expense > m) m = p.expense;
    }
    return m * 1.25;
  }
}

