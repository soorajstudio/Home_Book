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

  const ProfileScreen({super.key, this.isAdmin = false, this.familyName = ''});

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
        _saveMsg = 'Profile updated';
        _saveOk = true;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _saveMsg = 'Could not save changes. Please try again.';
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
        SnackBar(content: Text('Invite code "$code" copied')),
      );
    }
  }

  Future<void> _leaveFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave family'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            child: const Text('Leave family'),
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
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: AppTheme.coralGlow,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('@$username',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.coralSoft,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: const Text('Administrator',
                          style: TextStyle(
                              color: AppTheme.coralDeep, fontWeight: FontWeight.w700, fontSize: 11.5)),
                    ),
                  const SizedBox(height: 24),
                  if (_family != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.divider),
                        boxShadow: AppTheme.softShadow(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppTheme.sand,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.home_outlined,
                                    color: AppTheme.textPrimary, size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  familyDisplayName,
                                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.sand,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Text(
                                  '${_members.length} member${_members.length == 1 ? '' : 's'}',
                                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.inkGradient.colors.first,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Family invite code',
                                          style: TextStyle(
                                              fontSize: 10.5,
                                              color: Colors.white.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text(
                                        _family!.displayInviteCode,
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: AppTheme.coral,
                                  borderRadius: BorderRadius.circular(11),
                                  child: InkWell(
                                    onTap: _copyInviteCode,
                                    borderRadius: BorderRadius.circular(11),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text('Copy',
                                              style: TextStyle(
                                                  color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _leaveFamily,
                              icon: const Icon(Icons.logout_rounded, size: 15, color: AppTheme.rose),
                              label: const Text('Leave family',
                                  style: TextStyle(color: AppTheme.rose, fontSize: 12.5, fontWeight: FontWeight.w700)),
                              style: TextButton.styleFrom(foregroundColor: AppTheme.rose),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Personal details', style: AppTheme.sectionTitle),
                        const SizedBox(height: 14),
                        const Text('Full name', style: AppTheme.eyebrow),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fullNameCtrl,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Phone number', style: AppTheme.eyebrow),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _saveMsg != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (_saveOk ? AppTheme.tealSoft : AppTheme.roseSoft),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(_saveMsg!,
                                        style: TextStyle(
                                            color: _saveOk ? AppTheme.teal : AppTheme.coralDeep,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, size: 17, color: AppTheme.rose),
                      label: const Text('Sign out', style: TextStyle(color: AppTheme.rose)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFF1CFC9))),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
