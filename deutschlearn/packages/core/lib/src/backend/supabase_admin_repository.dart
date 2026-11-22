import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin.dart';
import '../models/link.dart';
import '../models/role.dart';
import 'admin_repository.dart';
import 'supabase_errors.dart';

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  static const _party = 'display_name, avatar_url, cefr_level';

  Future<Map<String, dynamic>> _fn(Map<String, Object?> body) async {
    final res = await _client.functions.invoke('admin-users', body: body);
    return (res.data as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<AdminStats> fetchStats() => guardSupabase(() async {
    final row = await _client.rpc<Map<String, dynamic>>('admin_stats');
    return AdminStats.fromJson(row);
  });

  @override
  Future<AdminUserPage> listUsers({String? search, Role? role, int limit = 50, int offset = 0}) =>
      guardSupabase(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'admin_list_users',
          params: {
            'p_search': (search?.trim().isEmpty ?? true) ? null : search!.trim(),
            'p_role': role?.name,
            'p_limit': limit,
            'p_offset': offset,
          },
        );
        final maps = rows.cast<Map<String, dynamic>>();
        final total = maps.isEmpty ? 0 : (maps.first['total_count'] as num).toInt();
        return AdminUserPage(maps.map(AdminUser.fromJson).toList(), total);
      });

  @override
  Future<void> updateUser(String userId, AdminProfileUpdate u) => guardSupabase(() async {
    await _client.rpc<dynamic>(
      'admin_update_profile',
      params: {
        'p_user_id': userId,
        'p_display_name': u.displayName,
        'p_role': u.role?.name,
        'p_cefr_level': u.cefrLevel?.code,
        'p_locale': u.locale,
      },
    );
  });

  @override
  Future<String> createUser(AdminNewUser u) => guardSupabase(() async {
    final res = await _fn({
      'action': 'create_user',
      'email': u.email,
      'role': u.role.name,
      'display_name': u.displayName,
      'locale': u.locale,
      'password': u.password,
    });
    return res['user_id'] as String;
  });

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) =>
      guardSupabase(() => _fn({'action': 'set_blocked', 'user_id': userId, 'blocked': blocked}));

  @override
  Future<void> deleteUser(String userId) => guardSupabase(() => _fn({'action': 'delete_user', 'user_id': userId}));

  @override
  Future<void> confirmEmail(String userId) => guardSupabase(() => _fn({'action': 'confirm_email', 'user_id': userId}));

  @override
  Future<String> createPasswordResetLink(String userId) => guardSupabase(() async {
    final res = await _fn({'action': 'password_reset', 'user_id': userId, 'mode': 'link'});
    return res['link'] as String;
  });

  @override
  Future<void> sendPasswordResetEmail(String userId) =>
      guardSupabase(() => _fn({'action': 'password_reset', 'user_id': userId, 'mode': 'email'}));

  @override
  Future<List<AdminCode>> listCodes({bool activeOnly = true}) => guardSupabase(() async {
    var q = _client
        .from('teacher_codes')
        .select(
          'id, code, revoked, created_at, revoked_at, teacher_id, '
          'teacher:profiles!teacher_codes_teacher_id_fkey(display_name)',
        );
    if (activeOnly) q = q.eq('revoked', false);
    final rows = await q.order('created_at', ascending: false).limit(500);
    return rows.map(AdminCode.fromJson).toList();
  });

  @override
  Future<AdminCode> issueCode(String teacherId) => guardSupabase(() async {
    final res = await _fn({'action': 'issue_code', 'teacher_id': teacherId});
    return AdminCode.fromJson({...res, 'teacher_id': teacherId});
  });

  @override
  Future<void> revokeCode(String codeId) =>
      guardSupabase(() => _client.rpc<dynamic>('admin_revoke_code', params: {'p_code_id': codeId}));

  @override
  Future<List<TeacherStudentLink>> listLinks({LinkStatus? status}) => guardSupabase(() async {
    var q = _client
        .from('teacher_student_links')
        .select(
          'id, teacher_id, student_id, status, created_at, updated_at, '
          'teacher:profiles!teacher_student_links_teacher_id_fkey($_party), '
          'student:profiles!teacher_student_links_student_id_fkey($_party)',
        );
    if (status != null) q = q.eq('status', status.name);
    final rows = await q.order('updated_at', ascending: false).limit(500);
    return rows.map(TeacherStudentLink.fromJson).toList();
  });

  @override
  Future<List<AdminLinkRequest>> listRequests({LinkRequestStatus? status}) => guardSupabase(() async {
    var q = _client
        .from('link_requests')
        .select(
          'id, link_id, teacher_id, student_id, status, created_at, responded_at, '
          'teacher:profiles!link_requests_teacher_id_fkey($_party), '
          'student:profiles!link_requests_student_id_fkey($_party)',
        );
    if (status != null) q = q.eq('status', status.name);
    final rows = await q.order('created_at', ascending: false).limit(500);
    return rows.map(AdminLinkRequest.fromJson).toList();
  });

  @override
  Future<void> respondToRequest(String requestId, {required bool approve}) => guardSupabase(
    () => _client.rpc<dynamic>('admin_respond_request', params: {'p_request_id': requestId, 'p_approve': approve}),
  );

  @override
  Future<void> disconnectLink(String linkId) =>
      guardSupabase(() => _client.rpc<dynamic>('admin_disconnect_link', params: {'p_link_id': linkId}));

  @override
  Future<void> linkStudent({required String teacherId, required String studentId}) => guardSupabase(
    () => _client.rpc<dynamic>('admin_link_student', params: {'p_teacher_id': teacherId, 'p_student_id': studentId}),
  );

  @override
  Future<List<AuditEntry>> auditLog({int limit = 100}) => guardSupabase(() async {
    final rows = await _client
        .from('admin_audit_log')
        .select(
          'id, action, target_type, target_id, details, created_at, '
          'admin:profiles!admin_audit_log_admin_id_fkey(display_name)',
        )
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(AuditEntry.fromJson).toList();
  });
}
