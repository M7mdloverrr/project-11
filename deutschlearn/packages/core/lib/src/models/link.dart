import 'cefr_level.dart';

enum LinkStatus {
  pending,
  active,
  disconnected;

  static LinkStatus parse(Object? value) => switch (value) {
    'active' => LinkStatus.active,
    'disconnected' => LinkStatus.disconnected,
    _ => LinkStatus.pending,
  };

  /// Transitions the backend allows (see request_teacher_link,
  /// respond_link_request and disconnect_link in the migrations).
  bool canTransitionTo(LinkStatus next) => switch ((this, next)) {
    (LinkStatus.pending, LinkStatus.active) => true,
    (LinkStatus.pending, LinkStatus.disconnected) => true,
    (LinkStatus.active, LinkStatus.disconnected) => true,
    (LinkStatus.disconnected, LinkStatus.pending) => true,
    _ => false,
  };
}

enum LinkRequestStatus {
  pending,
  approved,
  declined,
  cancelled;

  static LinkRequestStatus parse(Object? value) =>
      LinkRequestStatus.values.firstWhere((s) => s.name == value, orElse: () => LinkRequestStatus.pending);
}

/// The public part of a teacher, as returned by lookup_teacher_by_code.
class TeacherPublicInfo {
  const TeacherPublicInfo({required this.displayName, this.avatarUrl});

  factory TeacherPublicInfo.fromJson(Map<String, dynamic> json) =>
      TeacherPublicInfo(displayName: (json['display_name'] as String?) ?? '', avatarUrl: json['avatar_url'] as String?);

  final String displayName;
  final String? avatarUrl;
}

/// Minimal profile of the other party in a link.
class LinkParty {
  const LinkParty({required this.id, required this.displayName, this.avatarUrl, this.cefrLevel});

  factory LinkParty.fromJson(String id, Map<String, dynamic>? json) => LinkParty(
    id: id,
    displayName: (json?['display_name'] as String?) ?? '',
    avatarUrl: json?['avatar_url'] as String?,
    cefrLevel: json?['cefr_level'] == null ? null : CefrLevel.parse(json!['cefr_level']),
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
  final CefrLevel? cefrLevel;
}

class TeacherStudentLink {
  const TeacherStudentLink({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.status,
    required this.updatedAt,
    this.teacher,
    this.student,
  });

  factory TeacherStudentLink.fromJson(Map<String, dynamic> json) {
    final teacherId = json['teacher_id'] as String;
    final studentId = json['student_id'] as String;
    return TeacherStudentLink(
      id: json['id'] as String,
      teacherId: teacherId,
      studentId: studentId,
      status: LinkStatus.parse(json['status']),
      updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at']) as String),
      teacher: json['teacher'] is Map ? LinkParty.fromJson(teacherId, json['teacher'] as Map<String, dynamic>) : null,
      student: json['student'] is Map ? LinkParty.fromJson(studentId, json['student'] as Map<String, dynamic>) : null,
    );
  }

  final String id;
  final String teacherId;
  final String studentId;
  final LinkStatus status;
  final DateTime updatedAt;
  final LinkParty? teacher;
  final LinkParty? student;

  TeacherStudentLink copyWith({LinkStatus? status}) => TeacherStudentLink(
    id: id,
    teacherId: teacherId,
    studentId: studentId,
    status: status ?? this.status,
    updatedAt: DateTime.now(),
    teacher: teacher,
    student: student,
  );
}

class LinkRequest {
  const LinkRequest({
    required this.id,
    required this.linkId,
    required this.teacherId,
    required this.studentId,
    required this.status,
    required this.createdAt,
    this.student,
  });

  factory LinkRequest.fromJson(Map<String, dynamic> json) {
    final studentId = json['student_id'] as String;
    return LinkRequest(
      id: json['id'] as String,
      linkId: json['link_id'] as String,
      teacherId: json['teacher_id'] as String,
      studentId: studentId,
      status: LinkRequestStatus.parse(json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      student: json['student'] is Map ? LinkParty.fromJson(studentId, json['student'] as Map<String, dynamic>) : null,
    );
  }

  final String id;
  final String linkId;
  final String teacherId;
  final String studentId;
  final LinkRequestStatus status;
  final DateTime createdAt;
  final LinkParty? student;
}

/// Result of resolve-teacher-code.
class LinkRequestResult {
  const LinkRequestResult({
    required this.linkId,
    required this.status,
    required this.teacherDisplayName,
    this.requestId,
  });

  factory LinkRequestResult.fromJson(Map<String, dynamic> json) => LinkRequestResult(
    linkId: json['link_id'] as String,
    requestId: json['request_id'] as String?,
    status: LinkStatus.parse(json['status']),
    teacherDisplayName: (json['teacher_display_name'] as String?) ?? '',
  );

  final String linkId;
  final String? requestId;
  final LinkStatus status;
  final String teacherDisplayName;
}

/// What the student's teacher card should show, derived from their latest link.
sealed class StudentLinkView {
  const StudentLinkView();

  factory StudentLinkView.fromLink(TeacherStudentLink? link) {
    if (link == null) return const NoTeacherLinked();
    return switch (link.status) {
      LinkStatus.pending => LinkPendingApproval(link),
      LinkStatus.active => LinkActive(link),
      LinkStatus.disconnected => LinkDisconnected(link),
    };
  }

  /// Whether the student may enter a new teacher code.
  bool get canLinkNewTeacher => this is NoTeacherLinked || this is LinkDisconnected;
}

class NoTeacherLinked extends StudentLinkView {
  const NoTeacherLinked();
}

class LinkPendingApproval extends StudentLinkView {
  const LinkPendingApproval(this.link);
  final TeacherStudentLink link;
}

class LinkActive extends StudentLinkView {
  const LinkActive(this.link);
  final TeacherStudentLink link;
}

class LinkDisconnected extends StudentLinkView {
  const LinkDisconnected(this.link);
  final TeacherStudentLink link;
}
