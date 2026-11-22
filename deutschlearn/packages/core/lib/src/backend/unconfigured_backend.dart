import '../failure.dart';
import '../models/admin.dart';
import '../models/link.dart';
import '../models/profile.dart';
import '../models/role.dart';
import '../models/teacher_code.dart';
import 'admin_repository.dart';
import 'auth_gateway.dart';
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
