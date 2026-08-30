import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

class PdfService {
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static Future<Uint8List> generateReport({
    required String familyName,
    required DateTime fromDate,
    required DateTime toDate,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
        italic: await PdfGoogleFonts.robotoItalic(),
      ),
    );

    // Calculations
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryTotals = {};

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        final cat = t.displayCategory;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    // Sort categories by amount desc
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort transactions by date desc
    final sortedTxns = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(familyName, fromDate, toDate),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _summarySection(totalIncome, totalExpense, balance),
          pw.SizedBox(height: 20),
          if (sortedCategories.isNotEmpty) ...[
            _sectionTitle('Expense by Category'),
            pw.SizedBox(height: 8),
            _categoryTable(sortedCategories, totalExpense),
            pw.SizedBox(height: 20),
          ],
          _sectionTitle('Transaction Details'),
          pw.SizedBox(height: 8),
          if (sortedTxns.isEmpty)
            pw.Text('No transactions found for this period.',
                style: pw.TextStyle(color: PdfColors.grey600))
          else
            _transactionTable(sortedTxns),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      String familyName, DateTime fromDate, DateTime toDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$familyName — Family Finance Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Period: ${_dateFormat.format(fromDate)} to ${_dateFormat.format(toDate)}',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            'Generated: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _summarySection(
      double income, double expense, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Income', income, PdfColors.green800),
          _summaryItem('Total Expenses', expense, PdfColors.red800),
          _summaryItem(
              'Net Balance', balance, balance >= 0 ? PdfColors.blue800 : PdfColors.red800),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label,
            style:
                const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          _currency.format(value),
          style: pw.TextStyle(
              fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
      child: pw.Text(
        title,
        style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _categoryTable(
      List<MapEntry<String, double>> entries, double total) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Category'),
            _tableHeader('Amount'),
            _tableHeader('% of Total'),
          ],
        ),
        ...entries.map((e) {
          final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
          return pw.TableRow(children: [
            _tableCell(e.key),
            _tableCell(_currency.format(e.value), align: pw.TextAlign.right),
            _tableCell('$pct%', align: pw.TextAlign.center),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _transactionTable(List<TransactionModel> txns) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Date'),
            _tableHeader('Category'),
            _tableHeader('Member'),
            _tableHeader('Description'),
            _tableHeader('Amount'),
            _tableHeader('Type'),
          ],
        ),
        ...txns.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final bg = i.isEven ? PdfColors.white : PdfColors.grey50;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _tableCell(DateFormat('dd/MM/yy').format(t.date)),
              _tableCell(t.displayCategory),
              _tableCell(t.memberDisplayName),
              _tableCell(t.description ?? '—'),
              _tableCell(
                _currency.format(t.amount),
                align: pw.TextAlign.right,
                color: t.isIncome ? PdfColors.green800 : PdfColors.red800,
              ),
              _tableCell(
                t.isIncome ? 'IN' : 'OUT',
                align: pw.TextAlign.center,
                color: t.isIncome ? PdfColors.green800 : PdfColors.red800,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800)),
    );
  }

  static pw.Widget _tableCell(String text,
      {pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
            fontSize: 9,
            color: color ?? PdfColors.grey900),
      ),
    );
  }

  /// Share/print the PDF on all platforms.
  static Future<void> shareReport(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// Preview PDF (browser print dialog on web, native on mobile).
  static Future<void> previewReport(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
