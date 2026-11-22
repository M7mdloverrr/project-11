import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Lesson _l(String id, String module, int pos, {LessonKind kind = LessonKind.lesson, CefrLevel level = CefrLevel.a1}) =>
    Lesson(id: id, titleDe: id, moduleId: module, position: pos, kind: kind, level: level);

LessonProgress _p(String id, int score, int max) =>
    LessonProgress(studentId: 's', lessonId: id, bestScore: score, maxScore: max, completedAt: DateTime(2026));

void main() {
  const m1 = CurriculumModule(id: 'm1', titleDe: 'Alphabet', slug: 'alphabet', position: 0);
  const m2 = CurriculumModule(id: 'm2', titleDe: 'Kontakte', position: 1);
  const m3 = CurriculumModule(id: 'm3', titleDe: 'A2', level: CefrLevel.a2, position: 1);
  final lessons = [
    _l('b1', 'm2', 101),
    _l('a2', 'm1', 2),
    _l('a1', 'm1', 1),
    _l('t', 'm2', 102, kind: LessonKind.test),
    _l('x', 'm3', 101, level: CefrLevel.a2),
    _l('p', 'm1', 99, kind: LessonKind.placement),
  ];

  test('orders the path by level, module and position and keeps placement separate', () {
    final c = Curriculum(modules: const [m3, m2, m1], lessons: lessons, progress: const {});
    expect(c.path.map((l) => l.id), ['a1', 'a2', 'b1', 't', 'x']);
    expect(c.placement?.id, 'p');
  });

  test('a lesson unlocks only after the previous one is passed with 70%', () {
    var c = Curriculum(modules: const [m1, m2, m3], lessons: lessons, progress: {'a1': _p('a1', 6, 10)});
    expect(c.isUnlocked(lessons[2]), isTrue);
    expect(c.isUnlocked(lessons[1]), isFalse);
    expect(c.next?.id, 'a1');
    c = Curriculum(modules: const [m1, m2, m3], lessons: lessons, progress: {'a1': _p('a1', 7, 10)});
    expect(c.isUnlocked(lessons[1]), isTrue);
    expect(c.next?.id, 'a2');
    expect(c.moduleProgress(m1), (done: 1, total: 2));
    expect(c.isModuleUnlocked(m3), isFalse);
  });

  test('placement level opens lower levels and the start of the placed level', () {
    final c = Curriculum(modules: const [m1, m2, m3], lessons: lessons, progress: const {}, level: CefrLevel.a2);
    expect(c.isUnlocked(lessons[3]), isTrue);
    expect(c.isUnlocked(lessons[4]), isTrue);
    expect(Curriculum.levelForPlacement(0.3), CefrLevel.a1);
    expect(Curriculum.levelForPlacement(0.6), CefrLevel.a2);
    expect(Curriculum.levelForPlacement(0.85), CefrLevel.b1);
  });

  test('write answers accept umlaut spellings, case and punctuation', () {
    const item = LessonItem(id: 'w', kind: LessonItemKind.write, german: 'Ich heiße Anna.|Mein Name ist Anna.');
    expect(item.accepts('ich heisse anna'), isTrue);
    expect(item.accepts('Mein Name ist Anna'), isTrue);
    expect(item.accepts('Ich bin Anna'), isFalse);
    expect(item.accepts(''), isFalse);
  });

  test('order scrambles differently from the answer; match parses pairs', () {
    const order = LessonItem(id: 'o', kind: LessonItemKind.order, german: 'Ich wohne in Berlin.');
    expect(order.scrambledWords.join(' '), isNot('Ich wohne in Berlin.'));
    expect([...order.scrambledWords]..sort(), [...'Ich wohne in Berlin.'.split(' ')]..sort());
    const match = LessonItem(id: 'm', kind: LessonItemKind.match, options: ['der Hund = الكلب', 'die Katze = القطة']);
    expect(match.pairs.first, (de: 'der Hund', ar: 'الكلب'));
    expect(LessonItemKind.text.isScored, isFalse);
    expect(LessonItemKind.match.isScored, isTrue);
  });
}
