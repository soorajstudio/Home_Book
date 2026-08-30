import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/family_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'reports/reports_screen.dart';
import 'profile/profile_screen.dart';

class ShellScreen extends StatefulWidget {
  final bool isAdmin;
  const ShellScreen({super.key, this.isAdmin = false});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;
  String? _familyId;
  String _familyName = 'My Family';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      final fs = FamilyService();
      final family = await fs.getMyFamily();
      if (mounted) {
        setState(() {
          _familyId = family?.id;
          _familyName = family?.name ?? 'My Family';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Widget> get _pages {
    if (_familyId == null) {
      return [
        _NoFamilyPage(isAdmin: widget.isAdmin, onFamilyCreated: _loadFamily),
        _NoFamilyPage(isAdmin: widget.isAdmin, onFamilyCreated: _loadFamily),
        _NoFamilyPage(isAdmin: widget.isAdmin, onFamilyCreated: _loadFamily),
        ProfileScreen(isAdmin: widget.isAdmin, familyName: _familyName),
      ];
    }
    return [
      DashboardScreen(familyId: _familyId!, familyName: _familyName, isAdmin: widget.isAdmin),
      TransactionsScreen(familyId: _familyId!),
      ReportsScreen(familyId: _familyId!, familyName: _familyName),
      ProfileScreen(isAdmin: widget.isAdmin, familyName: _familyName),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _pages;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _NoFamilyPage extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback onFamilyCreated;
  const _NoFamilyPage(
      {required this.isAdmin, required this.onFamilyCreated});

  @override
  State<_NoFamilyPage> createState() => _NoFamilyPageState();
}

class _NoFamilyPageState extends State<_NoFamilyPage> {
  final _createCtrl = TextEditingController(text: 'My Family');
  final _joinCtrl = TextEditingController();
  bool _creating = false;
  bool _joining = false;
  String? _error;

  Future<void> _create() async {
    final name = _createCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _creating = true; _error = null; });
    try {
      await FamilyService().createFamily(name);
      widget.onFamilyCreated();
    } catch (e) {
      setState(() { _error = e.toString(); _creating = false; });
    }
  }

  Future<void> _join() async {
    final code = _joinCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _joining = true; _error = null; });
    try {
      await FamilyService().joinFamilyByCode(code);
      widget.onFamilyCreated();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _joining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, size: 72, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Create your own family tracker or enter an invite code to join one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.expenseColor, fontSize: 13)),
                const SizedBox(height: 12),
              ],
              // Create Family
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Create a New Family',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _createCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Family Name',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _creating ? null : _create,
                        icon: _creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_home_outlined),
                        label: const Text('Create Family'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Join Family
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Join with Invite Code',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _joinCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Invite Code',
                          hintText: 'e.g. FAM924',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _joining ? null : _join,
                        icon: _joining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.group_add_outlined),
                        label: const Text('Join Family'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
