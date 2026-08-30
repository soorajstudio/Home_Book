import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/family_service.dart';
import '../../services/auth_service.dart';
import '../shell_screen.dart';
import '../admin/admin_shell_screen.dart';
import '../login_screen.dart';

class FamilyOnboardingScreen extends StatefulWidget {
  const FamilyOnboardingScreen({super.key});

  @override
  State<FamilyOnboardingScreen> createState() => _FamilyOnboardingScreenState();
}

class _FamilyOnboardingScreenState extends State<FamilyOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _familyService = FamilyService();
  final _authService = AuthService();

  final _createNameCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createNameCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _createNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a family name');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _familyService.createFamily(name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShellScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create family: $e';
        _loading = false;
      });
    }
  }

  Future<void> _handleJoin() async {
    final code = _joinCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _familyService.joinFamilyByCode(code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen(isAdmin: false)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Household Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Header Illustration/Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.holiday_village_outlined,
                    size: 56,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Family Finance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set up your family or join an existing one to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Create Family'),
                    Tab(text: 'Join Family'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.expenseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.expenseColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.expenseColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.expenseColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tab Content Area
              SizedBox(
                height: 260,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Create Family Tab
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Start a new family tracker as the Administrator.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _createNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Family Name *',
                            hintText: 'e.g. The Sharma Family',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _handleCreate,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_home_outlined),
                          label: const Text('Create Family & Continue'),
                        ),
                      ],
                    ),

                    // Join Family Tab
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter the 6-character Invite Code shared by your family admin.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _joinCodeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Family Invite Code *',
                            hintText: 'e.g. FAM924',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _handleJoin,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.group_add_outlined),
                          label: const Text('Join Family & Continue'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
