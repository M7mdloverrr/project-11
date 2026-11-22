import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:student/src/link/link_teacher_screen.dart';

void main() {
  late FakeLinkRepository repo;

  setUp(() {
    repo = FakeLinkRepository()..codes['TCH-7K2P9Q'] = const TeacherPublicInfo(displayName: 'Frau Weber');
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [linkRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: DLTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const LinkTeacherScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> lookup(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('link-code-input')), code);
    await tapKey(tester, 'link-lookup');
  }

  testWidgets('invalid and unknown codes show errors without creating a request', (tester) async {
    await pumpScreen(tester);
    await lookup(tester, 'ABC');
    expect(find.textContaining('صيغة الرمز غير صحيحة'), findsOneWidget);

    await lookup(tester, 'TCH-ZZZZZZ');
    expect(find.textContaining('لم يتم العثور على معلم'), findsOneWidget);
    expect(repo.studentLink, isNull);
  });

  testWidgets('enter code → preview teacher → confirm → pending → active → disconnected', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const Key('link-code-input')), findsOneWidget);

    await lookup(tester, 'tch 7k2p9q');
    expect(find.byKey(const Key('link-preview')), findsOneWidget);
    expect(find.text('Frau Weber'), findsOneWidget);
    expect(repo.studentLink, isNull, reason: 'preview must not create a link');

    await tapKey(tester, 'link-confirm');
    expect(repo.studentLink?.status, LinkStatus.pending);
    expect(find.byKey(const Key('link-status-pending')), findsOneWidget);
    expect(find.byKey(const Key('link-code-input')), findsNothing);

    // Teacher approves in the other app.
    repo.setStudentLinkStatus(LinkStatus.active);
    await tapKey(tester, 'link-refresh');
    expect(find.byKey(const Key('link-status-active')), findsOneWidget);

    await tapKey(tester, 'link-disconnect');
    await tapKey(tester, 'confirm-disconnect');
    expect(repo.studentLink?.status, LinkStatus.disconnected);
    expect(find.byKey(const Key('link-status-disconnected')), findsOneWidget);
    expect(find.byKey(const Key('link-code-input')), findsOneWidget, reason: 'can link again');
  });

  testWidgets('"not this teacher" returns to code entry', (tester) async {
    await pumpScreen(tester);
    await lookup(tester, 'TCH-7K2P9Q');
    await tapKey(tester, 'link-cancel');
    expect(find.byKey(const Key('link-code-input')), findsOneWidget);
    expect(repo.studentLink, isNull);
  });

  testWidgets('backend errors are shown on the preview', (tester) async {
    await pumpScreen(tester);
    await lookup(tester, 'TCH-7K2P9Q');
    repo.nextError = const AppFailure(FailureKind.rateLimited);
    await tapKey(tester, 'link-confirm');
    expect(find.textContaining('محاولات كثيرة'), findsOneWidget);
    expect(find.byKey(const Key('link-preview')), findsOneWidget);
  });
}
