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
      final txns =
          await _txnService.getTransactions(familyId: widget.familyId, limit: 500);
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
        title: const Text('Delete transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
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
    final totalIncome =
        _filtered.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpense =
        _filtered.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Activity')),
      body: Column(
        children: [
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilter(),
                  decoration: const InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
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
                        color: AppTheme.teal,
                        onTap: () {
                          setState(() => _typeFilter = 'income');
                          _applyFilter();
                        }),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: 'Expense',
                        selected: _typeFilter == 'expense',
                        color: AppTheme.rose,
                        onTap: () {
                          setState(() => _typeFilter = 'expense');
                          _applyFilter();
                        }),
                    const Spacer(),
                    Text('${_filtered.length} items',
                        style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (_filtered.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                      label: 'Income',
                      amount: totalIncome,
                      color: AppTheme.teal,
                      currency: _currency),
                  Container(height: 28, width: 1, color: AppTheme.divider),
                  _SummaryChip(
                      label: 'Expense',
                      amount: totalExpense,
                      color: AppTheme.rose,
                      currency: _currency),
                  Container(height: 28, width: 1, color: AppTheme.divider),
                  _SummaryChip(
                      label: 'Balance',
                      amount: totalIncome - totalExpense,
                      color: AppTheme.textPrimary,
                      currency: _currency),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.sand,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.receipt_long_outlined,
                                  size: 28, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 14),
                            const Text('No transactions found',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppTheme.coral,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                          itemCount: dateKeys.length,
                          itemBuilder: (ctx, dateIdx) {
                            final dateKey = dateKeys[dateIdx];
                            final txns = grouped[dateKey]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
                                  child: Text(
                                    dateKey,
                                    style: AppTheme.eyebrow,
                                  ),
                                ),
                                ...txns.map((t) => Dismissible(
                                      key: Key(t.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 22),
                                        decoration: BoxDecoration(
                                          color: AppTheme.rose,
                                          borderRadius:
                                              BorderRadius.circular(AppTheme.radiusMd),
                                        ),
                                        child: const Icon(
                                            Icons.delete_outline_rounded,
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
                                                  familyId: widget.familyId,
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
              icon: const Icon(Icons.add_rounded),
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
      {required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.coral;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : AppTheme.sand,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700),
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
      {required this.label, required this.amount, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(
          currency.format(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
      ],
    );
  }
}

class _TxnCard extends StatelessWidget {
  final TransactionModel t;
  final NumberFormat currency;
  final VoidCallback onEdit;

  const _TxnCard({required this.t, required this.currency, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isIncome = t.isIncome;
    final color = isIncome ? AppTheme.teal : AppTheme.rose;
    final catColor =
        t.categoryColor != null ? AppTheme.hexToColor(t.categoryColor!) : color;
    final hasDesc = t.description != null && t.description!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(AppTheme.getIcon(t.categoryIconName),
                      color: catColor, size: 20),
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
                      if (hasDesc)
                        Text(t.description!,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      Text(t.memberDisplayName,
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncome ? '+' : '−'} ${currency.format(t.amount)}',
                  style: AppTheme.moneySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
