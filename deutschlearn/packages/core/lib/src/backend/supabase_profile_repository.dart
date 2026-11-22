import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'profile_repository.dart';
import 'supabase_errors.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;
  static const _columns = 'id, role, display_name, locale, avatar_url, cefr_level';

  @override
  Future<Profile?> fetchProfile(String userId) => guardSupabase(() async {
    final row = await _client.from('profiles').select(_columns).eq('id', userId).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  });

  @override
  Future<Profile> updateProfile(String userId, {String? displayName, String? locale}) => guardSupabase(() async {
    final row = await _client
        .from('profiles')
        .update({'display_name': ?displayName?.trim(), 'locale': ?locale})
        .eq('id', userId)
        .select(_columns)
        .single();
    return Profile.fromJson(row);
  });
}
