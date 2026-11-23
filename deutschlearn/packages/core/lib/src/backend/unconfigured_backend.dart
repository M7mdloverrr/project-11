import '../models/homework.dart';
import '../models/live.dart';
import 'classroom_repository.dart';
import '../failure.dart';
import '../models/admin.dart';
import '../models/lesson.dart';
import '../models/link.dart';
import '../models/profile.dart';
import '../models/role.dart';
import '../models/teacher_code.dart';
import '../models/cefr_level.dart';
import '../models/chat.dart';
import 'admin_repository.dart';
import 'auth_gateway.dart';
import 'chat_repository.dart';
import 'lesson_repository.dart';
import 'link_repository.dart';
import 'profile_repository.dart';

const _notConfigured = AppFailure(FailureKind.backendNotConfigured);

/// Used when SUPABASE_URL / SUPABASE_ANON_KEY are missing: every call fails
/// with [FailureKind.backendNotConfigured] instead of pretending to work.
class UnconfiguredAuthGateway implements AuthGateway {
  const UnconfiguredAuthGateway();

  @override
  bool get isConfigured => false;
  @override
  AuthUser? get currentUser => null;
  @override
  Stream<AuthEvent> get events => const Stream.empty();
  @override
  Future<AuthUser> signIn({required String email, required String password}) => Future.error(_notConfigured);
  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required Role role,
    required String locale,
  }) => Future.error(_notConfigured);
  @override
  Future<void> sendPasswordReset(String email) => Future.error(_notConfigured);
  @override
  Future<void> updatePassword(String newPassword) => Future.error(_notConfigured);
  @override
  Future<void> signOut() async {}
}

class UnconfiguredProfileRepository implements ProfileRepository {
  const UnconfiguredProfileRepository();
  @override
  Future<Profile?> fetchProfile(String userId) => Future.error(_notConfigured);
  @override
  Future<Profile> updateProfile(String userId, {String? displayName, String? locale}) => Future.error(_notConfigured);
}

class UnconfiguredLinkRepository implements LinkRepository {
  const UnconfiguredLinkRepository();
  @override
  Future<TeacherPublicInfo?> lookupTeacher(String code) => Future.error(_notConfigured);
  @override
  Future<LinkRequestResult> requestLink(String code) => Future.error(_notConfigured);
  @override
  Future<TeacherStudentLink?> fetchStudentLink() => Future.error(_notConfigured);
  @override
  Future<TeacherStudentLink> disconnect(String linkId) => Future.error(_notConfigured);
  @override
  Future<TeacherCode?> fetchActiveCode() => Future.error(_notConfigured);
  @override
  Future<TeacherCode> generateCode() => Future.error(_notConfigured);
  @override
  Future<void> revokeCode(String codeId) => Future.error(_notConfigured);
  @override
  Future<List<LinkRequest>> fetchPendingRequests() => Future.error(_notConfigured);
  @override
  Future<List<TeacherStudentLink>> fetchLinkedStudents() => Future.error(_notConfigured);
  @override
  Future<TeacherStudentLink> respondToRequest(String requestId, {required bool approve}) =>
      Future.error(_notConfigured);
}

class UnconfiguredAdminRepository implements AdminRepository {
  const UnconfiguredAdminRepository();

  @override
  Future<AdminStats> fetchStats() => Future.error(_notConfigured);
  @override
  Future<AdminUserPage> listUsers({String? search, Role? role, int limit = 50, int offset = 0}) =>
      Future.error(_notConfigured);
  @override
  Future<void> updateUser(String userId, AdminProfileUpdate update) => Future.error(_notConfigured);
  @override
  Future<String> createUser(AdminNewUser user) => Future.error(_notConfigured);
  @override
  Future<void> setBlocked(String userId, {required bool blocked}) => Future.error(_notConfigured);
  @override
  Future<void> deleteUser(String userId) => Future.error(_notConfigured);
  @override
  Future<void> confirmEmail(String userId) => Future.error(_notConfigured);
  @override
  Future<String> createPasswordResetLink(String userId) => Future.error(_notConfigured);
  @override
  Future<void> sendPasswordResetEmail(String userId) => Future.error(_notConfigured);
  @override
  Future<List<AdminCode>> listCodes({bool activeOnly = true}) => Future.error(_notConfigured);
  @override
  Future<AdminCode> issueCode(String teacherId) => Future.error(_notConfigured);
  @override
  Future<void> revokeCode(String codeId) => Future.error(_notConfigured);
  @override
  Future<List<TeacherStudentLink>> listLinks({LinkStatus? status}) => Future.error(_notConfigured);
  @override
  Future<List<AdminLinkRequest>> listRequests({LinkRequestStatus? status}) => Future.error(_notConfigured);
  @override
  Future<void> respondToRequest(String requestId, {required bool approve}) => Future.error(_notConfigured);
  @override
  Future<void> disconnectLink(String linkId) => Future.error(_notConfigured);
  @override
  Future<void> linkStudent({required String teacherId, required String studentId}) => Future.error(_notConfigured);
  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) => Future.error(_notConfigured);
}

class UnconfiguredLessonRepository implements LessonRepository {
  const UnconfiguredLessonRepository();

  @override
  Future<List<Lesson>> listLessons() => Future.error(_notConfigured);
  @override
  Future<List<CurriculumModule>> listModules() => Future.error(_notConfigured);
  @override
  Future<void> setPlacementLevel(CefrLevel level) => Future.error(_notConfigured);
  @override
  Future<Lesson> fetchLesson(String lessonId) => Future.error(_notConfigured);
  @override
  Future<List<LessonProgress>> fetchProgress({String? studentId}) => Future.error(_notConfigured);
  @override
  Future<LessonProgress> completeLesson(String lessonId, {required int score, required int maxScore}) =>
      Future.error(_notConfigured);
  @override
  Future<Lesson> saveLesson(Lesson lesson) => Future.error(_notConfigured);
  @override
  Future<void> deleteLesson(String lessonId) => Future.error(_notConfigured);
  @override
  Future<void> saveItems(String lessonId, List<LessonItem> items) => Future.error(_notConfigured);

  @override
  Future<List<LessonAssignment>> fetchAssignments({String? studentId}) => Future.error(_notConfigured);

  @override
  Future<LessonAssignment> assignLesson({required String studentId, required String lessonId, String note = ''}) =>
      Future.error(_notConfigured);

  @override
  Future<void> removeAssignment(String assignmentId) => Future.error(_notConfigured);
}

class UnconfiguredChatRepository implements ChatRepository {
  const UnconfiguredChatRepository();

  @override
  Stream<List<ChatMessage>> watchThread({required String teacherId, required String studentId}) =>
      Stream.error(_notConfigured);

  @override
  Future<ChatMessage> send({required String teacherId, required String studentId, required String body}) =>
      Future.error(_notConfigured);
}

class UnconfiguredClassroomRepository implements ClassroomRepository {
  const UnconfiguredClassroomRepository();

  @override
  Stream<List<Homework>> watchHomework() => Stream.error(_notConfigured);
  @override
  Stream<List<HomeworkSubmission>> watchSubmissions() => Stream.error(_notConfigured);
  @override
  Future<Map<String, List<String>>> fetchTargets() => Future.error(_notConfigured);
  @override
  Future<Homework> createHomework(Homework draft, {required List<String> studentIds}) => Future.error(_notConfigured);
  @override
  Future<void> deleteHomework(String homeworkId) => Future.error(_notConfigured);
  @override
  Future<HomeworkSubmission> saveSubmission(
    String homeworkId, {
    required Map<String, String> answers,
    required bool submit,
    required int autoScore,
    required int maxScore,
  }) => Future.error(_notConfigured);
  @override
  Future<HomeworkSubmission> gradeSubmission(
    String submissionId, {
    required int grade,
    required String feedback,
    Map<String, String> corrections = const {},
    bool returnForRevision = false,
  }) => Future.error(_notConfigured);
  @override
  Future<List<SchoolClass>> listClasses() => Future.error(_notConfigured);
  @override
  Future<SchoolClass> saveClass({String? id, required String name, required List<String> memberIds}) =>
      Future.error(_notConfigured);
  @override
  Future<void> deleteClass(String classId) => Future.error(_notConfigured);
  @override
  Stream<List<LiveSession>> watchLiveSessions() => Stream.error(_notConfigured);
  @override
  Stream<List<LiveResponse>> watchLiveResponses(String sessionId) => Stream.error(_notConfigured);
  @override
  Stream<List<LiveParticipant>> watchLiveParticipants(String sessionId) => Stream.error(_notConfigured);
  @override
  Future<LiveSession> startLive({required String title, String? lessonId, String? classId}) =>
      Future.error(_notConfigured);
  @override
  Future<void> updateLive(String sessionId, Map<String, dynamic> changes) => Future.error(_notConfigured);
  @override
  Future<void> endLive(String sessionId) => Future.error(_notConfigured);
  @override
  Future<void> joinLive(String sessionId) => Future.error(_notConfigured);
  @override
  Future<void> answerLive(String sessionId, {required int itemIndex, required String answer, bool? correct}) =>
      Future.error(_notConfigured);
  @override
  Future<void> markLive(String sessionId, {required String studentId, required int itemIndex, required String mark}) =>
      Future.error(_notConfigured);
}
