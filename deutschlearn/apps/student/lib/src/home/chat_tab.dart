import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../link/link_controller.dart';
import '../router.dart';

class ChatTab extends ConsumerWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(studentLinkProvider)) {
      AsyncData(value: LinkActive(:final link)) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DLSpacing.lg, DLSpacing.lg, DLSpacing.lg, 0),
            child: DLBilingualTitle(
              arabic: 'المحادثة مع ${link.teacher?.displayName ?? 'معلّمك'}',
              german: 'Chat mit deiner Lehrkraft',
            ),
          ),
          Expanded(
            child: ChatThreadView(teacherId: link.teacherId, studentId: link.studentId),
          ),
        ],
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(DLSpacing.lg),
        child: DLBanner(
          tone: DLStatusTone.error,
          message: error is AppFailure ? error.message : '$error',
          action: TextButton(
            onPressed: () => ref.read(studentLinkProvider.notifier).refresh(),
            child: const Text('إعادة • Erneut'),
          ),
        ),
      ),
      AsyncData() => ListView(
        padding: const EdgeInsets.all(DLSpacing.lg),
        children: [
          const DLBilingualTitle(arabic: 'المحادثة', german: 'Chat'),
          const SizedBox(height: DLSpacing.xl),
          const DLEmptyState(
            icon: Icons.chat_bubble_outline,
            message: 'المحادثة متاحة بعد ربط حسابك بمعلّم وموافقته.\nChat ist verfügbar, sobald deine Lehrkraft dich bestätigt hat.',
          ),
          const SizedBox(height: DLSpacing.lg),
          DLPrimaryButton(
            key: const Key('chat-link-teacher'),
            label: bilingualLabel('ربط معلّم', 'Lehrkraft verbinden'),
            onPressed: () => context.push(StudentRoutes.linkTeacher),
          ),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
