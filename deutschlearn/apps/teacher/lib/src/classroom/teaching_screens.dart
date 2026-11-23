import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../dashboard/teacher_controllers.dart';
import '../router.dart';
import '../students/student_providers.dart';
import 'classroom_providers.dart';
import 'homework_create_screen.dart';
import 'lesson_picker.dart';

/// Lesson preparation: browse every level and module, open any lesson.
class LessonBrowserScreen extends StatelessWidget {
  const LessonBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const DLBilingualTitle(arabic: 'تحضير الدروس', german: 'Unterricht vorbereiten'),
    ),
    body: DLMaxWidth(child: CurriculumBrowser(onLesson: (l) => context.push(TeacherRoutes.lessonPreview(l.id)))),
  );
}

/// Full lesson content with answers, plus "assign" and "teach live" actions.
class LessonPreviewScreen extends ConsumerWidget {
  const LessonPreviewScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lesson = ref.watch(teacherLessonDetailProvider(lessonId));
    return Scaffold(
      appBar: AppBar(title: Text(lesson.value?.titleDe ?? '')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DLSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: DLSecondaryButton(
                  key: const Key('preview-assign'),
                  label: 'واجب • Hausaufgabe',
                  icon: Icons.assignment_add,
                  onPressed: () => context.push(
                    TeacherRoutes.homeworkNew,
                    extra: (lessonId: lessonId, studentId: null, kind: null) as HomeworkDraftArgs,
                  ),
                ),
              ),
              const SizedBox(width: DLSpacing.md),
              Expanded(
                child: DLPrimaryButton(
                  key: const Key('preview-live'),
                  label: 'تدريس مباشر • Live',
                  icon: Icons.sensors_rounded,
                  onPressed: () => context.push(TeacherRoutes.live, extra: lessonId),
                ),
              ),
            ],
          ),
        ),
      ),
      body: DLMaxWidth(
        child: switch (lesson) {
          AsyncError(:final error) => DLBanner(tone: DLStatusTone.error, message: '$error'),
          AsyncData(value: final l) => ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              DLCard(
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonLabel(l),
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                    if (l.goalAr.isNotEmpty)
                      Text('🎯 ${l.goalAr}', style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
                    Text(
                      '${l.items.length} خطوة • ${l.items.where((i) => i.isScored).length} تمرين',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              if (l.explanationAr.isNotEmpty) ...[
                const SizedBox(height: DLSpacing.md),
                ExpansionTile(
                  title: const Text('الشرح • Erklärung'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(DLSpacing.md),
                      child: Text(l.explanationAr, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: DLSpacing.md),
              for (final (i, it) in l.items.indexed)
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(it.promptText),
                  subtitle: Text(
                    it.isScored ? '${it.kind.name} · ✓ ${it.answerText}' : '${it.kind.name} · ${it.german}',
                    maxLines: 3,
                  ),
                ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Per-student report: lessons, scores per level and homework results.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(linkedStudentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'التقارير', german: 'Berichte'),
      ),
      body: DLMaxWidth(
        child: switch (students) {
          AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
            icon: Icons.insights_outlined,
            message: 'لا يوجد طلاب بعد • Noch keine Schüler',
          ),
          AsyncData(value: final list) => ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [for (final s in list) _StudentReport(link: s)],
          ),
          AsyncError(:final error) => DLBanner(tone: DLStatusTone.error, message: '$error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _StudentReport extends ConsumerWidget {
  const _StudentReport({required this.link});

  final TeacherStudentLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(studentProgressProvider(link.studentId)).value;
    final targets = ref.watch(homeworkTargetsProvider).value ?? const <String, List<String>>{};
    final subs = (ref.watch(teacherSubmissionsProvider).value ?? const <HomeworkSubmission>[])
        .where((s) => s.studentId == link.studentId)
        .toList();
    final assigned = targets.values.where((t) => t.contains(link.studentId)).length;
    final handedIn = subs
        .where((s) => s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded)
        .length;
    final grades = subs.map((s) => s.grade).nonNulls.toList();
    final avgGrade = grades.isEmpty ? null : (grades.reduce((a, b) => a + b) / grades.length).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: DLSpacing.md),
      child: DLCard(
        key: Key('report-${link.studentId}'),
        onTap: () => context.push(TeacherRoutes.student(link.studentId), extra: link.student),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DLProgressRing(value: summary?.ratio ?? 0, size: 56),
                const SizedBox(width: DLSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.student?.displayName ?? '—', style: theme.textTheme.titleMedium),
                      Text(
                        summary == null
                            ? '…'
                            : '${summary.completed}/${summary.total} دروس • Ø ${(summary.averageScore * 100).round()}%',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'واجبات • HA: $handedIn/$assigned${avgGrade == null ? '' : ' • Note Ø $avgGrade'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: DLSpacing.sm),
              for (final lv in CefrLevel.values)
                if (summary.lessons.where((l) => l.level == lv).toList() case final ls when ls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: DLSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: Text(lv.code, style: theme.textTheme.labelMedium)),
                        Expanded(
                          child: DLProgressBar(
                            value: ls.where((l) => summary.progress.containsKey(l.id)).length / ls.length,
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '${ls.where((l) => summary.progress.containsKey(l.id)).length}/${ls.length}',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Classes: named groups of linked students for homework and live lessons.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [SchoolClass? c]) async {
    final students = ref.read(linkedStudentsProvider).value ?? const <TeacherStudentLink>[];
    final name = TextEditingController(text: c?.name);
    final members = {...?c?.memberIds};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(c == null ? 'صف جديد • Neue Klasse' : c.name),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  key: const Key('class-name'),
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الصف • Name'),
                ),
                for (final s in students)
                  CheckboxListTile(
                    key: Key('member-${s.studentId}'),
                    value: members.contains(s.studentId),
                    title: Text(s.student?.displayName ?? '—'),
                    onChanged: (v) =>
                        setState(() => v == true ? members.add(s.studentId) : members.remove(s.studentId)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء • Abbrechen')),
            FilledButton(
              key: const Key('class-save'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ • Speichern'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await ref.read(classroomRepositoryProvider).saveClass(id: c?.id, name: name.text, memberIds: [...members]);
      ref.invalidate(classesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is AppFailure ? e.message : '$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider);
    final names = ref.watch(studentNamesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'الصفوف', german: 'Klassen'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('class-new'),
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('صف جديد • Neu'),
      ),
      body: DLMaxWidth(
        child: switch (classes) {
          AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
            icon: Icons.groups_outlined,
            message: 'أنشئ صفاً لتجميع طلابك • Erstelle eine Klasse',
          ),
          AsyncData(value: final list) => ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: DLSpacing.md),
                  child: DLFeatureTile(
                    key: Key('class-tile-${c.id}'),
                    icon: Icons.groups_rounded,
                    color: DLColors.blue,
                    title: '${c.name} (${c.memberIds.length})',
                    subtitle: c.memberIds.map((m) => names[m] ?? '—').join('، '),
                    onTap: () => _edit(context, ref, c),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(classroomRepositoryProvider).deleteClass(c.id);
                        ref.invalidate(classesProvider);
                      },
                    ),
                  ),
                ),
            ],
          ),
          AsyncError(:final error) => DLBanner(tone: DLStatusTone.error, message: '$error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
