import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'lesson_providers.dart';
import 'lessons_tab.dart';

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
          (l) => l.items.isEmpty
              ? const DLEmptyState(icon: Icons.menu_book_outlined, message: 'هذا الدرس فارغ • Diese Lektion ist leer')
              : _LessonPlayer(lesson: l),
        ),
      ),
    );
  }
}

class _LessonPlayer extends ConsumerStatefulWidget {
  const _LessonPlayer({required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<_LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends ConsumerState<_LessonPlayer> {
  int _index = 0;
  int _score = 0;
  int? _picked;
  bool _saving = false;
  bool _done = false;
  String? _error;

  List<LessonItem> get _items => widget.lesson.items;

  void _next() {
    setState(() {
      _picked = null;
      _index++;
    });
    if (_index >= _items.length) _finish();
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(lessonRepositoryProvider)
          .completeLesson(widget.lesson.id, score: _score, maxScore: widget.lesson.quizCount);
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
    final t = Theme.of(context).textTheme;
    if (_index >= _items.length) {
      final max = widget.lesson.quizCount;
      return ListView(
        padding: const EdgeInsets.all(DLSpacing.xl),
        children: [
          const SizedBox(height: DLSpacing.xl),
          Center(child: DLProgressRing(value: max == 0 ? 1 : _score / max, size: 120)),
          const SizedBox(height: DLSpacing.xl),
          const DLBilingualTitle(
            arabic: 'أحسنت! انتهى الدرس',
            german: 'Super! Lektion geschafft',
            align: CrossAxisAlignment.center,
          ),
          const SizedBox(height: DLSpacing.md),
          Text(
            'النتيجة • Ergebnis: $_score / $max',
            key: const Key('lesson-score'),
            textAlign: TextAlign.center,
            style: t.titleLarge,
          ),
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
            onPressed: _saving
                ? null
                : () => setState(() {
                    _index = 0;
                    _score = 0;
                    _done = false;
                  }),
          ),
        ],
      );
    }

    final item = _items[_index];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DLSpacing.lg, DLSpacing.md, DLSpacing.lg, 0),
          child: DLProgressBar(value: _index / _items.length),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [item.isQuiz ? _quiz(item, t) : _card(item, t)],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DLSpacing.lg),
          child: DLPrimaryButton(
            key: const Key('lesson-next'),
            label: _index == _items.length - 1 ? bilingualLabel('إنهاء', 'Fertig') : bilingualLabel('التالي', 'Weiter'),
            icon: Icons.arrow_back,
            onPressed: item.isQuiz && _picked == null ? null : _next,
          ),
        ),
      ],
    );
  }

  Widget _card(LessonItem item, TextTheme t) => DLCard(
    key: Key('item-${item.id}'),
    padding: const EdgeInsets.all(DLSpacing.xl),
    child: Column(
      children: [
        DLStatusChip(
          label: item.kind == LessonItemKind.vocab ? 'كلمة • Wort' : 'عبارة • Satz',
          tone: DLStatusTone.info,
        ),
        const SizedBox(height: DLSpacing.xl),
        Text(
          item.german,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DLSpacing.md),
        Text(
          item.arabic,
          textAlign: TextAlign.center,
          style: t.titleLarge?.copyWith(color: DLColors.teal),
        ),
        if (item.exampleDe != null) ...[
          const Divider(height: DLSpacing.xxl),
          Text(item.exampleDe!, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: t.bodyLarge),
          if (item.exampleAr != null) Text(item.exampleAr!, textAlign: TextAlign.center, style: t.bodyMedium),
        ],
      ],
    ),
  );

  Widget _quiz(LessonItem item, TextTheme t) {
    final q = item.shuffled();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DLStatusChip(label: 'اختبار • Quiz', tone: DLStatusTone.warning),
        const SizedBox(height: DLSpacing.lg),
        Text(item.arabic, style: t.titleLarge),
        if (item.german.isNotEmpty) Text(item.german, textDirection: TextDirection.ltr, style: t.bodyLarge),
        const SizedBox(height: DLSpacing.lg),
        for (final (i, option) in q.options.indexed) ...[
          _OptionButton(
            key: Key('option-$i'),
            label: option,
            state: _picked == null
                ? _OptionState.idle
                : i == q.answer
                ? _OptionState.correct
                : i == _picked
                ? _OptionState.wrong
                : _OptionState.idle,
            onTap: _picked != null
                ? null
                : () => setState(() {
                    _picked = i;
                    if (i == q.answer) _score++;
                  }),
          ),
          const SizedBox(height: DLSpacing.md),
        ],
        if (_picked != null)
          DLBanner(
            key: const Key('quiz-feedback'),
            tone: _picked == q.answer ? DLStatusTone.success : DLStatusTone.error,
            message: _picked == q.answer
                ? 'إجابة صحيحة! • Richtig!'
                : 'الإجابة الصحيحة: ${q.options[q.answer]} • Leider falsch',
          ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionButton extends StatelessWidget {
  const _OptionButton({super.key, required this.label, required this.state, required this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptionState.correct => DLColors.success,
      _OptionState.wrong => DLColors.error,
      _OptionState.idle => null,
    };
    return DLCard(
      onTap: onTap,
      color: color?.withValues(alpha: 0.12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          if (state == _OptionState.correct) const Icon(Icons.check_circle, color: DLColors.success),
          if (state == _OptionState.wrong) const Icon(Icons.cancel, color: DLColors.error),
        ],
      ),
    );
  }
}
