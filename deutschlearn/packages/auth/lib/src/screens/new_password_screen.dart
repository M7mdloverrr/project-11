import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../session.dart';
import '../validators.dart';
import 'auth_scaffold.dart';

/// Shown after opening a password-reset link.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authGatewayProvider).updatePassword(_password.text);
      await ref.read(sessionControllerProvider.notifier).passwordUpdated();
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DLBilingualTitle(arabic: 'كلمة مرور جديدة', german: 'Neues Passwort'),
            const SizedBox(height: DLSpacing.xl),
            TextFormField(
              controller: _password,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: bilingualLabel('كلمة المرور الجديدة', 'Neues Passwort')),
              validator: AuthValidators.newPassword,
            ),
            const SizedBox(height: DLSpacing.lg),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: bilingualLabel('تأكيد كلمة المرور', 'Passwort bestätigen')),
              validator: AuthValidators.confirmPassword(() => _password.text),
            ),
            const SizedBox(height: DLSpacing.xl),
            if (_error != null) FormErrorBanner(_error!),
            DLPrimaryButton(
              label: bilingualLabel('حفظ', 'Speichern'),
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
