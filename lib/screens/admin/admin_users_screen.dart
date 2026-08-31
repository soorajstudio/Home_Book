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
          backgroundColor: AppTheme.teal,
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
          backgroundColor: AppTheme.rose,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user account'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('login_sessions').delete().eq('user_id', user.id);
      await _supabase.from('transactions').update({'user_id': null}).eq('user_id', user.id);
      await _supabase.from('profiles').delete().eq('id', user.id);

      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User @${user.username} deleted successfully'),
            backgroundColor: AppTheme.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: AppTheme.rose,
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
          title: const Text('Create new user'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20, color: AppTheme.textMuted),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: isAdmin,
                  onChanged: (v) => setS(() => isAdmin = v ?? false),
                  title: const Text('Grant admin privileges',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(error!,
                        style: const TextStyle(color: AppTheme.rose, fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: creating ? null : () => Navigator.pop(ctx),
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
                        setS(() => error = 'Password must be at least 6 characters');
                        return;
                      }
                      setS(() {
                        creating = true;
                        error = null;
                      });
                      try {
                        await _auth.adminCreateUser(username, password, isAdmin: isAdmin);
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
                              content: Text('User "$username" created'),
                              backgroundColor: AppTheme.teal,
                            ),
                          );
                        }
                      } catch (e) {
                        final msg = e.toString().toLowerCase();
                        setS(() {
                          creating = false;
                          error = msg.contains('taken') ? 'Username already taken' : 'Error: $e';
                        });
                      }
                    },
              child: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Users & logins'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_users_fab',
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New user'),
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)))
          : _users.isEmpty
              ? const Center(
                  child: Text('No users found', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final user = _users[i];
                    final inFamily = user.familyId == _familyId;
                    final sessions = _sessionsByUser[user.id] ?? [];
                    final lastSession = sessions.isNotEmpty ? sessions.first : null;
                    final isOnline = lastSession != null && (lastSession['is_active'] == true);
                    final accent = user.isAdmin ? AppTheme.coral : AppTheme.teal;
                    final accentSoft = user.isAdmin ? AppTheme.coralSoft : AppTheme.tealSoft;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Stack(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: accentSoft,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Center(
                                  child: Text(
                                    user.initials,
                                    style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: -1,
                                  bottom: -1,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF23C16B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.card, width: 2),
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
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.coralSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Admin',
                                      style: TextStyle(
                                          fontSize: 9.5, color: AppTheme.coralDeep, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${user.username}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        lastSession != null
                                            ? 'Last login: ${_formatDateTime(lastSession['logged_in_at'] as String?)}'
                                            : 'No login recorded',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
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
                                      color: AppTheme.coral,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(user.isAdmin ? 'Remove admin' : 'Make admin'),
                                  ],
                                ),
                              ),
                              if (!inFamily && _familyId != null)
                                const PopupMenuItem(
                                  value: 'add_family',
                                  child: Row(
                                    children: [
                                      Icon(Icons.group_add_outlined, size: 18, color: AppTheme.teal),
                                      SizedBox(width: 8),
                                      Text('Add to family'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete_user',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.rose),
                                    SizedBox(width: 8),
                                    Text('Delete user', style: TextStyle(color: AppTheme.rose)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(height: 1, color: AppTheme.divider),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Icon(Icons.history_rounded, size: 15, color: AppTheme.coral),
                                      SizedBox(width: 6),
                                      Text('Login history & devices',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: AppTheme.textPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (sessions.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text('No login history found for this user.',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    )
                                  else
                                    ...sessions.take(5).map((sess) {
                                      final device = sess['device_info'] as String? ?? 'Unknown device';
                                      final loginTime = _formatDateTime(sess['logged_in_at'] as String?);
                                      final isActive = sess['is_active'] == true;

                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.sand.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              device.toLowerCase().contains('android')
                                                  ? Icons.phone_android_rounded
                                                  : device.toLowerCase().contains('web')
                                                      ? Icons.language_rounded
                                                      : Icons.devices_rounded,
                                              size: 18,
                                              color: AppTheme.coral,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(device,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700, fontSize: 12)),
                                                  Text('Logged in: $loginTime',
                                                      style: const TextStyle(
                                                          fontSize: 11, color: AppTheme.textMuted)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? const Color(0xFF23C16B).withValues(alpha: 0.14)
                                                    : AppTheme.divider,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isActive ? 'Active' : 'Offline',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: isActive
                                                        ? const Color(0xFF178A4C)
                                                        : AppTheme.textMuted),
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
                      ),
                    );
                  },
                ),
    );
  }
}
