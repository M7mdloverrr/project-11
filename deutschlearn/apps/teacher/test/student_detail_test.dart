import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teacher/src/students/student_detail_screen.dart';

void main() {
  testWidgets('teacher sees student progress and assigns homework', (tester) async {
    final repo = FakeLessonRepository(studentId: 'student-1')
      ..lessons.addAll(const [
        Lesson(id: 'l1', titleDe: 'Begrüßung', titleAr: 'التحية', position: 1),
        Lesson(id: 'l2', titleDe: 'Zahlen', titleAr: 'الأرقام', position: 2),
      ])
      ..progress['l1'] = LessonProgress(
        studentId: 'student-1',
        lessonId: 'l1',
        bestScore: 3,
        maxScore: 4,
        attempts: 2,
        completedAt: DateTime.utc(2026),
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
          home: const StudentDetailScreen(
            studentId: 'student-1',
            student: LinkParty(id: 'student-1', displayName: 'Amira'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.textContaining('3/4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assign-l2')));
    await tester.pumpAndSettle();
    expect(repo.assignments.single.lessonId, 'l2');
    expect(find.textContaining('Hausaufgabe'), findsWidgets);

    await tester.tap(find.byKey(const Key('assign-l2')));
    await tester.pumpAndSettle();
    expect(repo.assignments, isEmpty);
  });
}
