import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _keySupabaseUrl = 'nexora_supabase_url';
  static const String _keySupabaseAnonKey = 'nexora_supabase_anon_key';
  static const String _keyDemoMode = 'nexora_demo_mode';

  // Default demo / development configuration
  // Developers can set their real project credentials in Settings or via compile-time env variables
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );
  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy',
  );

  static bool _isInitialized = false;
  static bool _isDemoMode = false;
  static SupabaseClient? _client;

  static bool get isInitialized => _isInitialized;
  static bool get isDemoMode => _isDemoMode;
  static SupabaseClient? get client => _client;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_keySupabaseUrl) ?? defaultUrl;
    final customKey = prefs.getString(_keySupabaseAnonKey) ?? defaultAnonKey;
    final forceDemo = prefs.getBool(_keyDemoMode);

    // If default dummy credentials or explicit demo mode flag is active, initialize in demo-ready mode
    final isPlaceholder = customUrl.contains('xyzcompany.supabase.co') || customKey.contains('dummy');
    _isDemoMode = forceDemo ?? isPlaceholder;

    if (!isPlaceholder && !_isDemoMode) {
      try {
        await Supabase.initialize(
          url: customUrl,
          publishableKey: customKey,
          debug: kDebugMode,
        );
        _client = Supabase.instance.client;
        _isInitialized = true;
      } catch (e) {
        debugPrint('Supabase initialize error, falling back to local demo mode: $e');
        _isDemoMode = true;
      }
    } else {
      _isDemoMode = true;
    }
  }

  static Future<void> setCredentials(String url, String anonKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySupabaseUrl, url);
    await prefs.setString(_keySupabaseAnonKey, anonKey);
    await prefs.setBool(_keyDemoMode, false);
    _isDemoMode = false;
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      _client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Supabase with custom credentials: $e');
    }
  }

  static Future<void> toggleDemoMode(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDemoMode, enable);
    _isDemoMode = enable;
  }
}
