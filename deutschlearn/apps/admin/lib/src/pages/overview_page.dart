import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';
import '../router.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    return PageBody(
      onRefresh: () async => invalidateAdminData(ref),
      children: [
        PageHeader(
          title: 'Overview',
          subtitle: 'Live numbers from the database',
          actions: [
            OutlinedButton.icon(
              onPressed: () => invalidateAdminData(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        AsyncView<AdminStats>(
          value: stats,
          onRetry: () => ref.invalidate(adminStatsProvider),
          builder: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.pendingRequests > 0) ...[
                DLBanner(
                  tone: DLStatusTone.info,
                  title: '${s.pendingRequests} link request(s) waiting',
                  message: 'Students are waiting for a teacher to approve them.',
                  action: TextButton(onPressed: () => context.go(AdminRoutes.links), child: const Text('Review')),
                ),
                const SizedBox(height: DLSpacing.lg),
              ],
              Wrap(
                spacing: DLSpacing.lg,
                runSpacing: DLSpacing.lg,
                children: [
                  _Stat('Users', s.totalUsers, Icons.people_alt_outlined, DLColors.navy, AdminRoutes.users),
                  _Stat('Students', s.students, Icons.school_outlined, DLColors.teal, AdminRoutes.users),
                  _Stat('Teachers', s.teachers, Icons.co_present_outlined, DLColors.blue, AdminRoutes.users),
                  _Stat(
                    'Admins',
                    s.admins,
                    Icons.admin_panel_settings_outlined,
                    const Color(0xFFB7791F),
                    AdminRoutes.users,
                  ),
                  _Stat('New this week', s.newUsers7d, Icons.person_add_alt, DLColors.success, AdminRoutes.users),
                  _Stat('Active links', s.activeLinks, Icons.link, DLColors.teal, AdminRoutes.links),
                  _Stat('Pending requests', s.pendingRequests, Icons.hourglass_top, DLColors.blue, AdminRoutes.links),
                  _Stat('Active teacher codes', s.activeCodes, Icons.qr_code_2, DLColors.navy, AdminRoutes.codes),
                  _Stat(
                    'Students without teacher',
                    s.studentsWithoutTeacher,
                    Icons.person_off_outlined,
                    const Color(0xFFB7791F),
                    AdminRoutes.users,
                  ),
                  _Stat(
                    'Unconfirmed e-mails',
                    s.unconfirmedUsers,
                    Icons.mark_email_unread_outlined,
                    DLColors.textSecondary,
                    AdminRoutes.users,
                  ),
                  _Stat('Blocked users', s.blockedUsers, Icons.block, DLColors.error, AdminRoutes.users),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color, this.route);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 200,
      child: DLCard(
        key: Key('stat-$label'),
        onTap: () => context.go(route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DLIconBadge(icon: icon, color: color, size: 40),
            const SizedBox(height: DLSpacing.md),
            Text('$value', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: t.bodyMedium?.copyWith(color: DLColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
