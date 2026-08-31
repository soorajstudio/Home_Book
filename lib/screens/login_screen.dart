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

    setState(() {
      loading = true;
      errorMessage = null;
    });

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
      if (msg.contains('invalid') ||
          msg.contains('credentials') ||
          msg.contains('password')) {
        friendly = 'Invalid username or password';
      } else if (msg.contains('network') || msg.contains('socket')) {
        friendly = 'Network error — please check your connection';
      } else {
        friendly = 'Login failed. Please try again.';
      }
      setState(() {
        errorMessage = friendly;
        loading = false;
      });
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
      backgroundColor: AppTheme.ink,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Hero
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: AppTheme.coralGlow,
                              ),
                              child: const Icon(Icons.savings_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to keep your family\'s money\non the same page.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 14.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form sheet
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppTheme.cream,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Username', style: AppTheme.eyebrow),
                              const SizedBox(height: 8),
                              TextField(
                                controller: usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your username',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text('Password', style: AppTheme.eyebrow),
                              const SizedBox(height: 8),
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => handleLogin(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => obscurePassword = !obscurePassword),
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                child: errorMessage != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 14),
                                        child: _ErrorBanner(text: errorMessage!),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: loading ? null : handleLogin,
                                  child: loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Sign in'),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 18),
                                          ],
                                        ),
                                ),
                              ),
                              const Spacer(),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("New here? ",
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14)),
                                      GestureDetector(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen()),
                                        ),
                                        child: const Text('Create an account',
                                            style: TextStyle(
                                                color: AppTheme.coralDeep,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.coralDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
