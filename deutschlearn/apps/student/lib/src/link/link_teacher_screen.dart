import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'link_controller.dart';

class LinkTeacherScreen extends ConsumerWidget {
  const LinkTeacherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(studentLinkProvider);
    return Scaffold(
      appBar: AppBar(title: Text(bilingualLabel('ربط المعلّم', 'Lehrkraft verbinden'))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(studentLinkProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.xl),
          children: [
            switch (link) {
              AsyncValue(:final value?) => switch (value) {
                LinkPendingApproval(:final link) => LinkStatusCard(link: link),
                LinkActive(:final link) => LinkStatusCard(link: link),
                LinkDisconnected(:final link) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [LinkStatusCard(link: link), const SizedBox(height: DLSpacing.xl), const LinkCodeFlow()],
                ),
                NoTeacherLinked() => const LinkCodeFlow(),
              },
              AsyncError(:final error) => DLBanner(
                tone: DLStatusTone.error,
                message: error is AppFailure ? error.message : '$error',
                action: TextButton(
                  onPressed: () => ref.read(studentLinkProvider.notifier).refresh(),
                  child: const Text('إعادة • Erneut'),
                ),
              ),
              _ => const Padding(padding: EdgeInsets.all(DLSpacing.xxl), child: Center(child: CircularProgressIndicator())),
            },
          ],
        ),
      ),
    );
  }
}

String _initial(String name) => name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

/// Pending / active / disconnected state of the student's link.
class LinkStatusCard extends ConsumerWidget {
  const LinkStatusCard({super.key, required this.link});
  final TeacherStudentLink link;

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فك الارتباط؟ • Verbindung trennen?'),
        content: const Text('لن يتمكن المعلّم من متابعة تقدّمك.\nDeine Lehrkraft sieht deinen Fortschritt dann nicht mehr.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء • Abbrechen')),
          TextButton(
            key: const Key('confirm-disconnect'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('فك الارتباط • Trennen', style: TextStyle(color: DLColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(studentLinkProvider.notifier).disconnect(link.id);
    } on AppFailure catch (f) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = link.teacher?.displayName ?? '';
    final (chip, tone, explanation) = switch (link.status) {
      LinkStatus.pending => (
        'بانتظار الموافقة • Wartet auf Bestätigung',
        DLStatusTone.warning,
        'أُرسل طلبك. سيظهر الربط كنشط بعد موافقة المعلّم.\nDeine Anfrage wurde gesendet.',
      ),
      LinkStatus.active => ('مرتبط • Verbunden', DLStatusTone.success, 'معلّمك يتابع تقدّمك.\nDeine Lehrkraft begleitet dich.'),
      LinkStatus.disconnected => (
        'غير مرتبط • Getrennt',
        DLStatusTone.neutral,
        'انتهى الربط السابق. يمكنك إدخال رمز جديد.\nDie Verbindung wurde beendet.',
      ),
    };
    return DLCard(
      key: Key('link-status-${link.status.name}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: DLColors.tintBlue,
                child: Text(_initial(name), style: theme.textTheme.titleLarge?.copyWith(color: DLColors.blue)),
              ),
              const SizedBox(width: DLSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: DLSpacing.xs),
                    DLStatusChip(label: chip, tone: tone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DLSpacing.md),
          Text(explanation, style: theme.textTheme.bodyMedium),
          if (link.status == LinkStatus.pending) ...[
            const SizedBox(height: DLSpacing.md),
            DLSecondaryButton(
              key: const Key('link-refresh'),
              label: bilingualLabel('تحديث الحالة', 'Status aktualisieren'),
              icon: Icons.refresh,
              onPressed: () => ref.read(studentLinkProvider.notifier).refresh(),
            ),
          ],
          if (link.status != LinkStatus.disconnected) ...[
            const SizedBox(height: DLSpacing.sm),
            TextButton.icon(
              key: const Key('link-disconnect'),
              onPressed: () => _disconnect(context, ref),
              icon: const Icon(Icons.link_off, color: DLColors.error),
              label: Text(
                link.status == LinkStatus.pending ? 'إلغاء الطلب • Anfrage zurückziehen' : 'فك الارتباط • Verbindung trennen',
                style: const TextStyle(color: DLColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enter code → see teacher public name → confirm.
class LinkCodeFlow extends ConsumerStatefulWidget {
  const LinkCodeFlow({super.key});

  @override
  ConsumerState<LinkCodeFlow> createState() => _LinkCodeFlowState();
}

class _LinkCodeFlowState extends ConsumerState<LinkCodeFlow> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(linkFlowProvider);
    final controller = ref.read(linkFlowProvider.notifier);
    final theme = Theme.of(context);

    return switch (flow) {
      LinkFlowEntering() || LinkFlowLookingUp() => DLCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLIconBadge(icon: Icons.qr_code_2_rounded, color: DLColors.blue),
            const SizedBox(height: DLSpacing.md),
            const DLBilingualTitle(arabic: 'أدخل رمز المعلّم', german: 'Lehrer-Code eingeben'),
            const SizedBox(height: DLSpacing.sm),
            Text('اطلب الرمز من معلّمك، مثال: TCH-7K2P9Q', style: theme.textTheme.bodyMedium),
            const SizedBox(height: DLSpacing.lg),
            TextField(
              key: const Key('link-code-input'),
              controller: _code,
              textDirection: TextDirection.ltr,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
                LengthLimitingTextInputFormatter(12),
              ],
              style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'TCH-XXXXXX',
                errorText: flow is LinkFlowEntering ? flow.error?.message : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              onSubmitted: (v) => controller.lookup(v),
            ),
            const SizedBox(height: DLSpacing.lg),
            DLPrimaryButton(
              key: const Key('link-lookup'),
              label: bilingualLabel('بحث عن المعلّم', 'Lehrkraft suchen'),
              icon: Icons.search,
              loading: flow is LinkFlowLookingUp,
              onPressed: flow is LinkFlowLookingUp ? null : () => controller.lookup(_code.text),
            ),
          ],
        ),
      ),
      LinkFlowPreview(:final code, :final teacher, :final submitting, :final error) => DLCard(
        key: const Key('link-preview'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'هل هذا معلّمك؟', german: 'Ist das deine Lehrkraft?'),
            const SizedBox(height: DLSpacing.lg),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: DLColors.tintTeal,
                child: Text(_initial(teacher.displayName), style: theme.textTheme.headlineMedium?.copyWith(color: DLColors.teal)),
              ),
            ),
            const SizedBox(height: DLSpacing.md),
            Text(teacher.displayName, key: const Key('link-teacher-name'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            Text(code, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium),
            const SizedBox(height: DLSpacing.lg),
            if (error != null) ...[
              DLBanner(tone: DLStatusTone.error, message: error.message),
              const SizedBox(height: DLSpacing.md),
            ],
            DLPrimaryButton(
              key: const Key('link-confirm'),
              label: bilingualLabel('تأكيد الربط', 'Verbindung anfragen'),
              icon: Icons.link,
              loading: submitting,
              onPressed: submitting ? null : controller.confirm,
            ),
            const SizedBox(height: DLSpacing.sm),
            DLSecondaryButton(
              key: const Key('link-cancel'),
              label: bilingualLabel('ليس هو', 'Falsche Person'),
              onPressed: submitting ? null : controller.reset,
            ),
          ],
        ),
      ),
      LinkFlowRequested(:final result) => DLBanner(
        key: const Key('link-requested'),
        tone: DLStatusTone.success,
        message: 'تم إرسال الطلب إلى ${result.teacherDisplayName}.\nAnfrage an ${result.teacherDisplayName} gesendet.',
      ),
    };
  }
}
