import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:admin/src/app.dart';
import 'package:admin/src/pages/codes_page.dart';
import 'package:admin/src/pages/links_page.dart';
import 'package:admin/src/pages/users_page.dart';
import 'package:admin/src/set_password_dialog.dart';

final _now = DateTime.utc(2026, 11, 22);

FakeAdminRepository _seed() {
  final repo = FakeAdminRepository();
  repo.users.addAll([
    AdminUser(
      id: 'admin-1',
      email: 'boss@x.de',
      role: Role.admin,
      displayName: 'Boss',
      createdAt: _now,
      emailConfirmedAt: _now,
    ),
    AdminUser(
      id: 't1',
      email: 'weber@x.de',
      role: Role.teacher,
      displayName: 'Frau Weber',
      createdAt: _now,
      emailConfirmedAt: _now,
    ),
    AdminUser(
      id: 's1',
      email: 'amira@x.de',
      role: Role.student,
      displayName: 'Amira',
      createdAt: _now,
      emailConfirmedAt: _now,
    ),
    AdminUser(id: 's2', email: 'omar@x.de', role: Role.student, displayName: 'Omar', createdAt: _now),
  ]);
  repo.links.add(
    TeacherStudentLink(
      id: 'l1',
      teacherId: 't1',
      studentId: 's2',
      status: LinkStatus.pending,
      updatedAt: _now,
      teacher: const LinkParty(id: 't1', displayName: 'Frau Weber'),
      student: const LinkParty(id: 's2', displayName: 'Omar'),
    ),
  );
  repo.requests.add(
    AdminLinkRequest(
      id: 'r1',
      linkId: 'l1',
      status: LinkRequestStatus.pending,
      createdAt: _now,
      teacher: const LinkParty(id: 't1', displayName: 'Frau Weber'),
      student: const LinkParty(id: 's2', displayName: 'Omar'),
    ),
  );
  return repo;
}

Future<void> _pump(WidgetTester tester, Widget page, FakeAdminRepository repo) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: DLTheme.light(),
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without Supabase env the panel says the backend is not configured', (tester) async {
    await tester.pumpWidget(const ProviderScope(retry: noRetry, child: AdminApp()));
    await tester.pumpAndSettle();
    expect(find.text('Backend not configured'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL is missing'), findsOneWidget);
  });

  testWidgets('a signed-in non-admin is refused', (tester) async {
    final auth = FakeAuthGateway(
      restoredUser: const AuthUser(id: 't1', email: 'weber@x.de'),
    );
    final profiles = FakeProfileRepository()
      ..profiles['t1'] = const Profile(id: 't1', role: Role.teacher, displayName: 'Frau Weber');
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
          allowedRolesProvider.overrideWithValue(const {Role.admin}),
        ],
        child: const AdminApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admins only'), findsOneWidget);
  });

  testWidgets('users: search, filter and edit role/level', (tester) async {
    final repo = _seed();
    await _pump(tester, const UsersPage(), repo);
    expect(find.text('4 user(s)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('user-search')), 'amira');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('1 user(s)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('user-search')), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('role-filter-student')));
    expect(find.text('2 user(s)'), findsOneWidget);
    expect(find.text('E-mail not confirmed'), findsOneWidget);

    await _tap(tester, find.text('Amira'));
    await _tap(tester, find.byKey(const Key('edit-level')));
    await _tap(tester, find.text('B1').last);
    await _tap(tester, find.byKey(const Key('edit-save')));
    expect(repo.users.firstWhere((u) => u.id == 's1').cefrLevel, CefrLevel.b1);
    expect(repo.audit.first.action, 'update_profile');
  });

  testWidgets('users: block, reset link and delete with confirmation', (tester) async {
    final repo = _seed();
    await _pump(tester, const UsersPage(), repo);

    await _tap(tester, find.byKey(const Key('user-menu-s1')));
    await _tap(tester, find.byKey(const Key('user-action-block')));
    await _tap(tester, find.byKey(const Key('confirm-action')));
    expect(repo.users.firstWhere((u) => u.id == 's1').isBlocked, isTrue);
    expect(find.text('Blocked'), findsOneWidget);

    await _tap(tester, find.byKey(const Key('user-menu-s1')));
    await _tap(tester, find.byKey(const Key('user-action-resetLink')));
    expect(find.byKey(const Key('reset-link')), findsOneWidget);
    await _tap(tester, find.text('Close'));

    await _tap(tester, find.byKey(const Key('user-menu-s2')));
    await _tap(tester, find.byKey(const Key('user-action-delete')));
    await _tap(tester, find.text('Cancel'));
    expect(repo.users.any((u) => u.id == 's2'), isTrue, reason: 'cancel keeps the user');
    await _tap(tester, find.byKey(const Key('user-menu-s2')));
    await _tap(tester, find.byKey(const Key('user-action-delete')));
    await _tap(tester, find.byKey(const Key('confirm-action')));
    expect(repo.users.any((u) => u.id == 's2'), isFalse);
    expect(find.text('Omar'), findsNothing);
  });

  testWidgets('users: add a teacher with a password', (tester) async {
    final repo = _seed();
    await _pump(tester, const UsersPage(), repo);
    await _tap(tester, find.byKey(const Key('add-user')));
    await _tap(tester, find.byKey(const Key('create-submit')));
    expect(find.text('Enter a valid e-mail address'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('create-email')), 'neu@x.de');
    await tester.enterText(find.byKey(const Key('create-name')), 'Herr Neu');
    await tester.enterText(find.byKey(const Key('create-password')), 'geheim123');
    await _tap(tester, find.byKey(const Key('create-submit')));
    final created = repo.users.firstWhere((u) => u.email == 'neu@x.de');
    expect(created.role, Role.teacher);
    expect(find.text('Herr Neu'), findsOneWidget);
  });

  testWidgets('links: approve a pending request, then disconnect', (tester) async {
    final repo = _seed();
    await _pump(tester, const LinksPage(), repo);
    await _tap(tester, find.byKey(const Key('approve-r1')));
    expect(repo.requests.single.status, LinkRequestStatus.approved);
    expect(repo.links.single.status, LinkStatus.active);
    expect(find.text('No pending requests'), findsOneWidget);

    await _tap(tester, find.byKey(const Key('disconnect-l1')));
    await _tap(tester, find.byKey(const Key('confirm-action')));
    expect(repo.links.single.status, LinkStatus.disconnected);
  });

  testWidgets('codes: issue for a teacher and revoke', (tester) async {
    final repo = _seed();
    await _pump(tester, const CodesPage(), repo);
    expect(find.text('No codes'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('issue-code')));
    await _tap(tester, find.byKey(const Key('pick-teacher')));
    await _tap(tester, find.textContaining('weber@x.de').last);
    await _tap(tester, find.byKey(const Key('pick-teacher-submit')));
    final code = repo.codes.single;
    expect(find.text(code.code), findsOneWidget);

    await _tap(tester, find.byKey(Key('revoke-${code.id}')));
    await _tap(tester, find.byKey(const Key('confirm-action')));
    expect(repo.codes.single.revoked, isTrue);
    expect(find.text('No codes'), findsOneWidget);
  });

  testWidgets('backend failures are shown with a retry button', (tester) async {
    final repo = _seed()..nextError = const AppFailure(FailureKind.network);
    await _pump(tester, const UsersPage(), repo);
    expect(find.textContaining('Cannot reach the server'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('retry')));
    expect(find.text('4 user(s)'), findsOneWidget);
  });

  testWidgets('after a one-time link the admin is asked to set a password', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = FakeAuthGateway(
      restoredUser: const AuthUser(id: 'admin-1', email: 'boss@x.de'),
    );
    final profiles = FakeProfileRepository()
      ..profiles['admin-1'] = const Profile(id: 'admin-1', role: Role.admin, displayName: 'Boss');
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
          adminRepositoryProvider.overrideWithValue(_seed()),
          allowedRolesProvider.overrideWithValue(const {Role.admin}),
          openedFromRecoveryLinkProvider.overrideWithValue(true),
        ],
        child: const AdminApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set your password'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('set-password-new')), 'geheim123');
    await tester.enterText(find.byKey(const Key('set-password-repeat')), 'geheim124');
    await _tap(tester, find.byKey(const Key('set-password-save')));
    expect(find.text('The passwords do not match'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('set-password-repeat')), 'geheim123');
    await _tap(tester, find.byKey(const Key('set-password-save')));
    expect(find.text('Set your password'), findsNothing);
    expect(find.text('Password saved'), findsOneWidget);

    // Also reachable any time from the app bar.
    await _tap(tester, find.byKey(const Key('set-password')));
    expect(find.text('Set your password'), findsOneWidget);
  });
}
