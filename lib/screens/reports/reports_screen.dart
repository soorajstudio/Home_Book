import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/pdf_service.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  const ReportsScreen({super.key, required this.familyId, required this.familyName});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _txnService = TransactionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  String _period = 'this_month';
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
          colorScheme: const ColorScheme.light(primary: AppTheme.coral),
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
      final income =
          await _txnService.getTotalIncome(widget.familyId, _fromDate, _toDate);
      final expense =
          await _txnService.getTotalExpense(widget.familyId, _fromDate, _toDate);
      final txns = await _txnService.getTransactions(
          familyId: widget.familyId, fromDate: _fromDate, toDate: _toDate);
      final catMap = await _txnService.getExpenseByCategory(
          familyId: widget.familyId, fromDate: _fromDate, toDate: _toDate);

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
      final filename = 'family_report_${DateFormat('MMMyyyy').format(_fromDate)}.pdf';
      await PdfService.shareReport(bytes, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generation failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;
    final entries = _catBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const colors = AppTheme.chartPalette;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          _pdfLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Export PDF',
                  onPressed: _generatePdf,
                ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4)))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.coral,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Period', style: AppTheme.eyebrow),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PeriodChip(
                            label: 'This month',
                            selected: _period == 'this_month',
                            onTap: () => _setPeriod('this_month')),
                        _PeriodChip(
                            label: 'Last month',
                            selected: _period == 'last_month',
                            onTap: () => _setPeriod('last_month')),
                        _PeriodChip(
                            label: 'Custom range',
                            selected: _period == 'custom',
                            onTap: _pickCustomRange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(_fromDate)} — ${DateFormat('dd MMM yyyy').format(_toDate)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Income',
                            amount: _income,
                            color: AppTheme.teal,
                            bg: AppTheme.tealSoft,
                            icon: Icons.arrow_downward_rounded,
                            currency: _currency,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Expenses',
                            amount: _expense,
                            color: AppTheme.rose,
                            bg: AppTheme.roseSoft,
                            icon: Icons.arrow_upward_rounded,
                            currency: _currency,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      label: 'Net balance',
                      amount: balance,
                      color: balance >= 0 ? AppTheme.coralDeep : AppTheme.rose,
                      bg: balance >= 0 ? AppTheme.coralSoft : AppTheme.roseSoft,
                      icon: Icons.account_balance_wallet_outlined,
                      currency: _currency,
                      wide: true,
                    ),
                    const SizedBox(height: 24),
                    if (entries.isNotEmpty) ...[
                      const Text('Expense by category', style: AppTheme.sectionTitle),
                      const SizedBox(height: 10),
                      ...entries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final pct = _expense > 0 ? e.value / _expense : 0.0;
                        return _CategoryRow(
                          name: e.key,
                          amount: e.value,
                          pct: pct,
                          color: colors[i % colors.length],
                          currency: _currency,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                    const Text('All transactions', style: AppTheme.sectionTitle),
                    const SizedBox(height: 10),
                    if (_transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: AppTheme.sand.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: const Center(
                          child: Text('No transactions in this period',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                      )
                    else
                      ..._transactions.map((t) {
                        final isIncome = t.isIncome;
                        final color = isIncome ? AppTheme.teal : AppTheme.rose;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(AppTheme.getIcon(t.categoryIconName),
                                    color: color, size: 15),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.displayCategory,
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700)),
                                    Text(
                                      '${DateFormat('dd MMM').format(t.date)} · ${t.memberDisplayName}',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '−'} ${_currency.format(t.amount)}',
                                style: TextStyle(
                                    color: color, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _pdfLoading ? null : _generatePdf,
                        icon: _pdfLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Export PDF report'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ink),
                      ),
                    ),
                    const SizedBox(height: 40),
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

  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.ink : AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: selected ? AppTheme.ink : AppTheme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Color bg;
  final IconData icon;
  final NumberFormat currency;
  final bool wide;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.bg,
    required this.icon,
    required this.currency,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  currency.format(amount),
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.moneyMedium.copyWith(color: color, fontSize: 17),
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
              Text(
                currency.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 13.5),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
