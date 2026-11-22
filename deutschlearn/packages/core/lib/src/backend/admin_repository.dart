import '../models/admin.dart';
import '../models/link.dart';
import '../models/role.dart';

/// Everything the admin panel can read and change. Calls fail with
/// FailureKind.forbidden unless the signed-in user is an admin.
abstract interface class AdminRepository {
  Future<AdminStats> fetchStats();
  Future<AdminUserPage> listUsers({String? search, Role? role, int limit = 50, int offset = 0});
  Future<void> updateUser(String userId, AdminProfileUpdate update);
  Future<String> createUser(AdminNewUser user);
  Future<void> setBlocked(String userId, {required bool blocked});
  Future<void> deleteUser(String userId);
  Future<void> confirmEmail(String userId);

  /// Returns a one-time sign-in link the admin can share by hand.
  Future<String> createPasswordResetLink(String userId);
  Future<void> sendPasswordResetEmail(String userId);

  Future<List<AdminCode>> listCodes({bool activeOnly = true});
  Future<AdminCode> issueCode(String teacherId);
  Future<void> revokeCode(String codeId);

  Future<List<TeacherStudentLink>> listLinks({LinkStatus? status});
  Future<List<AdminLinkRequest>> listRequests({LinkRequestStatus? status});
  Future<void> respondToRequest(String requestId, {required bool approve});
  Future<void> disconnectLink(String linkId);
  Future<void> linkStudent({required String teacherId, required String studentId});

  Future<List<AuditEntry>> auditLog({int limit = 100});
}
