import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'exercises.dart';
import 'lesson_providers.dart';
import 'lessons_tab.dart';
import 'rich_explanation.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonDetailProvider(lessonId));
    return Scaffold(
      appBar: AppBar(title: Text(lesson.value?.titleAr ?? 'الدرس • Lektion')),
      body: SafeArea(
        child: asyncBody<Lesson>(
          lesson,
          () => ref.invalidate(lessonDetailProvider(lessonId)),
          (l) => l.items.isEmpty && l.explanationAr.isEmpty
              ? const DLEmptyState(icon: Icons.menu_book_outlined, message: 'هذا الدرس فارغ • Diese Lektion ist leer')
              : LessonPlayer(lesson: l),
        ),
      ),
    );
  }
}

/// Intro (goal + explanation) → items one by one → result with the pass mark.
class LessonPlayer extends ConsumerStatefulWidget {
  const LessonPlayer({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends ConsumerState<LessonPlayer> {
  late int _index = _hasIntro ? -1 : 0;
  int _score = 0;
  bool _answered = false;
  bool _saving = false;
  bool _done = false;
  String? _error;
  CefrLevel? _placed;

  Lesson get _lesson => widget.lesson;
  List<LessonItem> get _items => _lesson.items;
  bool get _hasIntro => _lesson.goalAr.isNotEmpty || _lesson.explanationAr.isNotEmpty;
  int get _max => _lesson.quizCount;

  void _next() {
    setState(() {
      _answered = false;
      _index++;
    });
    if (_index >= _items.length) _finish();
  }

  void _restart() => setState(() {
    _index = _hasIntro ? -1 : 0;
    _score = 0;
    _answered = false;
    _done = false;
    _error = null;
  });

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(lessonRepositoryProvider);
      await repo.completeLesson(_lesson.id, score: _score, maxScore: _max);
      if (_lesson.kind == LessonKind.placement) {
        final level = Curriculum.levelForPlacement(_max == 0 ? 0 : _score / _max);
        await repo.setPlacementLevel(level);
        ref.read(placementLevelProvider.notifier).set(level);
        _placed = level;
      }
      ref.invalidate(myProgressProvider);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = e is AppFailure ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index < 0) return _intro(context);
    if (_index >= _items.length) return _result(context);
    final item = _items[_index];
    final scored = item.isScored;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DLSpacing.lg, DLSpacing.md, DLSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(child: DLProgressBar(value: _index / _items.length)),
              const SizedBox(width: DLSpacing.md),
              Text('${_index + 1}/${_items.length}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              ExerciseView(
                key: ValueKey('ex-$_index-${item.id}'),
                item: item,
                onAnswered: (correct) => setState(() {
                  _answered = true;
                  if (correct) _score++;
                }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DLSpacing.lg),
          child: DLPrimaryButton(
            key: const Key('lesson-next'),
            label: _index == _items.length - 1 ? bilingualLabel('إنهاء', 'Fertig') : bilingualLabel('التالي', 'Weiter'),
            icon: Icons.arrow_back,
            onPressed: scored && !_answered ? null : _next,
          ),
        ),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isTest = _lesson.kind != LessonKind.lesson;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const Key('lesson-intro'),
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              DLBilingualTitle(arabic: _lesson.titleAr, german: '${_lesson.level.code} • ${_lesson.titleDe}'),
              const SizedBox(height: DLSpacing.lg),
              if (_lesson.goalAr.isNotEmpty)
                DLCard(
                  color: DLColors.mint,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(isTest ? Icons.workspace_premium_rounded : Icons.flag_rounded, color: DLColors.teal),
                      const SizedBox(width: DLSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isTest ? 'عن الاختبار • Test' : 'هدف الدرس • Lernziel', style: t.titleSmall),
                            Text(_lesson.goalAr, style: t.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_lesson.explanationAr.isNotEmpty) ...[
                const SizedBox(height: DLSpacing.lg),
                DLCard(child: RichExplanation(_lesson.explanationAr)),
              ],
              const SizedBox(height: DLSpacing.md),
              Text(
                '${_items.length} خطوة • $_max تمرين • النجاح من ${_lesson.passPercent}٪',
                textAlign: TextAlign.center,
                style: t.bodyMedium,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DLSpacing.lg),
          child: DLPrimaryButton(
            key: const Key('lesson-start'),
            label: bilingualLabel(isTest ? 'ابدأ الاختبار' : 'ابدأ التمارين', 'Los geht\'s'),
            icon: Icons.play_arrow_rounded,
            onPressed: _items.isEmpty ? null : () => setState(() => _index = 0),
          ),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ratio = _max == 0 ? 1.0 : _score / _max;
    final placement = _lesson.kind == LessonKind.placement;
    final passed = placement || ratio * 100 >= _lesson.passPercent - 1e-9;
    return ListView(
      padding: const EdgeInsets.all(DLSpacing.xl),
      children: [
        const SizedBox(height: DLSpacing.xl),
        Center(
          child: DLProgressRing(value: ratio, size: 120, color: passed ? DLColors.success : DLColors.error),
        ),
        const SizedBox(height: DLSpacing.xl),
        DLBilingualTitle(
          arabic: placement
              ? 'انتهى اختبار تحديد المستوى'
              : passed
              ? 'أحسنت! نجحت'
              : 'لم تصل إلى ${_lesson.passPercent}٪ بعد',
          german: placement
              ? 'Einstufung abgeschlossen'
              : passed
              ? 'Super! Bestanden'
              : 'Noch nicht bestanden',
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: DLSpacing.md),
        Text(
          'النتيجة • Ergebnis: $_score / $_max (${(ratio * 100).round()}٪)',
          key: const Key('lesson-score'),
          textAlign: TextAlign.center,
          style: t.titleLarge,
        ),
        if (_placed != null) ...[
          const SizedBox(height: DLSpacing.md),
          Text(
            'مستوى البداية المقترح • Startniveau: ${_placed!.code}',
            key: const Key('placement-level'),
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(color: DLColors.teal),
          ),
        ],
        if (!passed) ...[
          const SizedBox(height: DLSpacing.md),
          Text(
            'راجع الشرح ثم أعد المحاولة لفتح الدرس التالي • Wiederhole die Lektion',
            textAlign: TextAlign.center,
            style: t.bodyLarge,
          ),
        ],
        const SizedBox(height: DLSpacing.xl),
        if (_saving) const Center(child: CircularProgressIndicator()),
        if (_error != null) ...[
          DLBanner(tone: DLStatusTone.error, message: _error!),
          const SizedBox(height: DLSpacing.md),
          DLSecondaryButton(label: bilingualLabel('حفظ مجدداً', 'Erneut speichern'), onPressed: _finish),
        ],
        if (_done) const DLBanner(tone: DLStatusTone.success, message: 'تم حفظ تقدّمك • Fortschritt gespeichert'),
        const SizedBox(height: DLSpacing.lg),
        DLPrimaryButton(
          key: const Key('lesson-close'),
          label: bilingualLabel('العودة إلى الدروس', 'Zurück zu den Lektionen'),
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: DLSpacing.md),
        DLSecondaryButton(
          key: const Key('lesson-restart'),
          label: bilingualLabel('إعادة الدرس', 'Wiederholen'),
          onPressed: _saving ? null : _restart,
        ),
      ],
    );
  }
}
