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
        final total = txns
            .where((t) => t.userId == m.id)
            .fold(0.0, (s, t) => s + t.amount);
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
      appBar: AppBar(
        title: Text(widget.familyName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Family header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.family_restroom,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.familyName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_members.length} member${_members.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Members',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
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
      {required this.member,
      required this.monthExpense,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: member.isAdmin
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.secondary.withOpacity(0.15),
              child: Text(
                member.initials,
                style: TextStyle(
                  color: member.isAdmin
                      ? AppTheme.primary
                      : AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                      Text(
                        member.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (member.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${member.username}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'This month',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10),
                ),
                Text(
                  currency.format(monthExpense),
                  style: const TextStyle(
                      color: AppTheme.expenseColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
