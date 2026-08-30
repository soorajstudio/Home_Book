import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final String familyId;
  final bool canAdd;
  const TransactionsScreen({super.key, required this.familyId, this.canAdd = true});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txnService = TransactionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _searchCtrl = TextEditingController();

  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  String _typeFilter = 'all'; // all | income | expense
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final txns = await _txnService.getTransactions(
          familyId: widget.familyId, limit: 500);
      if (mounted) {
        setState(() {
          _all = txns;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((t) {
        final matchType = _typeFilter == 'all' || t.type == _typeFilter;
        final matchSearch = query.isEmpty ||
            (t.displayCategory.toLowerCase().contains(query)) ||
            (t.description?.toLowerCase().contains(query) ?? false) ||
            (t.memberDisplayName.toLowerCase().contains(query));
        return matchType && matchSearch;
      }).toList();
    });
  }

  Future<void> _delete(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _txnService.deleteTransaction(t.id);
      _load();
    }
  }

  Map<String, List<TransactionModel>> _groupByDate() {
    final map = <String, List<TransactionModel>>{};
    for (final t in _filtered) {
      final key = DateFormat('dd MMMM yyyy').format(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dateKeys = grouped.keys.toList();
    final totalIncome = _filtered
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = _filtered
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Column(
        children: [
          // Filter & search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilter(),
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _FilterChip(
                        label: 'All',
                        selected: _typeFilter == 'all',
                        onTap: () {
                          setState(() => _typeFilter = 'all');
                          _applyFilter();
                        }),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: 'Income',
                        selected: _typeFilter == 'income',
                        color: AppTheme.incomeColor,
                        onTap: () {
                          setState(() => _typeFilter = 'income');
                          _applyFilter();
                        }),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: 'Expense',
                        selected: _typeFilter == 'expense',
                        color: AppTheme.expenseColor,
                        onTap: () {
                          setState(() => _typeFilter = 'expense');
                          _applyFilter();
                        }),
                    const Spacer(),
                    Text(
                      '${_filtered.length} items',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Summary bar
          if (_filtered.isNotEmpty)
            Container(
              color: AppTheme.background,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                      label: 'Income',
                      amount: totalIncome,
                      color: AppTheme.incomeColor,
                      currency: _currency),
                  _SummaryChip(
                      label: 'Expense',
                      amount: totalExpense,
                      color: AppTheme.expenseColor,
                      currency: _currency),
                  _SummaryChip(
                      label: 'Balance',
                      amount: totalIncome - totalExpense,
                      color: AppTheme.primary,
                      currency: _currency),
                ],
              ),
            ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('No transactions found',
                                style:
                                    TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: dateKeys.length,
                          itemBuilder: (ctx, dateIdx) {
                            final dateKey = dateKeys[dateIdx];
                            final txns = grouped[dateKey]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 4),
                                  child: Text(
                                    dateKey,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                        letterSpacing: 0.5),
                                  ),
                                ),
                                ...txns.map((t) => Dismissible(
                                      key: Key(t.id),
                                      direction:
                                          DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                            right: 20),
                                        color: AppTheme.expenseColor,
                                        child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (_) async {
                                        await _delete(t);
                                        return false;
                                      },
                                      child: _TxnCard(
                                          t: t,
                                          currency: _currency,
                                          onEdit: () async {
                                            final edited =
                                                await Navigator.of(context)
                                                    .push<bool>(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddTransactionScreen(
                                                  familyId:
                                                      widget.familyId,
                                                  editTransaction: t,
                                                ),
                                              ),
                                            );
                                            if (edited == true) _load();
                                          }),
                                    )),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.canAdd
          ? FloatingActionButton.extended(
              heroTag: 'transactions_fab',
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTransactionScreen(familyId: widget.familyId),
                  ),
                );
                if (added == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : c,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;

  const _SummaryChip(
      {required this.label,
      required this.amount,
      required this.color,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        Text(
          currency.format(amount),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class _TxnCard extends StatelessWidget {
  final TransactionModel t;
  final NumberFormat currency;
  final VoidCallback onEdit;

  const _TxnCard(
      {required this.t, required this.currency, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isIncome = t.isIncome;
    final color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final catColor = t.categoryColor != null
        ? AppTheme.hexToColor(t.categoryColor!)
        : color;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: catColor.withOpacity(0.15),
          child: Icon(AppTheme.getIcon(t.categoryIconName),
              color: catColor, size: 20),
        ),
        title: Text(
          t.displayCategory,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.description != null && t.description!.isNotEmpty)
              Text(t.description!,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            Text(
              t.memberDisplayName,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        isThreeLine: t.description != null && t.description!.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'} ${currency.format(t.amount)}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
