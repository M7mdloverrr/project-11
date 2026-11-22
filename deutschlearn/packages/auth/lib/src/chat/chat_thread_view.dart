import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../session.dart';

/// Live teacher–student chat thread with a composer; shared by both apps.
class ChatThreadView extends ConsumerStatefulWidget {
  const ChatThreadView({super.key, required this.teacherId, required this.studentId});

  final String teacherId;
  final String studentId;

  @override
  ConsumerState<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<ChatThreadView> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  ChatThreadKey get _key => (teacherId: widget.teacherId, studentId: widget.studentId);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(chatRepositoryProvider).send(teacherId: widget.teacherId, studentId: widget.studentId, body: body);
      _text.clear();
    } catch (e) {
      _error = e is AppFailure ? e.message : '$e';
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentProfileProvider).id;
    final thread = ref.watch(chatThreadProvider(_key));
    return Column(
      children: [
        Expanded(
          child: switch (thread) {
            AsyncError(:final error) => Padding(
              padding: const EdgeInsets.all(DLSpacing.lg),
              child: DLBanner(
                tone: DLStatusTone.error,
                message: error is AppFailure ? error.message : '$error',
                action: TextButton(
                  onPressed: () => ref.invalidate(chatThreadProvider(_key)),
                  child: const Text('إعادة • Erneut'),
                ),
              ),
            ),
            AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
              icon: Icons.chat_bubble_outline,
              message: 'لا توجد رسائل بعد. اكتب أول رسالة!\nNoch keine Nachrichten.',
            ),
            AsyncData(value: final list) => ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(DLSpacing.md),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[list.length - 1 - i];
                return _Bubble(key: ValueKey(m.id), message: m, mine: m.senderId == myId);
              },
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md),
            child: DLBanner(tone: DLStatusTone.error, message: _error!),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(DLSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat-input'),
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'اكتب رسالة… • Nachricht…', counterText: ''),
                  ),
                ),
                const SizedBox(width: DLSpacing.sm),
                IconButton.filled(
                  key: const Key('chat-send'),
                  tooltip: 'إرسال • Senden',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final local = message.createdAt.toLocal();
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: DLSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md, vertical: DLSpacing.sm),
        decoration: BoxDecoration(
          color: mine ? DLColors.teal : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(DLRadius.md),
          border: mine ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.body, style: t.bodyLarge?.copyWith(color: mine ? Colors.white : null)),
            Text(time, style: t.labelSmall?.copyWith(color: mine ? Colors.white70 : null)),
          ],
        ),
      ),
    );
  }
}
