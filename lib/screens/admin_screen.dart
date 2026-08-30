import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;
  final authService = AuthService();

  List<Map<String, dynamic>> profiles = [];
  Map<String, List<Map<String, dynamic>>> sessionsByUser = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final profilesResult = await supabase.from('profiles').select();

      final sessionsResult = await supabase
          .from('login_sessions')
          .select()
          .order('logged_in_at', ascending: false);

      final sessions = List<Map<String, dynamic>>.from(sessionsResult);

      // Group sessions by user_id
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final session in sessions) {
        final userId = session['user_id'] as String;
        grouped.putIfAbsent(userId, () => []).add(session);
      }

      setState(() {
        profiles = List<Map<String, dynamic>>.from(profilesResult);
        sessionsByUser = grouped;
        loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load admin data: $e');
      setState(() => loading = false);
    }
  }

  String formatTime(String? isoString) {
    if (isoString == null) return 'Still active';
    final dt = DateTime.parse(isoString).toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m:$s';
  }

  // ── Create User Dialog ──────────────────────────────────────────────────────

  Future<void> showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAdmin = false;
    bool obscure = true;
    String? dialogError;
    bool creating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Create New User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isAdmin,
                          onChanged: (v) =>
                              setDialogState(() => isAdmin = v ?? false),
                        ),
                        const Text('Grant admin privileges'),
                      ],
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: creating
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text;

                          if (username.isEmpty || password.isEmpty) {
                            setDialogState(() =>
                                dialogError = 'Please fill in all fields');
                            return;
                          }
                          if (password.length < 6) {
                            setDialogState(() => dialogError =
                                'Password must be at least 6 characters');
                            return;
                          }

                          setDialogState(() {
                            creating = true;
                            dialogError = null;
                          });

                          try {
                            await authService.adminCreateUser(
                              username,
                              password,
                              isAdmin: isAdmin,
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop();

                            // Refresh list
                            setState(() => loading = true);
                            await loadData();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'User "$username" created successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            final msg = e.toString().toLowerCase();
                            setDialogState(() {
                              creating = false;
                              if (msg.contains('taken') ||
                                  msg.contains('already')) {
                                dialogError = 'Username already taken';
                              } else {
                                dialogError = 'Failed to create user: $e';
                              }
                            });
                          }
                        },
                  child: creating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();
    passwordController.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => loading = true);
              loadData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Create User'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profiles.isEmpty
              ? const Center(child: Text('No users found.'))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final user = profiles[index];
                      final userId = user['id'] as String;
                      final userSessions = sessionsByUser[userId] ?? [];
                      final activeCount = userSessions
                          .where((s) => s['is_active'] == true)
                          .length;
                      final multiDevice = activeCount > 1;
                      final isUserAdmin = user['is_admin'] == true;

                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isUserAdmin
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          child: Icon(
                            isUserAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: isUserAdmin ? Colors.blue : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              user['username'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (isUserAdmin) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('Admin',
                                    style: TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ],
                        ),
                        subtitle:
                            Text('${userSessions.length} login(s) recorded'),
                        trailing: multiDevice
                            ? Chip(
                                label: Text('$activeCount devices'),
                                backgroundColor: Colors.red.shade100,
                                labelStyle:
                                    const TextStyle(color: Colors.red),
                              )
                            : null,
                        children: userSessions.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No login history yet'),
                                ),
                              ]
                            : userSessions.map((session) {
                                final isActive = session['is_active'] == true;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isActive
                                        ? Icons.circle
                                        : Icons.circle_outlined,
                                    size: 12,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  title: Text(
                                    'Login: ${formatTime(session['logged_in_at'])}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'Logout: ${formatTime(session['logged_out_at'])}\n'
                                    'Device: ${session['device_info'] ?? 'Unknown'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  isThreeLine: true,
                                );
                              }).toList(),
                      );
                    },
                  ),
                ),
    );
  }
}
