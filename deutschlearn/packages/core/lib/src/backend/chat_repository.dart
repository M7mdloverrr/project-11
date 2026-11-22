import '../models/chat.dart';

/// Messages between a teacher and one actively linked student.
abstract interface class ChatRepository {
  /// The thread, oldest first, updated live as messages arrive.
  Stream<List<ChatMessage>> watchThread({required String teacherId, required String studentId});

  Future<ChatMessage> send({required String teacherId, required String studentId, required String body});
}
