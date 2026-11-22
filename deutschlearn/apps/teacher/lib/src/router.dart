import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'dashboard/dashboard_screen.dart';

import 'package:core/core.dart';

import 'profile_setup_screen.dart';
import 'students/student_chat_screen.dart';
import 'students/student_detail_screen.dart';

abstract final class TeacherRoutes {
  static const dashboard = '/dashboard';
  static const profileSetup = '/profile-setup';
  static String student(String id) => '/dashboard/student/$id';
  static String chat(String id) => '/dashboard/student/$id/chat';
}

const _appSubtitle = 'لوحة المعلّم • Lehrer-Dashboard';

final teacherRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      session: ref.read(sessionControllerProvider),
      location: state.matchedLocation,
      allowedRoles: ref.read(allowedRolesProvider),
      signedOutHome: AuthRoutes.login,
      signedInHome: TeacherRoutes.dashboard,
      // A teacher must have a public name before students can find them.
      signedInRedirect: (location, profile) => profile.hasDisplayName ? null : TeacherRoutes.profileSetup,
    ),
    routes: [
      GoRoute(
        path: AuthRoutes.splash,
        builder: (_, _) => const SplashScreen(subtitle: _appSubtitle),
      ),
      GoRoute(
        path: AuthRoutes.notConfigured,
        builder: (_, _) =>
            const BackendNotConfiguredScreen(previewRoute: AuthRoutes.login, appName: 'DeutschLearn Lehrer'),
      ),
      GoRoute(
        path: AuthRoutes.login,
        builder: (_, _) => const LoginScreen(logoSubtitle: _appSubtitle),
      ),
      GoRoute(
        path: AuthRoutes.signUp,
        builder: (_, _) => const SignUpScreen(logoSubtitle: _appSubtitle),
      ),
      GoRoute(path: AuthRoutes.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: AuthRoutes.newPassword, builder: (_, _) => const NewPasswordScreen()),
      GoRoute(path: AuthRoutes.sessionError, builder: (_, _) => const SessionErrorScreen()),
      GoRoute(
        path: AuthRoutes.wrongRole,
        builder: (_, _) => const WrongRoleScreen(otherAppArabic: 'تطبيق الطالب', otherAppGerman: 'Schüler-App'),
      ),
      GoRoute(path: TeacherRoutes.profileSetup, builder: (_, _) => const ProfileSetupScreen()),
      GoRoute(
        path: TeacherRoutes.dashboard,
        builder: (_, _) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'student/:id',
            builder: (_, state) =>
                StudentDetailScreen(studentId: state.pathParameters['id']!, student: state.extra as LinkParty?),
            routes: [
              GoRoute(
                path: 'chat',
                builder: (_, state) =>
                    StudentChatScreen(studentId: state.pathParameters['id']!, student: state.extra as LinkParty?),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
