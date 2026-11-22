import '../models/link.dart';
import '../models/teacher_code.dart';

/// Teacher codes and teacher/student links.
abstract interface class LinkRepository {
  // Student side.
  /// Public preview (name + avatar) for [code], or null if no active code.
  Future<TeacherPublicInfo?> lookupTeacher(String code);

  /// Calls the resolve-teacher-code edge function.
  Future<LinkRequestResult> requestLink(String code);

  /// Student's most recent link (any status), with the teacher's profile.
  Future<TeacherStudentLink?> fetchStudentLink();

  Future<TeacherStudentLink> disconnect(String linkId);

  // Teacher side.
  Future<TeacherCode?> fetchActiveCode();

  /// Calls the generate-teacher-code edge function (revokes the old code).
  Future<TeacherCode> generateCode();

  Future<void> revokeCode(String codeId);

  Future<List<LinkRequest>> fetchPendingRequests();

  Future<List<TeacherStudentLink>> fetchLinkedStudents();

  Future<TeacherStudentLink> respondToRequest(String requestId, {required bool approve});
}
