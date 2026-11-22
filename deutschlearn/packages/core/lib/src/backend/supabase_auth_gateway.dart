import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../failure.dart';
import '../models/role.dart';
import 'auth_gateway.dart';
import 'supabase_errors.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client, {required this.redirectUrl});

  final sb.SupabaseClient _client;

  /// Deep link the confirmation / reset emails return to,
  /// e.g. `com.deutschlearn.student://auth-callback`.
  final String redirectUrl;

  sb.GoTrueClient get _auth => _client.auth;

  @override
  bool get isConfigured => true;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthEvent> get events => _auth.onAuthStateChange.map((s) {
    final kind = switch (s.event) {
      sb.AuthChangeEvent.signedIn || sb.AuthChangeEvent.initialSession || sb.AuthChangeEvent.tokenRefreshed =>
        s.session == null ? AuthEventKind.other : AuthEventKind.signedIn,
      sb.AuthChangeEvent.signedOut => AuthEventKind.signedOut,
      sb.AuthChangeEvent.passwordRecovery => AuthEventKind.passwordRecovery,
      _ => AuthEventKind.other,
    };
    return AuthEvent(kind, _toUser(s.session?.user));
  });

  @override
  Future<AuthUser> signIn({required String email, required String password}) => guardSupabase(() async {
    final res = await _auth.signInWithPassword(email: email.trim(), password: password);
    final user = _toUser(res.user);
    if (user == null) throw const AppFailure(FailureKind.invalidCredentials);
    return user;
  });

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required Role role,
    required String locale,
  }) => guardSupabase(() async {
    final res = await _auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: redirectUrl,
      data: {'role': role.name, 'display_name': displayName.trim(), 'locale': locale},
    );
    // With "Confirm email" enabled Supabase hides existing accounts by
    // returning a user without identities.
    if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
      throw const AppFailure(FailureKind.emailInUse);
    }
    return res.session == null ? SignUpOutcome.confirmationEmailSent : SignUpOutcome.signedIn;
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      guardSupabase(() => _auth.resetPasswordForEmail(email.trim(), redirectTo: redirectUrl));

  @override
  Future<void> updatePassword(String newPassword) =>
      guardSupabase(() => _auth.updateUser(sb.UserAttributes(password: newPassword)));

  @override
  Future<void> signOut() => guardSupabase(() => _auth.signOut());

  static AuthUser? _toUser(sb.User? u) => u == null ? null : AuthUser(id: u.id, email: u.email);
}
