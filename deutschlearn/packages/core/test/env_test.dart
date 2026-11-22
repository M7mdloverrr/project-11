import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(String role) {
  String part(Map<String, Object> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'role': role, 'iss': 'supabase'})}.sig';
}

void main() {
  test('missing env is not configured', () {
    expect(AppEnv.unconfigured.isConfigured, isFalse);
    expect(AppEnv.unconfigured.issues, hasLength(2));
  });

  test('placeholders from .env.example are rejected', () {
    const env = AppEnv(supabaseUrl: 'https://YOUR_PROJECT_REF.supabase.co', supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY');
    expect(env.isConfigured, isFalse);
  });

  test('service-role keys are rejected', () {
    expect(AppEnv(supabaseUrl: 'https://abc.supabase.co', supabaseAnonKey: _jwt('service_role')).isConfigured, isFalse);
    expect(const AppEnv(supabaseUrl: 'https://abc.supabase.co', supabaseAnonKey: 'sb_secret_x').isConfigured, isFalse);
  });

  test('anon / publishable keys are accepted', () {
    expect(AppEnv(supabaseUrl: 'https://abc.supabase.co', supabaseAnonKey: _jwt('anon')).isConfigured, isTrue);
    expect(
      const AppEnv(supabaseUrl: 'https://abc.supabase.co', supabaseAnonKey: 'sb_publishable_x').isConfigured,
      isTrue,
    );
  });

  test('plain http is only allowed for local development', () {
    expect(
      const AppEnv(supabaseUrl: 'http://abc.supabase.co', supabaseAnonKey: 'sb_publishable_x').isConfigured,
      isFalse,
    );
    expect(
      const AppEnv(supabaseUrl: 'http://10.0.2.2:54321', supabaseAnonKey: 'sb_publishable_x').isConfigured,
      isTrue,
    );
  });
}
