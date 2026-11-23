import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../lessons/lesson_providers.dart';
import '../router.dart';
import 'home_shell.dart';
import 'teacher_link_tile.dart';

const alphabetModuleSlug = 'alphabet-pronunciation';
const vocabularyModuleSlug = 'a1-wortschatz';

/// Home dashboard laid out like the reference: hero header, roadmap, resume card,
/// pastel feature grid and the overall progress strip.
class StartTab extends ConsumerWidget {
  const StartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final curriculum = ref.watch(curriculumProvider).value;
    final homework = ref.watch(homeworkProvider).value ?? const [];
    final openHomework = homework.where((h) => h.progress == null).length;
    void openTab(HomeTab t) => ref.read(homeTabProvider.notifier).select(t);

    final next = curriculum?.next;
    final alphabet = curriculum?.modules.where((m) => m.slug == alphabetModuleSlug).firstOrNull;
    final roadIndex = next == null
        ? profile.cefrLevel.index + 1
        : (alphabet != null && next.moduleId == alphabet.id ? 0 : next.level.index + 1);
    final nextModule = next == null ? null : curriculum!.modules.where((m) => m.id == next.moduleId).firstOrNull;
    final moduleDone = nextModule == null ? null : curriculum!.moduleProgress(nextModule);
    final level = next?.level ?? profile.cefrLevel;
    final levelLessons = curriculum?.path.where((l) => l.level == level).toList() ?? const <Lesson>[];
    final levelRatio = levelLessons.isEmpty
        ? 0.0
        : levelLessons.where(curriculum!.isPassed).length / levelLessons.length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myProgressProvider);
        ref.invalidate(myAssignmentsProvider);
        await ref.read(curriculumProvider.future);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DLHeroHeader(
            title: 'Hallo, ${profile.displayName} 👋',
            subtitle: 'مرحباً ${profile.displayName}',
            leading: DLHeaderIcon(
              icon: Icons.menu_rounded,
              tooltip: 'القائمة • Menü',
              onPressed: () => openTab(HomeTab.profile),
            ),
            actions: [
              DLHeaderIcon(
                key: const Key('home-bell'),
                icon: Icons.notifications_none_rounded,
                badge: openHomework,
                tooltip: 'الإشعارات • Mitteilungen',
                onPressed: () => _showHomework(context, homework),
              ),
            ],
            height: 170,
          ),
          DLMaxWidth(
            child: Transform.translate(
              offset: const Offset(0, -56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DLRoadmapCard(
                      key: const Key('home-roadmap'),
                      titleAr: 'مسار تعلّم الألمانية',
                      titleDe: 'Dein Lernweg',
                      badge: 'A1 → B1',
                      current: roadIndex.clamp(0, 3),
                      stages: const [
                        (label: 'A1', caption: 'Alphabet'),
                        (label: 'A1', caption: null),
                        (label: 'A2', caption: null),
                        (label: 'B1', caption: null),
                      ],
                      onStage: (i) {
                        if (i == 0 && alphabet != null) {
                          context.push(StudentRoutes.module(alphabet.id));
                        } else {
                          openTab(HomeTab.lessons);
                        }
                      },
                    ),
                    const SizedBox(height: DLSpacing.lg),
                    if (next != null)
                      DLResumeCard(
                        key: const Key('next-lesson'),
                        titleAr: 'متابعة الدرس',
                        titleDe: 'Lektion fortsetzen',
                        lessonLabel:
                            '${next.level.code} · ${next.titleDe}${next.titleAr.isEmpty ? '' : ' (${next.titleAr})'}',
                        progress: moduleDone == null || moduleDone.total == 0 ? 0 : moduleDone.done / moduleDone.total,
                        buttonAr: 'متابعة التعلّم',
                        buttonDe: 'Lektion fortsetzen',
                        onPressed: () => context.push(StudentRoutes.lesson(next.id)),
                      ),
                    const SizedBox(height: DLSpacing.lg),
                    DLTileGrid(
                      children: [
                        DLPastelTile(
                          key: const Key('tile-vocab'),
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFF1F9E58),
                          titleAr: 'ممارسة المفردات',
                          titleDe: 'Wortschatz üben',
                          onTap: () {
                            final m = curriculum?.modules.where((m) => m.slug == vocabularyModuleSlug).firstOrNull;
                            m == null ? openTab(HomeTab.lessons) : context.push(StudentRoutes.module(m.id));
                          },
                        ),
                        DLPastelTile(
                          key: const Key('tile-homework'),
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFFE58A1F),
                          titleAr: 'الواجبات المنزلية',
                          titleDe: 'Hausaufgaben',
                          badge: openHomework,
                          onTap: () => context.push(StudentRoutes.homework),
                        ),
                        DLPastelTile(
                          key: const Key('tile-live'),
                          icon: Icons.videocam_rounded,
                          color: DLColors.blue,
                          titleAr: 'درس مباشر',
                          titleDe: 'Live-Unterricht',
                          onTap: () => context.push(StudentRoutes.live),
                        ),
                        DLPastelTile(
                          key: const Key('tile-placement'),
                          icon: Icons.track_changes_rounded,
                          color: DLColors.success,
                          titleAr: 'اختبار تحديد المستوى',
                          titleDe: 'Einstufungstest',
                          onTap: curriculum?.placement == null
                              ? null
                              : () => context.push(StudentRoutes.lesson(curriculum!.placement!.id)),
                        ),
                        DLPastelTile(
                          key: const Key('tile-exams'),
                          icon: Icons.description_rounded,
                          color: const Color(0xFF7B4FD6),
                          titleAr: 'الاختبارات',
                          titleDe: 'Prüfungen',
                          onTap: curriculum == null ? null : () => _showExams(context, curriculum),
                        ),
                        DLPastelTile(
                          key: const Key('tile-achievements'),
                          icon: Icons.emoji_events_rounded,
                          color: const Color(0xFFD49A12),
                          titleAr: 'الإنجازات',
                          titleDe: 'Erfolge',
                          onTap: curriculum == null ? null : () => _showAchievements(context, curriculum),
                        ),
                      ],
                    ),
                    const SizedBox(height: DLSpacing.lg),
                    DLOverallProgressCard(
                      key: const Key('home-overall'),
                      label: level.code,
                      value: levelRatio,
                      onTap: () => openTab(HomeTab.progress),
                    ),
                    const SizedBox(height: DLSpacing.lg),
                    const TeacherLinkTile(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHomework(BuildContext context, List<Homework> homework) => context.push(StudentRoutes.homework);

  void _showExams(BuildContext context, Curriculum c) {
    final exams = c.path.where((l) => l.kind != LessonKind.lesson).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(DLSpacing.lg),
          children: [
            const DLBilingualTitle(arabic: 'الاختبارات والامتحانات', german: 'Tests & Prüfungen'),
            const SizedBox(height: DLSpacing.md),
            for (final l in exams)
              Padding(
                padding: const EdgeInsets.only(bottom: DLSpacing.sm),
                child: DLFeatureTile(
                  key: Key('exam-${l.id}'),
                  icon: c.isPassed(l)
                      ? Icons.verified_rounded
                      : (l.kind == LessonKind.exam ? Icons.school_rounded : Icons.quiz_rounded),
                  color: c.isPassed(l) ? DLColors.success : const Color(0xFF7B4FD6),
                  title: '${l.level.code} · ${l.titleAr.isEmpty ? l.titleDe : l.titleAr}',
                  subtitle: l.titleDe,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(StudentRoutes.lesson(l.id));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAchievements(BuildContext context, Curriculum c) {
    final passed = c.path.where(c.isPassed).toList();
    final tests = passed.where((l) => l.kind != LessonKind.lesson).length;
    final full = c.progress.values.where((p) => p.maxScore > 0 && p.bestScore == p.maxScore).length;
    final levels = CefrLevel.values.where((lv) {
      final ls = c.path.where((l) => l.level == lv).toList();
      return ls.isNotEmpty && ls.every(c.isPassed);
    }).toList();
    final items = [
      (Icons.star_rounded, 'أول درس', 'Erste Lektion', passed.isNotEmpty),
      (Icons.local_fire_department_rounded, '10 دروس', '10 Lektionen', passed.length >= 10),
      (Icons.rocket_launch_rounded, '50 درساً', '50 Lektionen', passed.length >= 50),
      (Icons.quiz_rounded, 'نجحت في اختبار', 'Test bestanden', tests > 0),
      (Icons.workspace_premium_rounded, 'علامة كاملة', '100 %', full > 0),
      for (final lv in CefrLevel.values.where((lv) => c.path.any((l) => l.level == lv)))
        (Icons.emoji_events_rounded, 'أنهيت ${lv.code}', '${lv.code} geschafft', levels.contains(lv)),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(DLSpacing.lg, 0, DLSpacing.lg, DLSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DLBilingualTitle(arabic: 'الإنجازات • ${passed.length} درس', german: 'Erfolge'),
            const SizedBox(height: DLSpacing.md),
            Wrap(
              spacing: DLSpacing.md,
              runSpacing: DLSpacing.md,
              children: [
                for (final (icon, ar, de, got) in items)
                  SizedBox(
                    width: 96,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: got ? DLColors.yellow : Theme.of(ctx).colorScheme.outline,
                          child: Icon(icon, color: got ? DLColors.navy : Theme.of(ctx).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: DLSpacing.xs),
                        Text(ar, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.labelMedium),
                        Text(de, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.labelSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
