import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_screens.dart';
import 'pages/activity_page.dart';
import 'pages/codes_page.dart';
import 'pages/lessons_page.dart';
import 'pages/links_page.dart';
import 'pages/overview_page.dart';
import 'pages/users_page.dart';
import 'shell.dart';

abstract final class AdminRoutes {
  static const overview = '/overview';
  static const users = '/users';
  static const lessons = '/lessons';
  static const codes = '/codes';
  static const links = '/links';
  static const activity = '/activity';
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  NoTransitionPage<void> page(Widget child) => NoTransitionPage(child: child);

  final router = GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      session: ref.read(sessionControllerProvider),
      location: state.matchedLocation,
      allowedRoles: ref.read(allowedRolesProvider),
      signedOutHome: AuthRoutes.login,
      signedInHome: AdminRoutes.overview,
    ),
    routes: [
      GoRoute(path: AuthRoutes.splash, builder: (_, _) => const AdminSplash()),
      GoRoute(path: AuthRoutes.notConfigured, builder: (_, _) => const AdminNotConfiguredScreen()),
      GoRoute(path: AuthRoutes.login, builder: (_, _) => const AdminLoginScreen()),
      GoRoute(path: AuthRoutes.signUp, redirect: (_, _) => AuthRoutes.login),
      GoRoute(path: AuthRoutes.resetPassword, builder: (_, _) => const AdminResetPasswordScreen()),
      GoRoute(path: AuthRoutes.newPassword, builder: (_, _) => const AdminNewPasswordScreen()),
      GoRoute(path: AuthRoutes.sessionError, builder: (_, _) => const AdminSessionErrorScreen()),
      GoRoute(path: AuthRoutes.wrongRole, builder: (_, _) => const AdminWrongRoleScreen()),
      ShellRoute(
        builder: (_, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AdminRoutes.overview, pageBuilder: (_, _) => page(const OverviewPage())),
          GoRoute(path: AdminRoutes.users, pageBuilder: (_, _) => page(const UsersPage())),
          GoRoute(path: AdminRoutes.lessons, pageBuilder: (_, _) => page(const LessonsPage())),
          GoRoute(path: AdminRoutes.codes, pageBuilder: (_, _) => page(const CodesPage())),
          GoRoute(path: AdminRoutes.links, pageBuilder: (_, _) => page(const LinksPage())),
          GoRoute(path: AdminRoutes.activity, pageBuilder: (_, _) => page(const ActivityPage())),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
