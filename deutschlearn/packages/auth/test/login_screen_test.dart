import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(List<Override> overrides) {
  final router = GoRouter(
    initialLocation: AuthRoutes.login,
    routes: [
      GoRoute(path: AuthRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AuthRoutes.signUp,
        builder: (_, _) => const Scaffold(body: Text('signup')),
      ),
      GoRoute(
        path: AuthRoutes.resetPassword,
        builder: (_, _) => const Scaffold(body: Text('reset')),
      ),
    ],
  );
  return ProviderScope(
    retry: noRetry,
    overrides: overrides,
    child: MaterialApp.router(theme: DLTheme.light(), routerConfig: router),
  );
}

void main() {
  late FakeAuthGateway auth;
  late FakeProfileRepository profiles;

  setUp(() {
    auth = FakeAuthGateway(accounts: {'amira@example.com': (password: 'deutsch1', id: 'u1')});
    profiles = FakeProfileRepository({
      'u1': const Profile(id: 'u1', role: Role.student, displayName: 'Amira', locale: 'ar', cefrLevel: CefrLevel.a2),
    });
  });

  List<Override> overrides() => [
    authGatewayProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
  ];

  testWidgets('empty form shows validation errors and does not call the backend', (tester) async {
    await tester.pumpWidget(_app(overrides()));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('أدخل بريدك الإلكتروني • E-Mail eingeben'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور • Passwort eingeben'), findsOneWidget);
    expect(auth.signInCalls, isEmpty);
  });

  testWidgets('invalid email format is rejected locally', (tester) async {
    await tester.pumpWidget(_app(overrides()));
    await tester.enterText(find.byKey(const Key('login-email')), 'amira@');
    await tester.enterText(find.byKey(const Key('login-password')), 'x');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('بريد إلكتروني غير صالح • Ungültige E-Mail-Adresse'), findsOneWidget);
    expect(auth.signInCalls, isEmpty);
  });

  testWidgets('wrong password shows the backend error', (tester) async {
    await tester.pumpWidget(_app(overrides()));
    await tester.enterText(find.byKey(const Key('login-email')), 'amira@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(auth.signInCalls, ['amira@example.com']);
    expect(find.byKey(const Key('form-error')), findsOneWidget);
    expect(find.textContaining('غير صحيحة'), findsOneWidget);
  });

  testWidgets('valid credentials sign in and load the profile', (tester) async {
    final container = ProviderContainer(overrides: overrides(), retry: noRetry);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: AuthRoutes.login,
      routes: [GoRoute(path: AuthRoutes.login, builder: (_, _) => const LoginScreen())],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(find.byKey(const Key('login-email')), 'amira@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), 'deutsch1');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    final session = container.read(sessionControllerProvider);
    expect(session, isA<SessionSignedIn>());
    expect((session as SessionSignedIn).profile.cefrLevel, CefrLevel.a2);
  });

  testWidgets('unconfigured backend shows the banner and an explicit error', (tester) async {
    await tester.pumpWidget(_app([]));
    expect(find.byKey(const Key('backend-not-configured-banner')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login-email')), 'amira@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), 'deutsch1');
    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('form-error')), findsOneWidget);
    expect(find.textContaining('الخادم غير مُعدّ'), findsOneWidget);
  });
}
