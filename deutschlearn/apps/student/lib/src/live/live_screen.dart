import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../homework/homework_providers.dart';
import '../lessons/exercises.dart';
import '../lessons/lesson_providers.dart';

/// Live lesson: the teacher decides which exercise is on screen, who answers and when the answer is shown.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  String? _joined;

  void _join(String sessionId) {
    if (_joined == sessionId) return;
    _joined = sessionId;
    ref.read(classroomRepositoryProvider).joinLive(sessionId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(liveSessionsProvider);
    final session = ref.watch(activeLiveSessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'الدرس المباشر', german: 'Live-Unterricht'),
      ),
      body: DLMaxWidth(
        child: switch ((sessions, session)) {
          (AsyncError(:final error), _) => Padding(
            padding: const EdgeInsets.all(DLSpacing.lg),
            child: DLBanner(tone: DLStatusTone.error, message: error is AppFailure ? error.message : '$error'),
          ),
          (AsyncLoading(), null) => const Center(child: CircularProgressIndicator()),
          (_, null) => const DLEmptyState(
            icon: Icons.videocam_off_outlined,
            message:
                'لا يوجد درس مباشر الآن. ستظهر الحصة هنا تلقائياً عندما يبدأها معلّمك.\n'
                'Gerade kein Live-Unterricht. Die Stunde erscheint hier automatisch.',
          ),
          (_, final s?) => Builder(
            builder: (context) {
              _join(s.id);
              return _LiveBody(session: s);
            },
          ),
        },
      ),
    );
  }
}

class _LiveBody extends ConsumerWidget {
  const _LiveBody({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(currentProfileProvider).id;
    final lesson = session.lessonId == null ? null : ref.watch(lessonDetailProvider(session.lessonId!));
    final mine = ref
        .watch(liveResponsesProvider(session.id))
        .value
        ?.where((r) => r.studentId == me && r.itemIndex == session.itemIndex)
        .firstOrNull;
    final items = lesson?.value?.items ?? const <LessonItem>[];
    final idx = session.itemIndex.clamp(0, items.isEmpty ? 0 : items.length - 1);
    final item = items.isEmpty ? null : items[idx];

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
                    Text(
                      session.title.isEmpty ? 'Live' : session.title,
                      key: const Key('live-title'),
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      lesson?.value == null ? '' : '${lesson!.value!.level.code} · ${lesson.value!.titleDe}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${idx + 1}/${items.length}',
                  key: const Key('live-position'),
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: DLSpacing.md),
        if (session.answererId == me)
          const DLBanner(
            key: Key('live-your-turn'),
            tone: DLStatusTone.warning,
            message: 'دورك للإجابة! • Du bist dran!',
          )
        else if (session.answererId != null)
          const DLBanner(tone: DLStatusTone.info, message: 'طالب آخر يجيب الآن • Ein anderer Schüler antwortet'),
        const SizedBox(height: DLSpacing.md),
        if (lesson == null)
          const DLEmptyState(icon: Icons.co_present_rounded, message: 'المعلّم يشرح الآن • Der Lehrer erklärt gerade')
        else if (item == null)
          const Center(child: CircularProgressIndicator())
        else if (item.isScored && mine != null)
          DLCard(
            key: const Key('live-answered'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.promptText, style: theme.textTheme.titleMedium),
                const SizedBox(height: DLSpacing.sm),
                Text(
                  mine.correct == true ? '✓ إجابتك صحيحة • Richtig' : '✗ إجابتك أُرسلت • Antwort gesendet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: mine.correct == true ? DLColors.success : theme.colorScheme.error,
                  ),
                ),
                if (mine.teacherMark != null) ...[
                  const SizedBox(height: DLSpacing.sm),
                  DLStatusChip(
                    key: const Key('live-mark'),
                    label: switch (mine.teacherMark) {
                      'correct' => 'المعلّم: صحيح • Richtig',
                      'wrong' => 'المعلّم: خطأ • Falsch',
                      _ => 'المعلّم: حاول مجدداً • Nochmal',
                    },
                    tone: switch (mine.teacherMark) {
                      'correct' => DLStatusTone.success,
                      'wrong' => DLStatusTone.error,
                      _ => DLStatusTone.warning,
                    },
                  ),
                ],
                if (mine.teacherMark == 'retry')
                  TextButton(
                    key: const Key('live-retry'),
                    onPressed: () => ref
                        .read(classroomRepositoryProvider)
                        .answerLive(session.id, itemIndex: idx, answer: '', correct: null),
                    child: const Text('أعد المحاولة • Nochmal versuchen'),
                  ),
              ],
            ),
          )
        else
          ExerciseView(
            key: ValueKey('live-${session.id}-$idx-${mine?.answer}'),
            item: item,
            onAnswered: (ok) => ref
                .read(classroomRepositoryProvider)
                .answerLive(session.id, itemIndex: idx, answer: ok ? '✓' : '✗', correct: ok),
          ),
        if (item != null && session.showAnswer && item.isScored) ...[
          const SizedBox(height: DLSpacing.md),
          DLBanner(
            key: const Key('live-answer'),
            tone: DLStatusTone.success,
            title: 'الإجابة الصحيحة • Lösung',
            message: item.answerText,
          ),
        ],
      ],
    );
  }
}
