import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../session.dart';

/// Signed in with an account whose role does not belong in this app.
class WrongRoleScreen extends ConsumerWidget {
  const WrongRoleScreen({super.key, required this.otherAppArabic, required this.otherAppGerman});

  final String otherAppArabic;
  final String otherAppGerman;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionControllerProvider);
    final role = s is SessionSignedIn ? s.profile.role : null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DLSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DLIconBadge(icon: Icons.swap_horiz_rounded, color: DLColors.blue, size: 72),
              const SizedBox(height: DLSpacing.lg),
              DLBilingualTitle(
                arabic: 'هذا الحساب ${role?.labelAr ?? ''}',
                german: 'Dieses Konto ist ein ${role?.labelDe ?? ''}-Konto',
                align: CrossAxisAlignment.center,
              ),
              const SizedBox(height: DLSpacing.md),
              Text('يرجى استخدام $otherAppArabic.\nBitte nutze die $otherAppGerman.', textAlign: TextAlign.center),
              const SizedBox(height: DLSpacing.xl),
              DLPrimaryButton(
                label: bilingualLabel('تسجيل الخروج', 'Abmelden'),
                icon: Icons.logout,
                onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
