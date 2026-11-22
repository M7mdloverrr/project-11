import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../validators.dart';
import 'auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
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
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authGatewayProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'استعادة كلمة المرور', german: 'Passwort zurücksetzen'),
            const SizedBox(height: DLSpacing.sm),
            Text(
              'سنرسل لك رابطاً لتعيين كلمة مرور جديدة.\nWir senden dir einen Link zum Zurücksetzen.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DLSpacing.xl),
            if (_sent)
              const DLBanner(
                key: Key('reset-sent'),
                tone: DLStatusTone.success,
                message:
                    'إذا كان هناك حساب بهذا البريد فستصلك رسالة خلال دقائق.\n'
                    'Falls ein Konto existiert, erhältst du in Kürze eine E-Mail.',
              )
            else ...[
              TextFormField(
                key: const Key('reset-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: bilingualLabel('البريد الإلكتروني', 'E-Mail'),
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                validator: AuthValidators.email,
              ),
              const SizedBox(height: DLSpacing.xl),
              if (_error != null) FormErrorBanner(_error!),
              DLPrimaryButton(
                key: const Key('reset-submit'),
                label: bilingualLabel('إرسال الرابط', 'Link senden'),
                icon: Icons.send,
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
