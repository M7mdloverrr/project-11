import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../router.dart';
import 'teacher_controllers.dart';

String _initial(String name) => name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

void _showFailure(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is AppFailure ? error.message : '$error')));
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء • Abbrechen')),
        TextButton(key: const Key('dialog-confirm'), onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return ok == true;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(teacherCodeProvider)
      ..invalidate(pendingRequestsProvider)
      ..invalidate(linkedStudentsProvider);
    await Future.wait(
      [
        ref.read(teacherCodeProvider.future),
        ref.read(pendingRequestsProvider.future),
        ref.read(linkedStudentsProvider.future),
      ].map((f) => f.then((_) {}, onError: (_) {})),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const DLLogo(size: 32),
        actions: [
          IconButton(
            key: const Key('edit-profile'),
            tooltip: 'الملف الشخصي • Profil',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => context.go(TeacherRoutes.profileSetup),
          ),
          IconButton(
            key: const Key('sign-out'),
            tooltip: 'تسجيل الخروج • Abmelden',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.lg),
          children: [
            Text(
              'مرحباً، ${profile.displayName}',
              key: const Key('dashboard-greeting'),
              style: theme.textTheme.headlineSmall,
            ),
            Text('Willkommen zurück!', textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium),
            const SizedBox(height: DLSpacing.xl),
            const TeacherCodeCard(),
            const SizedBox(height: DLSpacing.xl),
            const DLSectionHeader(arabic: 'طلبات الربط', german: 'Anfragen'),
            const SizedBox(height: DLSpacing.md),
            const PendingRequestsSection(),
            const SizedBox(height: DLSpacing.xl),
            const DLSectionHeader(arabic: 'طلابي', german: 'Meine Schüler'),
            const SizedBox(height: DLSpacing.md),
            const LinkedStudentsSection(),
          ],
        ),
      ),
    );
  }
}

class TeacherCodeCard extends ConsumerStatefulWidget {
  const TeacherCodeCard({super.key});

  @override
  ConsumerState<TeacherCodeCard> createState() => _TeacherCodeCardState();
}

class _TeacherCodeCardState extends ConsumerState<TeacherCodeCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerate() async {
    final ok = await _confirm(
      context,
      title: 'رمز جديد؟ • Neuen Code erstellen?',
      body:
          'سيتوقف الرمز الحالي عن العمل. الطلاب المرتبطون يبقون مرتبطين.\n'
          'Der alte Code wird ungültig. Verbundene Schüler bleiben verbunden.',
      action: 'رمز جديد • Neu erstellen',
    );
    if (ok) await _run(ref.read(teacherCodeProvider.notifier).generate);
  }

  Future<void> _revoke() async {
    final ok = await _confirm(
      context,
      title: 'إلغاء الرمز؟ • Code widerrufen?',
      body: 'لن يتمكن أي طالب جديد من استخدام هذا الرمز.\nNeue Schüler können diesen Code nicht mehr verwenden.',
      action: 'إلغاء الرمز • Widerrufen',
    );
    if (ok) await _run(ref.read(teacherCodeProvider.notifier).revoke);
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ • Kopiert')));
    }
  }

  Future<void> _share(String code, String name) => _run(() async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'DeutschLearn',
        text:
            'انضم إلى صفّي على DeutschLearn برمز المعلّم: $code\n'
            'Tritt meiner Klasse in DeutschLearn bei – Lehrer-Code: $code\n— $name',
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = ref.watch(teacherCodeProvider);
    return DLCard(
      key: const Key('teacher-code-card'),
      color: DLColors.mint,
      child: switch (code) {
        AsyncError(:final error) => DLBanner(
          tone: DLStatusTone.error,
          message: error is AppFailure ? error.message : '$error',
          action: TextButton(onPressed: () => ref.invalidate(teacherCodeProvider), child: const Text('إعادة • Erneut')),
        ),
        AsyncData(value: final c?) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'رمز المعلّم', german: 'Lehrer-Code'),
            const SizedBox(height: DLSpacing.md),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                c.code,
                key: const Key('teacher-code'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: DLColors.navy,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: DLSpacing.sm),
            Text(
              'شارك الرمز مع طلابك ليرسلوا طلب ربط.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: DLColors.textSecondary),
            ),
            const SizedBox(height: DLSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: DLIconAction(
                    key: const Key('code-copy'),
                    icon: Icons.copy_rounded,
                    label: 'نسخ • Kopieren',
                    onPressed: _busy ? null : () => _copy(c.code),
                  ),
                ),
                Expanded(
                  child: DLIconAction(
                    key: const Key('code-share'),
                    icon: Icons.share_rounded,
                    label: 'مشاركة • Teilen',
                    color: DLColors.blue,
                    onPressed: _busy ? null : () => _share(c.code, ref.read(currentProfileProvider).displayName),
                  ),
                ),
                Expanded(
                  child: DLIconAction(
                    key: const Key('code-regenerate'),
                    icon: Icons.autorenew_rounded,
                    label: 'جديد • Neu',
                    color: DLColors.navy,
                    onPressed: _busy ? null : _regenerate,
                  ),
                ),
                Expanded(
                  child: DLIconAction(
                    key: const Key('code-revoke'),
                    icon: Icons.block_rounded,
                    label: 'إلغاء • Widerrufen',
                    color: DLColors.error,
                    onPressed: _busy ? null : _revoke,
                  ),
                ),
              ],
            ),
          ],
        ),
        AsyncData() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'لا يوجد رمز نشط', german: 'Kein aktiver Code'),
            const SizedBox(height: DLSpacing.sm),
            Text(
              'أنشئ رمزاً ليتمكن طلابك من الارتباط بك.\nErstelle einen Code, damit Schüler sich verbinden können.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DLSpacing.lg),
            DLPrimaryButton(
              key: const Key('code-generate'),
              label: bilingualLabel('إنشاء رمز', 'Code erstellen'),
              icon: Icons.add,
              loading: _busy,
              onPressed: _busy ? null : () => _run(ref.read(teacherCodeProvider.notifier).generate),
            ),
          ],
        ),
        _ => const Padding(
          padding: EdgeInsets.all(DLSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class PendingRequestsSection extends ConsumerWidget {
  const PendingRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingRequestsProvider);
    return switch (requests) {
      AsyncError(:final error) => DLBanner(
        tone: DLStatusTone.error,
        message: error is AppFailure ? error.message : '$error',
        action: TextButton(
          onPressed: () => ref.invalidate(pendingRequestsProvider),
          child: const Text('إعادة • Erneut'),
        ),
      ),
      AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
        icon: Icons.inbox_outlined,
        message: 'لا توجد طلبات جديدة • Keine offenen Anfragen',
      ),
      AsyncData(value: final list) => Column(
        children: [
          for (final r in list)
            Padding(
              key: ValueKey(r.id),
              padding: const EdgeInsets.only(bottom: DLSpacing.md),
              child: _RequestTile(r),
            ),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile(this.request);
  final LinkRequest request;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _respond(bool approve) async {
    setState(() => _busy = true);
    try {
      await ref.read(pendingRequestsProvider.notifier).respond(widget.request.id, approve: approve);
    } catch (e) {
      if (mounted) {
        _showFailure(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.request.student?.displayName ?? '';
    final theme = Theme.of(context);
    return DLCard(
      key: Key('request-${widget.request.id}'),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: DLColors.tintYellow,
            child: Text(_initial(name), style: const TextStyle(color: DLColors.navy)),
          ),
          const SizedBox(width: DLSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                Text('يريد الانضمام • möchte beitreten', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (_busy)
            const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            IconButton.filledTonal(
              key: Key('decline-${widget.request.id}'),
              tooltip: 'رفض • Ablehnen',
              color: DLColors.error,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _respond(false),
            ),
            const SizedBox(width: DLSpacing.xs),
            IconButton.filled(
              key: Key('approve-${widget.request.id}'),
              tooltip: 'قبول • Annehmen',
              style: IconButton.styleFrom(backgroundColor: DLColors.success),
              icon: const Icon(Icons.check_rounded),
              onPressed: () => _respond(true),
            ),
          ],
        ],
      ),
    );
  }
}

class LinkedStudentsSection extends ConsumerWidget {
  const LinkedStudentsSection({super.key});

  Future<void> _disconnect(BuildContext context, WidgetRef ref, TeacherStudentLink link) async {
    final ok = await _confirm(
      context,
      title: 'فك الارتباط؟ • Verbindung trennen?',
      body: link.student?.displayName ?? '',
      action: 'فك الارتباط • Trennen',
    );
    if (!ok) return;
    try {
      await ref.read(linkedStudentsProvider.notifier).disconnect(link.id);
    } catch (e) {
      if (context.mounted) _showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(linkedStudentsProvider);
    return switch (students) {
      AsyncError(:final error) => DLBanner(
        tone: DLStatusTone.error,
        message: error is AppFailure ? error.message : '$error',
        action: TextButton(
          onPressed: () => ref.invalidate(linkedStudentsProvider),
          child: const Text('إعادة • Erneut'),
        ),
      ),
      AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
        icon: Icons.groups_outlined,
        message: 'لا يوجد طلاب مرتبطون بعد • Noch keine Schüler verbunden',
      ),
      AsyncData(value: final list) => Column(
        children: [
          for (final l in list)
            Padding(
              key: ValueKey(l.id),
              padding: const EdgeInsets.only(bottom: DLSpacing.md),
              child: DLFeatureTile(
                key: Key('student-${l.id}'),
                icon: Icons.person_rounded,
                color: DLColors.teal,
                title: l.student?.displayName ?? '',
                subtitle: 'CEFR ${l.student?.cefrLevel?.code ?? 'A1'}',
                trailing: IconButton(
                  tooltip: 'فك الارتباط • Trennen',
                  icon: const Icon(Icons.link_off, color: DLColors.error),
                  onPressed: () => _disconnect(context, ref, l),
                ),
              ),
            ),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
