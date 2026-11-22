import 'cefr_level.dart';

enum LessonItemKind {
  vocab,
  phrase,
  quiz;

  static LessonItemKind parse(Object? v) =>
      LessonItemKind.values.firstWhere((k) => k.name == v, orElse: () => LessonItemKind.vocab);
}

class LessonItem {
  const LessonItem({
    required this.id,
    required this.kind,
    this.position = 0,
    this.german = '',
    this.arabic = '',
    this.exampleDe,
    this.exampleAr,
    this.options = const [],
    this.answer,
  });

  factory LessonItem.fromJson(Map<String, dynamic> j) => LessonItem(
    id: j['id'] as String,
    kind: LessonItemKind.parse(j['kind']),
    position: (j['position'] as num?)?.toInt() ?? 0,
    german: (j['german'] as String?) ?? '',
    arabic: (j['arabic'] as String?) ?? '',
    exampleDe: j['example_de'] as String?,
    exampleAr: j['example_ar'] as String?,
    options: ((j['options'] as List<dynamic>?) ?? const []).map((o) => o.toString()).toList(),
    answer: (j['answer'] as num?)?.toInt(),
  );

  final String id;
  final LessonItemKind kind;
  final int position;

  /// vocab/phrase: German text; quiz: optional German prompt.
  final String german;

  /// vocab/phrase: Arabic meaning; quiz: the question.
  final String arabic;
  final String? exampleDe;
  final String? exampleAr;
  final List<String> options;

  /// Index into [options] of the correct answer (quiz only).
  final int? answer;

  bool get isQuiz => kind == LessonItemKind.quiz;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'position': position,
    'german': german,
    'arabic': arabic,
    'example_de': (exampleDe?.trim().isEmpty ?? true) ? null : exampleDe!.trim(),
    'example_ar': (exampleAr?.trim().isEmpty ?? true) ? null : exampleAr!.trim(),
    'options': isQuiz ? options : null,
    'answer': isQuiz ? answer : null,
  };

  /// Quiz options in a stable shuffled order (the stored correct answer is
  /// usually first), with the index of the correct one.
  ({List<String> options, int answer}) shuffled() {
    final order = List<int>.generate(options.length, (i) => i);
    var seed = id.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
    for (var i = order.length - 1; i > 0; i--) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final j = seed % (i + 1);
      final t = order[i];
      order[i] = order[j];
      order[j] = t;
    }
    return (options: [for (final i in order) options[i]], answer: order.indexOf(answer ?? 0));
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.titleDe,
    this.level = CefrLevel.a1,
    this.position = 0,
    this.titleAr = '',
    this.descriptionAr = '',
    this.published = true,
    this.itemCount = 0,
    this.items = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> j) {
    final items = j['lesson_items'];
    final parsed = items is List
        ? (items.cast<Map<String, dynamic>>().map(LessonItem.fromJson).toList()
            ..sort((a, b) => a.position.compareTo(b.position)))
        : const <LessonItem>[];
    final count = j['item_count'];
    return Lesson(
      id: j['id'] as String,
      level: CefrLevel.parse(j['cefr_level']),
      position: (j['position'] as num?)?.toInt() ?? 0,
      titleDe: (j['title_de'] as String?) ?? '',
      titleAr: (j['title_ar'] as String?) ?? '',
      descriptionAr: (j['description_ar'] as String?) ?? '',
      published: (j['published'] as bool?) ?? true,
      items: parsed,
      itemCount: count is List && count.isNotEmpty
          ? ((count.first as Map<String, dynamic>)['count'] as num).toInt()
          : parsed.length,
    );
  }

  final String id;
  final CefrLevel level;
  final int position;
  final String titleDe;
  final String titleAr;
  final String descriptionAr;
  final bool published;
  final int itemCount;

  /// Only filled when the lesson was loaded with its items.
  final List<LessonItem> items;

  int get quizCount => items.where((i) => i.isQuiz).length;
}

class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.bestScore,
    required this.maxScore,
    required this.completedAt,
    this.studentId = '',
    this.attempts = 1,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
    studentId: (j['student_id'] as String?) ?? '',
    lessonId: j['lesson_id'] as String,
    bestScore: (j['best_score'] as num?)?.toInt() ?? 0,
    maxScore: (j['max_score'] as num?)?.toInt() ?? 0,
    attempts: (j['attempts'] as num?)?.toInt() ?? 1,
    completedAt: DateTime.parse(j['completed_at'] as String),
  );

  final String studentId;
  final String lessonId;
  final int bestScore;
  final int maxScore;
  final int attempts;
  final DateTime completedAt;

  /// 0..1; a lesson without quizzes counts as fully done.
  double get ratio => maxScore == 0 ? 1 : bestScore / maxScore;
}

/// Totals for the Fortschritt tab and teacher views.
class ProgressSummary {
  const ProgressSummary({required this.lessons, required this.progress});

  final List<Lesson> lessons;
  final Map<String, LessonProgress> progress;

  int get completed => lessons.where((l) => progress.containsKey(l.id)).length;
  int get total => lessons.length;
  double get ratio => total == 0 ? 0 : completed / total;

  /// Average best quiz score over completed lessons, 0..1.
  double get averageScore {
    final done = lessons.map((l) => progress[l.id]).whereType<LessonProgress>().toList();
    if (done.isEmpty) return 0;
    return done.map((p) => p.ratio).reduce((a, b) => a + b) / done.length;
  }

  ({int done, int total}) forLevel(CefrLevel level) {
    final ls = lessons.where((l) => l.level == level).toList();
    return (done: ls.where((l) => progress.containsKey(l.id)).length, total: ls.length);
  }

  /// First lesson (in level/position order) that is not completed yet.
  Lesson? get next {
    final sorted = [...lessons]
      ..sort((a, b) => a.level.index != b.level.index ? a.level.index - b.level.index : a.position - b.position);
    for (final l in sorted) {
      if (!progress.containsKey(l.id)) return l;
    }
    return null;
  }
}

/// A lesson a teacher assigned to a linked student as homework.
class LessonAssignment {
  const LessonAssignment({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.lessonId,
    required this.createdAt,
    this.note = '',
    this.dueOn,
  });

  factory LessonAssignment.fromJson(Map<String, dynamic> j) => LessonAssignment(
    id: j['id'] as String,
    teacherId: j['teacher_id'] as String,
    studentId: j['student_id'] as String,
    lessonId: j['lesson_id'] as String,
    note: (j['note'] as String?) ?? '',
    dueOn: j['due_on'] == null ? null : DateTime.parse(j['due_on'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  final String id;
  final String teacherId;
  final String studentId;
  final String lessonId;
  final String note;
  final DateTime? dueOn;
  final DateTime createdAt;
}
