import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/family_service.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../models/family_model.dart';
import '../login_screen.dart';
import '../transactions/transactions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final _familyService = FamilyService();
  final _txnService = TransactionService();
  final _auth = AuthService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  int _totalUsers = 0;
  int _totalTransactions = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;
  String? _familyId;
  String _familyName = '';
  bool _loading = true;

  FamilyModel? _family;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final family = await _familyService.getMyFamily();

      int usersCount = 0;
      int txnCount = 0;
      double income = 0;
      double expense = 0;

      if (family != null) {
        final users = await _supabase
            .from('profiles')
            .select('id')
            .eq('family_id', family.id);
        usersCount = (users as List).length;

        final transactions = await _supabase
            .from('transactions')
            .select('id')
            .eq('family_id', family.id);
        txnCount = (transactions as List).length;

        final now = DateTime.now();
        final from = DateTime(now.year, now.month, 1);
        income = await _txnService.getTotalIncome(family.id, from, now);
        expense = await _txnService.getTotalExpense(family.id, from, now);
      }

      if (mounted) {
        setState(() {
          _family = family;
          _totalUsers = usersCount;
          _totalTransactions = txnCount;
          _monthIncome = income;
          _monthExpense = expense;
          _familyId = family?.id;
          _familyName = family?.name ?? 'No family set up';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryDark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Family header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Family',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                            _familyName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          if (_family != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Invite Code: ',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),
                                      Text(
                                        _family!.displayInviteCode,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      color: Colors.white, size: 18),
                                  tooltip: 'Copy Invite Code',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final code = _family!.displayInviteCode;
                                    Clipboard.setData(ClipboardData(text: code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Invite code "$code" copied to clipboard!'),
                                        backgroundColor: AppTheme.primary,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Overview',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                          label: 'Total Users',
                          value: _totalUsers.toString(),
                          icon: Icons.group_outlined,
                          color: AppTheme.primary,
                        ),
                        _StatCard(
                          label: 'Total Transactions',
                          value: _totalTransactions.toString(),
                          icon: Icons.receipt_long_outlined,
                          color: AppTheme.secondary,
                          onTap: _familyId != null
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TransactionsScreen(
                                        familyId: _familyId!,
                                        canAdd: false,
                                      ),
                                    ),
                                  ).then((_) => _load())
                              : null,
                        ),
                        _StatCard(
                          label: 'Month Income',
                          value: _currency.format(_monthIncome),
                          icon: Icons.trending_up,
                          color: AppTheme.incomeColor,
                        ),
                        _StatCard(
                          label: 'Month Expense',
                          value: _currency.format(_monthExpense),
                          icon: Icons.trending_down,
                          color: AppTheme.expenseColor,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppTheme.textSecondary),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
