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
          familyId: widget.familyId,
          fromDate: firstDay,
          toDate: lastDay);

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
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    if (_selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AppTheme.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration:
                            const BoxDecoration(gradient: AppTheme.primaryGradient),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$_greeting, $_username! 👋',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.familyName,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: const Text('Dashboard'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month selector
                          _MonthSelector(
                            month: _selectedMonth,
                            onPrev: _prevMonth,
                            onNext: _nextMonth,
                          ),
                          const SizedBox(height: 16),
                          // Balance card
                          _BalanceCard(
                            income: _income,
                            expense: _expense,
                            balance: balance,
                            currency: _currency,
                          ),
                          // Spending by Category pie chart
                          if (_categoryBreakdown.isNotEmpty) ...[
                            _SectionTitle('Spending by Category'),
                            const SizedBox(height: 8),
                            _CategoryPieChart(
                                data: _categoryBreakdown,
                                currency: _currency),
                            const SizedBox(height: 20),
                          ],
                          // Monthly stalk chart (Income vs Expenses)
                          if (_monthlySummary.isNotEmpty) ...[
                            _SectionTitle('Income vs Expenses (6 months)'),
                            const SizedBox(height: 8),
                            _MonthlyStalkChart(
                                summary: _monthlySummary,
                                selectedMonth: _selectedMonth),
                            const SizedBox(height: 20),
                          ],
                          // Recent transactions
                          _SectionTitle('Recent Transactions'),
                          const SizedBox(height: 8),
                          if (_recent.isEmpty)
                            const _EmptyState(
                                message: 'No transactions yet. Add your first one!'),
                          ..._recent.map((t) => _TransactionTile(t: t, currency: _currency)),
                          const SizedBox(height: 80),
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
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector(
      {required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = month.year == DateTime.now().year &&
        month.month == DateTime.now().month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Overview',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: onPrev,
                  visualDensity: VisualDensity.compact),
              Text(
                DateFormat('MMM yyyy').format(month),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              IconButton(
                  icon: Icon(Icons.chevron_right,
                      size: 20,
                      color: isCurrentMonth ? Colors.grey.shade300 : null),
                  onPressed: isCurrentMonth ? null : onNext,
                  visualDensity: VisualDensity.compact),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final NumberFormat currency;

  const _BalanceCard(
      {required this.income,
      required this.expense,
      required this.balance,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: balance >= 0
            ? AppTheme.primaryGradient
            : AppTheme.expenseGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (balance >= 0 ? AppTheme.primary : AppTheme.expenseColor)
                  .withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Net Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            currency.format(balance),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                  label: 'Income',
                  amount: income,
                  icon: Icons.arrow_upward,
                  color: const Color(0xFF81C784),
                  currency: currency),
              Container(
                  height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
              _MiniStat(
                  label: 'Expenses',
                  amount: expense,
                  icon: Icons.arrow_downward,
                  color: const Color(0xFFEF9A9A),
                  currency: currency),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final NumberFormat currency;

  const _MiniStat(
      {required this.label,
      required this.amount,
      required this.icon,
      required this.color,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(currency.format(amount),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _MonthlyStalkChart extends StatelessWidget {
  final List<Map<String, double>> summary;
  final DateTime selectedMonth;

  const _MonthlyStalkChart(
      {required this.summary, required this.selectedMonth});

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.incomeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Income',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.expenseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Expense',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade900,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final idx = group.x.toInt();
                        if (idx < 0 || idx >= summary.length) return null;
                        final mName = months[idx];
                        final inc = summary[idx]['income'] ?? 0;
                        final exp = summary[idx]['expense'] ?? 0;
                        final cur = NumberFormat.compactCurrency(
                            locale: 'en_IN', symbol: '₹');
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
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (val, meta) => Text(
                          NumberFormat.compactCurrency(
                                  locale: 'en_IN', symbol: '₹')
                              .format(val),
                          style: const TextStyle(
                              fontSize: 9, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i < 0 || i >= months.length) {
                            return const SizedBox();
                          }
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
                    getDrawingHorizontalLine: (v) => const FlLine(
                        color: Color(0xFFEEEEEE), strokeWidth: 1),
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
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          rodStackItems: [
                            BarChartRodStackItem(
                                0, expense, AppTheme.expenseColor),
                            BarChartRodStackItem(
                                expense, total, AppTheme.incomeColor),
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

  static const _colors = [
    Color(0xFFE65100), Color(0xFF1565C0), Color(0xFFAD1457),
    Color(0xFF4527A0), Color(0xFF2E7D32), Color(0xFF00695C),
    Color(0xFFF57F17), Color(0xFF4E342E), Color(0xFFBF360C),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, resp) {
                      if (resp?.touchedSection != null) {
                        setState(() => _touched =
                            resp!.touchedSection!.touchedSectionIndex);
                      } else {
                        setState(() => _touched = -1);
                      }
                    },
                  ),
                  sections: List.generate(entries.length.clamp(0, 8), (i) {
                    final isTouched = i == _touched;
                    final pct = total > 0
                        ? (entries[i].value / total * 100)
                        : 0.0;
                    return PieChartSectionData(
                      color: _colors[i % _colors.length],
                      value: entries[i].value,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: isTouched ? 70 : 60,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                    entries.length.clamp(0, 6),
                    (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _colors[i % _colors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entries[i].key,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                NumberFormat.compactCurrency(
                                        locale: 'en_IN', symbol: '₹')
                                    .format(entries[i].value),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        )),
              ),
            ),
          ],
        ),
      ),
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
    final color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final catColor = t.categoryColor != null
        ? AppTheme.hexToColor(t.categoryColor!)
        : color;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: catColor.withOpacity(0.15),
          child: Icon(AppTheme.getIcon(t.categoryIconName),
              color: catColor, size: 20),
        ),
        title: Text(
          t.displayCategory,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${t.memberDisplayName} · ${DateFormat('dd MMM').format(t.date)}',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${currency.format(t.amount)}',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary));
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
