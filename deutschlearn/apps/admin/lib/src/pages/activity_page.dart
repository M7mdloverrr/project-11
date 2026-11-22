import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';

const _actionLabels = {
  'update_profile': 'Edited profile',
  'create_user': 'Created user',
  'delete_user': 'Deleted user',
  'block_user': 'Blocked user',
  'unblock_user': 'Unblocked user',
  'confirm_email': 'Confirmed e-mail',
  'send_password_reset': 'Sent password reset e-mail',
  'create_password_reset_link': 'Created password reset link',
  'issue_code': 'Issued teacher code',
  'revoke_code': 'Revoked teacher code',
  'approve_request': 'Approved link request',
  'decline_request': 'Declined link request',
  'disconnect_link': 'Disconnected link',
  'link_student': 'Linked student to teacher',
};

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      onRefresh: () async => ref.invalidate(auditLogProvider),
      children: [
        const PageHeader(title: 'Activity', subtitle: 'Every admin action, newest first'),
        AsyncView<List<AuditEntry>>(
          value: ref.watch(auditLogProvider),
          onRetry: () => ref.invalidate(auditLogProvider),
          builder: (list) => list.isEmpty
              ? const DLEmptyState(icon: Icons.history, message: 'No admin actions yet')
              : DLCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, e) in list.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          key: ValueKey(e.id),
                          leading: const Icon(Icons.history, color: DLColors.teal),
                          title: Text(_actionLabels[e.action] ?? e.action),
                          subtitle: Text(
                            [
                              'by ${nameOr(e.adminName, 'deleted admin')}',
                              ...e.details.entries.map((d) => '${d.key}: ${d.value}'),
                            ].join('  •  '),
                          ),
                          trailing: Text(
                            formatDate(e.createdAt),
                            style: const TextStyle(color: DLColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
