import 'lesson.dart';

/// Homework: assigned by a teacher to students (individually or via a class),
/// answered and submitted by students, then graded with feedback.
enum HomeworkKind {
  lesson,
  exercises,
  custom,
  study;

  static HomeworkKind parse(Object? v) => values.firstWhere((k) => k.name == v, orElse: () => lesson);
}

/// A teacher-written question. [answer] is the expected answer (empty for open questions graded by hand).
class CustomItem {
  const CustomItem({required this.kind, required this.prompt, this.options = const [], this.answer = ''});

  /// 'quiz' (pick one of [options]), 'write' (type an answer) or 'open' (free text, teacher grades).
  final String kind;
  final String prompt;
  final List<String> options;
  final String answer;

  bool get isAutoGraded => kind != 'open' && answer.trim().isNotEmpty;

  bool accepts(String input) {
    String n(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[.!?,;]'), '').replaceAll(RegExp(r'\s+'), ' ');
    return answer.split('|').any((a) => n(a) == n(input) && n(a).isNotEmpty);
  }

  factory CustomItem.fromJson(Map<String, dynamic> j) => CustomItem(
    kind: j['kind'] as String? ?? 'open',
    prompt: j['prompt'] as String? ?? '',
    options: [for (final o in (j['options'] as List?) ?? const []) o.toString()],
    answer: j['answer'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'kind': kind, 'prompt': prompt, 'options': options, 'answer': answer};
}

class Homework {
  const Homework({
    required this.id,
    required this.teacherId,
    required this.kind,
    required this.title,
    this.instructions = '',
    this.lessonId,
    this.itemIds = const [],
    this.customItems = const [],
    this.classId,
    this.dueAt,
    this.createdAt,
  });

  final String id;
  final String teacherId;
  final HomeworkKind kind;
  final String title;
  final String instructions;
  final String? lessonId;
  final List<String> itemIds;
  final List<CustomItem> customItems;
  final String? classId;
  final DateTime? dueAt;
  final DateTime? createdAt;

  bool isOverdue([DateTime? now]) => dueAt != null && (now ?? DateTime.now()).isAfter(dueAt!);

  factory Homework.fromJson(Map<String, dynamic> j) => Homework(
    id: j['id'] as String,
    teacherId: j['teacher_id'] as String,
    kind: HomeworkKind.parse(j['kind']),
    title: j['title'] as String? ?? '',
    instructions: j['instructions'] as String? ?? '',
    lessonId: j['lesson_id'] as String?,
    itemIds: [for (final i in (j['item_ids'] as List?) ?? const []) i.toString()],
    customItems: [
      for (final i in (j['custom_items'] as List?) ?? const [])
        CustomItem.fromJson(Map<String, dynamic>.from(i as Map)),
    ],
    classId: j['class_id'] as String?,
    dueAt: j['due_at'] == null ? null : DateTime.parse(j['due_at'] as String).toLocal(),
    createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String).toLocal(),
  );

  Map<String, dynamic> toInsert() => {
    'teacher_id': teacherId,
    'kind': kind.name,
    'title': title.trim(),
    'instructions': instructions.trim(),
    'lesson_id': lessonId,
    'item_ids': itemIds,
    'custom_items': [for (final c in customItems) c.toJson()],
    'class_id': classId,
    'due_at': dueAt?.toUtc().toIso8601String(),
  };
}

enum SubmissionStatus {
  notStarted,
  inProgress,
  submitted,
  graded,
  returned;

  static SubmissionStatus parse(Object? v) => switch (v) {
    'in_progress' => inProgress,
    'submitted' => submitted,
    'graded' => graded,
    'returned' => returned,
    _ => notStarted,
  };

  String get ar => switch (this) {
    notStarted => 'لم يبدأ',
    inProgress => 'قيد الحل',
    submitted => 'تم التسليم',
    graded => 'تم التصحيح',
    returned => 'أعيد للتعديل',
  };

  String get de => switch (this) {
    notStarted => 'Nicht begonnen',
    inProgress => 'In Bearbeitung',
    submitted => 'Abgegeben',
    graded => 'Bewertet',
    returned => 'Zur Überarbeitung',
  };

  bool get editableByStudent => this == notStarted || this == inProgress || this == returned;
}

class HomeworkSubmission {
  const HomeworkSubmission({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.status,
    this.answers = const {},
    this.autoScore = 0,
    this.maxScore = 0,
    this.grade,
    this.feedback = '',
    this.corrections = const {},
    this.submittedAt,
    this.gradedAt,
    this.updatedAt,
  });

  final String id;
  final String homeworkId;
  final String studentId;
  final SubmissionStatus status;

  /// Answer per question key (lesson item id or `c<index>` for custom questions).
  final Map<String, String> answers;
  final int autoScore;
  final int maxScore;
  final int? grade;
  final String feedback;

  /// Teacher's correction per question key.
  final Map<String, String> corrections;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime? updatedAt;

  bool isLate(Homework h) => h.dueAt != null && submittedAt != null && submittedAt!.isAfter(h.dueAt!);

  static Map<String, String> _strings(Object? v) =>
      v is Map ? {for (final e in v.entries) e.key.toString(): e.value?.toString() ?? ''} : const {};

  factory HomeworkSubmission.fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) => j[k] == null ? null : DateTime.parse(j[k] as String).toLocal();
    return HomeworkSubmission(
      id: j['id'] as String,
      homeworkId: j['homework_id'] as String,
      studentId: j['student_id'] as String,
      status: SubmissionStatus.parse(j['status']),
      answers: _strings(j['answers']),
      autoScore: (j['auto_score'] as num?)?.toInt() ?? 0,
      maxScore: (j['max_score'] as num?)?.toInt() ?? 0,
      grade: (j['grade'] as num?)?.toInt(),
      feedback: j['feedback'] as String? ?? '',
      corrections: _strings(j['corrections']),
      submittedAt: d('submitted_at'),
      gradedAt: d('graded_at'),
      updatedAt: d('updated_at'),
    );
  }
}

class SchoolClass {
  const SchoolClass({required this.id, required this.teacherId, required this.name, this.memberIds = const []});

  final String id;
  final String teacherId;
  final String name;
  final List<String> memberIds;

  factory SchoolClass.fromJson(Map<String, dynamic> j) => SchoolClass(
    id: j['id'] as String,
    teacherId: j['teacher_id'] as String,
    name: j['name'] as String? ?? '',
    memberIds: [for (final m in (j['class_members'] as List?) ?? const []) (m as Map)['student_id'] as String],
  );
}

/// One question of a homework: a lesson exercise or a teacher-written question.
typedef HomeworkQuestion = ({String key, LessonItem? item, CustomItem? custom});

List<HomeworkQuestion> homeworkQuestions(Homework h, Lesson? lesson) => [
  if (lesson != null)
    for (final i in lesson.items)
      if (i.isScored && (h.kind == HomeworkKind.lesson || h.itemIds.contains(i.id))) (key: i.id, item: i, custom: null),
  for (final (n, c) in h.customItems.indexed) (key: 'c$n', item: null, custom: c),
];

/// Auto-score: correct lesson exercises plus auto-gradable custom answers.
({int score, int max}) scoreAnswers(List<HomeworkQuestion> qs, Map<String, String> answers) {
  var score = 0, max = 0;
  for (final q in qs) {
    final a = answers[q.key] ?? '';
    if (q.item != null) {
      max++;
      if (a == '✓') score++;
    } else if (q.custom!.isAutoGraded) {
      max++;
      if (q.custom!.accepts(a)) score++;
    }
  }
  return (score: score, max: max);
}
