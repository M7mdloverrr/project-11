import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'rich_explanation.dart';
import 'tts.dart';

/// One lesson step. Scored kinds call [onAnswered] exactly once.
class ExerciseView extends StatelessWidget {
  const ExerciseView({super.key, required this.item, required this.onAnswered});

  final LessonItem item;
  final ValueChanged<bool> onAnswered;

  @override
  Widget build(BuildContext context) => switch (item.kind) {
    LessonItemKind.vocab || LessonItemKind.phrase => _WordCard(item: item),
    LessonItemKind.text => _TextCard(item: item),
    LessonItemKind.rule => _RuleCard(item: item),
    LessonItemKind.quiz || LessonItemKind.gap || LessonItemKind.listen => _Choice(item: item, onAnswered: onAnswered),
    LessonItemKind.order => _Order(item: item, onAnswered: onAnswered),
    LessonItemKind.match => _Match(item: item, onAnswered: onAnswered),
    LessonItemKind.write => _Write(item: item, onAnswered: onAnswered),
  };
}

Color articleColor(String word) => switch (word.split(' ').first.toLowerCase()) {
  'der' => DLColors.blue,
  'die' => DLColors.error,
  'das' => DLColors.success,
  _ => DLColors.navy,
};

class SpeakButton extends ConsumerWidget {
  const SpeakButton({super.key, required this.text, this.size = 28});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        key: const Key('speak'),
        tooltip: 'استمع • Anhören',
        iconSize: size,
        color: DLColors.teal,
        onPressed: () => ref.read(speakerProvider).speak(text),
        icon: const Icon(Icons.volume_up_rounded),
      ),
      IconButton(
        key: const Key('speak-slow'),
        tooltip: 'ببطء • Langsam',
        iconSize: size * 0.8,
        color: DLColors.teal,
        onPressed: () => ref.read(speakerProvider).speak(text, slow: true),
        icon: const Icon(Icons.slow_motion_video_rounded),
      ),
    ],
  );
}

Widget _chip(String label, DLStatusTone tone) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: DLStatusChip(label: label, tone: tone),
);

Widget _feedback(bool correct, String solution) => Padding(
  padding: const EdgeInsets.only(top: DLSpacing.md),
  child: DLBanner(
    key: const Key('quiz-feedback'),
    tone: correct ? DLStatusTone.success : DLStatusTone.error,
    message: correct ? 'إجابة صحيحة! • Richtig!' : 'الإجابة الصحيحة: $solution • Leider falsch',
  ),
);

class _WordCard extends StatelessWidget {
  const _WordCard({required this.item});
  final LessonItem item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final vocab = item.kind == LessonItemKind.vocab;
    final parts = item.german.split(', ');
    final word = parts.first;
    final plural = parts.length > 1 ? parts.sublist(1).join(', ') : null;
    return DLCard(
      key: Key('item-${item.id}'),
      padding: const EdgeInsets.all(DLSpacing.xl),
      child: Column(
        children: [
          DLStatusChip(label: vocab ? 'كلمة • Wort' : 'عبارة • Satz', tone: DLStatusTone.info),
          const SizedBox(height: DLSpacing.lg),
          Text(
            word,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: vocab ? articleColor(word) : null),
          ),
          if (plural != null) Text('الجمع • Plural: $plural', textDirection: TextDirection.ltr, style: t.bodyMedium),
          SpeakButton(text: word),
          Text(
            item.arabic,
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(color: DLColors.teal),
          ),
          if (item.exampleDe != null) ...[
            const Divider(height: DLSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    item.exampleDe!,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: t.bodyLarge,
                  ),
                ),
                SpeakButton(text: item.exampleDe!, size: 22),
              ],
            ),
            if (item.exampleAr != null) Text(item.exampleAr!, textAlign: TextAlign.center, style: t.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _TextCard extends StatefulWidget {
  const _TextCard({required this.item});
  final LessonItem item;

  @override
  State<_TextCard> createState() => _TextCardState();
}

class _TextCardState extends State<_TextCard> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chip('نص وحوار • Text', DLStatusTone.info),
        const SizedBox(height: DLSpacing.md),
        DLCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SpeakButton(text: item.german),
              ),
              Text(item.german, textDirection: TextDirection.ltr, style: t.bodyLarge?.copyWith(height: 1.7)),
            ],
          ),
        ),
        if (item.arabic.isNotEmpty) ...[
          const SizedBox(height: DLSpacing.md),
          TextButton.icon(
            key: const Key('toggle-translation'),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
            icon: Icon(_showTranslation ? Icons.visibility_off : Icons.translate),
            label: Text(_showTranslation ? 'إخفاء الترجمة' : 'إظهار الترجمة • Übersetzung'),
          ),
          if (_showTranslation)
            DLCard(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(item.arabic, style: t.bodyLarge),
            ),
        ],
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.item});
  final LessonItem item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _chip('قاعدة • Regel', DLStatusTone.warning),
      const SizedBox(height: DLSpacing.md),
      DLCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichExplanation(item.arabic),
            if (item.german.isNotEmpty) ...[
              const SizedBox(height: DLSpacing.sm),
              for (final ex in item.german.split('\n').where((l) => l.trim().isNotEmpty))
                RichExplanation('> ${ex.trim()}'),
            ],
          ],
        ),
      ),
    ],
  );
}

class _Choice extends ConsumerStatefulWidget {
  const _Choice({required this.item, required this.onAnswered});
  final LessonItem item;
  final ValueChanged<bool> onAnswered;

  @override
  ConsumerState<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends ConsumerState<_Choice> {
  int? _picked;

  @override
  void initState() {
    super.initState();
    if (widget.item.kind == LessonItemKind.listen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(speakerProvider).speak(widget.item.german);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = widget.item;
    final q = item.shuffled();
    final (label, tone) = switch (item.kind) {
      LessonItemKind.gap => ('أكمل الفراغ • Lücke', DLStatusTone.info),
      LessonItemKind.listen => ('استماع • Hören', DLStatusTone.success),
      _ => ('اختبار • Quiz', DLStatusTone.warning),
    };
    final picked = _picked;
    final gapSentence = picked == null ? item.german : item.german.replaceFirst('___', q.options[q.answer]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chip(label, tone),
        const SizedBox(height: DLSpacing.lg),
        switch (item.kind) {
          LessonItemKind.gap => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DLCard(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  gapSentence,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (item.arabic.isNotEmpty) ...[
                const SizedBox(height: DLSpacing.sm),
                Text(item.arabic, textAlign: TextAlign.center, style: t.bodyLarge),
              ],
            ],
          ),
          LessonItemKind.listen => Column(
            children: [
              Text(item.arabic, textAlign: TextAlign.center, style: t.titleLarge),
              const SizedBox(height: DLSpacing.sm),
              SpeakButton(text: item.german, size: 48),
              if (picked != null) Text(item.german, textDirection: TextDirection.ltr, style: t.titleMedium),
            ],
          ),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.arabic, style: t.titleLarge),
              if (item.german.isNotEmpty) Text(item.german, textDirection: TextDirection.ltr, style: t.titleMedium),
            ],
          ),
        },
        const SizedBox(height: DLSpacing.lg),
        for (final (i, option) in q.options.indexed) ...[
          _OptionButton(
            key: Key('option-$i'),
            label: option,
            state: picked == null
                ? _OptionState.idle
                : i == q.answer
                ? _OptionState.correct
                : i == picked
                ? _OptionState.wrong
                : _OptionState.idle,
            onTap: picked != null
                ? null
                : () {
                    setState(() => _picked = i);
                    widget.onAnswered(i == q.answer);
                  },
          ),
          const SizedBox(height: DLSpacing.md),
        ],
        if (picked != null) _feedback(picked == q.answer, q.options[q.answer]),
      ],
    );
  }
}

class _Order extends StatefulWidget {
  const _Order({required this.item, required this.onAnswered});
  final LessonItem item;
  final ValueChanged<bool> onAnswered;

  @override
  State<_Order> createState() => _OrderState();
}

class _OrderState extends State<_Order> {
  late final List<String> _pool = widget.item.scrambledWords;
  final List<int> _chosen = [];
  bool? _correct;

  String get _answer => widget.item.german.split(RegExp(r'\s+')).join(' ');

  void _check() {
    final ok = _chosen.map((i) => _pool[i]).join(' ') == _answer;
    setState(() => _correct = ok);
    widget.onAnswered(ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final locked = _correct != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chip('رتّب الكلمات • Satzbau', DLStatusTone.info),
        const SizedBox(height: DLSpacing.lg),
        Text(widget.item.arabic, style: t.titleLarge),
        const SizedBox(height: DLSpacing.md),
        Container(
          key: const Key('order-answer'),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(DLSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DLColors.teal.withValues(alpha: 0.4)),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in _chosen)
                  ActionChip(label: Text(_pool[i]), onPressed: locked ? null : () => setState(() => _chosen.remove(i))),
              ],
            ),
          ),
        ),
        const SizedBox(height: DLSpacing.md),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, w) in _pool.indexed)
                if (!_chosen.contains(i))
                  ActionChip(
                    key: Key('word-$i'),
                    label: Text(w),
                    onPressed: locked ? null : () => setState(() => _chosen.add(i)),
                  ),
            ],
          ),
        ),
        const SizedBox(height: DLSpacing.lg),
        if (!locked)
          FilledButton(
            key: const Key('check'),
            onPressed: _chosen.length == _pool.length ? _check : null,
            child: const Text('تحقّق • Prüfen'),
          ),
        if (_correct != null) _feedback(_correct!, _answer),
      ],
    );
  }
}

class _Match extends StatefulWidget {
  const _Match({required this.item, required this.onAnswered});
  final LessonItem item;
  final ValueChanged<bool> onAnswered;

  @override
  State<_Match> createState() => _MatchState();
}

class _MatchState extends State<_Match> {
  late final pairs = widget.item.pairs;
  late final List<int> _rightOrder = widget.item.shuffled().options.map((o) => widget.item.options.indexOf(o)).toList();
  final Set<int> _matched = {};
  int? _left;
  int? _wrongRight;
  int _mistakes = 0;

  void _pickRight(int pairIndex) {
    final left = _left;
    if (left == null || _matched.contains(pairIndex)) return;
    if (left == pairIndex) {
      setState(() {
        _matched.add(pairIndex);
        _left = null;
        _wrongRight = null;
      });
      if (_matched.length == pairs.length) widget.onAnswered(_mistakes == 0);
    } else {
      setState(() {
        _mistakes++;
        _wrongRight = pairIndex;
      });
    }
  }

  Widget _tile(String text, {required bool ltr, required Color? color, VoidCallback? onTap, Key? key}) => Padding(
    padding: const EdgeInsets.only(bottom: DLSpacing.sm),
    child: DLCard(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md, vertical: DLSpacing.md),
      color: color,
      onTap: onTap,
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final done = _matched.length == pairs.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chip('طابق • Zuordnen', DLStatusTone.info),
        const SizedBox(height: DLSpacing.lg),
        Text(widget.item.arabic, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DLSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final (i, p) in pairs.indexed)
                    _tile(
                      p.de,
                      key: Key('match-de-$i'),
                      ltr: true,
                      color: _matched.contains(i)
                          ? DLColors.success.withValues(alpha: 0.15)
                          : (_left == i ? DLColors.yellow.withValues(alpha: 0.35) : null),
                      onTap: _matched.contains(i) ? null : () => setState(() => _left = i),
                    ),
                ],
              ),
            ),
            const SizedBox(width: DLSpacing.md),
            Expanded(
              child: Column(
                children: [
                  for (final i in _rightOrder)
                    if (i >= 0 && i < pairs.length)
                      _tile(
                        pairs[i].ar,
                        key: Key('match-ar-$i'),
                        ltr: false,
                        color: _matched.contains(i)
                            ? DLColors.success.withValues(alpha: 0.15)
                            : (_wrongRight == i ? DLColors.error.withValues(alpha: 0.15) : null),
                        onTap: () => _pickRight(i),
                      ),
                ],
              ),
            ),
          ],
        ),
        if (done)
          DLBanner(
            key: const Key('quiz-feedback'),
            tone: _mistakes == 0 ? DLStatusTone.success : DLStatusTone.warning,
            message: _mistakes == 0 ? 'ممتاز! بدون أخطاء • Perfekt!' : 'انتهيت مع $_mistakes أخطاء • $_mistakes Fehler',
          ),
      ],
    );
  }
}

class _Write extends StatefulWidget {
  const _Write({required this.item, required this.onAnswered});
  final LessonItem item;
  final ValueChanged<bool> onAnswered;

  @override
  State<_Write> createState() => _WriteState();
}

class _WriteState extends State<_Write> {
  final _controller = TextEditingController();
  bool? _correct;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final ok = widget.item.accepts(_controller.text);
    setState(() => _correct = ok);
    widget.onAnswered(ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chip('كتابة • Schreiben', DLStatusTone.info),
        const SizedBox(height: DLSpacing.lg),
        Text(widget.item.arabic, style: t.titleLarge),
        const SizedBox(height: DLSpacing.md),
        TextField(
          key: const Key('write-input'),
          controller: _controller,
          enabled: _correct == null,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          decoration: const InputDecoration(hintText: 'اكتب بالألمانية • Auf Deutsch schreiben'),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _controller.text.trim().isEmpty || _correct != null ? null : _check(),
        ),
        const SizedBox(height: DLSpacing.md),
        if (_correct == null)
          FilledButton(
            key: const Key('check'),
            onPressed: _controller.text.trim().isEmpty ? null : _check,
            child: const Text('تحقّق • Prüfen'),
          ),
        if (_correct != null) _feedback(_correct!, widget.item.acceptedAnswers.first),
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
