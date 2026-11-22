import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class StudentChatScreen extends ConsumerWidget {
  const StudentChatScreen({super.key, required this.studentId, this.student});

  final String studentId;
  final LinkParty? student;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text('${student?.displayName ?? ''} • Chat')),
    body: ChatThreadView(teacherId: ref.watch(currentProfileProvider).id, studentId: studentId),
  );
}
