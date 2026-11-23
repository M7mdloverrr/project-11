/// A live lesson the teacher drives: students see the item at [itemIndex] of [lessonId].
class LiveSession {
  const LiveSession({
    required this.id,
    required this.teacherId,
    required this.title,
    this.classId,
    this.lessonId,
    this.itemIndex = 0,
    this.showAnswer = false,
    this.answererId,
    this.live = true,
    this.startedAt,
  });

  final String id;
  final String teacherId;
  final String title;
  final String? classId;
  final String? lessonId;
  final int itemIndex;
  final bool showAnswer;
  final String? answererId;
  final bool live;
  final DateTime? startedAt;

  factory LiveSession.fromJson(Map<String, dynamic> j) => LiveSession(
    id: j['id'] as String,
    teacherId: j['teacher_id'] as String,
    title: j['title'] as String? ?? '',
    classId: j['class_id'] as String?,
    lessonId: j['lesson_id'] as String?,
    itemIndex: (j['item_index'] as num?)?.toInt() ?? 0,
    showAnswer: j['show_answer'] as bool? ?? false,
    answererId: j['answerer_id'] as String?,
    live: j['status'] != 'ended',
    startedAt: j['started_at'] == null ? null : DateTime.parse(j['started_at'] as String).toLocal(),
  );
}

class LiveResponse {
  const LiveResponse({
    required this.sessionId,
    required this.studentId,
    required this.itemIndex,
    required this.answer,
    this.correct,
    this.teacherMark,
  });

  final String sessionId;
  final String studentId;
  final int itemIndex;
  final String answer;
  final bool? correct;

  /// 'correct', 'wrong' or 'retry' once the teacher has reacted.
  final String? teacherMark;

  factory LiveResponse.fromJson(Map<String, dynamic> j) => LiveResponse(
    sessionId: j['session_id'] as String,
    studentId: j['student_id'] as String,
    itemIndex: (j['item_index'] as num).toInt(),
    answer: j['answer'] as String? ?? '',
    correct: j['correct'] as bool?,
    teacherMark: j['teacher_mark'] as String?,
  );
}

class LiveParticipant {
  const LiveParticipant({required this.sessionId, required this.studentId, this.lastSeen});

  final String sessionId;
  final String studentId;
  final DateTime? lastSeen;

  factory LiveParticipant.fromJson(Map<String, dynamic> j) => LiveParticipant(
    sessionId: j['session_id'] as String,
    studentId: j['student_id'] as String,
    lastSeen: j['last_seen'] == null ? null : DateTime.parse(j['last_seen'] as String).toLocal(),
  );
}
