import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/pdf_service.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  const ReportsScreen(
      {super.key, required this.familyId, required this.familyName});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _txnService = TransactionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  String _period = 'this_month'; // this_month | last_month | custom
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  double _income = 0;
  double _expense = 0;
  Map<String, double> _catBreakdown = {};
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _setPeriod(String p) {
    final now = DateTime.now();
    setState(() {
      _period = p;
      if (p == 'this_month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = now;
      } else if (p == 'last_month') {
        _fromDate = DateTime(now.year, now.month - 1, 1);
        _toDate = DateTime(now.year, now.month, 0);
      }
    });
    if (p != 'custom') _load();
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
        _period = 'custom';
      });
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final income = await _txnService.getTotalIncome(
          widget.familyId, _fromDate, _toDate);
      final expense = await _txnService.getTotalExpense(
          widget.familyId, _fromDate, _toDate);
      final txns = await _txnService.getTransactions(
          familyId: widget.familyId,
          fromDate: _fromDate,
          toDate: _toDate);
      final catMap = await _txnService.getExpenseByCategory(
          familyId: widget.familyId,
          fromDate: _fromDate,
          toDate: _toDate);

      if (mounted) {
        setState(() {
          _income = income;
          _expense = expense;
          _transactions = txns;
          _catBreakdown = catMap;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await PdfService.generateReport(
        familyName: widget.familyName,
        fromDate: _fromDate,
        toDate: _toDate,
        transactions: _transactions,
      );
      final filename =
          'family_report_${DateFormat('MMMyyyy').format(_fromDate)}.pdf';
      await PdfService.shareReport(bytes, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generation failed: $e'),
            backgroundColor: AppTheme.expenseColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  static const _colors = [
    Color(0xFFE65100), Color(0xFF1565C0), Color(0xFFAD1457),
    Color(0xFF4527A0), Color(0xFF2E7D32), Color(0xFF00695C),
    Color(0xFFF57F17), Color(0xFF4E342E), Color(0xFFBF360C),
    Color(0xFF546E7A),
  ];

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;
    final entries = _catBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          _pdfLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Generate PDF',
                  onPressed: _generatePdf,
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Period selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Period',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _PeriodChip(
                                    label: 'This Month',
                                    selected: _period == 'this_month',
                                    onTap: () => _setPeriod('this_month')),
                                _PeriodChip(
                                    label: 'Last Month',
                                    selected: _period == 'last_month',
                                    onTap: () => _setPeriod('last_month')),
                                _PeriodChip(
                                    label: 'Custom Range',
                                    selected: _period == 'custom',
                                    onTap: _pickCustomRange),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(_fromDate)} — ${DateFormat('dd MMM yyyy').format(_toDate)}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Total Income',
                            amount: _income,
                            color: AppTheme.incomeColor,
                            icon: Icons.arrow_upward,
                            currency: _currency,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Total Expenses',
                            amount: _expense,
                            color: AppTheme.expenseColor,
                            icon: Icons.arrow_downward,
                            currency: _currency,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      label: 'Net Balance',
                      amount: balance,
                      color: balance >= 0
                          ? AppTheme.primary
                          : AppTheme.expenseColor,
                      icon: Icons.account_balance_wallet_outlined,
                      currency: _currency,
                    ),
                    const SizedBox(height: 20),
                    // Category breakdown
                    if (entries.isNotEmpty) ...[
                      const _SectionHeader('Expense by Category'),
                      const SizedBox(height: 8),
                      ...entries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final pct = _expense > 0 ? e.value / _expense : 0.0;
                        return _CategoryRow(
                          name: e.key,
                          amount: e.value,
                          pct: pct,
                          color: _colors[i % _colors.length],
                          currency: _currency,
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                    // Transaction list
                    const _SectionHeader('All Transactions'),
                    const SizedBox(height: 8),
                    if (_transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No transactions in this period',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ),
                      )
                    else
                      ..._transactions.map((t) {
                        final isIncome = t.isIncome;
                        final color = isIncome
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withOpacity(0.12),
                              child: Icon(
                                AppTheme.getIcon(t.categoryIconName),
                                color: color,
                                size: 16,
                              ),
                            ),
                            title: Text(t.displayCategory,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${DateFormat('dd MMM').format(t.date)} · ${t.memberDisplayName}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'} ${_currency.format(t.amount)}',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    // Generate PDF button
                    ElevatedButton.icon(
                      onPressed: _pdfLoading ? null : _generatePdf,
                      icon: _pdfLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Generate PDF Report'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currency;

  const _SummaryCard(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    currency.format(amount),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final double pct;
  final Color color;
  final NumberFormat currency;

  const _CategoryRow(
      {required this.name,
      required this.amount,
      required this.pct,
      required this.color,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Text(
                  currency.format(amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.expenseColor),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${(pct * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary));
  }
}
