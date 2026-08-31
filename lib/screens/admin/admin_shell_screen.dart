import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/family_service.dart';
import '../transactions/transactions_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;
  String? _familyId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      final fid = await FamilyService().getMyFamilyId();
      if (mounted) {
        setState(() {
          _familyId = fid;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTransactionsPage() {
    if (_familyId == null) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(
          title: const Text('Transactions'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Text(
            'No family set up. Create or link a family first.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }
    return TransactionsScreen(familyId: _familyId!, canAdd: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.cream,
        body: Center(
          child: SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
      );
    }

    final pages = [
      const AdminDashboardScreen(),
      _buildTransactionsPage(),
      const AdminUsersScreen(),
      const AdminCategoriesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 68,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.label_outline_rounded),
              selectedIcon: Icon(Icons.label_rounded),
              label: 'Categories'),
        ],
      ),
    );
  }
}
