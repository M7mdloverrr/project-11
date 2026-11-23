import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../lessons/exercises.dart';
import '../lessons/lesson_providers.dart';
import '../router.dart';
import 'homework_providers.dart';
import 'homework_screen.dart';

/// One question of a homework: a lesson exercise or a teacher-written question.
typedef HomeworkQuestion = ({String key, LessonItem? item, CustomItem? custom});

List<HomeworkQuestion> homeworkQuestions(Homework h, Lesson? lesson) => [
  if (lesson != null)
    for (final i in lesson.items)
      if (i.isScored && (h.kind == HomeworkKind.lesson || h.itemIds.contains(i.id))) (key: i.id, item: i, custom: null),
  for (final (n, c) in h.customItems.indexed) (key: 'c$n', item: null, custom: c),
];

/// Auto-score: correct lesson exercises plus auto-gradable custom answers.
({int score, int max}) scoreAnswers(List<HomeworkQuestion> qs, Map<String, String> answers) {
  var score = 0, max = 0;
  for (final q in qs) {
    final a = answers[q.key] ?? '';
    if (q.item != null) {
      max++;
      if (a == '✓') score++;
    } else if (q.custom!.isAutoGraded) {
      max++;
      if (q.custom!.accepts(a)) score++;
    }
  }
  return (score: score, max: max);
}

class HomeworkDetailScreen extends ConsumerStatefulWidget {
  const HomeworkDetailScreen({super.key, required this.homeworkId});

  final String homeworkId;

  @override
  ConsumerState<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends ConsumerState<HomeworkDetailScreen> {
  Map<String, String>? _answers;
  bool _busy = false;
  int _round = 0;

  Future<void> _save(Homework h, List<HomeworkQuestion> qs, {required bool submit}) async {
    final answers = _answers ?? const {};
    if (submit) {
      final missing = qs.where((q) => (answers[q.key] ?? '').trim().isEmpty).length;
      if (missing > 0) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تسليم الواجب؟ • Abgeben?'),
            content: Text('$missing سؤال بدون إجابة • $missing Fragen offen'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء • Abbrechen')),
              TextButton(
                key: const Key('confirm-submit'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تسليم • Abgeben'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
    }
    setState(() => _busy = true);
    final s = scoreAnswers(qs, answers);
    try {
      await ref
          .read(classroomRepositoryProvider)
          .saveSubmission(h.id, answers: answers, submit: submit, autoScore: s.score, maxScore: s.max);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(submit ? 'تم التسليم • Abgegeben' : 'تم الحفظ • Gespeichert')));
      if (submit) context.canPop() ? context.pop() : context.go(StudentRoutes.homework);
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
    final entries = ref.watch(homeworkProvider);
    final entry = entries.value?.where((e) => e.homework.id == widget.homeworkId).firstOrNull;
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: entries is AsyncLoading
            ? const Center(child: CircularProgressIndicator())
            : const DLEmptyState(icon: Icons.search_off_rounded, message: 'الواجب غير موجود • Nicht gefunden'),
      );
    }
    final h = entry.homework;
    final lesson = h.lessonId == null ? null : ref.watch(lessonDetailProvider(h.lessonId!));
    final sub = entry.submission;
    final editable = entry.status.editableByStudent;
    _answers ??= {...?sub?.answers};
    final qs = homeworkQuestions(h, lesson?.value);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(h.title.isEmpty ? 'Hausaufgabe' : h.title)),
      bottomNavigationBar: editable
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DLSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: DLSecondaryButton(
                        key: const Key('homework-save'),
                        label: 'حفظ • Speichern',
                        icon: Icons.save_outlined,
                        onPressed: _busy ? null : () => _save(h, qs, submit: false),
                      ),
                    ),
                    const SizedBox(width: DLSpacing.md),
                    Expanded(
                      child: DLPrimaryButton(
                        key: const Key('homework-submit'),
                        label: 'تسليم • Abgeben',
                        icon: Icons.send_rounded,
                        loading: _busy,
                        onPressed: _busy ? null : () => _save(h, qs, submit: true),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: DLMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.lg),
          children: [
            DLCard(
              color: theme.colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(homeworkIcon(h.kind), color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: DLSpacing.sm),
                      Expanded(
                        child: Text(switch (h.kind) {
                          HomeworkKind.lesson => 'درس كامل • Ganze Lektion',
                          HomeworkKind.exercises => 'تمارين مختارة • Ausgewählte Übungen',
                          HomeworkKind.custom => 'أسئلة المعلّم • Aufgaben vom Lehrer',
                          HomeworkKind.study => 'حفظ ودراسة ذاتية • Lernen & Auswendiglernen',
                        }, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                      ),
                      DLStatusChip(
                        label: '${entry.status.ar} • ${entry.status.de}',
                        tone: statusTone(entry.status, overdue: editable && h.isOverdue()),
                      ),
                    ],
                  ),
                  if (h.dueAt != null) ...[
                    const SizedBox(height: DLSpacing.sm),
                    Text(
                      'آخر موعد • Frist: ${formatDue(h.dueAt!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                  if (h.instructions.isNotEmpty) ...[
                    const SizedBox(height: DLSpacing.sm),
                    Text(
                      h.instructions,
                      key: const Key('homework-instructions'),
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ],
              ),
            ),
            if (sub != null && (sub.status == SubmissionStatus.graded || sub.status == SubmissionStatus.returned)) ...[
              const SizedBox(height: DLSpacing.md),
              DLBanner(
                key: const Key('homework-feedback'),
                tone: sub.status == SubmissionStatus.graded ? DLStatusTone.success : DLStatusTone.warning,
                title: sub.grade == null ? 'ملاحظات المعلّم • Feedback' : 'العلامة • Note: ${sub.grade} / 100',
                message: sub.feedback.isEmpty ? '—' : sub.feedback,
              ),
            ],
            if (sub != null && sub.maxScore > 0) ...[
              const SizedBox(height: DLSpacing.sm),
              Text(
                'التصحيح الآلي • Automatisch: ${sub.autoScore} / ${sub.maxScore}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (h.lessonId != null) ...[
              const SizedBox(height: DLSpacing.md),
              DLFeatureTile(
                key: const Key('homework-open-lesson'),
                icon: Icons.play_lesson_rounded,
                color: DLColors.teal,
                title: lesson?.value?.titleAr.isNotEmpty == true ? lesson!.value!.titleAr : 'الدرس • Lektion',
                subtitle: lesson?.value == null
                    ? '…'
                    : '${lesson!.value!.level.code} · ${lesson.value!.titleDe} — الشرح والمفردات • Erklärung',
                onTap: () => context.push(StudentRoutes.lesson(h.lessonId!)),
              ),
            ],
            if (h.kind == HomeworkKind.study) ...[
              const SizedBox(height: DLSpacing.md),
              Text(
                'ادرس المادة واحفظها، ثم اضغط «تسليم» عند الانتهاء.\nLerne den Stoff und tippe dann auf „Abgeben“.',
                style: theme.textTheme.bodyLarge,
              ),
              if (editable) ...[
                const SizedBox(height: DLSpacing.sm),
                TextField(
                  key: const Key('study-note'),
                  controller: TextEditingController(text: _answers!['note'] ?? ''),
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'ملاحظة للمعلّم • Notiz an den Lehrer'),
                  onChanged: (v) => _answers!['note'] = v,
                ),
              ],
            ],
            if (lesson is AsyncLoading)
              const Padding(
                padding: EdgeInsets.all(DLSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (final (n, q) in qs.indexed) ...[
              const SizedBox(height: DLSpacing.lg),
              Text('سؤال ${n + 1} • Frage ${n + 1}', style: theme.textTheme.labelLarge),
              const SizedBox(height: DLSpacing.sm),
              if (editable && q.item != null && (_answers![q.key] ?? '').isEmpty)
                ExerciseView(
                  key: ValueKey('ex-$_round-${q.key}'),
                  item: q.item!,
                  onAnswered: (ok) => setState(() => _answers![q.key] = ok ? '✓' : '✗'),
                )
              else if (q.item != null)
                _AnsweredItem(
                  item: q.item!,
                  answer: _answers![q.key] ?? '',
                  correction: sub?.corrections[q.key],
                  onRetry: editable
                      ? () => setState(() {
                          _answers!.remove(q.key);
                          _round++;
                        })
                      : null,
                )
              else
                _CustomQuestion(
                  key: ValueKey('cq-${q.key}'),
                  item: q.custom!,
                  answer: _answers![q.key] ?? '',
                  editable: editable,
                  correction: sub?.corrections[q.key],
                  onChanged: (v) => setState(() => _answers![q.key] = v),
                ),
            ],
            const SizedBox(height: DLSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _AnsweredItem extends StatelessWidget {
  const _AnsweredItem({required this.item, required this.answer, this.correction, this.onRetry});

  final LessonItem item;
  final String answer;
  final String? correction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ok = answer == '✓';
    final prompt = item.arabic.isNotEmpty ? item.arabic : item.german;
    return DLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                answer.isEmpty ? Icons.radio_button_unchecked : (ok ? Icons.check_circle : Icons.cancel),
                color: answer.isEmpty ? theme.colorScheme.onSurfaceVariant : (ok ? DLColors.success : DLColors.error),
              ),
              const SizedBox(width: DLSpacing.sm),
              Expanded(child: Text(prompt, style: theme.textTheme.bodyLarge)),
              if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('إعادة • Nochmal')),
            ],
          ),
          if (correction != null && correction!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DLSpacing.sm),
              child: Text(
                '✎ $correction',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomQuestion extends StatefulWidget {
  const _CustomQuestion({
    super.key,
    required this.item,
    required this.answer,
    required this.editable,
    required this.onChanged,
    this.correction,
  });

  final CustomItem item;
  final String answer;
  final bool editable;
  final String? correction;
  final ValueChanged<String> onChanged;

  @override
  State<_CustomQuestion> createState() => _CustomQuestionState();
}

class _CustomQuestionState extends State<_CustomQuestion> {
  late final _ctrl = TextEditingController(text: widget.answer);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final it = widget.item;
    return DLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(it.prompt, style: theme.textTheme.titleMedium),
          const SizedBox(height: DLSpacing.sm),
          if (it.kind == 'quiz')
            for (final o in it.options)
              Padding(
                padding: const EdgeInsets.only(bottom: DLSpacing.xs),
                child: ChoiceChip(
                  label: SizedBox(width: double.infinity, child: Text(o)),
                  selected: widget.answer == o,
                  onSelected: widget.editable ? (_) => widget.onChanged(o) : null,
                ),
              )
          else
            TextField(
              controller: _ctrl,
              enabled: widget.editable,
              minLines: it.kind == 'open' ? 3 : 1,
              maxLines: it.kind == 'open' ? 8 : 2,
              decoration: const InputDecoration(labelText: 'إجابتك • Deine Antwort'),
              onChanged: widget.onChanged,
            ),
          if (!widget.editable && it.isAutoGraded)
            Padding(
              padding: const EdgeInsets.only(top: DLSpacing.sm),
              child: Text(
                it.accepts(widget.answer) ? '✓ صحيح • Richtig' : '✗ الصحيح • Richtig: ${it.answer.split('|').first}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: it.accepts(widget.answer) ? DLColors.success : theme.colorScheme.error,
                ),
              ),
            ),
          if (widget.correction != null && widget.correction!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DLSpacing.sm),
              child: Text(
                '✎ ${widget.correction}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
