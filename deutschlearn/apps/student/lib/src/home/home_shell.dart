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
        bottomNavigationBar: DLBottomNav(
          key: const Key('bottom-nav'),
          index: tab.index,
          onTap: (i) => ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
          items: const [
            (icon: Icons.home_rounded, ar: 'الرئيسية', de: 'Start'),
            (icon: Icons.menu_book_rounded, ar: 'الدروس', de: 'Lektionen'),
            (icon: Icons.insights_rounded, ar: 'التقدّم', de: 'Fortschritt'),
            (icon: Icons.chat_bubble_rounded, ar: 'المحادثة', de: 'Chat'),
            (icon: Icons.person_rounded, ar: 'حسابي', de: 'Profil'),
          ],
        ),
      ),
    );
  }
}
