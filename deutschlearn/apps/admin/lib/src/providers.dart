import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>(
  (ref) => ref.watch(adminRepositoryProvider).fetchStats(),
);

class UserQuery {
  const UserQuery({this.search = '', this.role, this.page = 0});
  final String search;
  final Role? role;
  final int page;

  static const pageSize = 25;
}

class UserQueryController extends Notifier<UserQuery> {
  @override
  UserQuery build() => const UserQuery();

  void setSearch(String s) => state = UserQuery(search: s, role: state.role);
  void setRole(Role? r) => state = UserQuery(search: state.search, role: r);
  void setPage(int p) => state = UserQuery(search: state.search, role: state.role, page: p);
}

final userQueryProvider = NotifierProvider<UserQueryController, UserQuery>(UserQueryController.new);

final usersProvider = FutureProvider.autoDispose<AdminUserPage>((ref) {
  final q = ref.watch(userQueryProvider);
  return ref
      .watch(adminRepositoryProvider)
      .listUsers(search: q.search, role: q.role, limit: UserQuery.pageSize, offset: q.page * UserQuery.pageSize);
});

/// All teachers, for pickers.
final teachersProvider = FutureProvider.autoDispose<List<AdminUser>>(
  (ref) async => (await ref.watch(adminRepositoryProvider).listUsers(role: Role.teacher, limit: 200)).users,
);

final showRevokedCodesProvider = NotifierProvider<_Flag, bool>(_Flag.new);

class _Flag extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final codesProvider = FutureProvider.autoDispose<List<AdminCode>>(
  (ref) => ref.watch(adminRepositoryProvider).listCodes(activeOnly: !ref.watch(showRevokedCodesProvider)),
);

final linkStatusFilterProvider = NotifierProvider<_LinkFilter, LinkStatus?>(_LinkFilter.new);

class _LinkFilter extends Notifier<LinkStatus?> {
  @override
  LinkStatus? build() => LinkStatus.active;
  void set(LinkStatus? v) => state = v;
}

final linksProvider = FutureProvider.autoDispose<List<TeacherStudentLink>>(
  (ref) => ref.watch(adminRepositoryProvider).listLinks(status: ref.watch(linkStatusFilterProvider)),
);

final pendingRequestsProvider = FutureProvider.autoDispose<List<AdminLinkRequest>>(
  (ref) => ref.watch(adminRepositoryProvider).listRequests(status: LinkRequestStatus.pending),
);

final auditLogProvider = FutureProvider.autoDispose<List<AuditEntry>>(
  (ref) => ref.watch(adminRepositoryProvider).auditLog(),
);

/// Refreshes everything after a change, so counts and lists stay consistent.
void invalidateAdminData(WidgetRef ref) {
  ref
    ..invalidate(adminStatsProvider)
    ..invalidate(usersProvider)
    ..invalidate(teachersProvider)
    ..invalidate(codesProvider)
    ..invalidate(linksProvider)
    ..invalidate(pendingRequestsProvider)
    ..invalidate(auditLogProvider);
}
