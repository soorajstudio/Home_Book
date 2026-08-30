import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/admin/admin_shell_screen.dart';
import 'screens/onboarding/family_onboarding_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Book',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Fetch profile to check if user has a family and if admin
    bool isAdmin = false;
    String? familyId;
    try {
      final profile = await AuthService().getProfile();
      isAdmin = profile?['is_admin'] as bool? ?? false;
      familyId = profile?['family_id'] as String?;
    } catch (_) {}

    if (!mounted) return;

    // If user has not joined or created a family, route to onboarding
    if (familyId == null || familyId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FamilyOnboardingScreen()),
      );
      return;
    }

    // Route Admin directly to AdminShellScreen, normal users to ShellScreen
    if (isAdmin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShellScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen(isAdmin: false)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.account_balance_wallet,
                  size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Home Book',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track together, grow together',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
