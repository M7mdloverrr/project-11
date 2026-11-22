import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Roles allowed to use the current app; overridden per app.
final allowedRolesProvider = Provider<Set<Role>>((ref) => const {Role.student});

/// Role assigned at self sign-up in the current app; overridden per app.
final signUpRoleProvider = Provider<Role>((ref) => Role.student);

sealed class SessionState {
  const SessionState();
}

/// A persisted session exists and the profile is being loaded.
final class SessionRestoring extends SessionState {
  const SessionRestoring();
}

final class SessionBackendNotConfigured extends SessionState {
  const SessionBackendNotConfigured(this.issues);
  final List<String> issues;
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// The user opened a password-reset link and must choose a new password.
final class SessionPasswordRecovery extends SessionState {
  const SessionPasswordRecovery(this.user);
  final AuthUser user;
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user, this.profile);
  final AuthUser user;
  final Profile profile;
}

/// Signed in, but the profile could not be loaded.
final class SessionFailed extends SessionState {
  const SessionFailed(this.user, this.failure);
  final AuthUser user;
  final AppFailure failure;
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  String? _loadingUserId;

  @override
  SessionState build() {
    final gateway = ref.watch(authGatewayProvider);
    if (!gateway.isConfigured) return SessionBackendNotConfigured(ref.watch(appEnvProvider).issues);
    final sub = gateway.events.listen(_onEvent);
    ref.onDispose(sub.cancel);
    final user = gateway.currentUser;
    if (user == null) return const SessionSignedOut();
    _loadingUserId = user.id;
    Future.microtask(() => _loadProfile(user));
    return const SessionRestoring();
  }

  void _onEvent(AuthEvent e) {
    switch (e.kind) {
      case AuthEventKind.signedIn:
        final user = e.user;
        if (user != null) signedIn(user);
      case AuthEventKind.signedOut:
        _loadingUserId = null;
        state = const SessionSignedOut();
      case AuthEventKind.passwordRecovery:
        final user = e.user;
        if (user != null) state = SessionPasswordRecovery(user);
      case AuthEventKind.other:
        break;
    }
  }

  /// Called after a successful sign-in (also triggered by auth events).
  void signedIn(AuthUser user) {
    final s = state;
    if (s is SessionPasswordRecovery) return;
    if (s is SessionSignedIn && s.user.id == user.id) return;
    if (_loadingUserId == user.id && s is SessionRestoring) return;
    _loadingUserId = user.id;
    unawaited(_loadProfile(user));
  }

  Future<void> _loadProfile(AuthUser user) async {
    state = const SessionRestoring();
    SessionState next;
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchProfile(user.id);
      next = profile == null
          ? SessionFailed(user, const AppFailure(FailureKind.notFound, 'profile missing'))
          : SessionSignedIn(user, profile);
    } on AppFailure catch (f) {
      next = SessionFailed(user, f);
    }
    if (!ref.mounted || _loadingUserId != user.id) return;
    _loadingUserId = null;
    state = next;
  }

  Future<void> retry() async {
    final s = state;
    final user = switch (s) {
      SessionFailed(:final user) || SessionSignedIn(:final user) => user,
      _ => ref.read(authGatewayProvider).currentUser,
    };
    if (user == null) return;
    _loadingUserId = user.id;
    await _loadProfile(user);
  }

  void profileUpdated(Profile profile) {
    final s = state;
    if (s is SessionSignedIn) state = SessionSignedIn(s.user, profile);
  }

  /// After choosing a new password the recovery session becomes a normal one.
  Future<void> passwordUpdated() async {
    final s = state;
    if (s is! SessionPasswordRecovery) return;
    _loadingUserId = s.user.id;
    await _loadProfile(s.user);
  }

  Future<void> signOut() async {
    try {
      await ref.read(authGatewayProvider).signOut();
    } finally {
      if (ref.mounted && state is! SessionBackendNotConfigured) {
        _loadingUserId = null;
        state = const SessionSignedOut();
      }
    }
  }
}

/// Profile of the signed-in user; throws if used outside a signed-in session.
final currentProfileProvider = Provider<Profile>((ref) {
  final s = ref.watch(sessionControllerProvider);
  if (s is SessionSignedIn) return s.profile;
  throw StateError('No signed-in profile ($s)');
});
