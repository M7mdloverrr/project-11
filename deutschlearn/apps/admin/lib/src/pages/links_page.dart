import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';

class LinksPage extends ConsumerWidget {
  const LinksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingRequestsProvider);
    final filter = ref.watch(linkStatusFilterProvider);
    final links = ref.watch(linksProvider);
    final repo = ref.read(adminRepositoryProvider);

    Future<void> act(Future<void> Function() f, String done) async {
      if (await runAction(context, f, success: done)) invalidateAdminData(ref);
    }

    return PageBody(
      onRefresh: () async => invalidateAdminData(ref),
      children: [
        const PageHeader(title: 'Links', subtitle: 'Teacher–student connections and requests'),
        const DLSectionHeader(arabic: 'Pending requests', german: 'Waiting for approval'),
        const SizedBox(height: DLSpacing.sm),
        AsyncView<List<AdminLinkRequest>>(
          value: requests,
          onRetry: () => ref.invalidate(pendingRequestsProvider),
          builder: (list) => list.isEmpty
              ? const DLEmptyState(icon: Icons.inbox_outlined, message: 'No pending requests')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in list) ...[
                      DLCard(
                        key: ValueKey(r.id),
                        padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.md),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: DLSpacing.md,
                          runSpacing: DLSpacing.sm,
                          children: [
                            _Pair(student: r.student, teacher: r.teacher, when: 'requested ${formatDate(r.createdAt)}'),
                            Wrap(
                              spacing: DLSpacing.sm,
                              children: [
                                OutlinedButton(
                                  key: Key('decline-${r.id}'),
                                  onPressed: () => act(() => repo.respondToRequest(r.id, approve: false), 'Declined'),
                                  child: const Text('Decline'),
                                ),
                                FilledButton(
                                  key: Key('approve-${r.id}'),
                                  onPressed: () => act(() => repo.respondToRequest(r.id, approve: true), 'Approved'),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DLSpacing.sm),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: DLSpacing.xl),
        const DLSectionHeader(arabic: 'All links', german: 'Filter by status'),
        const SizedBox(height: DLSpacing.sm),
        Wrap(
          spacing: DLSpacing.sm,
          children: [
            for (final s in <LinkStatus?>[LinkStatus.active, LinkStatus.pending, LinkStatus.disconnected, null])
              ChoiceChip(
                key: Key('link-filter-${s?.name ?? 'all'}'),
                label: Text(s == null ? 'All' : _statusLabel(s)),
                selected: filter == s,
                onSelected: (_) => ref.read(linkStatusFilterProvider.notifier).set(s),
              ),
          ],
        ),
        const SizedBox(height: DLSpacing.md),
        AsyncView<List<TeacherStudentLink>>(
          value: links,
          onRetry: () => ref.invalidate(linksProvider),
          builder: (list) => list.isEmpty
              ? const DLEmptyState(icon: Icons.link_off, message: 'No links')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final l in list) ...[
                      DLCard(
                        key: ValueKey(l.id),
                        padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Pair(
                                student: l.student,
                                teacher: l.teacher,
                                when: 'updated ${formatDate(l.updatedAt)}',
                                status: l.status,
                              ),
                            ),
                            if (l.status != LinkStatus.disconnected)
                              TextButton.icon(
                                key: Key('disconnect-${l.id}'),
                                style: TextButton.styleFrom(foregroundColor: DLColors.error),
                                onPressed: () async {
                                  if (!await confirm(
                                    context,
                                    title: 'Disconnect?',
                                    message:
                                        '${nameOr(l.student?.displayName ?? '')} will no longer be linked to '
                                        '${nameOr(l.teacher?.displayName ?? '')}.',
                                    action: 'Disconnect',
                                    destructive: true,
                                  )) {
                                    return;
                                  }
                                  await act(() => repo.disconnectLink(l.id), 'Disconnected');
                                },
                                icon: const Icon(Icons.link_off),
                                label: const Text('Disconnect'),
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
}

String _statusLabel(LinkStatus s) => switch (s) {
  LinkStatus.active => 'Active',
  LinkStatus.pending => 'Pending',
  LinkStatus.disconnected => 'Disconnected',
};

class _Pair extends StatelessWidget {
  const _Pair({required this.student, required this.teacher, required this.when, this.status});

  final LinkParty? student;
  final LinkParty? teacher;
  final String when;
  final LinkStatus? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: DLSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 18, color: DLColors.teal),
            Text(nameOr(student?.displayName ?? ''), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (student?.cefrLevel != null) Text(student!.cefrLevel!.code),
            const Icon(Icons.arrow_forward, size: 16, color: DLColors.textSecondary),
            const Icon(Icons.co_present_outlined, size: 18, color: DLColors.blue),
            Text(nameOr(teacher?.displayName ?? ''), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (status != null)
              DLStatusChip(
                label: _statusLabel(status!),
                tone: switch (status!) {
                  LinkStatus.active => DLStatusTone.success,
                  LinkStatus.pending => DLStatusTone.info,
                  LinkStatus.disconnected => DLStatusTone.neutral,
                },
              ),
          ],
        ),
        Text(when, style: const TextStyle(color: DLColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
