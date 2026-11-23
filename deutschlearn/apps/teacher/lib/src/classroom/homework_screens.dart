import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router.dart';
import 'classroom_providers.dart';
import 'homework_create_screen.dart';

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}. '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

DLStatusTone toneOf(SubmissionStatus s) => switch (s) {
  SubmissionStatus.graded => DLStatusTone.success,
  SubmissionStatus.submitted => DLStatusTone.info,
  SubmissionStatus.returned => DLStatusTone.warning,
  SubmissionStatus.inProgress => DLStatusTone.warning,
  SubmissionStatus.notStarted => DLStatusTone.neutral,
};

/// All homework the teacher has given, with live completion counts.
class TeacherHomeworkScreen extends ConsumerWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hw = ref.watch(teacherHomeworkProvider);
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'الواجبات', german: 'Hausaufgaben'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('homework-new'),
        onPressed: () => context.push(TeacherRoutes.homeworkNew),
        icon: const Icon(Icons.add),
        label: const Text('واجب جديد • Neu'),
      ),
      body: DLMaxWidth(
        child: switch (hw) {
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.all(DLSpacing.lg),
            child: DLBanner(tone: DLStatusTone.error, message: error is AppFailure ? error.message : '$error'),
          ),
          AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
            icon: Icons.assignment_outlined,
            message: 'لم تُرسل أي واجب بعد • Noch keine Hausaufgaben',
          ),
          AsyncData(value: final list) => ListView(
            padding: const EdgeInsets.fromLTRB(DLSpacing.lg, DLSpacing.lg, DLSpacing.lg, 96),
            children: [for (final h in list) _HomeworkCard(h)],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _HomeworkCard extends ConsumerWidget {
  const _HomeworkCard(this.h);

  final Homework h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(homeworkStatusProvider(h.id));
    final done = status
        .where((s) => s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded)
        .length;
    final toReview = status.where((s) => s.status == SubmissionStatus.submitted).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: DLSpacing.md),
      child: DLCard(
        key: Key('t-homework-${h.id}'),
        onTap: () => context.push(TeacherRoutes.homeworkDetail(h.id)),
        child: Row(
          children: [
            DLProgressRing(value: status.isEmpty ? 0 : done / status.length, size: 52),
            const SizedBox(width: DLSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.title.isEmpty ? '—' : h.title, style: theme.textTheme.titleMedium),
                  Text(
                    '${kindLabel(h.kind)}${h.dueAt == null ? '' : ' • ${fmtDate(h.dueAt!)}'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: DLSpacing.xs),
                  Wrap(
                    spacing: DLSpacing.sm,
                    children: [
                      DLStatusChip(label: '$done/${status.length} سلّموا • abgegeben', tone: DLStatusTone.info),
                      if (toReview > 0)
                        DLStatusChip(label: '$toReview للتصحيح • zu bewerten', tone: DLStatusTone.warning),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// One homework: who has started, submitted or been graded.
class TeacherHomeworkDetailScreen extends ConsumerWidget {
  const TeacherHomeworkDetailScreen({super.key, required this.homeworkId});

  final String homeworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final h = ref.watch(teacherHomeworkProvider).value?.where((x) => x.id == homeworkId).firstOrNull;
    final names = ref.watch(studentNamesProvider);
    final status = ref.watch(homeworkStatusProvider(homeworkId));
    if (h == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(h.title),
        actions: [
          IconButton(
            key: const Key('homework-delete'),
            tooltip: 'حذف • Löschen',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('حذف الواجب؟ • Löschen?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء • Abbrechen')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف • Löschen')),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(classroomRepositoryProvider).deleteHomework(h.id);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: DLMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.lg),
          children: [
            DLCard(
              color: theme.colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kindLabel(h.kind),
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                  if (h.dueAt != null)
                    Text(
                      'آخر موعد • Frist: ${fmtDate(h.dueAt!)}',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  if (h.instructions.isNotEmpty)
                    Text(h.instructions, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
            const SizedBox(height: DLSpacing.lg),
            const DLSectionHeader(arabic: 'الطلاب', german: 'Schüler'),
            const SizedBox(height: DLSpacing.sm),
            for (final t in status)
              Padding(
                padding: const EdgeInsets.only(bottom: DLSpacing.sm),
                child: DLCard(
                  key: Key('target-row-${t.studentId}'),
                  onTap: t.submission == null
                      ? null
                      : () => context.push(TeacherRoutes.review(homeworkId, t.studentId)),
                  child: Row(
                    children: [
                      CircleAvatar(child: Text((names[t.studentId] ?? '?').characters.first)),
                      const SizedBox(width: DLSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(names[t.studentId] ?? '—', style: theme.textTheme.titleMedium),
                            Wrap(
                              spacing: DLSpacing.sm,
                              children: [
                                DLStatusChip(label: '${t.status.ar} • ${t.status.de}', tone: toneOf(t.status)),
                                if (t.submission?.isLate(h) ?? (h.isOverdue() && t.submission == null))
                                  const DLStatusChip(label: 'متأخر • Verspätet', tone: DLStatusTone.error),
                                if (t.submission case final s? when s.maxScore > 0)
                                  DLStatusChip(label: 'Auto ${s.autoScore}/${s.maxScore}', tone: DLStatusTone.neutral),
                                if (t.submission?.grade case final g?)
                                  DLStatusChip(label: '$g/100', tone: DLStatusTone.success),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (t.submission != null) const Icon(Icons.rate_review_rounded),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Review one student's answers: corrections per question, a grade and feedback.
class SubmissionReviewScreen extends ConsumerStatefulWidget {
  const SubmissionReviewScreen({super.key, required this.homeworkId, required this.studentId});

  final String homeworkId;
  final String studentId;

  @override
  ConsumerState<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends ConsumerState<SubmissionReviewScreen> {
  final _feedback = TextEditingController();
  final _corrections = <String, TextEditingController>{};
  double? _grade;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _feedback.dispose();
    for (final c in _corrections.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send(HomeworkSubmission s, {required bool returnIt}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(classroomRepositoryProvider)
          .gradeSubmission(
            s.id,
            grade: (_grade ?? 0).round(),
            feedback: _feedback.text,
            corrections: {
              for (final e in _corrections.entries)
                if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
            },
            returnForRevision: returnIt,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(returnIt ? 'أعيد للطالب • Zurückgegeben' : 'تم التصحيح • Bewertet')));
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is AppFailure ? e.message : '$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = ref.watch(teacherHomeworkProvider).value?.where((x) => x.id == widget.homeworkId).firstOrNull;
    final s = ref
        .watch(teacherSubmissionsProvider)
        .value
        ?.where((x) => x.homeworkId == widget.homeworkId && x.studentId == widget.studentId)
        .firstOrNull;
    final name = ref.watch(studentNamesProvider)[widget.studentId] ?? '';
    if (h == null || s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lesson = h.lessonId == null ? null : ref.watch(teacherLessonDetailProvider(h.lessonId!)).value;
    final qs = homeworkQuestions(h, lesson);
    if (!_seeded) {
      _seeded = true;
      _feedback.text = s.feedback;
      _grade = (s.grade ?? (s.maxScore == 0 ? 100 : (100 * s.autoScore / s.maxScore).round())).toDouble();
    }
    TextEditingController ctrl(String k) =>
        _corrections.putIfAbsent(k, () => TextEditingController(text: s.corrections[k]));
    return Scaffold(
      appBar: AppBar(title: Text('$name • ${h.title}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DLSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: DLSecondaryButton(
                  key: const Key('review-return'),
                  label: 'إعادة للتعديل • Zurückgeben',
                  icon: Icons.undo_rounded,
                  onPressed: _busy ? null : () => _send(s, returnIt: true),
                ),
              ),
              const SizedBox(width: DLSpacing.md),
              Expanded(
                child: DLPrimaryButton(
                  key: const Key('review-grade'),
                  label: 'اعتماد العلامة • Bewerten',
                  icon: Icons.check_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : () => _send(s, returnIt: false),
                ),
              ),
            ],
          ),
        ),
      ),
      body: DLMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.lg),
          children: [
            Wrap(
              spacing: DLSpacing.sm,
              children: [
                DLStatusChip(label: '${s.status.ar} • ${s.status.de}', tone: toneOf(s.status)),
                if (s.submittedAt != null) DLStatusChip(label: fmtDate(s.submittedAt!), tone: DLStatusTone.neutral),
                if (s.isLate(h)) const DLStatusChip(label: 'متأخر • Verspätet', tone: DLStatusTone.error),
                if (s.maxScore > 0) DLStatusChip(label: 'Auto ${s.autoScore}/${s.maxScore}', tone: DLStatusTone.info),
              ],
            ),
            if (s.answers['note'] case final n? when n.isNotEmpty) ...[
              const SizedBox(height: DLSpacing.md),
              DLBanner(title: 'ملاحظة الطالب • Notiz', message: n),
            ],
            for (final (i, q) in qs.indexed) ...[
              const SizedBox(height: DLSpacing.md),
              DLCard(
                key: Key('review-q-${q.key}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${i + 1}. ${q.item?.promptText ?? q.custom!.prompt}', style: theme.textTheme.titleSmall),
                    const SizedBox(height: DLSpacing.xs),
                    Text(
                      'إجابة الطالب • Antwort: ${(s.answers[q.key] ?? '').isEmpty ? '—' : s.answers[q.key]}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      'الصحيح • Lösung: ${q.item?.answerText ?? (q.custom!.answer.isEmpty ? '(مفتوح • offen)' : q.custom!.answer)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: DLColors.success),
                    ),
                    TextField(
                      controller: ctrl(q.key),
                      decoration: const InputDecoration(labelText: 'تصحيح • Korrektur', isDense: true),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DLSpacing.lg),
            Text(
              'العلامة • Note: ${(_grade ?? 0).round()} / 100',
              key: const Key('review-grade-label'),
              style: theme.textTheme.titleMedium,
            ),
            Slider(
              key: const Key('review-grade-slider'),
              value: _grade ?? 0,
              max: 100,
              divisions: 20,
              label: '${(_grade ?? 0).round()}',
              onChanged: (v) => setState(() => _grade = v),
            ),
            TextField(
              key: const Key('review-feedback'),
              controller: _feedback,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'ملاحظات للطالب • Feedback'),
            ),
            const SizedBox(height: DLSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
