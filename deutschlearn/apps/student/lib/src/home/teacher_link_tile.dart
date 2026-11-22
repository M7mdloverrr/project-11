import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../link/link_controller.dart';
import '../router.dart';

/// Summary of the teacher link that opens the link-teacher flow.
class TeacherLinkTile extends ConsumerWidget {
  const TeacherLinkTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(studentLinkProvider);
    final (subtitle, trailing) = switch (link) {
      AsyncValue(:final value?) => switch (value) {
        NoTeacherLinked() => (
          'أدخل رمز معلّمك • Lehrer-Code eingeben',
          const DLStatusChip(label: 'غير مرتبط', tone: DLStatusTone.neutral),
        ),
        LinkPendingApproval(:final link) => (
          link.teacher?.displayName ?? '',
          const DLStatusChip(label: 'بانتظار الموافقة', tone: DLStatusTone.warning),
        ),
        LinkActive(:final link) => (
          link.teacher?.displayName ?? '',
          const DLStatusChip(label: 'مرتبط', tone: DLStatusTone.success),
        ),
        LinkDisconnected() => (
          'انتهى الربط • Verbindung beendet',
          const DLStatusChip(label: 'غير مرتبط', tone: DLStatusTone.neutral),
        ),
      },
      AsyncError(:final error) => (
        error is AppFailure ? error.messageAr : '$error',
        const DLStatusChip(label: 'خطأ', tone: DLStatusTone.error),
      ),
      _ => ('…', const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))),
    };
    return DLFeatureTile(
      key: const Key('teacher-link-tile'),
      icon: Icons.co_present_rounded,
      color: DLColors.blue,
      title: bilingualLabel('معلّمي', 'Meine Lehrkraft'),
      subtitle: subtitle,
      trailing: trailing,
      onTap: () => context.push(StudentRoutes.linkTeacher),
    );
  }
}
