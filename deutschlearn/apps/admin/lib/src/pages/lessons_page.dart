import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';

class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(adminLessonsProvider);
    return PageBody(
      onRefresh: () async => ref.invalidate(adminLessonsProvider),
      children: [
        PageHeader(
          title: 'Lessons',
          subtitle: 'Lessons students see in the Lektionen tab',
          actions: [
            FilledButton.icon(
              key: const Key('new-lesson'),
              onPressed: () => _editLesson(context, ref, null, nextPosition: (lessons.value?.length ?? 0) + 1),
              icon: const Icon(Icons.add),
              label: const Text('New lesson'),
            ),
          ],
        ),
        AsyncView<List<Lesson>>(
          value: lessons,
          onRetry: () => ref.invalidate(adminLessonsProvider),
          builder: (list) => list.isEmpty
              ? const DLEmptyState(icon: Icons.menu_book_outlined, message: 'No lessons yet')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final l in list) ...[
                      DLCard(
                        key: ValueKey(l.id),
                        padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: DLSpacing.sm,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${l.level.code} · ${l.position}. ${l.titleDe}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      DLStatusChip(
                                        label: l.published ? 'Published' : 'Draft',
                                        tone: l.published ? DLStatusTone.success : DLStatusTone.neutral,
                                      ),
                                    ],
                                  ),
                                  Text('${l.titleAr} · ${l.itemCount} items'),
                                ],
                              ),
                            ),
                            IconButton(
                              key: Key('items-${l.id}'),
                              tooltip: 'Edit content',
                              icon: const Icon(Icons.list_alt),
                              onPressed: () => _editItems(context, ref, l),
                            ),
                            IconButton(
                              key: Key('edit-${l.id}'),
                              tooltip: 'Edit details',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editLesson(context, ref, l),
                            ),
                            IconButton(
                              key: Key('delete-${l.id}'),
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: DLColors.error),
                              onPressed: () => _delete(context, ref, l),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DLSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Lesson l) async {
    final ok = await confirm(
      context,
      title: 'Delete "${l.titleDe}"?',
      message: 'The lesson, its content and all student progress for it are deleted.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await runAction(context, () => ref.read(lessonRepositoryProvider).deleteLesson(l.id), success: 'Lesson deleted');
    ref.invalidate(adminLessonsProvider);
  }

  Future<void> _editLesson(BuildContext context, WidgetRef ref, Lesson? l, {int nextPosition = 1}) async {
    final result = await showDialog<Lesson>(
      context: context,
      builder: (_) => _LessonDialog(lesson: l, nextPosition: nextPosition),
    );
    if (result == null || !context.mounted) return;
    await runAction(context, () => ref.read(lessonRepositoryProvider).saveLesson(result), success: 'Lesson saved');
    ref.invalidate(adminLessonsProvider);
  }

  Future<void> _editItems(BuildContext context, WidgetRef ref, Lesson l) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LessonItemsEditor(lessonId: l.id, title: l.titleDe),
      ),
    );
    if (saved ?? false) ref.invalidate(adminLessonsProvider);
  }
}

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({required this.lesson, required this.nextPosition});
  final Lesson? lesson;
  final int nextPosition;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  final _form = GlobalKey<FormState>();
  late final _de = TextEditingController(text: widget.lesson?.titleDe);
  late final _ar = TextEditingController(text: widget.lesson?.titleAr);
  late final _desc = TextEditingController(text: widget.lesson?.descriptionAr);
  late final _pos = TextEditingController(text: '${widget.lesson?.position ?? widget.nextPosition}');
  late CefrLevel _level = widget.lesson?.level ?? CefrLevel.a1;
  late bool _published = widget.lesson?.published ?? false;

  @override
  void dispose() {
    for (final c in [_de, _ar, _desc, _pos]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.lesson == null ? 'New lesson' : 'Edit lesson'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('lesson-title-de'),
              controller: _de,
              decoration: const InputDecoration(labelText: 'German title'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              key: const Key('lesson-title-ar'),
              controller: _ar,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'Arabic title'),
            ),
            TextFormField(
              controller: _desc,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Arabic description'),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CefrLevel>(
                    initialValue: _level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [for (final l in CefrLevel.values) DropdownMenuItem(value: l, child: Text(l.code))],
                    onChanged: (v) => setState(() => _level = v ?? _level),
                  ),
                ),
                const SizedBox(width: DLSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _pos,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Order'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Number' : null,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              key: const Key('lesson-published'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Published (visible to students)'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        key: const Key('lesson-save'),
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            Lesson(
              id: widget.lesson?.id ?? '',
              titleDe: _de.text.trim(),
              titleAr: _ar.text.trim(),
              descriptionAr: _desc.text.trim(),
              level: _level,
              position: int.parse(_pos.text),
              published: _published,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

/// Full-screen editor for a lesson's vocabulary, phrases and quiz questions.
class LessonItemsEditor extends ConsumerStatefulWidget {
  const LessonItemsEditor({super.key, required this.lessonId, required this.title});
  final String lessonId;
  final String title;

  @override
  ConsumerState<LessonItemsEditor> createState() => _LessonItemsEditorState();
}

class _ItemDraft {
  _ItemDraft(LessonItem i)
    : kind = i.kind,
      german = TextEditingController(text: i.german),
      arabic = TextEditingController(text: i.arabic),
      exampleDe = TextEditingController(text: i.exampleDe),
      exampleAr = TextEditingController(text: i.exampleAr),
      options = TextEditingController(text: i.options.join('\n')),
      answer = i.answer ?? 0;

  LessonItemKind kind;
  final TextEditingController german, arabic, exampleDe, exampleAr, options;
  int answer;

  List<String> get optionList => options.text.split('\n').map((o) => o.trim()).where((o) => o.isNotEmpty).toList();

  LessonItem toItem() => LessonItem(
    id: '',
    kind: kind,
    german: german.text.trim(),
    arabic: arabic.text.trim(),
    exampleDe: exampleDe.text,
    exampleAr: exampleAr.text,
    options: optionList,
    answer: answer,
  );

  void dispose() {
    for (final c in [german, arabic, exampleDe, exampleAr, options]) {
      c.dispose();
    }
  }
}

class _LessonItemsEditorState extends ConsumerState<LessonItemsEditor> {
  List<_ItemDraft>? _items;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await ref.read(lessonRepositoryProvider).fetchLesson(widget.lessonId);
      if (mounted) setState(() => _items = l.items.map(_ItemDraft.new).toList());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    for (final d in _items ?? const <_ItemDraft>[]) {
      d.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    for (final (i, d) in _items!.indexed) {
      if (d.arabic.text.trim().isEmpty) return 'Item ${i + 1}: Arabic text is required';
      if (d.kind == LessonItemKind.quiz) {
        if (d.optionList.length < 2) return 'Item ${i + 1}: a quiz needs at least 2 options';
        if (d.answer >= d.optionList.length) return 'Item ${i + 1}: pick the correct option';
      } else if (d.german.text.trim().isEmpty) {
        return 'Item ${i + 1}: German text is required';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: DLColors.error, content: Text(problem)));
      return;
    }
    setState(() => _saving = true);
    final ok = await runAction(
      context,
      () => ref.read(lessonRepositoryProvider).saveItems(widget.lessonId, [for (final d in _items!) d.toItem()]),
      success: 'Content saved',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text('Content: ${widget.title}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(DLSpacing.sm),
            child: FilledButton(
              key: const Key('items-save'),
              onPressed: items == null || _saving ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      floatingActionButton: items == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-item'),
              onPressed: () =>
                  setState(() => items.add(_ItemDraft(const LessonItem(id: '', kind: LessonItemKind.vocab)))),
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(DLSpacing.lg),
              child: DLBanner(tone: DLStatusTone.error, message: failureText(_error!)),
            )
          : items == null
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView(
              padding: const EdgeInsets.fromLTRB(DLSpacing.lg, DLSpacing.lg, DLSpacing.lg, 96),
              onReorderItem: (from, to) => setState(() => items.insert(to, items.removeAt(from))),
              children: [
                for (final (i, d) in items.indexed)
                  Padding(
                    key: ObjectKey(d),
                    padding: const EdgeInsets.only(bottom: DLSpacing.md),
                    child: DLCard(child: _itemForm(i, d)),
                  ),
              ],
            ),
    );
  }

  Widget _itemForm(int i, _ItemDraft d) {
    final quiz = d.kind == LessonItemKind.quiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${i + 1}.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: DLSpacing.md),
            SegmentedButton<LessonItemKind>(
              segments: const [
                ButtonSegment(value: LessonItemKind.vocab, label: Text('Word')),
                ButtonSegment(value: LessonItemKind.phrase, label: Text('Phrase')),
                ButtonSegment(value: LessonItemKind.quiz, label: Text('Quiz')),
              ],
              selected: {d.kind},
              onSelectionChanged: (s) => setState(() => d.kind = s.first),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: DLColors.error),
              onPressed: () => setState(() => _items!.remove(d)),
            ),
            const SizedBox(width: DLSpacing.xl),
          ],
        ),
        TextField(
          controller: d.german,
          decoration: InputDecoration(labelText: quiz ? 'German prompt (optional)' : 'German'),
        ),
        TextField(
          controller: d.arabic,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(labelText: quiz ? 'Question (Arabic)' : 'Arabic meaning / explanation'),
        ),
        if (!quiz) ...[
          TextField(
            controller: d.exampleDe,
            decoration: const InputDecoration(labelText: 'Example (German, optional)'),
          ),
          TextField(
            controller: d.exampleAr,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'Example (Arabic, optional)'),
          ),
        ] else ...[
          TextField(
            controller: d.options,
            maxLines: null,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Options (one per line)'),
          ),
          const SizedBox(height: DLSpacing.sm),
          Wrap(
            spacing: DLSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Correct:'),
              for (final (oi, o) in d.optionList.indexed)
                ChoiceChip(label: Text(o), selected: d.answer == oi, onSelected: (_) => setState(() => d.answer = oi)),
            ],
          ),
        ],
      ],
    );
  }
}
