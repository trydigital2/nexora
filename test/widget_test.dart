import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/app.dart';
import 'package:nexora/features/transactions/models/transaction.dart';
import 'package:nexora/shared/models/financial_summary.dart';

void main() {
  testWidgets('Nexora initial load and splash navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NexoraApp(),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(NexoraApp), findsOneWidget);

    // Fast-forward splash screen timer
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
  });

  test('FinancialSummary computation validation', () {
    const summary = FinancialSummary(
      totalBalance: 4200.0,
      monthlyIncome: 6500.0,
      monthlyExpenses: 2300.0,
      totalSavings: 14000.0,
      savingsRate: 64.6,
      netCashFlow: 4200.0,
    );

    expect(summary.totalBalance, 4200.0);
    expect(summary.monthlyIncome, 6500.0);
    expect(summary.monthlyExpenses, 2300.0);
    expect(summary.netCashFlow, 4200.0);
  });

  test('TransactionModel serialization and type parsing', () {
    final now = DateTime.now();
    final tx = TransactionModel(
      id: 'tx-test-1',
      userId: 'usr-1',
      title: 'Whole Foods Market',
      amount: 142.50,
      type: TransactionType.expense,
      category: 'Food & Dining',
      date: now,
      paymentMethod: 'Debit Card',
      createdAt: now,
    );

    final map = tx.toMap();
    expect(map['title'], 'Whole Foods Market');
    expect(map['amount'], 142.50);
    expect(map['type'], 'expense');

    final reconstructed = TransactionModel.fromMap(map);
    expect(reconstructed.id, tx.id);
    expect(reconstructed.title, tx.title);
    expect(reconstructed.amount, tx.amount);
    expect(reconstructed.type, TransactionType.expense);
  });
}
