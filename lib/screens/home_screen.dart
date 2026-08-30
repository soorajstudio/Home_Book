import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;

  String username = '';
  bool isAdmin = false;
  String quoteText = '';
  String quoteAuthor = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.isAdmin;
    loadData();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> loadData() async {
    try {
      final profile = await authService.getProfile();

      // Fetch a random quote
      List<Map<String, dynamic>> randomQuote = [];
      try {
        final quotes = await supabase.from('quotes').select();
        randomQuote = List<Map<String, dynamic>>.from(quotes)..shuffle();
      } catch (_) {
        // quotes table may not exist yet — that's fine
      }

      setState(() {
        username = profile?['username'] ?? 'there';
        isAdmin = profile?['is_admin'] ?? widget.isAdmin;
        if (randomQuote.isNotEmpty) {
          quoteText = randomQuote.first['text'] ?? '';
          quoteAuthor = randomQuote.first['author'] ?? '';
        }
        loading = false;
      });
    } catch (e) {
      setState(() {
        username = 'there';
        loading = false;
      });
    }
  }

  Future<void> handleLogout() async {
    await authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: handleLogout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${getGreeting()}, $username!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (quoteText.isNotEmpty) ...[
                    Text(
                      '"$quoteText"',
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— $quoteAuthor',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ] else ...[
                    const Text(
                      'You are now logged in!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
