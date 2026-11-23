import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teacher/src/dashboard/dashboard_screen.dart';

const _teacher = Profile(
  id: 'teacher-1',
  role: Role.teacher,
  displayName: 'Frau Weber',
  locale: 'de',
  cefrLevel: CefrLevel.c1,
);

LinkRequest _request(String id, String name) => LinkRequest(
  id: id,
  linkId: 'link-$id',
  teacherId: 'teacher-1',
  studentId: 'student-$id',
  status: LinkRequestStatus.pending,
  createdAt: DateTime.utc(2026),
  student: LinkParty(id: 'student-$id', displayName: name, cefrLevel: CefrLevel.a1),
);

void main() {
  late FakeLinkRepository repo;

  setUp(() {
    repo = FakeLinkRepository()..pending.addAll([_request('r1', 'Amira'), _request('r2', 'Omar')]);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [linkRepositoryProvider.overrideWithValue(repo), currentProfileProvider.overrideWithValue(_teacher)],
        child: MaterialApp(
          theme: DLTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('generate, regenerate and revoke the teacher code', (tester) async {
    await pump(tester);
    expect(find.textContaining('Frau Weber'), findsOneWidget);
    await tapKey(tester, 'code-generate');
    final first = repo.activeCode!.code;
    expect(TeacherCodeFormat.isValid(first), isTrue);
    expect(find.text(first), findsOneWidget);

    await tapKey(tester, 'code-regenerate');
    await tapKey(tester, 'dialog-confirm');
    final second = repo.activeCode!.code;
    expect(second, isNot(first));
    expect(find.text(second), findsOneWidget);

    await tapKey(tester, 'code-revoke');
    await tapKey(tester, 'dialog-confirm');
    expect(repo.activeCode, isNull);
    expect(find.byKey(const Key('code-generate')), findsOneWidget);
  });

  testWidgets('approve and decline pending link requests', (tester) async {
    await pump(tester);
    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Omar'), findsOneWidget);
    expect(find.textContaining('لا يوجد طلاب مرتبطون'), findsOneWidget);

    await tapKey(tester, 'approve-r1');
    expect(find.byKey(const Key('request-r1')), findsNothing);
    expect(find.byKey(const Key('student-link-r1')), findsOneWidget);

    await tapKey(tester, 'decline-r2');
    expect(find.byKey(const Key('request-r2')), findsNothing);
    expect(find.textContaining('لا توجد طلبات جديدة'), findsOneWidget);
    expect(repo.linked.map((l) => l.student?.displayName), ['Amira']);
  });
}
