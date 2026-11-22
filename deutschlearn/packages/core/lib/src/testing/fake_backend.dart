import 'dart:async';

import '../backend/admin_repository.dart';
import '../backend/auth_gateway.dart';
import '../backend/chat_repository.dart';
import '../backend/lesson_repository.dart';
import '../backend/link_repository.dart';
import '../backend/profile_repository.dart';
import '../failure.dart';
import '../models/admin.dart';
import '../models/cefr_level.dart';
import '../models/chat.dart';
import '../models/lesson.dart';
import '../models/link.dart';
import '../models/profile.dart';
import '../models/role.dart';
import '../models/teacher_code.dart';

/// In-memory stand-in for Supabase Auth.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.accounts = const {}, AuthUser? restoredUser}) : _current = restoredUser;

  /// email -> (password, userId)
  final Map<String, ({String password, String id})> accounts;
  AuthUser? _current;
  final _events = StreamController<AuthEvent>.broadcast();

  final signInCalls = <String>[];
  final resetEmails = <String>[];
  AppFailure? nextError;
  SignUpOutcome signUpOutcome = SignUpOutcome.confirmationEmailSent;

  @override
  bool get isConfigured => true;
  @override
  AuthUser? get currentUser => _current;
  @override
  Stream<AuthEvent> get events => _events.stream;

  void emit(AuthEvent e) => _events.add(e);

  Future<void> _maybeFail() async {
    await Future<void>.delayed(Duration.zero);
    final e = nextError;
    if (e != null) {
      nextError = null;
      throw e;
    }
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    signInCalls.add(email);
    await _maybeFail();
    final a = accounts[email.trim()];
    if (a == null || a.password != password) throw const AppFailure(FailureKind.invalidCredentials);
    final user = AuthUser(id: a.id, email: email.trim());
    _current = user;
    _events.add(AuthEvent(AuthEventKind.signedIn, user));
    return user;
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required Role role,
    required String locale,
  }) async {
    await _maybeFail();
    if (accounts.containsKey(email.trim())) throw const AppFailure(FailureKind.emailInUse);
    return signUpOutcome;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _maybeFail();
    resetEmails.add(email.trim());
  }

  @override
  Future<void> updatePassword(String newPassword) => _maybeFail();

  @override
  Future<void> signOut() async {
    _current = null;
    _events.add(const AuthEvent(AuthEventKind.signedOut, null));
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([Map<String, Profile>? profiles]) : profiles = profiles ?? {};

  final Map<String, Profile> profiles;

  @override
  Future<Profile?> fetchProfile(String userId) async => profiles[userId];

  @override
  Future<Profile> updateProfile(String userId, {String? displayName, String? locale}) async {
    final p = profiles[userId]!.copyWith(displayName: displayName, locale: locale);
    profiles[userId] = p;
    return p;
  }
}

/// In-memory teacher codes and links that mirrors the server rules.
class FakeLinkRepository implements LinkRepository {
  FakeLinkRepository({this.studentId = 'student-1', this.teacherId = 'teacher-1'});

  final String studentId;
  final String teacherId;

  /// code -> teacher public info
  final Map<String, TeacherPublicInfo> codes = {};
  TeacherStudentLink? studentLink;
  TeacherCode? activeCode;
  final List<LinkRequest> pending = [];
  final List<TeacherStudentLink> linked = [];
  int _seq = 0;
  final generatedCodes = <String>[];
  AppFailure? nextError;

  Future<void> _tick() async {
    await Future<void>.delayed(Duration.zero);
    final e = nextError;
    if (e != null) {
      nextError = null;
      throw e;
    }
  }

  String _code(String code) {
    final c = TeacherCodeFormat.normalize(code);
    if (c == null) throw const AppFailure(FailureKind.invalidCodeFormat);
    return c;
  }

  /// Simulates the teacher approving/declining from the other app.
  void setStudentLinkStatus(LinkStatus status) => studentLink = studentLink?.copyWith(status: status);

  @override
  Future<TeacherPublicInfo?> lookupTeacher(String code) async {
    final c = _code(code);
    await _tick();
    return codes[c];
  }

  @override
  Future<LinkRequestResult> requestLink(String code) async {
    final c = _code(code);
    await _tick();
    final teacher = codes[c];
    if (teacher == null) throw const AppFailure(FailureKind.codeNotFound);
    final current = studentLink;
    if (current != null && current.status != LinkStatus.disconnected) {
      throw const AppFailure(FailureKind.alreadyLinked);
    }
    studentLink = TeacherStudentLink(
      id: 'link-${++_seq}',
      teacherId: teacherId,
      studentId: studentId,
      status: LinkStatus.pending,
      updatedAt: DateTime.now(),
      teacher: LinkParty(id: teacherId, displayName: teacher.displayName),
    );
    return LinkRequestResult(
      linkId: studentLink!.id,
      requestId: 'req-$_seq',
      status: LinkStatus.pending,
      teacherDisplayName: teacher.displayName,
    );
  }

  @override
  Future<TeacherStudentLink?> fetchStudentLink() async {
    await _tick();
    return studentLink;
  }

  @override
  Future<TeacherStudentLink> disconnect(String linkId) async {
    await _tick();
    if (studentLink?.id == linkId) {
      studentLink = studentLink!.copyWith(status: LinkStatus.disconnected);
      return studentLink!;
    }
    final i = linked.indexWhere((l) => l.id == linkId);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    final l = linked.removeAt(i).copyWith(status: LinkStatus.disconnected);
    return l;
  }

  @override
  Future<TeacherCode?> fetchActiveCode() async {
    await _tick();
    return activeCode;
  }

  @override
  Future<TeacherCode> generateCode() async {
    await _tick();
    _seq++;
    final body = List.generate(6, (i) => TeacherCodeFormat.alphabet[(_seq * 7 + i * 5) % 32]).join();
    final code = TeacherCode(id: 'code-$_seq', code: 'TCH-$body', revoked: false, createdAt: DateTime.now());
    generatedCodes.add(code.code);
    activeCode = code;
    return code;
  }

  @override
  Future<void> revokeCode(String codeId) async {
    await _tick();
    if (activeCode?.id == codeId) activeCode = null;
  }

  @override
  Future<List<LinkRequest>> fetchPendingRequests() async {
    await _tick();
    return List.of(pending);
  }

  @override
  Future<List<TeacherStudentLink>> fetchLinkedStudents() async {
    await _tick();
    return List.of(linked);
  }

  @override
  Future<TeacherStudentLink> respondToRequest(String requestId, {required bool approve}) async {
    await _tick();
    final i = pending.indexWhere((r) => r.id == requestId);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    final r = pending.removeAt(i);
    final link = TeacherStudentLink(
      id: r.linkId,
      teacherId: r.teacherId,
      studentId: r.studentId,
      status: approve ? LinkStatus.active : LinkStatus.disconnected,
      updatedAt: DateTime.now(),
      student: r.student,
    );
    if (approve) linked.insert(0, link);
    return link;
  }
}

/// In-memory admin backend for admin panel tests.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.adminId = 'admin-1'});

  final String adminId;
  final List<AdminUser> users = [];
  final List<AdminCode> codes = [];
  final List<TeacherStudentLink> links = [];
  final List<AdminLinkRequest> requests = [];
  final List<AuditEntry> audit = [];
  AppFailure? nextError;
  int _seq = 0;

  Future<void> _tick() async {
    await Future<void>.delayed(Duration.zero);
    final e = nextError;
    if (e != null) {
      nextError = null;
      throw e;
    }
  }

  void _log(String action, String type, String? id) => audit.insert(
    0,
    AuditEntry(
      id: ++_seq,
      action: action,
      targetType: type,
      targetId: id,
      createdAt: DateTime.now(),
      adminName: 'Admin',
    ),
  );

  int _userIndex(String id) {
    final i = users.indexWhere((u) => u.id == id);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    return i;
  }

  AdminUser _copy(
    AdminUser u, {
    String? displayName,
    Role? role,
    CefrLevel? cefr,
    String? locale,
    DateTime? bannedUntil,
    bool clearBan = false,
    DateTime? confirmedAt,
  }) => AdminUser(
    id: u.id,
    email: u.email,
    role: role ?? u.role,
    displayName: displayName ?? u.displayName,
    locale: locale ?? u.locale,
    cefrLevel: cefr ?? u.cefrLevel,
    createdAt: u.createdAt,
    lastSignInAt: u.lastSignInAt,
    emailConfirmedAt: confirmedAt ?? u.emailConfirmedAt,
    bannedUntil: clearBan ? null : (bannedUntil ?? u.bannedUntil),
    teacherName: u.teacherName,
    studentCount: u.studentCount,
  );

  @override
  Future<AdminStats> fetchStats() async {
    await _tick();
    int count(Role r) => users.where((u) => u.role == r).length;
    return AdminStats(
      students: count(Role.student),
      teachers: count(Role.teacher),
      admins: count(Role.admin),
      blockedUsers: users.where((u) => u.isBlocked).length,
      activeLinks: links.where((l) => l.status == LinkStatus.active).length,
      pendingRequests: requests.where((r) => r.status == LinkRequestStatus.pending).length,
      activeCodes: codes.where((c) => !c.revoked).length,
    );
  }

  @override
  Future<AdminUserPage> listUsers({String? search, Role? role, int limit = 50, int offset = 0}) async {
    await _tick();
    final q = search?.trim().toLowerCase() ?? '';
    final all = users
        .where((u) => role == null || u.role == role)
        .where((u) => q.isEmpty || u.email.toLowerCase().contains(q) || u.displayName.toLowerCase().contains(q))
        .toList();
    return AdminUserPage(all.skip(offset).take(limit).toList(), all.length);
  }

  @override
  Future<void> updateUser(String userId, AdminProfileUpdate u) async {
    await _tick();
    final i = _userIndex(userId);
    if (u.role != null && u.role != users[i].role && userId == adminId) {
      throw const AppFailure(FailureKind.forbidden, 'you cannot change your own role');
    }
    users[i] = _copy(users[i], displayName: u.displayName, role: u.role, cefr: u.cefrLevel, locale: u.locale);
    _log('update_profile', 'user', userId);
  }

  @override
  Future<String> createUser(AdminNewUser u) async {
    await _tick();
    if (users.any((x) => x.email == u.email)) throw const AppFailure(FailureKind.emailInUse);
    final id = 'user-${++_seq}';
    users.insert(
      0,
      AdminUser(
        id: id,
        email: u.email,
        role: u.role,
        displayName: u.displayName,
        locale: u.locale,
        createdAt: DateTime.now(),
        emailConfirmedAt: u.password == null ? null : DateTime.now(),
      ),
    );
    _log('create_user', 'user', id);
    return id;
  }

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) async {
    await _tick();
    final i = _userIndex(userId);
    users[i] = blocked
        ? _copy(users[i], bannedUntil: DateTime.now().add(const Duration(days: 36500)))
        : _copy(users[i], clearBan: true);
    _log(blocked ? 'block_user' : 'unblock_user', 'user', userId);
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _tick();
    users.removeAt(_userIndex(userId));
    _log('delete_user', 'user', userId);
  }

  @override
  Future<void> confirmEmail(String userId) async {
    await _tick();
    final i = _userIndex(userId);
    users[i] = _copy(users[i], confirmedAt: DateTime.now());
    _log('confirm_email', 'user', userId);
  }

  @override
  Future<String> createPasswordResetLink(String userId) async {
    await _tick();
    _userIndex(userId);
    _log('create_password_reset_link', 'user', userId);
    return 'https://example.supabase.co/auth/v1/verify?token=fake-$userId&type=recovery';
  }

  @override
  Future<void> sendPasswordResetEmail(String userId) async {
    await _tick();
    _userIndex(userId);
    _log('send_password_reset', 'user', userId);
  }

  @override
  Future<List<AdminCode>> listCodes({bool activeOnly = true}) async {
    await _tick();
    return codes.where((c) => !activeOnly || !c.revoked).toList();
  }

  @override
  Future<AdminCode> issueCode(String teacherId) async {
    await _tick();
    for (var i = 0; i < codes.length; i++) {
      final c = codes[i];
      if (c.teacherId == teacherId && !c.revoked) {
        codes[i] = AdminCode(
          id: c.id,
          code: c.code,
          revoked: true,
          createdAt: c.createdAt,
          teacherId: c.teacherId,
          teacherName: c.teacherName,
          revokedAt: DateTime.now(),
        );
      }
    }
    final n = ++_seq;
    final code = AdminCode(
      id: 'code-$n',
      code: 'TCH-ADM${n.toString().padLeft(3, '2')}',
      revoked: false,
      createdAt: DateTime.now(),
      teacherId: teacherId,
    );
    codes.insert(0, code);
    _log('issue_code', 'teacher_code', code.id);
    return code;
  }

  @override
  Future<void> revokeCode(String codeId) async {
    await _tick();
    final i = codes.indexWhere((c) => c.id == codeId && !c.revoked);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    final c = codes[i];
    codes[i] = AdminCode(
      id: c.id,
      code: c.code,
      revoked: true,
      createdAt: c.createdAt,
      teacherId: c.teacherId,
      teacherName: c.teacherName,
      revokedAt: DateTime.now(),
    );
    _log('revoke_code', 'teacher_code', codeId);
  }

  @override
  Future<List<TeacherStudentLink>> listLinks({LinkStatus? status}) async {
    await _tick();
    return links.where((l) => status == null || l.status == status).toList();
  }

  @override
  Future<List<AdminLinkRequest>> listRequests({LinkRequestStatus? status}) async {
    await _tick();
    return requests.where((r) => status == null || r.status == status).toList();
  }

  @override
  Future<void> respondToRequest(String requestId, {required bool approve}) async {
    await _tick();
    final i = requests.indexWhere((r) => r.id == requestId && r.status == LinkRequestStatus.pending);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    final r = requests[i];
    requests[i] = AdminLinkRequest(
      id: r.id,
      linkId: r.linkId,
      status: approve ? LinkRequestStatus.approved : LinkRequestStatus.declined,
      createdAt: r.createdAt,
      respondedAt: DateTime.now(),
      teacher: r.teacher,
      student: r.student,
    );
    final li = links.indexWhere((l) => l.id == r.linkId);
    if (li >= 0) links[li] = links[li].copyWith(status: approve ? LinkStatus.active : LinkStatus.disconnected);
    _log(approve ? 'approve_request' : 'decline_request', 'link_request', requestId);
  }

  @override
  Future<void> disconnectLink(String linkId) async {
    await _tick();
    final i = links.indexWhere((l) => l.id == linkId && l.status != LinkStatus.disconnected);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    links[i] = links[i].copyWith(status: LinkStatus.disconnected);
    _log('disconnect_link', 'link', linkId);
  }

  @override
  Future<void> linkStudent({required String teacherId, required String studentId}) async {
    await _tick();
    if (links.any((l) => l.studentId == studentId && l.teacherId != teacherId && l.status != LinkStatus.disconnected)) {
      throw const AppFailure(FailureKind.alreadyLinked);
    }
    String name(String id) => users.where((u) => u.id == id).map((u) => u.displayName).firstOrNull ?? '';
    final id = 'link-${++_seq}';
    links.removeWhere((l) => l.teacherId == teacherId && l.studentId == studentId);
    links.insert(
      0,
      TeacherStudentLink(
        id: id,
        teacherId: teacherId,
        studentId: studentId,
        status: LinkStatus.active,
        updatedAt: DateTime.now(),
        teacher: LinkParty(id: teacherId, displayName: name(teacherId)),
        student: LinkParty(id: studentId, displayName: name(studentId)),
      ),
    );
    _log('link_student', 'link', id);
  }

  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) async {
    await _tick();
    return audit.take(limit).toList();
  }
}

/// In-memory lessons and progress.
class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository({this.studentId = 'student-1', this.teacherId = 'teacher-1'});

  final String studentId;
  final String teacherId;
  final List<LessonAssignment> assignments = [];
  final List<Lesson> lessons = [];
  final Map<String, LessonProgress> progress = {};
  final completions = <({String lessonId, int score, int max})>[];
  AppFailure? nextError;
  int _seq = 0;

  Future<void> _tick() async {
    await Future<void>.delayed(Duration.zero);
    final e = nextError;
    if (e != null) {
      nextError = null;
      throw e;
    }
  }

  Lesson _withItems(Lesson l, List<LessonItem> items) => Lesson(
    id: l.id,
    titleDe: l.titleDe,
    titleAr: l.titleAr,
    descriptionAr: l.descriptionAr,
    level: l.level,
    position: l.position,
    published: l.published,
    items: items,
    itemCount: items.length,
  );

  @override
  Future<List<Lesson>> listLessons() async {
    await _tick();
    return [for (final l in lessons) _withItems(l, const [])].map((l) {
      final full = lessons.firstWhere((x) => x.id == l.id);
      return Lesson(
        id: l.id,
        titleDe: l.titleDe,
        titleAr: l.titleAr,
        descriptionAr: l.descriptionAr,
        level: l.level,
        position: l.position,
        published: l.published,
        itemCount: full.items.length,
      );
    }).toList();
  }

  @override
  Future<Lesson> fetchLesson(String lessonId) async {
    await _tick();
    return lessons.firstWhere((l) => l.id == lessonId, orElse: () => throw const AppFailure(FailureKind.notFound));
  }

  @override
  Future<List<LessonProgress>> fetchProgress({String? studentId}) async {
    await _tick();
    final id = studentId ?? this.studentId;
    return progress.values.where((p) => p.studentId == id || p.studentId.isEmpty).toList();
  }

  @override
  Future<LessonProgress> completeLesson(String lessonId, {required int score, required int maxScore}) async {
    await _tick();
    completions.add((lessonId: lessonId, score: score, max: maxScore));
    final old = progress[lessonId];
    final p = LessonProgress(
      studentId: studentId,
      lessonId: lessonId,
      bestScore: old == null || score > old.bestScore ? score : old.bestScore,
      maxScore: maxScore,
      attempts: (old?.attempts ?? 0) + 1,
      completedAt: DateTime.now(),
    );
    progress[lessonId] = p;
    return p;
  }

  @override
  Future<Lesson> saveLesson(Lesson l) async {
    await _tick();
    final id = l.id.isEmpty ? 'lesson-${++_seq}' : l.id;
    final i = lessons.indexWhere((x) => x.id == id);
    final saved = _withItems(
      Lesson(
        id: id,
        titleDe: l.titleDe,
        titleAr: l.titleAr,
        descriptionAr: l.descriptionAr,
        level: l.level,
        position: l.position,
        published: l.published,
      ),
      i < 0 ? const [] : lessons[i].items,
    );
    if (i < 0) {
      lessons.add(saved);
    } else {
      lessons[i] = saved;
    }
    return saved;
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    await _tick();
    lessons.removeWhere((l) => l.id == lessonId);
  }

  @override
  Future<void> saveItems(String lessonId, List<LessonItem> items) async {
    await _tick();
    final i = lessons.indexWhere((l) => l.id == lessonId);
    if (i < 0) throw const AppFailure(FailureKind.notFound);
    lessons[i] = _withItems(lessons[i], [
      for (final (n, it) in items.indexed)
        LessonItem(
          id: it.id.isEmpty ? 'item-${++_seq}' : it.id,
          kind: it.kind,
          position: n + 1,
          german: it.german,
          arabic: it.arabic,
          exampleDe: it.exampleDe,
          exampleAr: it.exampleAr,
          options: it.options,
          answer: it.answer,
        ),
    ]);
  }

  @override
  Future<List<LessonAssignment>> fetchAssignments({String? studentId}) async {
    await _tick();
    final id = studentId ?? this.studentId;
    return assignments.where((a) => a.studentId == id).toList();
  }

  @override
  Future<LessonAssignment> assignLesson({required String studentId, required String lessonId, String note = ''}) async {
    await _tick();
    final a = LessonAssignment(
      id: 'assignment-${++_seq}',
      teacherId: teacherId,
      studentId: studentId,
      lessonId: lessonId,
      note: note,
      createdAt: DateTime.now(),
    );
    assignments.add(a);
    return a;
  }

  @override
  Future<void> removeAssignment(String assignmentId) async {
    await _tick();
    assignments.removeWhere((a) => a.id == assignmentId);
  }
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({required this.myId});

  final String myId;
  final List<ChatMessage> messages = [];
  final _changes = StreamController<void>.broadcast();
  AppFailure? nextError;
  int _seq = 0;

  /// Simulates a message arriving from the other party.
  void receive(ChatMessage m) {
    messages.add(m);
    _changes.add(null);
  }

  @override
  Stream<List<ChatMessage>> watchThread({required String teacherId, required String studentId}) async* {
    List<ChatMessage> thread() => messages.where((m) => m.teacherId == teacherId && m.studentId == studentId).toList();
    yield thread();
    await for (final _ in _changes.stream) {
      yield thread();
    }
  }

  @override
  Future<ChatMessage> send({required String teacherId, required String studentId, required String body}) async {
    await Future<void>.delayed(Duration.zero);
    final e = nextError;
    if (e != null) {
      nextError = null;
      throw e;
    }
    final m = ChatMessage(
      id: 'msg-${++_seq}',
      teacherId: teacherId,
      studentId: studentId,
      senderId: myId,
      body: body.trim(),
      createdAt: DateTime.now(),
    );
    receive(m);
    return m;
  }
}
