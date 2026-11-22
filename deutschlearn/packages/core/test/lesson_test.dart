import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shuffled quiz options keep the right answer and are stable', () {
    const item = LessonItem(id: 'q-123', kind: LessonItemKind.quiz, options: ['a', 'b', 'c'], answer: 0);
    final s1 = item.shuffled();
    final s2 = item.shuffled();
    expect(s1.options, s2.options);
    expect(s1.options[s1.answer], 'a');
    expect(s1.options.toSet(), {'a', 'b', 'c'});
  });

  test('progress summary counts, averages and next lesson', () {
    const a = Lesson(id: 'a', titleDe: 'A', position: 1);
    const b = Lesson(id: 'b', titleDe: 'B', position: 2);
    const c = Lesson(id: 'c', titleDe: 'C', level: CefrLevel.a2, position: 1);
    final s = ProgressSummary(
      lessons: const [c, b, a],
      progress: {'a': LessonProgress(lessonId: 'a', bestScore: 1, maxScore: 2, completedAt: DateTime.utc(2026))},
    );
    expect(s.completed, 1);
    expect(s.total, 3);
    expect(s.averageScore, 0.5);
    expect(s.next?.id, 'b');
    expect(s.forLevel(CefrLevel.a2), (done: 0, total: 1));
  });
}
