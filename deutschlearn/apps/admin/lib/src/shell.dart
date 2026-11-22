import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

typedef _Dest = ({String route, IconData icon, String label});

const List<_Dest> _destinations = [
  (route: AdminRoutes.overview, icon: Icons.space_dashboard_outlined, label: 'Overview'),
  (route: AdminRoutes.users, icon: Icons.people_alt_outlined, label: 'Users'),
  (route: AdminRoutes.codes, icon: Icons.qr_code_2, label: 'Teacher codes'),
  (route: AdminRoutes.links, icon: Icons.link, label: 'Links'),
  (route: AdminRoutes.activity, icon: Icons.history, label: 'Activity'),
];

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final email = session is SessionSignedIn ? session.user.email ?? '' : '';
    final index = _destinations.indexWhere((d) => location.startsWith(d.route)).clamp(0, _destinations.length - 1);
    void go(int i) => context.go(_destinations[i].route);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final appBar = AppBar(
      title: const Text('DeutschLearn Admin'),
      actions: [
        if (wide && email.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md),
              child: Text(email, style: const TextStyle(color: DLColors.textSecondary)),
            ),
          ),
        IconButton(
          key: const Key('sign-out'),
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
        ),
      ],
    );

    if (!wide) {
      return Scaffold(
        appBar: appBar,
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: go,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(key: Key('nav-${d.route}'), icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: index,
            onDestinationSelected: go,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon, key: Key('nav-${d.route}')),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
