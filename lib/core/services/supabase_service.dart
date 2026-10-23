import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service wrapper with fallback recovery.
///
/// Follows production best practices:
/// - Reads URL and anon key from environment defines (--dart-define)
/// - Provides baked-in production fallbacks
/// - Supports both full Flutter embedding and standalone SupabaseClient fallback
/// - Exposes initialization status cleanly to the UI layer
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _initError;
  String? get initError => _initError;

  SupabaseClient? _fallbackClient;

  SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return _fallbackClient;
      }
    }
    // Attempt fallback retrieval if Supabase was already initialized
    try {
      final c = Supabase.instance.client;
      _isInitialized = true;
      return c;
    } catch (_) {
      return _fallbackClient;
    }
  }

  /// Initialize Supabase using --dart-define or passed credentials.
  /// If credentials are not provided via environment or parameters,
  /// initialization falls back gracefully.
  Future<bool> initialize({
    String? url,
    String? anonKey,
  }) async {
    // If already initialized, return immediately
    try {
      if (_isInitialized && Supabase.instance.isInitialized) {
        return true;
      }
    } catch (_) {}

    final envUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://acbizqfvbqupkwakwjdh.supabase.co',
    );
    final supabaseUrl = (url ?? envUrl).trim();

    final envAnon = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_8Cq14U9y8gjtw4A76BXb-w_HWXE9hsj',
    );
    final envPub = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_8Cq14U9y8gjtw4A76BXb-w_HWXE9hsj',
    );

    final rawAnon = anonKey ?? (envAnon.isNotEmpty ? envAnon : envPub);
    final supabaseAnonKey = rawAnon.trim();

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      _initError = 'Supabase credentials missing.';
      _isInitialized = false;
      return false;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      _isInitialized = true;
      _initError = null;
      debugPrint('SupabaseService: Initialized successfully.');
      return true;
    } catch (e, stack) {
      debugPrint('SupabaseService: Initialization error: $e\n$stack');
      _initError = e.toString();

      // Check if instance is initialized despite the exception
      try {
        if (Supabase.instance.isInitialized) {
          _isInitialized = true;
          _initError = null;
          return true;
        }
      } catch (_) {}

      // Fallback: Create standalone client directly
      try {
        _fallbackClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
        _isInitialized = true;
        debugPrint('SupabaseService: Standalone fallback client created successfully.');
        return true;
      } catch (fallbackError) {
        debugPrint('SupabaseService: Standalone client error: $fallbackError');
      }

      _isInitialized = false;
      return false;
    }
  }

  /// Current auth user if available
  User? get currentUser => client?.auth.currentUser;

  /// Auth state change stream
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;
}
