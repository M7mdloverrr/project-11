import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'common.dart';

/// True when the panel was opened from a password-reset / sign-in link.
final openedFromRecoveryLinkProvider = Provider<bool>((ref) => false);

Future<void> showSetPasswordDialog(BuildContext context, {bool fromLink = false}) => showDialog<void>(
  context: context,
  builder: (_) => _SetPasswordDialog(fromLink: fromLink),
);

class _SetPasswordDialog extends ConsumerStatefulWidget {
  const _SetPasswordDialog({required this.fromLink});
  final bool fromLink;

  @override
  ConsumerState<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends ConsumerState<_SetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authGatewayProvider).updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password saved')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = failureText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set your password'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.fromLink) ...[
                const Text('You signed in with a one-time link. Choose a password to sign in next time.'),
                const SizedBox(height: DLSpacing.lg),
              ],
              TextFormField(
                key: const Key('set-password-new'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(labelText: 'New password (at least 8 characters)'),
                validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
              ),
              const SizedBox(height: DLSpacing.md),
              TextFormField(
                key: const Key('set-password-repeat'),
                controller: _repeat,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Repeat password'),
                validator: (v) => v != _password.text ? 'The passwords do not match' : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: DLSpacing.md),
                DLBanner(tone: DLStatusTone.error, message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
        FilledButton(key: const Key('set-password-save'), onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
