import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'shell_screen.dart';
import 'admin/admin_shell_screen.dart';
import 'onboarding/family_onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  String? errorMessage;

  Future<void> handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please enter username and password');
      return;
    }

    setState(() { loading = true; errorMessage = null; });

    try {
      await authService.login(username, password);
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
      String friendly;
      if (msg.contains('invalid') || msg.contains('credentials') || msg.contains('password')) {
        friendly = 'Invalid username or password';
      } else if (msg.contains('network') || msg.contains('socket')) {
        friendly = 'Network error — please check your connection';
      } else {
        friendly = 'Login failed. Please try again.';
      }
      setState(() { errorMessage = friendly; loading = false; });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.account_balance_wallet,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Family Finance',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Track together, grow together',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text('Sign in to your account',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : handleLogin,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(color: AppTheme.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text('Register',
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
