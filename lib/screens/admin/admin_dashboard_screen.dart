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
  final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
        final users =
            await _supabase.from('profiles').select('id').eq('family_id', family.id);
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
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            child: const Text('Sign out'),
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
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Admin overview'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _signOut,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.inkGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Family',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            _familyName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                          ),
                          if (_family != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text('Invite code',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _family!.displayInviteCode,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.4),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      final code = _family!.displayInviteCode;
                                      Clipboard.setData(ClipboardData(text: code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Invite code "$code" copied')),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Overview', style: AppTheme.sectionTitle),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        _StatCard(
                          label: 'Total users',
                          value: _totalUsers.toString(),
                          icon: Icons.group_rounded,
                          color: AppTheme.coral,
                          bg: AppTheme.coralSoft,
                        ),
                        _StatCard(
                          label: 'Transactions',
                          value: _totalTransactions.toString(),
                          icon: Icons.receipt_long_rounded,
                          color: AppTheme.textPrimary,
                          bg: AppTheme.sand,
                          onTap: _familyId != null
                              ? () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => TransactionsScreen(
                                        familyId: _familyId!,
                                        canAdd: false,
                                      ),
                                    ),
                                  )
                                  .then((_) => _load())
                              : null,
                        ),
                        _StatCard(
                          label: 'Month income',
                          value: _currency.format(_monthIncome),
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.teal,
                          bg: AppTheme.tealSoft,
                        ),
                        _StatCard(
                          label: 'Month expense',
                          value: _currency.format(_monthExpense),
                          icon: Icons.trending_down_rounded,
                          color: AppTheme.rose,
                          bg: AppTheme.roseSoft,
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
  final Color bg;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.textMuted),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
