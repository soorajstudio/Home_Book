import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Internal fake email domain — user never sees this
  static const String _fakeDomain = 'testapp.local';

  String _emailFromUsername(String username) {
    return '${username.toLowerCase().trim()}@$_fakeDomain';
  }

  // Check if a username is already taken
  Future<bool> isUsernameTaken(String username) async {
    final result = await supabase
        .from('profiles')
        .select('username')
        .eq('username', username.trim())
        .maybeSingle();

    return result != null;
  }

  // Register a new user with username + password
  Future<void> register(String username, String password) async {
    final cleanUsername = username.trim();

    final taken = await isUsernameTaken(cleanUsername);
    if (taken) {
      throw Exception('Username already taken');
    }

    final fakeEmail = _emailFromUsername(cleanUsername);

    final response = await supabase.auth.signUp(
      email: fakeEmail,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Registration failed');
    }

    // Create the profile row right away
    await supabase.from('profiles').insert({
      'id': response.user!.id,
      'username': cleanUsername,
      'is_admin': false,
    });
  }

  // Admin creates a user directly (same signUp flow but sets is_admin if needed)
  Future<void> adminCreateUser(
    String username,
    String password, {
    bool isAdmin = false,
  }) async {
    final cleanUsername = username.trim();

    final taken = await isUsernameTaken(cleanUsername);
    if (taken) {
      throw Exception('Username already taken');
    }

    final fakeEmail = _emailFromUsername(cleanUsername);

    final response = await supabase.auth.signUp(
      email: fakeEmail,
      password: password,
    );

    if (response.user == null) {
      throw Exception('User creation failed');
    }

    await supabase.from('profiles').insert({
      'id': response.user!.id,
      'username': cleanUsername,
      'is_admin': isAdmin,
    });
  }

  // Log in with username + password
  Future<void> login(String username, String password) async {
    final fakeEmail = _emailFromUsername(username.trim());

    await supabase.auth.signInWithPassword(
      email: fakeEmail,
      password: password,
    );
  }

  // Get the current user's profile
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return result;
  }

  // Get a simple device label for session tracking
  Future<String> getDeviceInfo() async {
    if (kIsWeb) return 'Web browser';

    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      // Use conditional import trick via kIsWeb already handled above.
      // For mobile we check the platform string via device_info_plus only.
      final androidInfo = await _tryAndroidInfo(deviceInfoPlugin);
      if (androidInfo != null) return androidInfo;

      final iosInfo = await _tryIosInfo(deviceInfoPlugin);
      if (iosInfo != null) return iosInfo;
    } catch (_) {
      // fallback
    }
    return 'Unknown device';
  }

  Future<String?> _tryAndroidInfo(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.androidInfo;
      return '${info.brand} ${info.model}';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryIosInfo(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.iosInfo;
      return '${info.name} ${info.model}';
    } catch (_) {
      return null;
    }
  }

  // Record a new login session
  Future<void> recordLoginSession() async {
    final userId = supabase.auth.currentUser!.id;
    final device = await getDeviceInfo();

    await supabase.from('login_sessions').insert({
      'user_id': userId,
      'device_info': device,
      'is_active': true,
    });
  }

  // Sign out and close the active session record
  Future<void> signOut() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      await supabase
          .from('login_sessions')
          .update({
            'is_active': false,
            'logged_out_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_active', true);
    }

    await supabase.auth.signOut();
  }

  bool get isLoggedIn => supabase.auth.currentSession != null;
}
