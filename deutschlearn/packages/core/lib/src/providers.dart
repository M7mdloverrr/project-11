import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend/admin_repository.dart';
import 'backend/auth_gateway.dart';
import 'backend/lesson_repository.dart';
import 'backend/link_repository.dart';
import 'backend/profile_repository.dart';
import 'backend/supabase_admin_repository.dart';
import 'backend/supabase_auth_gateway.dart';
import 'backend/supabase_lesson_repository.dart';
import 'backend/supabase_link_repository.dart';
import 'backend/supabase_profile_repository.dart';
import 'backend/unconfigured_backend.dart';
import 'env.dart';

/// Overridden in main() with the build-time env.
final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.unconfigured);

/// Overridden in main() with the initialized client; null = not configured.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

/// Deep link used in auth emails; each app overrides it with its own scheme.
final authRedirectUrlProvider = Provider<String>((ref) => 'com.deutschlearn.student://auth-callback');

final authGatewayProvider = Provider<AuthGateway>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const UnconfiguredAuthGateway();
  return SupabaseAuthGateway(client, redirectUrl: ref.watch(authRedirectUrlProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? const UnconfiguredProfileRepository() : SupabaseProfileRepository(client);
});

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? const UnconfiguredLinkRepository() : SupabaseLinkRepository(client);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? const UnconfiguredAdminRepository() : SupabaseAdminRepository(client);
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? const UnconfiguredLessonRepository() : SupabaseLessonRepository(client);
});

/// Disables Riverpod's automatic retry; screens offer explicit retry buttons
/// so failures (e.g. offline) are shown instead of silently retried.
Duration? noRetry(int retryCount, Object error) => null;
