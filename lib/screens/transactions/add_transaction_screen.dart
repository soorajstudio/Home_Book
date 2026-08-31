import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final String familyId;
  final TransactionModel? editTransaction;

  const AddTransactionScreen({
    super.key,
    required this.familyId,
    this.editTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _txnService = TransactionService();
  final _catService = CategoryService();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'expense';
  DateTime _date = DateTime.now();
  String? _categoryId;
  List<CategoryModel> _categories = [];
  bool _loading = false;
  bool _catLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.editTransaction?.type ?? 'expense';

    if (widget.editTransaction != null) {
      final e = widget.editTransaction!;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _descCtrl.text = e.description ?? '';
      _date = e.date;
      _categoryId = e.categoryId;
    }
    _loadCategories();
  }

  void _switchType(String type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null;
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _catLoading = true);
    try {
      final cats = await _catService.getCategoriesByType(widget.familyId, _type);
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_categoryId == null && cats.isNotEmpty) {
            _categoryId = cats.first.id;
          }
          _catLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _catLoading = false);
    }
  }

  Future<void> _save() async {
    final amountText = _amountCtrl.text.trim();
    if (amountText.isEmpty) {
      setState(() => _error = 'Please enter an amount');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.editTransaction != null) {
        await _txnService.updateTransaction(
          id: widget.editTransaction!.id,
          type: _type,
          amount: amount,
          date: _date,
          categoryId: _categoryId,
          description: _descCtrl.text.trim(),
        );
      } else {
        await _txnService.addTransaction(
          familyId: widget.familyId,
          type: _type,
          amount: amount,
          date: _date,
          categoryId: _categoryId,
          description: _descCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editTransaction != null;
    final typeColor = _type == 'income' ? AppTheme.teal : AppTheme.rose;
    final typeSoft = _type == 'income' ? AppTheme.tealSoft : AppTheme.roseSoft;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit transaction' : 'New transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented type switch
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.sand,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeSegment(
                      label: 'Expense',
                      icon: Icons.arrow_upward_rounded,
                      color: AppTheme.rose,
                      selected: _type == 'expense',
                      onTap: () => _switchType('expense'),
                    ),
                  ),
                  Expanded(
                    child: _TypeSegment(
                      label: 'Income',
                      icon: Icons.arrow_downward_rounded,
                      color: AppTheme.teal,
                      selected: _type == 'income',
                      onTap: () => _switchType('income'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: typeSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    _type == 'income' ? 'Income amount' : 'Expense amount',
                    style: TextStyle(
                        color: typeColor, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      autofocus: !isEdit,
                      style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: typeColor),
                      decoration: InputDecoration(
                        hintText: '₹0.00',
                        hintStyle:
                            TextStyle(color: typeColor.withValues(alpha: 0.3), fontSize: 38, fontWeight: FontWeight.w800),
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                            fontSize: 30, color: typeColor, fontWeight: FontWeight.w800),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Category', style: AppTheme.eyebrow),
            const SizedBox(height: 8),
            _catLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2))),
                  )
                : _categories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.goldGradient.colors.first.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Text(
                          'No categories found. Ask your admin to create categories first.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        hint: const Text('Select category'),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppTheme.hexToColor(c.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(c.name),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
            const SizedBox(height: 18),
            const Text('Date', style: AppTheme.eyebrow),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.expand_more_rounded),
                ),
                child: Text(DateFormat('dd MMMM yyyy').format(_date),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Description', style: AppTheme.eyebrow),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional note',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppTheme.roseSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppTheme.coralDeep,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: typeColor),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : Text(isEdit ? 'Update transaction' : 'Save transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSegment({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}
