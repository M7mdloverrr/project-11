import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:student/src/lessons/lesson_screen.dart';

void main() {
  testWidgets('step through a lesson, answer the quiz and save progress', (tester) async {
    const quiz = LessonItem(
      id: 'q1',
      kind: LessonItemKind.quiz,
      arabic: 'ماذا تعني Hallo؟',
      options: ['مرحباً', 'وداعاً', 'شكراً'],
      answer: 0,
    );
    final repo = FakeLessonRepository()
      ..lessons.add(
        const Lesson(
          id: 'l1',
          titleDe: 'Begrüßung',
          titleAr: 'التحية',
          items: [
            LessonItem(id: 'v1', kind: LessonItemKind.vocab, german: 'Hallo', arabic: 'مرحباً'),
            quiz,
          ],
        ),
      );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: DLTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const LessonScreen(lessonId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hallo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lesson-next')));
    await tester.pumpAndSettle();

    final correct = quiz.shuffled().answer;
    await tester.tap(find.byKey(Key('option-$correct')));
    await tester.pumpAndSettle();
    expect(find.textContaining('إجابة صحيحة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lesson-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 / 1'), findsOneWidget);
    expect(repo.completions.single, (lessonId: 'l1', score: 1, max: 1));
  });
}
