import 'dart:async';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../common.dart';
import '../providers.dart';

enum _UserAction { edit, resetLink, resetEmail, confirmEmail, issueCode, linkTeacher, block, unblock, delete }

class UserActionsMenu extends ConsumerWidget {
  const UserActionsMenu(this.user, {super.key});

  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final session = ref.watch(sessionControllerProvider);
    final isSelf = session is SessionSignedIn && session.user.id == u.id;
    PopupMenuItem<_UserAction> item(_UserAction a, IconData icon, String label, {Color? color}) => PopupMenuItem(
      key: Key('user-action-${a.name}'),
      value: a,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
      ),
    );
    return PopupMenuButton<_UserAction>(
      key: Key('user-menu-${u.id}'),
      tooltip: 'Actions',
      onSelected: (a) => _run(context, ref, a),
      itemBuilder: (_) => [
        item(_UserAction.edit, Icons.edit_outlined, 'Edit name, role, level'),
        item(_UserAction.resetLink, Icons.key_outlined, 'Create password reset link'),
        item(_UserAction.resetEmail, Icons.forward_to_inbox_outlined, 'E-mail password reset'),
        if (!u.isConfirmed) item(_UserAction.confirmEmail, Icons.mark_email_read_outlined, 'Mark e-mail as confirmed'),
        if (u.role == Role.teacher) item(_UserAction.issueCode, Icons.qr_code_2, 'Issue new teacher code'),
        if (u.role == Role.student) item(_UserAction.linkTeacher, Icons.link, 'Link to a teacher'),
        if (!isSelf && !u.isBlocked) item(_UserAction.block, Icons.block, 'Block sign-in', color: DLColors.error),
        if (!isSelf && u.isBlocked) item(_UserAction.unblock, Icons.lock_open, 'Unblock'),
        if (!isSelf) item(_UserAction.delete, Icons.delete_outline, 'Delete account', color: DLColors.error),
      ],
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, _UserAction a) async {
    final repo = ref.read(adminRepositoryProvider);
    final u = user;
    final who = nameOr(u.displayName, u.email);
    Future<void> act(Future<void> Function() f, String done) async {
      if (await runAction(context, f, success: done)) invalidateAdminData(ref);
    }

    switch (a) {
      case _UserAction.edit:
        await showEditUserDialog(context, ref, u);
      case _UserAction.resetLink:
        try {
          final link = await repo.createPasswordResetLink(u.id);
          if (context.mounted) await _showLinkDialog(context, who, link);
          invalidateAdminData(ref);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(backgroundColor: DLColors.error, content: Text(failureText(e))));
          }
        }
      case _UserAction.resetEmail:
        await act(() => repo.sendPasswordResetEmail(u.id), 'Reset e-mail sent to ${u.email}');
      case _UserAction.confirmEmail:
        await act(() => repo.confirmEmail(u.id), 'E-mail confirmed');
      case _UserAction.issueCode:
        if (!await confirm(
          context,
          title: 'Issue new code?',
          message: 'The current code of $who stops working.',
          action: 'Issue code',
        )) {
          return;
        }
        if (!context.mounted) return;
        AdminCode? issued;
        await act(() async => issued = await repo.issueCode(u.id), 'New code issued');
        final code = issued?.code;
        if (code != null && context.mounted) unawaited(copyText(context, code, label: 'New code $code copied'));
      case _UserAction.linkTeacher:
        await showLinkStudentDialog(context, ref, u);
      case _UserAction.block:
        if (!await confirm(
          context,
          title: 'Block $who?',
          message: 'They cannot sign in until you unblock them.',
          action: 'Block',
          destructive: true,
        )) {
          return;
        }
        if (!context.mounted) return;
        await act(() => repo.setBlocked(u.id, blocked: true), '$who is blocked');
      case _UserAction.unblock:
        await act(() => repo.setBlocked(u.id, blocked: false), '$who is unblocked');
      case _UserAction.delete:
        if (!await confirm(
          context,
          title: 'Delete $who?',
          message: 'This permanently deletes the account, its teacher codes and links. It cannot be undone.',
          action: 'Delete',
          destructive: true,
        )) {
          return;
        }
        if (!context.mounted) return;
        await act(() => repo.deleteUser(u.id), '$who was deleted');
    }
  }
}

Future<void> _showLinkDialog(BuildContext context, String who, String link) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Password reset link for $who'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send this link to the user (e.g. by WhatsApp). It works once and expires after about an hour. '
            'No e-mail is sent.',
          ),
          const SizedBox(height: DLSpacing.md),
          SelectableText(link, key: const Key('reset-link'), style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      FilledButton.icon(
        onPressed: () => copyText(context, link, label: 'Link copied'),
        icon: const Icon(Icons.copy),
        label: const Text('Copy link'),
      ),
    ],
  ),
);

Future<void> showEditUserDialog(BuildContext context, WidgetRef ref, AdminUser u) =>
    showDialog<void>(context: context, builder: (_) => _EditUserDialog(u));

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog(this.user);
  final AdminUser user;

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final _name = TextEditingController(text: widget.user.displayName);
  late Role _role = widget.user.role;
  late CefrLevel _level = widget.user.cefrLevel;
  late String _locale = widget.user.locale;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = widget.user;
    if (_role != u.role &&
        !await confirm(
          context,
          title: 'Change role to ${_role.labelEn}?',
          message: 'All current links and the teacher code of this user end.',
          action: 'Change role',
          destructive: true,
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .updateUser(
            u.id,
            AdminProfileUpdate(
              displayName: _name.text.trim() == u.displayName ? null : _name.text.trim(),
              role: _role == u.role ? null : _role,
              cefrLevel: _level == u.cefrLevel ? null : _level,
              locale: _locale == u.locale ? null : _locale,
            ),
          ),
      success: 'Saved',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      invalidateAdminData(ref);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return AlertDialog(
      title: Text('Edit ${nameOr(u.displayName, u.email)}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(u.email, style: const TextStyle(color: DLColors.textSecondary)),
            const SizedBox(height: DLSpacing.lg),
            TextField(
              key: const Key('edit-name'),
              controller: _name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: DLSpacing.md),
            DropdownButtonFormField<Role>(
              key: const Key('edit-role'),
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [for (final r in Role.values) DropdownMenuItem(value: r, child: Text(r.labelEn))],
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
            const SizedBox(height: DLSpacing.md),
            DropdownButtonFormField<CefrLevel>(
              key: const Key('edit-level'),
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'German level (CEFR)'),
              items: [for (final l in CefrLevel.values) DropdownMenuItem(value: l, child: Text(l.code))],
              onChanged: (l) => setState(() => _level = l ?? _level),
            ),
            const SizedBox(height: DLSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _locale,
              decoration: const InputDecoration(labelText: 'App language'),
              items: [for (final e in localeLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (l) => setState(() => _locale = l ?? _locale),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('edit-save'), onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}

Future<void> showCreateUserDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(context: context, builder: (_) => const _CreateUserDialog());

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  Role _role = Role.teacher;
  String _locale = 'ar';
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final withPassword = _password.text.isNotEmpty;
    final ok = await runAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .createUser(
            AdminNewUser(
              email: _email.text.trim(),
              role: _role,
              displayName: _name.text.trim(),
              locale: _locale,
              password: withPassword ? _password.text : null,
            ),
          ),
      success: withPassword
          ? 'Account created. They can sign in now.'
          : 'Invitation e-mail sent to ${_email.text.trim()}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      invalidateAdminData(ref);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add user'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('create-email'),
                controller: _email,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()))
                    ? 'Enter a valid e-mail address'
                    : null,
              ),
              const SizedBox(height: DLSpacing.md),
              TextFormField(
                key: const Key('create-name'),
                controller: _name,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              DropdownButtonFormField<Role>(
                key: const Key('create-role'),
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [for (final r in Role.values) DropdownMenuItem(value: r, child: Text(r.labelEn))],
                onChanged: (r) => setState(() => _role = r ?? _role),
              ),
              const SizedBox(height: DLSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _locale,
                decoration: const InputDecoration(labelText: 'App language'),
                items: [for (final e in localeLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (l) => setState(() => _locale = l ?? _locale),
              ),
              const SizedBox(height: DLSpacing.md),
              TextFormField(
                key: const Key('create-password'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (optional)',
                  helperText: 'Leave empty to send an invitation e-mail instead.',
                  helperMaxLines: 2,
                ),
                validator: (v) => (v != null && v.isNotEmpty && v.length < 8) ? 'Use at least 8 characters' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('create-submit'), onPressed: _busy ? null : _create, child: const Text('Create')),
      ],
    );
  }
}

Future<void> showLinkStudentDialog(BuildContext context, WidgetRef ref, AdminUser student) =>
    showDialog<void>(context: context, builder: (_) => _LinkStudentDialog(student));

class _LinkStudentDialog extends ConsumerStatefulWidget {
  const _LinkStudentDialog(this.student);
  final AdminUser student;

  @override
  ConsumerState<_LinkStudentDialog> createState() => _LinkStudentDialogState();
}

class _LinkStudentDialogState extends ConsumerState<_LinkStudentDialog> {
  String? _teacherId;
  bool _busy = false;

  Future<void> _link() async {
    final id = _teacherId;
    if (id == null) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(adminRepositoryProvider).linkStudent(teacherId: id, studentId: widget.student.id),
      success: 'Linked',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      invalidateAdminData(ref);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersProvider);
    return AlertDialog(
      title: Text('Link ${nameOr(widget.student.displayName, widget.student.email)} to a teacher'),
      content: SizedBox(
        width: 420,
        child: AsyncView<List<AdminUser>>(
          value: teachers,
          onRetry: () => ref.invalidate(teachersProvider),
          builder: (list) => list.isEmpty
              ? const Text('There are no teachers yet.')
              : DropdownButtonFormField<String>(
                  key: const Key('link-teacher'),
                  isExpanded: true,
                  initialValue: _teacherId,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: [
                    for (final t in list)
                      DropdownMenuItem(value: t.id, child: Text('${nameOr(t.displayName)} (${t.email})')),
                  ],
                  onChanged: (v) => setState(() => _teacherId = v),
                ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          key: const Key('link-submit'),
          onPressed: _busy || _teacherId == null ? null : _link,
          child: const Text('Link now'),
        ),
      ],
    );
  }
}
