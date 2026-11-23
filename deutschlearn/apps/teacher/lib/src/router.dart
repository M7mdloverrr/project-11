import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'classroom/homework_create_screen.dart';
import 'classroom/homework_screens.dart';
import 'classroom/live_control_screen.dart';
import 'classroom/teaching_screens.dart';
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
  static const homework = '/dashboard/homework';
  static const homeworkNew = '/dashboard/homework/new';
  static String homeworkDetail(String id) => '/dashboard/homework/$id';
  static String review(String homeworkId, String studentId) => '/dashboard/homework/$homeworkId/review/$studentId';
  static const live = '/dashboard/live';
  static const lessons = '/dashboard/lessons';
  static String lessonPreview(String id) => '/dashboard/lessons/$id';
  static const reports = '/dashboard/reports';
  static const classes = '/dashboard/classes';
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
            path: 'homework',
            builder: (_, _) => const TeacherHomeworkScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) => HomeworkCreateScreen(args: state.extra as HomeworkDraftArgs?),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => TeacherHomeworkDetailScreen(homeworkId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'review/:student',
                    builder: (_, state) => SubmissionReviewScreen(
                      homeworkId: state.pathParameters['id']!,
                      studentId: state.pathParameters['student']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'live',
            builder: (_, state) => LiveControlScreen(lessonId: state.extra as String?),
          ),
          GoRoute(
            path: 'lessons',
            builder: (_, _) => const LessonBrowserScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => LessonPreviewScreen(lessonId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: 'reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: 'classes', builder: (_, _) => const ClassesScreen()),
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
