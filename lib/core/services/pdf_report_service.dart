import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/transactions/models/transaction.dart';

class PdfReportService {
  static Future<Uint8List> generateFinancialReport({
    required String userName,
    required String currencyCode,
    required String currencySymbol,
    required double totalIncome,
    required double totalExpenses,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, double> categoryBreakdown,
    required String periodName,
  }) async {
    final pdf = pw.Document();

    final dateFormatted = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final savingsRate = totalIncome > 0
        ? (((totalIncome - totalExpenses) / totalIncome) * 100).clamp(0, 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NEXORA',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#10172A'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Your Money. Your Intelligence.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#7257E8'),
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Statement for: $userName',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#334155'),
                      ),
                    ),
                    pw.Text(
                      'Period: $periodName',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#10172A'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        'FINANCIAL REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Date: $dateFormatted',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Currency: $currencyCode ($currencySymbol)',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: PdfColor.fromHex('#CBD5E1')),
            pw.SizedBox(height: 14),

            // Summary Cards
            pw.Row(
              children: [
                _buildMetricCard(
                  'TOTAL INCOME',
                  '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                  PdfColor.fromHex('#10B981'),
                ),
                pw.SizedBox(width: 10),
                _buildMetricCard(
                  'TOTAL EXPENSES',
                  '$currencySymbol${totalExpenses.toStringAsFixed(2)}',
                  PdfColor.fromHex('#EF4444'),
                ),
                pw.SizedBox(width: 10),
                _buildMetricCard(
                  'NET SAVINGS',
                  '$currencySymbol${netBalance.toStringAsFixed(2)}',
                  PdfColor.fromHex('#7257E8'),
                ),
                pw.SizedBox(width: 10),
                _buildMetricCard(
                  'SAVINGS RATE',
                  '$savingsRate%',
                  PdfColor.fromHex('#35C99A'),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Category Breakdown Section
            pw.Text(
              'EXPENSE BREAKDOWN BY CATEGORY',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#10172A'),
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0')),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                  children: [
                    _tableCell('Category', isHeader: true),
                    _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('% of Total', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...categoryBreakdown.entries.map((entry) {
                  final pct = totalExpenses > 0
                      ? ((entry.value / totalExpenses) * 100).toStringAsFixed(1)
                      : '0.0';
                  return pw.TableRow(
                    children: [
                      _tableCell(entry.key),
                      _tableCell('$currencySymbol${entry.value.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      _tableCell('$pct%', align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),

            // Recent Transactions Table
            pw.Text(
              'TRANSACTION RECORD',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#10172A'),
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0')),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                  children: [
                    _tableCell('Date', isHeader: true),
                    _tableCell('Description', isHeader: true),
                    _tableCell('Category', isHeader: true),
                    _tableCell('Type', isHeader: true),
                    _tableCell('Payment Method', isHeader: true),
                    _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...transactions.take(30).map((tx) {
                  final isIncome = tx.type == TransactionType.income;
                  final formattedDate = DateFormat('yyyy-MM-dd').format(tx.date);
                  final formattedAmount = '${isIncome ? "+" : "-"}$currencySymbol${tx.amount.toStringAsFixed(2)}';

                  return pw.TableRow(
                    children: [
                      _tableCell(formattedDate),
                      _tableCell(tx.title),
                      _tableCell(tx.category),
                      _tableCell(isIncome ? 'Income' : 'Expense'),
                      _tableCell(tx.paymentMethod),
                      _tableCell(
                        formattedAmount,
                        align: pw.TextAlign.right,
                        textColor: isIncome
                            ? PdfColor.fromHex('#10B981')
                            : PdfColor.fromHex('#EF4444'),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
            pw.SizedBox(height: 8),

            // Disclaimer Footer
            pw.Text(
              'Notice: This statement was generated automatically by NEXORA. AI-generated insights and figures are provided for educational and personal financial tracking purposes only and do not constitute professional or certified financial advice.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          color: PdfColor.fromHex('#F8FAFC'),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColor.fromHex('#10172A') : PdfColor.fromHex('#334155')),
        ),
      ),
    );
  }

  static Future<void> shareOrPrintReport(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
