import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../session.dart';

/// Honest state when SUPABASE_URL / SUPABASE_ANON_KEY are missing or invalid.
class BackendNotConfiguredScreen extends ConsumerWidget {
  const BackendNotConfiguredScreen({super.key, required this.previewRoute, required this.appName});

  /// Public screen the user can still explore (sign-in calls will fail).
  final String previewRoute;
  final String appName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionControllerProvider);
    final issues = s is SessionBackendNotConfigured ? s.issues : const <String>[];
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DLSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DLIconBadge(icon: Icons.cloud_off_rounded, color: DLColors.error, size: 72),
                  const SizedBox(height: DLSpacing.lg),
                  const DLBilingualTitle(
                    arabic: 'الخادم غير مُعد',
                    german: 'Backend nicht konfiguriert',
                    align: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: DLSpacing.lg),
                  DLCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هذه النسخة من $appName بُنيت بدون بيانات Supabase، لذلك لا يمكن تسجيل الدخول أو ربط المعلّم.\n'
                          'Dieser Build von $appName hat keine Supabase-Zugangsdaten. Anmeldung und Verknüpfung sind deaktiviert.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DLSpacing.md),
                        for (final issue in issues)
                          Padding(
                            padding: const EdgeInsets.only(bottom: DLSpacing.xs),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text('• $issue', style: theme.textTheme.bodySmall?.copyWith(color: DLColors.error)),
                            ),
                          ),
                        const SizedBox(height: DLSpacing.sm),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: SelectableText(
                            'flutter run --dart-define-from-file=../../.env',
                            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DLSpacing.xl),
                  DLSecondaryButton(
                    key: const Key('not-configured-preview'),
                    label: 'استعراض الواجهة • Oberfläche ansehen',
                    icon: Icons.visibility_outlined,
                    onPressed: () => context.go(previewRoute),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
