import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'common.dart';

/// Centered card used by every signed-out admin screen.
class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DLSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DLLogo(size: 64, subtitle: 'Admin panel'),
                const SizedBox(height: DLSpacing.xl),
                DLCard(
                  padding: const EdgeInsets.all(DLSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: DLSpacing.lg),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminSplash extends StatelessWidget {
  const AdminSplash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DLLogo(size: 64, subtitle: 'Admin panel'),
          SizedBox(height: DLSpacing.xl),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = await ref.read(authGatewayProvider).signIn(email: _email.text.trim(), password: _password.text);
      ref.read(sessionControllerProvider.notifier).signedIn(user);
    } catch (e) {
      if (mounted) setState(() => _error = failureText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notConfigured = ref.watch(sessionControllerProvider) is SessionBackendNotConfigured;
    return _AuthCard(
      title: 'Sign in',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notConfigured) ...[
              DLBanner(
                tone: DLStatusTone.warning,
                message: failureText(const AppFailure(FailureKind.backendNotConfigured)),
              ),
              const SizedBox(height: DLSpacing.lg),
            ],
            TextFormField(
              key: const Key('login-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) => (v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()))
                  ? 'Enter a valid e-mail address'
                  : null,
            ),
            const SizedBox(height: DLSpacing.lg),
            TextFormField(
              key: const Key('login-password'),
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('login-forgot'),
                onPressed: () => context.push(AuthRoutes.resetPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_error != null) ...[
              DLBanner(key: const Key('login-error'), tone: DLStatusTone.error, message: _error!),
              const SizedBox(height: DLSpacing.md),
            ],
            DLPrimaryButton(
              key: const Key('login-submit'),
              label: 'Sign in',
              icon: Icons.login,
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminResetPasswordScreen extends ConsumerStatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  ConsumerState<AdminResetPasswordScreen> createState() => _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState extends ConsumerState<AdminResetPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authGatewayProvider).sendPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = failureText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      title: 'Reset password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sent)
            const DLBanner(
              tone: DLStatusTone.success,
              message: 'If this account exists, an e-mail with a reset link is on its way.',
            )
          else ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
            ),
            const SizedBox(height: DLSpacing.lg),
            if (_error != null) ...[
              DLBanner(tone: DLStatusTone.error, message: _error!),
              const SizedBox(height: DLSpacing.md),
            ],
            DLPrimaryButton(label: 'Send reset link', loading: _busy, onPressed: _busy ? null : _submit),
          ],
          const SizedBox(height: DLSpacing.md),
          TextButton(onPressed: () => context.go(AuthRoutes.login), child: const Text('Back to sign in')),
        ],
      ),
    );
  }
}

class AdminNewPasswordScreen extends ConsumerStatefulWidget {
  const AdminNewPasswordScreen({super.key});

  @override
  ConsumerState<AdminNewPasswordScreen> createState() => _AdminNewPasswordScreenState();
}

class _AdminNewPasswordScreenState extends ConsumerState<AdminNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authGatewayProvider).updatePassword(_password.text);
      await ref.read(sessionControllerProvider.notifier).passwordUpdated();
    } catch (e) {
      if (mounted) setState(() => _error = failureText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      title: 'Choose a new password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('new-password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password (at least 8 characters)'),
              validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
            ),
            const SizedBox(height: DLSpacing.lg),
            if (_error != null) ...[
              DLBanner(tone: DLStatusTone.error, message: _error!),
              const SizedBox(height: DLSpacing.md),
            ],
            DLPrimaryButton(label: 'Save password', loading: _busy, onPressed: _busy ? null : _submit),
          ],
        ),
      ),
    );
  }
}

class AdminWrongRoleScreen extends ConsumerWidget {
  const AdminWrongRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AuthCard(
    title: 'Admins only',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DLBanner(
          tone: DLStatusTone.warning,
          message: 'This account is not an admin. Students and teachers use the Android apps.',
        ),
        const SizedBox(height: DLSpacing.lg),
        DLSecondaryButton(
          label: 'Sign out',
          icon: Icons.logout,
          onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
        ),
      ],
    ),
  );
}

class AdminSessionErrorScreen extends ConsumerWidget {
  const AdminSessionErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionControllerProvider);
    return _AuthCard(
      title: 'Could not load your account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DLBanner(tone: DLStatusTone.error, message: s is SessionFailed ? failureText(s.failure) : 'Unknown error'),
          const SizedBox(height: DLSpacing.lg),
          DLPrimaryButton(label: 'Retry', onPressed: () => ref.read(sessionControllerProvider.notifier).retry()),
          const SizedBox(height: DLSpacing.md),
          DLSecondaryButton(label: 'Sign out', onPressed: () => ref.read(sessionControllerProvider.notifier).signOut()),
        ],
      ),
    );
  }
}

class AdminNotConfiguredScreen extends ConsumerWidget {
  const AdminNotConfiguredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionControllerProvider);
    final issues = s is SessionBackendNotConfigured ? s.issues : const <String>[];
    return _AuthCard(
      title: 'Backend not configured',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DLBanner(
            tone: DLStatusTone.warning,
            message:
                'This build has no Supabase credentials, so nothing can be loaded or changed.\n${issues.join('\n')}',
          ),
          const SizedBox(height: DLSpacing.lg),
          DLSecondaryButton(
            key: const Key('not-configured-preview'),
            label: 'Show sign-in screen',
            onPressed: () => context.go(AuthRoutes.login),
          ),
        ],
      ),
    );
  }
}
