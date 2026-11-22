import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'home_shell.dart';
import 'teacher_link_tile.dart';

class StartTab extends ConsumerWidget {
  const StartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);
    void openTab(HomeTab t) => ref.read(homeTabProvider.notifier).select(t);

    return ListView(
      padding: const EdgeInsets.all(DLSpacing.lg),
      children: [
        DLCard(
          gradient: const LinearGradient(colors: [DLColors.teal, DLColors.blue]),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${profile.displayName} 👋',
                      key: const Key('home-greeting'),
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: DLSpacing.xs),
                    Text(
                      'Hallo! Bereit für Deutsch?',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md, vertical: DLSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DLRadius.md),
                ),
                child: Text(
                  profile.cefrLevel.code,
                  key: const Key('home-cefr'),
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DLSpacing.xl),
        const DLSectionHeader(arabic: 'مرحلتك الحالية', german: 'Deine Stufe'),
        const SizedBox(height: DLSpacing.md),
        DLCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: DLStagePath(stages: CefrLevel.codes, current: profile.cefrLevel.code),
              ),
              const SizedBox(height: DLSpacing.md),
              Text(
                'المستوى ${profile.cefrLevel.code} مأخوذ من ملفك الشخصي. اختبار تحديد المستوى قادم قريباً.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: DLSpacing.xl),
        const DLSectionHeader(arabic: 'معلّمي', german: 'Lehrkraft'),
        const SizedBox(height: DLSpacing.md),
        const TeacherLinkTile(),
        const SizedBox(height: DLSpacing.xl),
        const DLSectionHeader(arabic: 'استكشف', german: 'Entdecken'),
        const SizedBox(height: DLSpacing.md),
        DLFeatureTile(
          icon: Icons.menu_book_rounded,
          color: DLColors.teal,
          title: bilingualLabel('الدروس', 'Lektionen'),
          subtitle: 'قريباً • Demnächst',
          onTap: () => openTab(HomeTab.lessons),
        ),
        const SizedBox(height: DLSpacing.md),
        DLFeatureTile(
          icon: Icons.insights_rounded,
          color: DLColors.yellow,
          title: bilingualLabel('التقدّم', 'Fortschritt'),
          subtitle: 'قريباً • Demnächst',
          onTap: () => openTab(HomeTab.progress),
        ),
        const SizedBox(height: DLSpacing.md),
        DLFeatureTile(
          icon: Icons.chat_bubble_rounded,
          color: DLColors.blue,
          title: bilingualLabel('المحادثة', 'Chat'),
          subtitle: 'قريباً • Demnächst',
          onTap: () => openTab(HomeTab.chat),
        ),
      ],
    );
  }
}
