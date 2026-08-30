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

    setState(() { loading = true; errorMessage = null; });

    try {
      await authService.register(username, password);
      // Save full name if provided
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
            : 'Registration failed: $e';
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Account',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Join your family finance tracker',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name (optional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.expenseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.expenseColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.expenseColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.expenseColor,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : handleRegister,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign In',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold)),
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
