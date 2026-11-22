import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../guard.dart';
import '../session.dart';
import '../validators.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.logoSubtitle});
  final String? logoSubtitle;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
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
      final user = await ref.read(authGatewayProvider).signIn(email: _email.text, password: _password.text);
      ref.read(sessionControllerProvider.notifier).signedIn(user);
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      logoSubtitle: widget.logoSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'تسجيل الدخول', german: 'Anmelden'),
            const SizedBox(height: DLSpacing.xl),
            TextFormField(
              key: const Key('login-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: bilingualLabel('البريد الإلكتروني', 'E-Mail'),
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: DLSpacing.lg),
            TextFormField(
              key: const Key('login-password'),
              controller: _password,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: bilingualLabel('كلمة المرور', 'Passwort'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'إظهار • Anzeigen' : 'إخفاء • Verbergen',
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: AuthValidators.loginPassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('login-forgot'),
                onPressed: () => context.push(AuthRoutes.resetPassword),
                child: Text(bilingualLabel('نسيت كلمة المرور؟', 'Passwort vergessen?')),
              ),
            ),
            const SizedBox(height: DLSpacing.md),
            if (_error != null) FormErrorBanner(_error!),
            DLPrimaryButton(
              key: const Key('login-submit'),
              label: bilingualLabel('دخول', 'Anmelden'),
              icon: Icons.login,
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: DLSpacing.lg),
            DLSecondaryButton(
              key: const Key('login-to-signup'),
              label: bilingualLabel('إنشاء حساب جديد', 'Konto erstellen'),
              onPressed: () => context.go(AuthRoutes.signUp),
            ),
          ],
        ),
      ),
    );
  }
}
