import 'package:core/core.dart';

import 'session.dart';

abstract final class AuthRoutes {
  static const splash = '/splash';
  static const notConfigured = '/not-configured';
  static const login = '/login';
  static const signUp = '/signup';
  static const resetPassword = '/reset-password';
  static const newPassword = '/new-password';
  static const wrongRole = '/wrong-role';
  static const sessionError = '/session-error';

  /// Reachable while signed out.
  static const public = {login, signUp, resetPassword};

  /// Session-state screens a signed-in user is sent away from.
  static const _transient = {splash, notConfigured, newPassword, wrongRole, sessionError};
}

/// Role-aware routing guard used as go_router's `redirect`.
///
/// Returns the location to go to, or null to stay on [location].
String? authRedirect({
  required SessionState session,
  required String location,
  required Set<Role> allowedRoles,
  required String signedOutHome,
  required String signedInHome,
  Set<String> extraPublicRoutes = const {},
  String? Function(String location, Profile profile)? signedInRedirect,
}) {
  final public = {...AuthRoutes.public, ...extraPublicRoutes};
  String? goTo(String target) => location == target ? null : target;

  switch (session) {
    case SessionRestoring():
      return goTo(AuthRoutes.splash);
    case SessionBackendNotConfigured():
      // Public screens stay reachable so the UI can be explored; every
      // backend call there fails with an explicit "not configured" error.
      return public.contains(location) ? null : goTo(AuthRoutes.notConfigured);
    case SessionSignedOut():
      return public.contains(location) ? null : signedOutHome;
    case SessionPasswordRecovery():
      return goTo(AuthRoutes.newPassword);
    case SessionFailed():
      return goTo(AuthRoutes.sessionError);
    case SessionSignedIn(:final profile):
      if (!allowedRoles.contains(profile.role)) return goTo(AuthRoutes.wrongRole);
      final custom = signedInRedirect?.call(location, profile);
      if (custom != null) return goTo(custom);
      if (public.contains(location) || AuthRoutes._transient.contains(location)) return signedInHome;
      return null;
  }
}
