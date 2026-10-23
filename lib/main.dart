import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'features/authentication/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if SUPABASE_URL and SUPABASE_ANON_KEY are provided
  // via --dart-define. If omitted, SupabaseService handles it gracefully.
  await SupabaseService.instance.initialize();

  // Initialize AuthService and restore persisted session
  await AuthService.instance.initialize();

  runApp(const ManitTeamUpApp());
}
