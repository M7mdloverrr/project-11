import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';
import 'user_dialogs.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  late final _search = TextEditingController(text: ref.read(userQueryProvider).search);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(userQueryProvider);
    final users = ref.watch(usersProvider);
    final ctrl = ref.read(userQueryProvider.notifier);
    return PageBody(
      onRefresh: () async => ref.invalidate(usersProvider),
      children: [
        PageHeader(
          title: 'Users',
          subtitle: 'Students, teachers and admins',
          actions: [
            FilledButton.icon(
              key: const Key('add-user'),
              onPressed: () => showCreateUserDialog(context, ref),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add user'),
            ),
          ],
        ),
        TextField(
          key: const Key('user-search'),
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search by name or e-mail',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.search.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      ctrl.setSearch('');
                    },
                  ),
          ),
          onSubmitted: ctrl.setSearch,
        ),
        const SizedBox(height: DLSpacing.md),
        Wrap(
          spacing: DLSpacing.sm,
          children: [
            for (final r in <Role?>[null, ...Role.values])
              ChoiceChip(
                key: Key('role-filter-${r?.name ?? 'all'}'),
                label: Text(r == null ? 'All' : '${r.labelEn}s'),
                selected: query.role == r,
                onSelected: (_) => ctrl.setRole(r),
              ),
          ],
        ),
        const SizedBox(height: DLSpacing.lg),
        AsyncView<AdminUserPage>(
          value: users,
          onRetry: () => ref.invalidate(usersProvider),
          builder: (page) {
            if (page.users.isEmpty) return const DLEmptyState(icon: Icons.person_search, message: 'No users found');
            final pages = (page.total / UserQuery.pageSize).ceil();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${page.total} user(s)', style: const TextStyle(color: DLColors.textSecondary)),
                const SizedBox(height: DLSpacing.sm),
                for (final u in page.users) ...[UserTile(u, key: ValueKey(u.id)), const SizedBox(height: DLSpacing.sm)],
                if (pages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: query.page == 0 ? null : () => ctrl.setPage(query.page - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Page ${query.page + 1} of $pages'),
                      IconButton(
                        onPressed: query.page + 1 >= pages ? null : () => ctrl.setPage(query.page + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class UserTile extends ConsumerWidget {
  const UserTile(this.user, {super.key});

  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final sub = <String>[
      u.email,
      if (u.role == Role.student) 'Level ${u.cefrLevel.code}',
      if (u.role == Role.student) 'Teacher: ${u.teacherName ?? 'none'}',
      if (u.role == Role.teacher) '${u.studentCount} student(s)',
      'Joined ${formatDate(u.createdAt)}',
      'Last sign-in ${formatDate(u.lastSignInAt)}',
    ];
    return DLCard(
      padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.md),
      onTap: () => showEditUserDialog(context, ref, u),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: DLColors.tintTeal,
            child: Text(u.label.characters.first.toUpperCase(), style: const TextStyle(color: DLColors.teal)),
          ),
          const SizedBox(width: DLSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: DLSpacing.sm,
                  runSpacing: DLSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(nameOr(u.displayName), style: const TextStyle(fontWeight: FontWeight.w700)),
                    roleChip(u.role),
                    if (u.isBlocked) const DLStatusChip(label: 'Blocked', tone: DLStatusTone.error),
                    if (!u.isConfirmed) const DLStatusChip(label: 'E-mail not confirmed', tone: DLStatusTone.warning),
                  ],
                ),
                const SizedBox(height: DLSpacing.xs),
                Text(sub.join('  •  '), style: const TextStyle(color: DLColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          UserActionsMenu(u),
        ],
      ),
    );
  }
}
