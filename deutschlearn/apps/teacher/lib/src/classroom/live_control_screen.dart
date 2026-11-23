import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'classroom_providers.dart';
import 'lesson_picker.dart';

/// Live lesson control: the teacher chooses the lesson and the exercise students see,
/// who answers, reveals the answer and marks each response.
class LiveControlScreen extends ConsumerStatefulWidget {
  const LiveControlScreen({super.key, this.lessonId});

  final String? lessonId;

  @override
  ConsumerState<LiveControlScreen> createState() => _LiveControlScreenState();
}

class _LiveControlScreenState extends ConsumerState<LiveControlScreen> {
  final _title = TextEditingController(text: 'Deutschstunde');
  Lesson? _lesson;
  String? _classId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.lessonId case final id?) {
      ref.read(teacherAllLessonsProvider.future).then((ls) {
        if (mounted) setState(() => _lesson = ls.where((l) => l.id == id).firstOrNull);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
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
    final live = ref.watch(activeTeacherLiveProvider);
    final loading = ref.watch(teacherLiveSessionsProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'الدرس المباشر', german: 'Live-Unterricht'),
        actions: [
          if (live != null)
            TextButton.icon(
              key: const Key('live-end'),
              onPressed: _busy ? null : () => _run(() => ref.read(classroomRepositoryProvider).endLive(live.id)),
              icon: const Icon(Icons.stop_circle_outlined, color: DLColors.error),
              label: const Text('إنهاء • Beenden'),
            ),
        ],
      ),
      body: DLMaxWidth(
        child: loading && live == null
            ? const Center(child: CircularProgressIndicator())
            : live == null
            ? _startForm(context)
            : _LiveControl(session: live),
      ),
    );
  }

  Widget _startForm(BuildContext context) {
    final classes = ref.watch(classesProvider).value ?? const <SchoolClass>[];
    return ListView(
      padding: const EdgeInsets.all(DLSpacing.lg),
      children: [
        const DLBanner(
          message:
              'ابدأ حصة مباشرة: يرى طلابك المرتبطون نفس التمرين الذي تختاره، في الوقت الحقيقي.\n'
              'Starte eine Live-Stunde: Deine Schüler sehen in Echtzeit die Übung, die du auswählst.',
        ),
        const SizedBox(height: DLSpacing.lg),
        TextField(
          key: const Key('live-title-field'),
          controller: _title,
          decoration: const InputDecoration(labelText: 'عنوان الحصة • Titel'),
        ),
        const SizedBox(height: DLSpacing.md),
        DLFeatureTile(
          key: const Key('live-pick-lesson'),
          icon: Icons.menu_book_rounded,
          color: DLColors.teal,
          title: _lesson == null ? 'اختر الدرس • Lektion wählen' : lessonLabel(_lesson!),
          subtitle: 'Alphabet · A1 · A2 · B1',
          onTap: () async {
            final l = await pickLesson(context);
            if (l != null) setState(() => _lesson = l);
          },
        ),
        const SizedBox(height: DLSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: _classId,
          decoration: const InputDecoration(labelText: 'الصف • Klasse'),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل طلابي • Alle Schüler')),
            for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _classId = v),
        ),
        const SizedBox(height: DLSpacing.xl),
        DLPrimaryButton(
          key: const Key('live-start'),
          label: 'بدء الحصة • Live starten',
          icon: Icons.sensors_rounded,
          loading: _busy,
          onPressed: _busy
              ? null
              : () => _run(
                  () => ref
                      .read(classroomRepositoryProvider)
                      .startLive(title: _title.text, lessonId: _lesson?.id, classId: _classId),
                ),
        ),
      ],
    );
  }
}

class _LiveControl extends ConsumerWidget {
  const _LiveControl({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(classroomRepositoryProvider);
    final names = ref.watch(studentNamesProvider);
    final lesson = session.lessonId == null ? null : ref.watch(teacherLessonDetailProvider(session.lessonId!)).value;
    final items = lesson?.items ?? const <LessonItem>[];
    final idx = session.itemIndex.clamp(0, items.isEmpty ? 0 : items.length - 1);
    final item = items.isEmpty ? null : items[idx];
    final participants = ref.watch(teacherLiveParticipantsProvider(session.id)).value ?? const <LiveParticipant>[];
    final responses = (ref.watch(teacherLiveResponsesProvider(session.id)).value ?? const <LiveResponse>[])
        .where((r) => r.itemIndex == idx)
        .toList();
    void update(Map<String, dynamic> c) => repo.updateLive(session.id, c).catchError((Object e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    });
    void go(int i) => update({'item_index': i, 'show_answer': false, 'answerer_id': null});

    return ListView(
      padding: const EdgeInsets.all(DLSpacing.lg),
      children: [
        DLCard(
          gradient: const LinearGradient(colors: [DLColors.navy, DLColors.blue]),
          child: Row(
            children: [
              const Icon(Icons.sensors_rounded, color: Colors.white),
              const SizedBox(width: DLSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                    Text(
                      lesson == null ? 'بدون درس • Ohne Lektion' : lessonLabel(lesson),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${participants.length}',
                    key: const Key('live-participants'),
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  Text('حاضر • da', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DLSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('live-change-lesson'),
                onPressed: () async {
                  final l = await pickLesson(context);
                  if (l != null) {
                    update({'lesson_id': l.id, 'item_index': 0, 'show_answer': false, 'answerer_id': null});
                  }
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('تغيير الدرس • Lektion'),
              ),
            ),
          ],
        ),
        const SizedBox(height: DLSpacing.md),
        if (item != null) ...[
          DLCard(
            key: const Key('live-current'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DLStatusChip(label: '${idx + 1} / ${items.length} • ${item.kind.name}', tone: DLStatusTone.info),
                    const Spacer(),
                    if (item.isScored)
                      Text('${responses.length}/${participants.length} أجابوا', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: DLSpacing.sm),
                Text(item.promptText, style: theme.textTheme.titleLarge),
                if (item.german.isNotEmpty && item.arabic.isNotEmpty)
                  Text(item.german, textDirection: TextDirection.ltr, style: theme.textTheme.titleMedium),
                if (item.options.isNotEmpty && item.kind.hasOptions)
                  for (final o in item.options) Text('• $o', style: theme.textTheme.bodyLarge),
                if (item.isScored) ...[
                  const Divider(),
                  Text('✓ ${item.answerText}', style: theme.textTheme.bodyLarge?.copyWith(color: DLColors.success)),
                ],
              ],
            ),
          ),
          const SizedBox(height: DLSpacing.md),
          Row(
            children: [
              IconButton.filledTonal(
                key: const Key('live-prev'),
                onPressed: idx > 0 ? () => go(idx - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: DLSpacing.sm),
              Expanded(
                child: FilterChip(
                  key: const Key('live-show-answer'),
                  label: const Text('إظهار الإجابة • Lösung zeigen'),
                  selected: session.showAnswer,
                  onSelected: item.isScored ? (v) => update({'show_answer': v}) : null,
                ),
              ),
              const SizedBox(width: DLSpacing.sm),
              IconButton.filled(
                key: const Key('live-next'),
                onPressed: idx < items.length - 1 ? () => go(idx + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ] else if (lesson != null)
          const Center(child: CircularProgressIndicator()),
        const SizedBox(height: DLSpacing.lg),
        const DLSectionHeader(arabic: 'الطلاب في الحصة', german: 'Teilnehmer'),
        const SizedBox(height: DLSpacing.sm),
        if (participants.isEmpty)
          Text('بانتظار انضمام الطلاب… • Warte auf Schüler…', style: theme.textTheme.bodyMedium),
        for (final p in participants)
          Builder(
            builder: (context) {
              final r = responses.where((r) => r.studentId == p.studentId).firstOrNull;
              final chosen = session.answererId == p.studentId;
              return Card(
                key: Key('live-p-${p.studentId}'),
                color: chosen ? theme.colorScheme.primaryContainer : null,
                child: Padding(
                  padding: const EdgeInsets.all(DLSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            r == null
                                ? Icons.hourglass_empty_rounded
                                : (r.correct == true ? Icons.check_circle : Icons.cancel),
                            color: r == null
                                ? theme.colorScheme.onSurfaceVariant
                                : (r.correct == true ? DLColors.success : DLColors.error),
                          ),
                          const SizedBox(width: DLSpacing.sm),
                          Expanded(child: Text(names[p.studentId] ?? '—', style: theme.textTheme.titleSmall)),
                          TextButton(
                            key: Key('live-pick-${p.studentId}'),
                            onPressed: () => update({'answerer_id': chosen ? null : p.studentId}),
                            child: Text(chosen ? 'إلغاء الدور • Abwählen' : 'دوره • Drannehmen'),
                          ),
                        ],
                      ),
                      if (r != null)
                        Wrap(
                          spacing: DLSpacing.xs,
                          children: [
                            for (final (mark, label, color) in const [
                              ('correct', 'صحيح • Richtig', DLColors.success),
                              ('wrong', 'خطأ • Falsch', DLColors.error),
                              ('retry', 'أعد • Nochmal', DLColors.blue),
                            ])
                              ChoiceChip(
                                key: Key('live-mark-${p.studentId}-$mark'),
                                label: Text(label),
                                selected: r.teacherMark == mark,
                                selectedColor: color.withValues(alpha: 0.25),
                                onSelected: (_) =>
                                    repo.markLive(session.id, studentId: p.studentId, itemIndex: idx, mark: mark),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
