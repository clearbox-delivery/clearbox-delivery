import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client provider
/// Initialize in main() before runApp()
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Initialize Supabase
/// Call this in main() with environment variables
Future<void> initializeSupabase({
  required String url,
  required String anonKey,
}) async {
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

/// Get current Supabase instance
SupabaseClient get supabase => Supabase.instance.client;


