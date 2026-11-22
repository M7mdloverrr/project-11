import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../guard.dart';
import '../session.dart';
import '../validators.dart';
import 'auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.logoSubtitle});
  final String? logoSubtitle;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final gateway = ref.read(authGatewayProvider);
    try {
      final outcome = await gateway.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
        role: ref.read(signUpRoleProvider),
        locale: Localizations.localeOf(context).languageCode,
      );
      if (outcome == SignUpOutcome.signedIn) {
        final user = gateway.currentUser;
        if (user != null) ref.read(sessionControllerProvider.notifier).signedIn(user);
      } else if (mounted) {
        setState(() => _emailSent = true);
      }
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return AuthScaffold(
        logoSubtitle: widget.logoSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DLBanner(
              key: const Key('signup-email-sent'),
              tone: DLStatusTone.success,
              title: 'تحقق من بريدك • Bitte E-Mail prüfen',
              message:
                  'أرسلنا رابط التأكيد إلى ${_email.text.trim()}. افتح الرابط ثم سجّل الدخول.\n'
                  'Wir haben einen Bestätigungslink gesendet. Danach kannst du dich anmelden.',
            ),
            const SizedBox(height: DLSpacing.xl),
            DLPrimaryButton(
              label: bilingualLabel('إلى تسجيل الدخول', 'Zur Anmeldung'),
              onPressed: () => context.go(AuthRoutes.login),
            ),
          ],
        ),
      );
    }
    return AuthScaffold(
      logoSubtitle: widget.logoSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'إنشاء حساب', german: 'Konto erstellen'),
            const SizedBox(height: DLSpacing.xl),
            TextFormField(
              key: const Key('signup-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: bilingualLabel('الاسم', 'Name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: AuthValidators.displayName,
            ),
            const SizedBox(height: DLSpacing.lg),
            TextFormField(
              key: const Key('signup-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: bilingualLabel('البريد الإلكتروني', 'E-Mail'),
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: DLSpacing.lg),
            TextFormField(
              key: const Key('signup-password'),
              controller: _password,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: bilingualLabel('كلمة المرور', 'Passwort'),
                helperText: '8+ • حروف وأرقام • Buchstaben & Ziffern',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: AuthValidators.newPassword,
            ),
            const SizedBox(height: DLSpacing.lg),
            TextFormField(
              key: const Key('signup-confirm'),
              controller: _confirm,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: bilingualLabel('تأكيد كلمة المرور', 'Passwort bestätigen'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: AuthValidators.confirmPassword(() => _password.text),
            ),
            const SizedBox(height: DLSpacing.xl),
            if (_error != null) FormErrorBanner(_error!),
            DLPrimaryButton(
              key: const Key('signup-submit'),
              label: bilingualLabel('إنشاء الحساب', 'Registrieren'),
              icon: Icons.person_add_alt_1,
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: DLSpacing.lg),
            DLSecondaryButton(
              label: bilingualLabel('لدي حساب بالفعل', 'Ich habe schon ein Konto'),
              onPressed: () => context.go(AuthRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
