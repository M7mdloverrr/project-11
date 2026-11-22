import 'dart:async';

import '../backend/auth_gateway.dart';
import '../backend/link_repository.dart';
import '../backend/profile_repository.dart';
import '../failure.dart';
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
