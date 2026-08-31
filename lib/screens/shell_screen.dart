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
      DashboardScreen(
          familyId: _familyId!, familyName: _familyName, isAdmin: widget.isAdmin),
      TransactionsScreen(familyId: _familyId!),
      ReportsScreen(familyId: _familyId!, familyName: _familyName),
      ProfileScreen(isAdmin: widget.isAdmin, familyName: _familyName),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.cream,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    final pages = _pages;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 68,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _NoFamilyPage extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback onFamilyCreated;
  const _NoFamilyPage({required this.isAdmin, required this.onFamilyCreated});

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
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await FamilyService().createFamily(name);
      widget.onFamilyCreated();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _creating = false;
      });
    }
  }

  Future<void> _join() async {
    final code = _joinCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _joining = true;
      _error = null;
    });
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
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.coralGlow,
                  ),
                  child: const Icon(Icons.family_restroom_rounded,
                      size: 34, color: Colors.white),
                ),
                const SizedBox(height: 22),
                const Text('Set up your family',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'Start a new tracker or join one with\nan invite code from a family member.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.roseSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.coralDeep,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                ],
                // Create Family
                _SetupCard(
                  icon: Icons.add_home_rounded,
                  iconColor: AppTheme.coral,
                  iconBg: AppTheme.coralSoft,
                  title: 'Create a new family',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _createCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Family name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _creating ? null : _create,
                          child: _creating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Create family'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Join Family
                _SetupCard(
                  icon: Icons.vpn_key_rounded,
                  iconColor: AppTheme.teal,
                  iconBg: AppTheme.tealSoft,
                  title: 'Join with an invite code',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _joinCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Invite code',
                          hintText: 'e.g. FAM924',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _joining ? null : _join,
                          child: _joining
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Join family'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget child;

  const _SetupCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
