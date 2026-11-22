class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    teacherId: j['teacher_id'] as String,
    studentId: j['student_id'] as String,
    senderId: j['sender_id'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  final String id;
  final String teacherId;
  final String studentId;
  final String senderId;
  final String body;
  final DateTime createdAt;
}
