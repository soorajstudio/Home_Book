import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/family_service.dart';
import '../../services/transaction_service.dart';
import '../../models/family_model.dart';

class FamilyScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  final bool isAdmin;

  const FamilyScreen({
    super.key,
    required this.familyId,
    required this.familyName,
    this.isAdmin = false,
  });

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _familyService = FamilyService();
  final _txnService = TransactionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  List<FamilyMemberModel> _members = [];
  Map<String, double> _memberExpense = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await _familyService.getFamilyMembers();
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = now;

      final Map<String, double> expenses = {};
      for (final m in members) {
        final txns = await _txnService.getTransactions(
          familyId: widget.familyId,
          fromDate: from,
          toDate: to,
          type: 'expense',
        );
        final total =
            txns.where((t) => t.userId == m.id).fold(0.0, (s, t) => s + t.amount);
        expenses[m.id] = total;
      }

      if (mounted) {
        setState(() {
          _members = members;
          _memberExpense = expenses;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: Text(widget.familyName)),
      body: _loading
          ? const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4)))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.coral,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.inkGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.family_restroom_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.familyName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_members.length} member${_members.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Members', style: AppTheme.sectionTitle),
                  const SizedBox(height: 10),
                  ..._members.map((m) => _MemberCard(
                        member: m,
                        monthExpense: _memberExpense[m.id] ?? 0,
                        currency: _currency,
                      )),
                ],
              ),
            ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMemberModel member;
  final double monthExpense;
  final NumberFormat currency;

  const _MemberCard(
      {required this.member, required this.monthExpense, required this.currency});

  @override
  Widget build(BuildContext context) {
    final accent = member.isAdmin ? AppTheme.coral : AppTheme.teal;
    final accentSoft = member.isAdmin ? AppTheme.coralSoft : AppTheme.tealSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                member.initials,
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.coralSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                              fontSize: 9.5, color: AppTheme.coralDeep, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('@${member.username}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('This month',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                currency.format(monthExpense),
                style: AppTheme.moneySmall.copyWith(color: AppTheme.rose),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
