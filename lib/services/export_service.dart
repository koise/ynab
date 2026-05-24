import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ExportService {
  // Generate CSV string
  static String generateCSV({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    final List<List<dynamic>> rows = [
      ['Date', 'Type', 'Category', 'Account', 'Amount', 'Note']
    ];

    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

    for (var transaction in transactions) {
      final dateStr = dateFormatter.format(transaction.date);
      final typeStr = transaction.type.label;

      final categoryName = categories
          .firstWhere((c) => c.id == transaction.categoryId,
              orElse: () => const Category(id: '', name: 'Unknown', icon: '', color: '', type: CategoryType.expense))
          .name;

      final accountName = accounts
          .firstWhere((a) => a.id == transaction.accountId,
              orElse: () => Account(id: '', name: 'Unknown', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now()))
          .name;

      var accountStr = accountName;
      if (transaction.type == TransactionType.transfer && transaction.toAccountId != null) {
        final toAccountName = accounts
            .firstWhere((a) => a.id == transaction.toAccountId,
                orElse: () => Account(id: '', name: 'Unknown', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now()))
            .name;
        accountStr = '$accountName -> $toAccountName';
      }

      final amountStr = transaction.amount.toStringAsFixed(2);
      final noteStr = transaction.note ?? '';

      rows.add([dateStr, typeStr, categoryName, accountStr, amountStr, noteStr]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // Generate PDF document
  static Future<Uint8List> generatePDF({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    required String currencySymbol,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    final double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Transaction Report',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  if (startDate != null && endDate != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 8),
                      child: pw.Text(
                        '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}',
                        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Income', style: const pw.TextStyle(color: PdfColors.grey700)),
                    pw.Text(
                      '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Expenses', style: const pw.TextStyle(color: PdfColors.grey700)),
                    pw.Text(
                      '$currencySymbol${totalExpense.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // Table of Transactions
            pw.Table.fromTextArray(
              headers: ['Date', 'Type', 'Category', 'Account', 'Amount'],
              data: List<List<String>>.generate(transactions.length, (index) {
                final transaction = transactions[index];
                final dateStr = dateFormatter.format(transaction.date);
                final typeStr = transaction.type.label;

                final categoryName = categories
                    .firstWhere((c) => c.id == transaction.categoryId,
                        orElse: () => const Category(id: '', name: 'Unknown', icon: '', color: '', type: CategoryType.expense))
                    .name;

                final accountName = accounts
                    .firstWhere((a) => a.id == transaction.accountId,
                        orElse: () => Account(id: '', name: 'Unknown', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now()))
                    .name;

                var accountStr = accountName;
                if (transaction.type == TransactionType.transfer && transaction.toAccountId != null) {
                  final toAccountName = accounts
                      .firstWhere((a) => a.id == transaction.toAccountId,
                          orElse: () => Account(id: '', name: 'Unknown', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now()))
                      .name;
                  accountStr = '$accountName -> $toAccountName';
                }

                final amountPrefix = transaction.type == TransactionType.income
                    ? '+'
                    : (transaction.type == TransactionType.expense ? '-' : '');
                final amountStr = '$amountPrefix$currencySymbol${transaction.amount.toStringAsFixed(2)}';

                return [dateStr, typeStr, categoryName, accountStr, amountStr];
              }),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Share CSV or PDF file
  static Future<void> shareFile({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$filename');
    await tempFile.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: mimeType)],
      subject: filename,
    );
  }
}
