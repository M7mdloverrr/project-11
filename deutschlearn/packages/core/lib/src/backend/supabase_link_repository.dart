import 'package:supabase_flutter/supabase_flutter.dart';

import '../failure.dart';
import '../models/link.dart';
import '../models/teacher_code.dart';
import 'link_repository.dart';
import 'supabase_errors.dart';

class SupabaseLinkRepository implements LinkRepository {
  SupabaseLinkRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppFailure(FailureKind.forbidden, 'not signed in');
    return id;
  }

  static const _linkColumns = 'id, teacher_id, student_id, status, created_at, updated_at';
  static const _partyColumns = 'display_name, avatar_url, cefr_level';

  String _normalized(String code) {
    final c = TeacherCodeFormat.normalize(code);
    if (c == null) throw const AppFailure(FailureKind.invalidCodeFormat);
    return c;
  }

  @override
  Future<TeacherPublicInfo?> lookupTeacher(String code) => guardSupabase(() async {
    final rows = await _client.rpc<List<dynamic>>('lookup_teacher_by_code', params: {'code': _normalized(code)});
    if (rows.isEmpty) return null;
    return TeacherPublicInfo.fromJson(rows.first as Map<String, dynamic>);
  });

  @override
  Future<LinkRequestResult> requestLink(String code) => guardSupabase(() async {
    final res = await _client.functions.invoke('resolve-teacher-code', body: {'code': _normalized(code)});
    return LinkRequestResult.fromJson(res.data as Map<String, dynamic>);
  });

  @override
  Future<TeacherStudentLink?> fetchStudentLink() => guardSupabase(() async {
    final row = await _client
        .from('teacher_student_links')
        .select('$_linkColumns, teacher:profiles!teacher_student_links_teacher_id_fkey($_partyColumns)')
        .eq('student_id', _uid)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : TeacherStudentLink.fromJson(row);
  });

  @override
  Future<TeacherStudentLink> disconnect(String linkId) => guardSupabase(() async {
    final row = await _client.rpc<Map<String, dynamic>>('disconnect_link', params: {'p_link_id': linkId});
    return TeacherStudentLink.fromJson(row);
  });

  @override
  Future<TeacherCode?> fetchActiveCode() => guardSupabase(() async {
    final row = await _client
        .from('teacher_codes')
        .select('id, code, revoked, created_at')
        .eq('teacher_id', _uid)
        .eq('revoked', false)
        .maybeSingle();
    return row == null ? null : TeacherCode.fromJson(row);
  });

  @override
  Future<TeacherCode> generateCode() => guardSupabase(() async {
    final res = await _client.functions.invoke('generate-teacher-code');
    return TeacherCode.fromJson(res.data as Map<String, dynamic>);
  });

  @override
  Future<void> revokeCode(String codeId) => guardSupabase(() async {
    await _client.from('teacher_codes').update({'revoked': true}).eq('id', codeId);
  });

  @override
  Future<List<LinkRequest>> fetchPendingRequests() => guardSupabase(() async {
    final rows = await _client
        .from('link_requests')
        .select(
          'id, link_id, teacher_id, student_id, status, created_at, '
          'student:profiles!link_requests_student_id_fkey($_partyColumns)',
        )
        .eq('teacher_id', _uid)
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(LinkRequest.fromJson).toList();
  });

  @override
  Future<List<TeacherStudentLink>> fetchLinkedStudents() => guardSupabase(() async {
    final rows = await _client
        .from('teacher_student_links')
        .select('$_linkColumns, student:profiles!teacher_student_links_student_id_fkey($_partyColumns)')
        .eq('teacher_id', _uid)
        .eq('status', 'active')
        .order('updated_at', ascending: false);
    return rows.map(TeacherStudentLink.fromJson).toList();
  });

  @override
  Future<TeacherStudentLink> respondToRequest(String requestId, {required bool approve}) => guardSupabase(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'respond_link_request',
      params: {'p_request_id': requestId, 'p_approve': approve},
    );
    return TeacherStudentLink.fromJson(row);
  });
}
