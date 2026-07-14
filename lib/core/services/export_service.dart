import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../features/transaction/domain/entities/transaction.dart';
import '../enums/transaction_type.dart';

class ExportService {
  const ExportService._();

  static Future<void> exportTransactionsToCsv(List<Transaction> transactions) async {
    final headers = ['Date', 'Category', 'Type', 'Amount', 'Note'];
    final rows = transactions.map((tx) {
      return [
        tx.transactionDate.toLocal().toString().split(' ')[0],
        tx.category.name,
        tx.type.name.toUpperCase(),
        tx.amount.toStringAsFixed(2),
        tx.note ?? '',
      ];
    }).toList();

    final buffer = StringBuffer();
    // Write headers
    buffer.writeln(headers.map((h) => '"$h"').join(','));
    // Write rows
    for (final row in rows) {
      buffer.writeln(row.map((val) => '"$val"').join(','));
    }
    final csvContent = buffer.toString();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/transactions_export.csv');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported Transactions (CSV)',
    );
  }

  static Future<void> exportTransactionsToPdf(
    List<Transaction> transactions,
    String currencySymbol,
    String userName,
    String userEmail,
  ) async {
    final pdf = pw.Document();
    final currencyText = currencySymbol == '₹' ? 'Rs. ' : '$currencySymbol ';

    // Compute totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FinTrack Statement',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().split(' ')[0],
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Account Details Group
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Account Details',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Name: ', style: pw.TextStyle(fontSize: 10)),
                            pw.Text(userName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text('Email: ', style: pw.TextStyle(fontSize: 10)),
                            pw.Text(userEmail, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    pw.Text(
                      'Created via FinTrack App',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Summary Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfSummaryCol('Total Income', totalIncome, PdfColors.green, currencyText),
                  _pdfSummaryCol('Total Expense', totalExpense, PdfColors.red, currencyText),
                  _pdfSummaryCol('Net Balance', netBalance, netBalance >= 0 ? PdfColors.green : PdfColors.red, currencyText),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Type', 'Amount', 'Note'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight,
              },
              data: transactions.map((tx) {
                final dateStr = tx.transactionDate.toLocal().toString().split(' ')[0];
                final sign = tx.type == TransactionType.income ? '+' : '-';
                return [
                  dateStr,
                  tx.category.name,
                  tx.type.name.toUpperCase(),
                  '$sign$currencyText${tx.amount.toStringAsFixed(0)}',
                  tx.note ?? '',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Want to organize your own budgets, subscriptions, and savings?',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.brown),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Download FinTrack App today on Android & iOS to secure your financial future!',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/transactions_statement.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported Transactions (PDF)',
    );
  }

  static pw.Widget _pdfSummaryCol(
    String title,
    double amount,
    PdfColor color,
    String currencyText,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          '$currencyText${amount.toStringAsFixed(0)}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
