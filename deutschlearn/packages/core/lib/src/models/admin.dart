import 'cefr_level.dart';
import 'link.dart';
import 'role.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Counts shown on the admin overview (admin_stats RPC).
class AdminStats {
  const AdminStats({
    this.students = 0,
    this.teachers = 0,
    this.admins = 0,
    this.newUsers7d = 0,
    this.blockedUsers = 0,
    this.unconfirmedUsers = 0,
    this.activeLinks = 0,
    this.pendingRequests = 0,
    this.activeCodes = 0,
    this.studentsWithoutTeacher = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    students: _int(j['students']),
    teachers: _int(j['teachers']),
    admins: _int(j['admins']),
    newUsers7d: _int(j['new_users_7d']),
    blockedUsers: _int(j['blocked_users']),
    unconfirmedUsers: _int(j['unconfirmed_users']),
    activeLinks: _int(j['active_links']),
    pendingRequests: _int(j['pending_requests']),
    activeCodes: _int(j['active_codes']),
    studentsWithoutTeacher: _int(j['students_without_teacher']),
  );

  final int students;
  final int teachers;
  final int admins;
  final int newUsers7d;
  final int blockedUsers;
  final int unconfirmedUsers;
  final int activeLinks;
  final int pendingRequests;
  final int activeCodes;
  final int studentsWithoutTeacher;

  int get totalUsers => students + teachers + admins;
}

/// A user row for admins: profile plus auth data (admin_list_users RPC).
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
    required this.createdAt,
    this.locale = 'ar',
    this.cefrLevel = CefrLevel.a1,
    this.lastSignInAt,
    this.emailConfirmedAt,
    this.bannedUntil,
    this.teacherName,
    this.studentCount = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'] as String,
    email: (j['email'] as String?) ?? '',
    role: Role.parse(j['role']),
    displayName: (j['display_name'] as String?) ?? '',
    locale: (j['locale'] as String?) ?? 'ar',
    cefrLevel: CefrLevel.parse(j['cefr_level']),
    createdAt: DateTime.parse(j['created_at'] as String),
    lastSignInAt: _date(j['last_sign_in_at']),
    emailConfirmedAt: _date(j['email_confirmed_at']),
    bannedUntil: _date(j['banned_until']),
    teacherName: j['teacher_name'] as String?,
    studentCount: _int(j['student_count']),
  );

  final String id;
  final String email;
  final Role role;
  final String displayName;
  final String locale;
  final CefrLevel cefrLevel;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final DateTime? emailConfirmedAt;
  final DateTime? bannedUntil;

  /// Display name of the student's active teacher, if any.
  final String? teacherName;

  /// Number of active students, for teachers.
  final int studentCount;

  bool get isBlocked => bannedUntil != null && bannedUntil!.isAfter(DateTime.now());
  bool get isConfirmed => emailConfirmedAt != null;
  String get label => displayName.trim().isEmpty ? email : displayName;
}

class AdminUserPage {
  const AdminUserPage(this.users, this.total);
  final List<AdminUser> users;
  final int total;
}

/// Changes an admin can make to a profile; null fields stay unchanged.
class AdminProfileUpdate {
  const AdminProfileUpdate({this.displayName, this.role, this.cefrLevel, this.locale});
  final String? displayName;
  final Role? role;
  final CefrLevel? cefrLevel;
  final String? locale;
}

class AdminNewUser {
  const AdminNewUser({
    required this.email,
    required this.role,
    this.displayName = '',
    this.locale = 'ar',
    this.password,
  });
  final String email;
  final Role role;
  final String displayName;
  final String locale;

  /// When null an invitation e-mail is sent instead.
  final String? password;
}

class AdminCode {
  const AdminCode({
    required this.id,
    required this.code,
    required this.revoked,
    required this.createdAt,
    required this.teacherId,
    this.teacherName = '',
    this.revokedAt,
  });

  factory AdminCode.fromJson(Map<String, dynamic> j) => AdminCode(
    id: j['id'] as String,
    code: j['code'] as String,
    revoked: (j['revoked'] as bool?) ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    revokedAt: _date(j['revoked_at']),
    teacherId: j['teacher_id'] as String,
    teacherName: ((j['teacher'] as Map<String, dynamic>?)?['display_name'] as String?) ?? '',
  );

  final String id;
  final String code;
  final bool revoked;
  final DateTime createdAt;
  final DateTime? revokedAt;
  final String teacherId;
  final String teacherName;
}

class AdminLinkRequest {
  const AdminLinkRequest({
    required this.id,
    required this.linkId,
    required this.status,
    required this.createdAt,
    required this.teacher,
    required this.student,
    this.respondedAt,
  });

  factory AdminLinkRequest.fromJson(Map<String, dynamic> j) => AdminLinkRequest(
    id: j['id'] as String,
    linkId: j['link_id'] as String,
    status: LinkRequestStatus.parse(j['status']),
    createdAt: DateTime.parse(j['created_at'] as String),
    respondedAt: _date(j['responded_at']),
    teacher: LinkParty.fromJson(j['teacher_id'] as String, j['teacher'] as Map<String, dynamic>?),
    student: LinkParty.fromJson(j['student_id'] as String, j['student'] as Map<String, dynamic>?),
  );

  final String id;
  final String linkId;
  final LinkRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final LinkParty teacher;
  final LinkParty student;
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.targetType,
    required this.createdAt,
    this.adminName = '',
    this.targetId,
    this.details = const {},
  });

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
    id: _int(j['id']),
    action: j['action'] as String,
    targetType: j['target_type'] as String,
    targetId: j['target_id'] as String?,
    details: (j['details'] as Map<String, dynamic>?) ?? const {},
    createdAt: DateTime.parse(j['created_at'] as String),
    adminName: ((j['admin'] as Map<String, dynamic>?)?['display_name'] as String?) ?? '',
  );

  final int id;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final String adminName;
}
