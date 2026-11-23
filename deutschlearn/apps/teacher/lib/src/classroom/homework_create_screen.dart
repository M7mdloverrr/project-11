import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../dashboard/teacher_controllers.dart';
import 'classroom_providers.dart';
import 'lesson_picker.dart';

typedef HomeworkDraftArgs = ({String? lessonId, String? studentId, HomeworkKind? kind});

String kindLabel(HomeworkKind k) => switch (k) {
  HomeworkKind.lesson => 'درس كامل • Lektion',
  HomeworkKind.exercises => 'تمارين • Übungen',
  HomeworkKind.custom => 'أسئلة خاصة • Eigene Aufgaben',
  HomeworkKind.study => 'حفظ ودراسة • Lernen',
};

/// Create homework for students or a class: a lesson, selected exercises, own questions or study material.
class HomeworkCreateScreen extends ConsumerStatefulWidget {
  const HomeworkCreateScreen({super.key, this.args});

  final HomeworkDraftArgs? args;

  @override
  ConsumerState<HomeworkCreateScreen> createState() => _HomeworkCreateScreenState();
}

class _HomeworkCreateScreenState extends ConsumerState<HomeworkCreateScreen> {
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  late HomeworkKind _kind = widget.args?.kind ?? HomeworkKind.lesson;
  Lesson? _lesson;
  final _itemIds = <String>{};
  final _custom = <CustomItem>[];
  late final _students = <String>{?widget.args?.studentId};
  String? _classId;
  DateTime? _due;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final id = widget.args?.lessonId;
    if (id != null) {
      ref.read(teacherAllLessonsProvider.future).then((ls) {
        final l = ls.where((l) => l.id == id).firstOrNull;
        if (l != null && mounted) _setLesson(l);
      }, onError: (_) {});
    }
  }

  void _setLesson(Lesson l) => setState(() {
    _lesson = l;
    _itemIds.clear();
    if (_title.text.isEmpty) _title.text = l.titleDe;
  });

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _due ?? now.add(const Duration(days: 7)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    setState(() => _due = DateTime(d.year, d.month, d.day, t?.hour ?? 23, t?.minute ?? 59));
  }

  Future<void> _addQuestion() async {
    final item = await showDialog<CustomItem>(context: context, builder: (_) => const _QuestionDialog());
    if (item != null) setState(() => _custom.add(item));
  }

  String? get _problem {
    if (_title.text.trim().isEmpty) return 'أدخل عنواناً • Titel fehlt';
    if ((_kind == HomeworkKind.lesson || _kind == HomeworkKind.exercises) && _lesson == null) {
      return 'اختر درساً • Lektion wählen';
    }
    if (_kind == HomeworkKind.exercises && _itemIds.isEmpty) return 'اختر تمريناً • Übung wählen';
    if (_kind == HomeworkKind.custom && _custom.isEmpty) return 'أضف سؤالاً • Frage hinzufügen';
    if (_students.isEmpty) return 'اختر طالباً أو صفاً • Schüler oder Klasse wählen';
    return null;
  }

  Future<void> _save() async {
    if (_problem case final p?) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p)));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(classroomRepositoryProvider)
          .createHomework(
            Homework(
              id: '',
              teacherId: '',
              kind: _kind,
              title: _title.text,
              instructions: _instructions.text,
              lessonId: _lesson?.id,
              itemIds: _kind == HomeworkKind.exercises ? [..._itemIds] : const [],
              customItems: _custom,
              classId: _classId,
              dueAt: _due,
            ),
            studentIds: [..._students],
          );
      ref.invalidate(homeworkTargetsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إرسال الواجب • Hausaufgabe verschickt')));
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
    final students = ref.watch(linkedStudentsProvider).value ?? const <TeacherStudentLink>[];
    final classes = ref.watch(classesProvider).value ?? const <SchoolClass>[];
    final detail = _lesson == null || _kind != HomeworkKind.exercises
        ? null
        : ref.watch(teacherLessonDetailProvider(_lesson!.id));
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'واجب جديد', german: 'Neue Hausaufgabe'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DLSpacing.md),
          child: DLPrimaryButton(
            key: const Key('homework-send'),
            label: 'إرسال الواجب • Verschicken',
            icon: Icons.send_rounded,
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ),
      ),
      body: DLMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.lg),
          children: [
            const DLSectionHeader(arabic: 'نوع الواجب', german: 'Art'),
            const SizedBox(height: DLSpacing.sm),
            Wrap(
              spacing: DLSpacing.sm,
              runSpacing: DLSpacing.sm,
              children: [
                for (final k in HomeworkKind.values)
                  ChoiceChip(
                    key: Key('kind-${k.name}'),
                    label: Text(kindLabel(k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: DLSpacing.lg),
            TextField(
              key: const Key('homework-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'العنوان • Titel'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DLSpacing.md),
            TextField(
              key: const Key('homework-instructions'),
              controller: _instructions,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'التعليمات (عربي/ألماني) • Anweisungen'),
            ),
            const SizedBox(height: DLSpacing.lg),
            if (_kind != HomeworkKind.custom || _lesson != null)
              DLFeatureTile(
                key: const Key('homework-pick-lesson'),
                icon: Icons.menu_book_rounded,
                color: DLColors.teal,
                title: _lesson == null ? 'اختر درساً من أي مستوى • Lektion wählen' : lessonLabel(_lesson!),
                subtitle: _kind == HomeworkKind.study ? 'اختياري • optional' : 'Alphabet · A1 · A2 · B1',
                onTap: () async {
                  final l = await pickLesson(context);
                  if (l != null) _setLesson(l);
                },
              ),
            if (detail != null) ...[
              const SizedBox(height: DLSpacing.md),
              const DLSectionHeader(arabic: 'اختر التمارين', german: 'Übungen auswählen'),
              if (detail.value case final l?)
                for (final it in l.items.where((i) => i.isScored))
                  CheckboxListTile(
                    key: Key('item-${it.id}'),
                    value: _itemIds.contains(it.id),
                    onChanged: (v) => setState(() => v == true ? _itemIds.add(it.id) : _itemIds.remove(it.id)),
                    title: Text(it.promptText),
                    subtitle: Text('${it.kind.name} · ${it.answerText}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  )
              else
                const Center(child: CircularProgressIndicator()),
            ],
            if (_kind == HomeworkKind.custom) ...[
              const SizedBox(height: DLSpacing.md),
              DLSectionHeader(
                arabic: 'الأسئلة',
                german: 'Fragen (${_custom.length})',
                trailing: TextButton.icon(
                  key: const Key('add-question'),
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('سؤال • Frage'),
                ),
              ),
              for (final (i, c) in _custom.indexed)
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(c.prompt),
                  subtitle: Text(c.kind == 'open' ? 'سؤال مفتوح • offen' : '✓ ${c.answer}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _custom.removeAt(i)),
                  ),
                ),
            ],
            const SizedBox(height: DLSpacing.lg),
            ListTile(
              key: const Key('homework-due'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(
                _due == null
                    ? 'بدون موعد نهائي • Keine Frist'
                    : 'آخر موعد • Frist: ${_due!.day}.${_due!.month}.${_due!.year} ${_due!.hour.toString().padLeft(2, '0')}:${_due!.minute.toString().padLeft(2, '0')}',
              ),
              trailing: _due == null
                  ? const Icon(Icons.edit_calendar_rounded)
                  : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _due = null)),
              onTap: _pickDue,
            ),
            const SizedBox(height: DLSpacing.md),
            const DLSectionHeader(arabic: 'لمن؟', german: 'Für wen?'),
            const SizedBox(height: DLSpacing.sm),
            if (classes.isNotEmpty)
              Wrap(
                spacing: DLSpacing.sm,
                children: [
                  for (final c in classes)
                    FilterChip(
                      key: Key('class-${c.id}'),
                      avatar: const Icon(Icons.groups_rounded, size: 18),
                      label: Text('${c.name} (${c.memberIds.length})'),
                      selected: _classId == c.id,
                      onSelected: (v) => setState(() {
                        _classId = v ? c.id : null;
                        if (v) _students.addAll(c.memberIds);
                      }),
                    ),
                ],
              ),
            if (students.isEmpty)
              Text('لا يوجد طلاب مرتبطون • Keine Schüler verbunden', style: theme.textTheme.bodyMedium)
            else ...[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const Key('select-all'),
                  onPressed: () => setState(() => _students.addAll(students.map((s) => s.studentId))),
                  child: const Text('الكل • Alle'),
                ),
              ),
              for (final s in students)
                CheckboxListTile(
                  key: Key('target-${s.studentId}'),
                  value: _students.contains(s.studentId),
                  onChanged: (v) =>
                      setState(() => v == true ? _students.add(s.studentId) : _students.remove(s.studentId)),
                  title: Text(s.student?.displayName ?? '—'),
                  subtitle: Text('CEFR ${s.student?.cefrLevel?.code ?? 'A1'}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog();

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  String _kind = 'quiz';
  final _prompt = TextEditingController();
  final _options = TextEditingController();
  final _answer = TextEditingController();
  int _correct = 0;

  List<String> get _opts => _options.text.split('\n').map((o) => o.trim()).where((o) => o.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final opts = _opts;
    return AlertDialog(
      title: const Text('سؤال جديد • Neue Frage'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'quiz', label: Text('اختيار')),
                ButtonSegment(value: 'write', label: Text('كتابة')),
                ButtonSegment(value: 'open', label: Text('مفتوح')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: DLSpacing.md),
            TextField(
              key: const Key('q-prompt'),
              controller: _prompt,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'السؤال • Frage'),
            ),
            const SizedBox(height: DLSpacing.md),
            if (_kind == 'quiz') ...[
              TextField(
                key: const Key('q-options'),
                controller: _options,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'الخيارات (سطر لكل خيار) • Optionen'),
                onChanged: (_) => setState(() => _correct = _correct.clamp(0, (_opts.length - 1).clamp(0, 99))),
              ),
              if (opts.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _correct.clamp(0, opts.length - 1),
                  decoration: const InputDecoration(labelText: 'الإجابة الصحيحة • Richtig'),
                  items: [for (final (i, o) in opts.indexed) DropdownMenuItem(value: i, child: Text(o))],
                  onChanged: (v) => setState(() => _correct = v ?? 0),
                ),
            ] else if (_kind == 'write')
              TextField(
                key: const Key('q-answer'),
                controller: _answer,
                decoration: const InputDecoration(labelText: 'الإجابة (بدائل بـ |) • Lösung'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء • Abbrechen')),
        FilledButton(
          key: const Key('q-save'),
          onPressed: () {
            if (_prompt.text.trim().isEmpty || (_kind == 'quiz' && opts.length < 2)) return;
            Navigator.pop(
              context,
              CustomItem(
                kind: _kind,
                prompt: _prompt.text.trim(),
                options: _kind == 'quiz' ? opts : const [],
                answer: switch (_kind) {
                  'quiz' => opts[_correct.clamp(0, opts.length - 1)],
                  'write' => _answer.text.trim(),
                  _ => '',
                },
              ),
            );
          },
          child: const Text('إضافة • Hinzufügen'),
        ),
      ],
    );
  }
}
