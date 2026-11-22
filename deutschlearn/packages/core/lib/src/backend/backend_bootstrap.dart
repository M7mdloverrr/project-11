import 'package:supabase_flutter/supabase_flutter.dart';

import '../env.dart';

/// Initializes Supabase when [env] is valid; returns null otherwise so the app
/// can show its "backend not configured" state.
abstract final class BackendBootstrap {
  static Future<SupabaseClient?> initialize(AppEnv env) async {
    if (!env.isConfigured) return null;
    await Supabase.initialize(url: env.supabaseUrl.trim(), publishableKey: env.supabaseAnonKey.trim());
    return Supabase.instance.client;
  }
}
