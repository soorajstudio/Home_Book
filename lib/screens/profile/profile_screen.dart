import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/family_service.dart';
import '../../models/family_model.dart';
import '../login_screen.dart';
import '../onboarding/family_onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isAdmin;
  final String familyName;

  const ProfileScreen(
      {super.key, this.isAdmin = false, this.familyName = ''});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _familyService = FamilyService();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Map<String, dynamic>? _profile;
  FamilyModel? _family;
  List<FamilyMemberModel> _members = [];
  bool _loading = true;
  bool _saving = false;
  String? _saveMsg;
  bool _saveOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await _auth.getProfile();
    final f = await _familyService.getMyFamily();
    final m = await _familyService.getFamilyMembers();

    if (mounted) {
      setState(() {
        _profile = p;
        _family = f;
        _members = m;
        _fullNameCtrl.text = p?['full_name'] as String? ?? '';
        _phoneCtrl.text = p?['phone'] as String? ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveMsg = null;
    });
    try {
      await _auth.supabase.from('profiles').update({
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      }).eq('id', _profile!['id'] as String);
      setState(() {
        _saveMsg = 'Profile updated!';
        _saveOk = true;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _saveMsg = 'Failed to save: $e';
        _saveOk = false;
        _saving = false;
      });
    }
  }

  Future<void> _copyInviteCode() async {
    final code = _family?.displayInviteCode ?? '';
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Family invite code "$code" copied to clipboard!'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _leaveFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Family'),
        content: Text(
          'Are you sure you want to leave "${_family?.name ?? 'your family'}"? You can create or join another family anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Leave Family'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _familyService.leaveFamily();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FamilyOnboardingScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = _profile?['username'] as String? ?? '';
    final isAdmin = _profile?['is_admin'] as bool? ?? widget.isAdmin;
    final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final familyDisplayName = _family?.name ?? widget.familyName;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('@$username',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Administrator',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  const SizedBox(height: 20),

                  // Household / Family Card
                  if (_family != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.home_outlined,
                                    color: AppTheme.primary, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    familyDisplayName,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_members.length} member${_members.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Family Invite Code',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary),
                                        ),
                                        Text(
                                          _family!.displayInviteCode,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _copyInviteCode,
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _leaveFamily,
                                icon: const Icon(Icons.exit_to_app,
                                    size: 16, color: AppTheme.expenseColor),
                                label: const Text('Leave Family',
                                    style: TextStyle(
                                        color: AppTheme.expenseColor,
                                        fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  // Edit form
                  TextField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  if (_saveMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_saveOk ? AppTheme.incomeColor : AppTheme.expenseColor)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_saveMsg!,
                          style: TextStyle(
                              color: _saveOk
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout,
                          color: AppTheme.expenseColor),
                      label: const Text('Sign Out',
                          style: TextStyle(color: AppTheme.expenseColor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.expenseColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
