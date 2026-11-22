import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'home/home_shell.dart';
import 'lessons/lesson_screen.dart';
import 'link/link_teacher_screen.dart';
import 'onboarding.dart';

abstract final class StudentRoutes {
  static const welcome = '/welcome';
  static const home = '/home';
  static const linkTeacher = '/home/link-teacher';
  static String lesson(String id) => '/home/lesson/$id';
}

const _appSubtitle = 'منصة تعلّم الألمانية • Deutsch lernen';

final studentRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingSeenProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      session: ref.read(sessionControllerProvider),
      location: state.matchedLocation,
      allowedRoles: const {Role.student},
      signedOutHome: ref.read(onboardingSeenProvider) ? AuthRoutes.login : StudentRoutes.welcome,
      signedInHome: StudentRoutes.home,
      extraPublicRoutes: const {StudentRoutes.welcome},
    ),
    routes: [
      GoRoute(
        path: AuthRoutes.splash,
        builder: (_, _) => const SplashScreen(subtitle: _appSubtitle),
      ),
      GoRoute(
        path: AuthRoutes.notConfigured,
        builder: (_, _) =>
            const BackendNotConfiguredScreen(previewRoute: StudentRoutes.welcome, appName: 'DeutschLearn'),
      ),
      GoRoute(path: StudentRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
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
        builder: (_, _) => const WrongRoleScreen(otherAppArabic: 'تطبيق المعلّم', otherAppGerman: 'Lehrer-App'),
      ),
      GoRoute(
        path: StudentRoutes.home,
        builder: (_, _) => const HomeShell(),
        routes: [
          GoRoute(path: 'link-teacher', builder: (_, _) => const LinkTeacherScreen()),
          GoRoute(
            path: 'lesson/:id',
            builder: (_, state) => LessonScreen(lessonId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
