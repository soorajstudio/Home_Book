import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/family_service.dart';
import '../../models/family_model.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  final _auth = AuthService();
  final _familyService = FamilyService();

  List<FamilyMemberModel> _users = [];
  Map<String, List<Map<String, dynamic>>> _sessionsByUser = {};
  String? _familyId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fid = await _familyService.getMyFamilyId();
      final users = await _familyService.getFamilyMembers();

      // Fetch login sessions for tracking login times & devices
      final sessionsResult = await _supabase
          .from('login_sessions')
          .select()
          .order('logged_in_at', ascending: false)
          .limit(200);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final s in (sessionsResult as List)) {
        final map = s as Map<String, dynamic>;
        final uid = map['user_id'] as String?;
        if (uid != null) {
          grouped.putIfAbsent(uid, () => []).add(map);
        }
      }

      if (mounted) {
        setState(() {
          _familyId = fid;
          _users = users;
          _sessionsByUser = grouped;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(FamilyMemberModel user) async {
    await _supabase
        .from('profiles')
        .update({'is_admin': !user.isAdmin})
        .eq('id', user.id);
    _load();
  }

  Future<void> _linkToFamily(FamilyMemberModel user) async {
    if (_familyId == null) return;
    await _familyService.linkUserToFamily(user.id, _familyId!);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName} added to family'),
          backgroundColor: AppTheme.incomeColor,
        ),
      );
    }
  }

  Future<void> _deleteUser(FamilyMemberModel user) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own admin account'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account'),
        content: Text(
          'Are you sure you want to permanently delete @${user.username} (${user.displayName})?\n\nThis will remove their profile, family link, and login history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete user login sessions
      await _supabase.from('login_sessions').delete().eq('user_id', user.id);
      // 2. Unlink from transactions
      await _supabase.from('transactions').update({'user_id': null}).eq('user_id', user.id);
      // 3. Delete profile
      await _supabase.from('profiles').delete().eq('id', user.id);

      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User @${user.username} deleted successfully'),
            backgroundColor: AppTheme.incomeColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: AppTheme.expenseColor,
          ),
        );
      }
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '—';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  void _showCreateUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isAdmin = false;
    bool obscure = true;
    bool creating = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isAdmin,
                      onChanged: (v) =>
                          setS(() => isAdmin = v ?? false),
                    ),
                    const Text('Grant admin privileges'),
                  ],
                ),
                if (error != null)
                  Text(error!,
                      style:
                          const TextStyle(color: AppTheme.expenseColor)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed:
                    creating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: creating
                  ? null
                  : () async {
                      final username = usernameCtrl.text.trim();
                      final password = passwordCtrl.text;
                      if (username.isEmpty || password.isEmpty) {
                        setS(() => error = 'Fill in all fields');
                        return;
                      }
                      if (password.length < 6) {
                        setS(() => error =
                            'Password must be at least 6 characters');
                        return;
                      }
                      setS(() {
                        creating = true;
                        error = null;
                      });
                      try {
                        await _auth.adminCreateUser(
                          username,
                          password,
                          isAdmin: isAdmin,
                        );
                        // Auto-link to family if admin has one
                        if (_familyId != null) {
                          final newUser = await _supabase
                              .from('profiles')
                              .select()
                              .eq('username', username)
                              .maybeSingle();
                          if (newUser != null) {
                            await _familyService.linkUserToFamily(
                                newUser['id'] as String, _familyId!);
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('User "$username" created'),
                              backgroundColor: AppTheme.incomeColor,
                            ),
                          );
                        }
                      } catch (e) {
                        final msg = e.toString().toLowerCase();
                        setS(() {
                          creating = false;
                          error = msg.contains('taken')
                              ? 'Username already taken'
                              : 'Error: $e';
                        });
                      }
                    },
              child: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users & Logins'),
        backgroundColor: AppTheme.primaryDark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_users_fab',
        backgroundColor: AppTheme.accent,
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Create User'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final user = _users[i];
                    final inFamily = user.familyId == _familyId;
                    final sessions = _sessionsByUser[user.id] ?? [];
                    final lastSession = sessions.isNotEmpty ? sessions.first : null;
                    final isOnline = lastSession != null && (lastSession['is_active'] == true);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: user.isAdmin
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : Colors.grey.shade200,
                              child: Text(
                                user.initials,
                                style: TextStyle(
                                  color: user.isAdmin
                                      ? AppTheme.primary
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${user.username}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lastSession != null
                                        ? 'Last login: ${_formatDateTime(lastSession['logged_in_at'] as String?)}'
                                        : 'No login recorded',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'toggle_admin') {
                              _toggleAdmin(user);
                            } else if (val == 'add_family') {
                              _linkToFamily(user);
                            } else if (val == 'delete_user') {
                              _deleteUser(user);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle_admin',
                              child: Row(
                                children: [
                                  Icon(
                                    user.isAdmin
                                        ? Icons.remove_moderator_outlined
                                        : Icons.admin_panel_settings_outlined,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user.isAdmin
                                      ? 'Remove Admin'
                                      : 'Make Admin'),
                                ],
                              ),
                            ),
                            if (!inFamily && _familyId != null)
                              PopupMenuItem(
                                value: 'add_family',
                                child: const Row(
                                  children: [
                                    Icon(Icons.group_add_outlined,
                                        size: 18,
                                        color: AppTheme.secondary),
                                    SizedBox(width: 8),
                                    Text('Add to Family'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete_user',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 18,
                                      color: AppTheme.expenseColor),
                                  SizedBox(width: 8),
                                  Text('Delete User',
                                      style: TextStyle(
                                          color: AppTheme.expenseColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.history, size: 16, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text('Login History & Devices',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppTheme.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (sessions.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('No login history found for this user.',
                                        style: TextStyle(
                                            fontSize: 12, color: AppTheme.textSecondary)),
                                  )
                                else
                                  ...sessions.take(5).map((sess) {
                                    final device = sess['device_info'] as String? ?? 'Unknown Device';
                                    final loginTime = _formatDateTime(sess['logged_in_at'] as String?);
                                    final isActive = sess['is_active'] == true;

                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            device.toLowerCase().contains('android')
                                                ? Icons.phone_android
                                                : device.toLowerCase().contains('web')
                                                    ? Icons.web
                                                    : Icons.devices,
                                            size: 20,
                                            color: AppTheme.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(device,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12)),
                                                Text('Logged in: $loginTime',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green.withValues(alpha: 0.15)
                                                  : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Offline',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isActive
                                                      ? Colors.green.shade800
                                                      : Colors.grey.shade600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
