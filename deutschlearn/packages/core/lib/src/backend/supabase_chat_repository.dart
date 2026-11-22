import 'package:supabase_flutter/supabase_flutter.dart';

import '../failure.dart';
import '../models/chat.dart';
import 'chat_repository.dart';
import 'supabase_errors.dart';

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<ChatMessage>> watchThread({required String teacherId, required String studentId}) => _client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('student_id', studentId)
      .order('created_at')
      .map((rows) => rows.map(ChatMessage.fromJson).where((m) => m.teacherId == teacherId).toList())
      .handleError((Object e) => throw e is AppFailure ? e : mapSupabaseError(e));

  @override
  Future<ChatMessage> send({required String teacherId, required String studentId, required String body}) =>
      guardSupabase(() async {
        final row = await _client
            .from('chat_messages')
            .insert({
              'teacher_id': teacherId,
              'student_id': studentId,
              'sender_id': _client.auth.currentUser?.id,
              'body': body.trim(),
            })
            .select('id, teacher_id, student_id, sender_id, body, created_at')
            .single();
        return ChatMessage.fromJson(row);
      });
}
