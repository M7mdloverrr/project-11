import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../session.dart';

/// Centered, scrollable layout shared by the auth screens.
class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({super.key, required this.child, this.showBack = false, this.logoSubtitle});

  final Widget child;
  final bool showBack;
  final String? logoSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notConfigured = ref.watch(sessionControllerProvider) is SessionBackendNotConfigured;
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DLSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DLLogo(size: 64, subtitle: logoSubtitle),
                  const SizedBox(height: DLSpacing.xl),
                  if (notConfigured) ...[
                    const BackendNotConfiguredBanner(),
                    const SizedBox(height: DLSpacing.lg),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackendNotConfiguredBanner extends StatelessWidget {
  const BackendNotConfiguredBanner({super.key});

  @override
  Widget build(BuildContext context) => const DLBanner(
    key: Key('backend-not-configured-banner'),
    tone: DLStatusTone.warning,
    title: 'الخادم غير مُعد • Backend nicht konfiguriert',
    message:
        'لم يتم ضبط SUPABASE_URL و SUPABASE_ANON_KEY. لن يعمل تسجيل الدخول حتى يتم ذلك.\n'
        'Anmeldung funktioniert erst, wenn SUPABASE_URL und SUPABASE_ANON_KEY gesetzt sind (siehe SETUP.md).',
  );
}

/// Error text shown under a form after a failed backend call.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DLSpacing.lg),
    child: DLBanner(key: const Key('form-error'), tone: DLStatusTone.error, message: message),
  );
}
