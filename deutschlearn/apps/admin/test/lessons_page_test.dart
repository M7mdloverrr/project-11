import 'package:admin/src/pages/lessons_page.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('admin creates, lists and deletes a lesson', (tester) async {
    final repo = FakeLessonRepository();
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: DLTheme.light(),
          home: const Scaffold(body: LessonsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No lessons yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-lesson')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-save')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('lesson-title-de')), 'Im Café');
    await tester.enterText(find.byKey(const Key('lesson-title-ar')), 'في المقهى');
    await tester.tap(find.byKey(const Key('lesson-save')));
    await tester.pumpAndSettle();
    expect(repo.lessons.single.titleDe, 'Im Café');
    expect(repo.lessons.single.published, isFalse);
    expect(find.textContaining('Im Café'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    await tester.tap(find.byKey(Key('delete-${repo.lessons.single.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-action')));
    await tester.pumpAndSettle();
    expect(repo.lessons, isEmpty);
  });
}
