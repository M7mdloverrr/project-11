import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../lessons/lessons_tab.dart';
import '../lessons/progress_tab.dart';
import 'chat_tab.dart';
import 'profile_tab.dart';
import 'start_tab.dart';

enum HomeTab { start, lessons, progress, chat, profile }

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(HomeTabController.new);

class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.start;

  void select(HomeTab tab) => state = tab;
}

/// Bottom navigation with the five Phase 1 tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    return DLExitGuard(
      onBack: () {
        if (ref.read(homeTabProvider) == HomeTab.start) return false;
        ref.read(homeTabProvider.notifier).select(HomeTab.start);
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: tab.index,
            children: const [StartTab(), LessonsTab(), ProgressTab(), ChatTab(), ProfileTab()],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Start',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Lektionen',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Fortschritt',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
