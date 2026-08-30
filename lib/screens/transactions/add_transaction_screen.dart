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

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.editTransaction?.isIncome == true ? 0 : 1,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _type = _tabController.index == 0 ? 'income' : 'expense';
          _categoryId = null;
          _loadCategories();
        });
      }
    });
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

    setState(() { _loading = true; _error = null; });

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
      setState(() { _error = 'Failed to save: $e'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editTransaction != null;
    final typeColor =
        _type == 'income' ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Column(
        children: [
          // Type Tabs
          Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.arrow_upward), text: 'Income'),
                Tab(icon: Icon(Icons.arrow_downward), text: 'Expense'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: typeColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _type == 'income' ? 'Income Amount' : 'Expense Amount',
                          style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: typeColor),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle:
                                TextStyle(color: typeColor.withOpacity(0.3),
                                    fontSize: 32),
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(
                                fontSize: 24,
                                color: typeColor,
                                fontWeight: FontWeight.bold),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Category
                  _catLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _categories.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Text(
                                'No categories found. Ask your admin to create categories first.',
                                style: TextStyle(color: Colors.orange),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon:
                                    Icon(Icons.category_outlined),
                              ),
                              hint: const Text('Select category'),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: AppTheme.hexToColor(
                                                    c.color),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(c.name),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _categoryId = v),
                            ),
                  const SizedBox(height: 16),
                  // Date picker
                  InkWell(
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
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(DateFormat('dd MMMM yyyy').format(_date)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.expenseColor)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Update Transaction' : 'Save Transaction'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
