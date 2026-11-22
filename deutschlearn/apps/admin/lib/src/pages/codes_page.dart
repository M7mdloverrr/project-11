import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';

class CodesPage extends ConsumerWidget {
  const CodesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRevoked = ref.watch(showRevokedCodesProvider);
    final codes = ref.watch(codesProvider);
    return PageBody(
      onRefresh: () async => ref.invalidate(codesProvider),
      children: [
        PageHeader(
          title: 'Teacher codes',
          subtitle: 'Students enter these codes to request a teacher',
          actions: [
            FilledButton.icon(
              key: const Key('issue-code'),
              onPressed: () => _issueForTeacher(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Issue code'),
            ),
          ],
        ),
        SwitchListTile(
          key: const Key('show-revoked'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Show revoked codes'),
          value: showRevoked,
          onChanged: ref.read(showRevokedCodesProvider.notifier).set,
        ),
        AsyncView<List<AdminCode>>(
          value: codes,
          onRetry: () => ref.invalidate(codesProvider),
          builder: (list) => list.isEmpty
              ? const DLEmptyState(icon: Icons.qr_code_2, message: 'No codes')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final c in list) ...[
                      DLCard(
                        key: ValueKey(c.id),
                        padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: DLSpacing.sm,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        c.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      DLStatusChip(
                                        label: c.revoked ? 'Revoked' : 'Active',
                                        tone: c.revoked ? DLStatusTone.neutral : DLStatusTone.success,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${nameOr(c.teacherName)}  •  created ${formatDate(c.createdAt)}'
                                    '${c.revoked ? '  •  revoked ${formatDate(c.revokedAt)}' : ''}',
                                    style: const TextStyle(color: DLColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy',
                              icon: const Icon(Icons.copy),
                              onPressed: () => copyText(context, c.code, label: '${c.code} copied'),
                            ),
                            if (!c.revoked)
                              IconButton(
                                key: Key('revoke-${c.id}'),
                                tooltip: 'Revoke',
                                icon: const Icon(Icons.block, color: DLColors.error),
                                onPressed: () => _revoke(context, ref, c),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DLSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, AdminCode c) async {
    if (!await confirm(
      context,
      title: 'Revoke ${c.code}?',
      message: 'Students can no longer use this code. Existing links stay.',
      action: 'Revoke',
      destructive: true,
    )) {
      return;
    }
    if (!context.mounted) return;
    if (await runAction(
      context,
      () => ref.read(adminRepositoryProvider).revokeCode(c.id),
      success: '${c.code} revoked',
    )) {
      invalidateAdminData(ref);
    }
  }

  Future<void> _issueForTeacher(BuildContext context, WidgetRef ref) async {
    final teacherId = await showDialog<String>(context: context, builder: (_) => const _PickTeacherDialog());
    if (teacherId == null || !context.mounted) return;
    AdminCode? issued;
    final ok = await runAction(
      context,
      () async => issued = await ref.read(adminRepositoryProvider).issueCode(teacherId),
      success: 'New code issued',
    );
    if (!ok) return;
    invalidateAdminData(ref);
    final code = issued?.code;
    if (code != null && context.mounted) unawaited(copyText(context, code, label: 'New code $code copied'));
  }
}

class _PickTeacherDialog extends ConsumerStatefulWidget {
  const _PickTeacherDialog();

  @override
  ConsumerState<_PickTeacherDialog> createState() => _PickTeacherDialogState();
}

class _PickTeacherDialogState extends ConsumerState<_PickTeacherDialog> {
  String? _id;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Issue a new code'),
      content: SizedBox(
        width: 420,
        child: AsyncView<List<AdminUser>>(
          value: ref.watch(teachersProvider),
          onRetry: () => ref.invalidate(teachersProvider),
          builder: (list) => list.isEmpty
              ? const Text('There are no teachers yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("The teacher's current code stops working."),
                    const SizedBox(height: DLSpacing.md),
                    DropdownButtonFormField<String>(
                      key: const Key('pick-teacher'),
                      isExpanded: true,
                      initialValue: _id,
                      decoration: const InputDecoration(labelText: 'Teacher'),
                      items: [
                        for (final t in list)
                          DropdownMenuItem(value: t.id, child: Text('${nameOr(t.displayName)} (${t.email})')),
                      ],
                      onChanged: (v) => setState(() => _id = v),
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          key: const Key('pick-teacher-submit'),
          onPressed: _id == null ? null : () => Navigator.pop(context, _id),
          child: const Text('Issue code'),
        ),
      ],
    );
  }
}
