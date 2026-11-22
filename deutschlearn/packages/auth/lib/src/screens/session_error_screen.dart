import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../session.dart';

/// Signed in, but loading the profile failed (offline, missing row, ...).
class SessionErrorScreen extends ConsumerWidget {
  const SessionErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DLSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DLBanner(
                tone: DLStatusTone.error,
                title: 'تعذر تحميل الملف الشخصي • Profil konnte nicht geladen werden',
                message: s is SessionFailed ? s.failure.message : '',
              ),
              const SizedBox(height: DLSpacing.xl),
              DLPrimaryButton(label: bilingualLabel('إعادة المحاولة', 'Erneut versuchen'), icon: Icons.refresh, onPressed: controller.retry),
              const SizedBox(height: DLSpacing.md),
              DLSecondaryButton(label: bilingualLabel('تسجيل الخروج', 'Abmelden'), icon: Icons.logout, onPressed: controller.signOut),
            ],
          ),
        ),
      ),
    );
  }
}
