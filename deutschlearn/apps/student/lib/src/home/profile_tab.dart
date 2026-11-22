import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'teacher_link_tile.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final session = ref.watch(sessionControllerProvider);
    final email = session is SessionSignedIn ? session.user.email : null;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(DLSpacing.lg),
      children: [
        DLCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: DLColors.tintTeal,
                child: Text(
                  profile.displayName.trim().isEmpty ? '?' : profile.displayName.trim().characters.first,
                  style: theme.textTheme.headlineMedium?.copyWith(color: DLColors.teal),
                ),
              ),
              const SizedBox(height: DLSpacing.md),
              Text(profile.displayName, style: theme.textTheme.titleLarge),
              if (email != null) Text(email, textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium),
              const SizedBox(height: DLSpacing.md),
              Wrap(
                spacing: DLSpacing.sm,
                children: [
                  DLStatusChip(label: profile.role.labelAr, tone: DLStatusTone.info),
                  DLStatusChip(label: 'CEFR ${profile.cefrLevel.code}', tone: DLStatusTone.success),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DLSpacing.xl),
        const TeacherLinkTile(),
        const SizedBox(height: DLSpacing.md),
        DLFeatureTile(
          icon: Icons.settings_rounded,
          color: DLColors.navy,
          title: bilingualLabel('الإعدادات', 'Einstellungen'),
          subtitle: 'قريباً • Demnächst',
          trailing: const DLStatusChip(label: 'قريباً', tone: DLStatusTone.neutral),
        ),
        const SizedBox(height: DLSpacing.xl),
        DLSecondaryButton(
          key: const Key('sign-out'),
          label: bilingualLabel('تسجيل الخروج', 'Abmelden'),
          icon: Icons.logout,
          color: DLColors.error,
          onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
