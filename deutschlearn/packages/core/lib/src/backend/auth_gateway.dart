import '../models/role.dart';

/// Signed-in user as seen by the app (no tokens exposed).
class AuthUser {
  const AuthUser({required this.id, this.email});
  final String id;
  final String? email;
}

enum AuthEventKind { signedIn, signedOut, passwordRecovery, other }

class AuthEvent {
  const AuthEvent(this.kind, this.user);
  final AuthEventKind kind;
  final AuthUser? user;
}

/// Result of sign-up: Supabase returns no session when email confirmation is on.
enum SignUpOutcome { signedIn, confirmationEmailSent }

/// Email/password auth operations. Implemented with Supabase and with fakes.
abstract interface class AuthGateway {
  bool get isConfigured;

  /// User of the persisted session, restored on app start.
  AuthUser? get currentUser;

  Stream<AuthEvent> get events;

  Future<AuthUser> signIn({required String email, required String password});

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required Role role,
    required String locale,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();
}
