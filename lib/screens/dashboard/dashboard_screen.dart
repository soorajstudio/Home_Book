import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction_model.dart';
import '../transactions/add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  final bool isAdmin;

  const DashboardScreen({
    super.key,
    required this.familyId,
    required this.familyName,
    this.isAdmin = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _txnService = TransactionService();
  final _auth = AuthService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  DateTime _selectedMonth = DateTime.now();
  double _income = 0;
  double _expense = 0;
  List<TransactionModel> _recent = [];
  List<Map<String, double>> _monthlySummary = [];
  Map<String, double> _categoryBreakdown = {};
  bool _loading = true;
  String _greeting = 'Hello';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _auth.getProfile();
      final fn = profile?['full_name'] as String?;
      final un = profile?['username'] as String?;
      _username = (fn != null && fn.isNotEmpty) ? fn : (un ?? 'there');

      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      final income = await _txnService.getTotalIncome(
          widget.familyId, firstDay, lastDay);
      final expense = await _txnService.getTotalExpense(
          widget.familyId, firstDay, lastDay);
      final recent =
          await _txnService.getRecentTransactions(widget.familyId, 5);
      final summary =
          await _txnService.getMonthlySummary(widget.familyId, 6);
      final catBreakdown = await _txnService.getExpenseByCategory(
          familyId: widget.familyId, fromDate: firstDay, toDate: lastDay);

      if (mounted) {
        setState(() {
          _income = income;
          _expense = expense;
          _recent = recent;
          _monthlySummary = summary;
          _categoryBreakdown = catBreakdown;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    if (_selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month) {
      return;
    }
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: _loading
          ? const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.coral,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeroHeader(
                      greeting: _greeting,
                      username: _username,
                      familyName: widget.familyName,
                      month: _selectedMonth,
                      onPrev: _prevMonth,
                      onNext: _nextMonth,
                      income: _income,
                      expense: _expense,
                      balance: balance,
                      currency: _currency,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_categoryBreakdown.isNotEmpty) ...[
                            const Text('Spending by category',
                                style: AppTheme.sectionTitle),
                            const SizedBox(height: 12),
                            _CategoryPieChart(
                                data: _categoryBreakdown, currency: _currency),
                            const SizedBox(height: 24),
                          ],
                          if (_monthlySummary.isNotEmpty) ...[
                            const Text('Income vs expenses',
                                style: AppTheme.sectionTitle),
                            const SizedBox(height: 12),
                            _MonthlyStalkChart(
                                summary: _monthlySummary,
                                selectedMonth: _selectedMonth),
                            const SizedBox(height: 24),
                          ],
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent activity',
                                  style: AppTheme.sectionTitle),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_recent.isEmpty)
                            const _EmptyState(
                                message:
                                    'No transactions yet. Add your first one!'),
                          ..._recent
                              .map((t) => _TransactionTile(t: t, currency: _currency)),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: widget.isAdmin
          ? null
          : FloatingActionButton.extended(
              heroTag: 'dashboard_fab',
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTransactionScreen(familyId: widget.familyId),
                  ),
                );
                if (added == true) _loadData();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
    );
  }
}

/// Signature element: a dark ink hero panel that carries the greeting,
/// month switcher, and the balance itself in one continuous surface —
/// replacing the old blue AppBar + separate gradient card pairing.
class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String username;
  final String familyName;
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final double income;
  final double expense;
  final double balance;
  final NumberFormat currency;

  const _HeroHeader({
    required this.greeting,
    required this.username,
    required this.familyName,
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = month.year == DateTime.now().year &&
        month.month == DateTime.now().month;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.inkGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$greeting, $username',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(familyName,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12.5)),
                      ],
                    ),
                  ),
                  _MonthPill(month: month, isCurrentMonth: isCurrentMonth,
                      onPrev: onPrev, onNext: onNext),
                ],
              ),
              const SizedBox(height: 26),
              Text('Net balance',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              const SizedBox(height: 6),
              Text(
                currency.format(balance),
                style: AppTheme.moneyLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Income',
                      amount: income,
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF6FE0C9),
                      currency: currency,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: 'Expenses',
                      amount: expense,
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFFF9D85),
                      currency: currency,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPill extends StatelessWidget {
  final DateTime month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthPill(
      {required this.month,
      required this.isCurrentMonth,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillArrow(Icons.chevron_left_rounded, onPrev, true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              DateFormat('MMM yyyy').format(month),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          _pillArrow(Icons.chevron_right_rounded, isCurrentMonth ? null : onNext,
              !isCurrentMonth),
        ],
      ),
    );
  }

  Widget _pillArrow(IconData icon, VoidCallback? onTap, bool enabled) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final NumberFormat currency;

  const _StatChip(
      {required this.label,
      required this.amount,
      required this.icon,
      required this.color,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5)),
                Text(currency.format(amount),
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.moneySmall.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  final Map<String, double> data;
  final NumberFormat currency;

  const _CategoryPieChart({required this.data, required this.currency});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    const colors = AppTheme.chartPalette;
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, resp) {
                    if (resp?.touchedSection != null) {
                      setState(() =>
                          _touched = resp!.touchedSection!.touchedSectionIndex);
                    } else {
                      setState(() => _touched = -1);
                    }
                  },
                ),
                sections: List.generate(entries.length.clamp(0, 8), (i) {
                  final isTouched = i == _touched;
                  final pct = total > 0 ? (entries[i].value / total * 100) : 0.0;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entries[i].value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: isTouched ? 66 : 58,
                    titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  );
                }),
                centerSpaceRadius: 34,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                  entries.length.clamp(0, 6),
                  (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                entries[i].key,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              NumberFormat.compactCurrency(
                                      locale: 'en_IN', symbol: '₹')
                                  .format(entries[i].value),
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyStalkChart extends StatelessWidget {
  final List<Map<String, double>> summary;
  final DateTime selectedMonth;

  const _MonthlyStalkChart({required this.summary, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final months = List.generate(6, (i) {
      final m = DateTime(selectedMonth.year, selectedMonth.month - 5 + i);
      return DateFormat('MMM').format(m);
    });

    double maxY = 1000;
    for (final s in summary) {
      final total = (s['income'] ?? 0) + (s['expense'] ?? 0);
      if (total > maxY) maxY = total;
    }
    maxY = maxY * 1.25;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(AppTheme.teal, 'Income'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.rose, 'Expense'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.ink,
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final idx = group.x.toInt();
                      if (idx < 0 || idx >= summary.length) return null;
                      final mName = months[idx];
                      final inc = summary[idx]['income'] ?? 0;
                      final exp = summary[idx]['expense'] ?? 0;
                      final cur =
                          NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
                      return BarTooltipItem(
                        '$mName\nIncome: ${cur.format(inc)}\nExpense: ${cur.format(exp)}',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) => Text(
                        NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹')
                            .format(val),
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[i],
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(summary.length, (i) {
                  final income = summary[i]['income'] ?? 0;
                  final expense = summary[i]['expense'] ?? 0;
                  final total = income + expense;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total > 0 ? total : 0,
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        rodStackItems: [
                          BarChartRodStackItem(0, expense, AppTheme.rose),
                          BarChartRodStackItem(expense, total, AppTheme.teal),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel t;
  final NumberFormat currency;

  const _TransactionTile({required this.t, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isIncome = t.isIncome;
    final color = isIncome ? AppTheme.teal : AppTheme.rose;
    final catColor =
        t.categoryColor != null ? AppTheme.hexToColor(t.categoryColor!) : color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(AppTheme.getIcon(t.categoryIconName), color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.displayCategory,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${t.memberDisplayName} · ${DateFormat('dd MMM').format(t.date)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '−'} ${currency.format(t.amount)}',
            style: AppTheme.moneySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppTheme.sand.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 24, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
