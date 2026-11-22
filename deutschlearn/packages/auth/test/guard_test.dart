import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(id: 'u1', email: 'a@b.de');
Profile _profile(Role role, {String name = 'Amira'}) =>
    Profile(id: 'u1', role: role, displayName: name, locale: 'ar', cefrLevel: CefrLevel.a1);

String? _go(SessionState s, String location, {String? Function(String, Profile)? custom}) => authRedirect(
  session: s,
  location: location,
  allowedRoles: const {Role.student},
  signedOutHome: '/welcome',
  signedInHome: '/home',
  extraPublicRoutes: const {'/welcome'},
  signedInRedirect: custom,
);

void main() {
  test('restoring session shows the splash', () {
    expect(_go(const SessionRestoring(), '/home'), AuthRoutes.splash);
    expect(_go(const SessionRestoring(), AuthRoutes.splash), isNull);
  });

  test('missing backend: public screens allowed, protected ones blocked', () {
    const s = SessionBackendNotConfigured(['SUPABASE_URL is missing']);
    expect(_go(s, AuthRoutes.splash), AuthRoutes.notConfigured);
    expect(_go(s, '/home'), AuthRoutes.notConfigured);
    expect(_go(s, AuthRoutes.login), isNull);
    expect(_go(s, '/welcome'), isNull);
  });

  test('signed out users are kept on public routes', () {
    expect(_go(const SessionSignedOut(), '/home'), '/welcome');
    expect(_go(const SessionSignedOut(), AuthRoutes.signUp), isNull);
  });

  test('signed in with the right role goes home', () {
    final s = SessionSignedIn(_user, _profile(Role.student));
    expect(_go(s, AuthRoutes.login), '/home');
    expect(_go(s, AuthRoutes.splash), '/home');
    expect(_go(s, '/home/link-teacher'), isNull);
  });

  test('wrong role is blocked', () {
    final s = SessionSignedIn(_user, _profile(Role.teacher));
    expect(_go(s, '/home'), AuthRoutes.wrongRole);
    expect(_go(s, AuthRoutes.wrongRole), isNull);
  });

  test('custom signed-in redirect (profile setup)', () {
    final s = SessionSignedIn(_user, _profile(Role.student, name: ''));
    String? setup(String _, Profile p) => p.hasDisplayName ? null : '/setup';
    expect(_go(s, '/home', custom: setup), '/setup');
    expect(_go(s, '/setup', custom: setup), isNull);
  });

  test('recovery and failure states', () {
    expect(_go(const SessionPasswordRecovery(_user), '/home'), AuthRoutes.newPassword);
    expect(_go(const SessionFailed(_user, AppFailure(FailureKind.network)), '/home'), AuthRoutes.sessionError);
  });
}
