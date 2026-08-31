import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'shell_screen.dart';
import 'admin/admin_shell_screen.dart';
import 'onboarding/family_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final authService = AuthService();
  final usernameCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool loading = false;
  bool obscure = true;
  bool obscureConfirm = true;
  String? errorMessage;

  Future<void> handleRegister() async {
    final username = usernameCtrl.text.trim();
    final fullName = fullNameCtrl.text.trim();
    final password = passwordCtrl.text;
    final confirm = confirmCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please fill in all required fields');
      return;
    }
    if (password.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await authService.register(username, password);
      if (fullName.isNotEmpty) {
        final profile = await authService.getProfile();
        if (profile != null) {
          await authService.supabase
              .from('profiles')
              .update({'full_name': fullName})
              .eq('id', profile['id'] as String);
        }
      }
      await authService.recordLoginSession();
      final profile = await authService.getProfile();
      final isAdmin = (profile?['is_admin'] as bool?) ?? false;
      final familyId = profile?['family_id'] as String?;

      if (!mounted) return;

      if (familyId == null || familyId.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FamilyOnboardingScreen()),
        );
        return;
      }

      if (isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShellScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ShellScreen(isAdmin: false)),
        );
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      setState(() {
        errorMessage = (msg.contains('taken') || msg.contains('already'))
            ? 'Username already taken'
            : 'Registration failed. Please try again.';
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    fullNameCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create your account',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'One account, your whole family\'s finances.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 14.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Username *', style: AppTheme.eyebrow),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Pick a username',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Full name', style: AppTheme.eyebrow),
                    const SizedBox(height: 8),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Optional',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Password *', style: AppTheme.eyebrow),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                              obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textMuted, size: 20),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Confirm password *', style: AppTheme.eyebrow),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textMuted, size: 20),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: errorMessage != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: AppTheme.roseSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: AppTheme.rose, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(errorMessage!,
                                          style: const TextStyle(
                                              color: AppTheme.coralDeep,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: loading ? null : handleRegister,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Text('Create account'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign in',
                              style: TextStyle(
                                  color: AppTheme.coralDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
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
