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
        appBar: AppBar(
          title: const Text('Transactions'),
          backgroundColor: AppTheme.primaryDark,
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
        body: Center(child: CircularProgressIndicator()),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Users'),
          BottomNavigationBarItem(
              icon: Icon(Icons.label_outline),
              activeIcon: Icon(Icons.label),
              label: 'Categories'),
        ],
      ),
    );
  }
}
