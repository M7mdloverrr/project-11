import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// English text for a failure; the admin panel is English-only.
String failureText(Object error) {
  if (error is! AppFailure) return 'Unexpected error: $error';
  final detail = error.detail;
  return switch (error.kind) {
    FailureKind.backendNotConfigured =>
      'Backend not configured. Build the panel with SUPABASE_URL and SUPABASE_ANON_KEY.',
    FailureKind.network => 'Cannot reach the server. Check the internet connection and try again.',
    FailureKind.invalidCredentials => 'Wrong e-mail or password.',
    FailureKind.emailNotConfirmed => 'This e-mail address is not confirmed yet.',
    FailureKind.emailInUse => 'An account with this e-mail already exists.',
    FailureKind.weakPassword => 'The password is too weak.',
    FailureKind.rateLimited => 'Too many attempts. Wait a few minutes and try again.',
    FailureKind.forbidden => 'Not allowed${detail == null ? '' : ': $detail'}',
    FailureKind.alreadyLinked => 'This student is already linked to another teacher. Disconnect that link first.',
    FailureKind.notFound || FailureKind.codeNotFound => 'Not found, or it was already handled. Refresh the page.',
    FailureKind.invalidCodeFormat => 'Invalid teacher code format.',
    FailureKind.unknown => 'Something went wrong${detail == null ? '.' : ': $detail'}',
  };
}

String formatDate(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

String nameOr(String name, [String fallback = '(no name)']) => name.trim().isEmpty ? fallback : name;

/// Shows [value]'s data, a spinner, or the error with a retry button.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.onRetry, required this.builder});

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(DLSpacing.lg),
        child: DLBanner(
          tone: DLStatusTone.error,
          title: 'Could not load',
          message: failureText(error),
          action: TextButton(key: const Key('retry'), onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(DLSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          key: const Key('confirm-action'),
          style: destructive ? FilledButton.styleFrom(backgroundColor: DLColors.error) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Runs an admin action, shows the result as a snackbar and returns whether it worked.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {required String success}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(backgroundColor: DLColors.error, content: Text(failureText(e))));
    return false;
  }
}

Future<void> copyText(BuildContext context, String text, {String label = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DLSpacing.lg),
      child: Wrap(
        spacing: DLSpacing.md,
        runSpacing: DLSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null) Text(subtitle!, style: t.bodyMedium?.copyWith(color: DLColors.textSecondary)),
            ],
          ),
          Theme(
            // The app theme makes buttons full-width; header actions stay compact.
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: Theme.of(context).filledButtonTheme.style
                    ?.copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 44))),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: Theme.of(context).outlinedButtonTheme.style
                    ?.copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 44))),
              ),
            ),
            child: Wrap(spacing: DLSpacing.sm, runSpacing: DLSpacing.sm, children: actions),
          ),
        ],
      ),
    );
  }
}

/// Scrollable, width-limited page body.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: const EdgeInsets.all(DLSpacing.xl),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

DLStatusChip roleChip(Role role) => DLStatusChip(
  label: role.labelEn,
  tone: switch (role) {
    Role.admin => DLStatusTone.warning,
    Role.teacher => DLStatusTone.info,
    Role.student => DLStatusTone.neutral,
  },
);

extension RoleEnglish on Role {
  String get labelEn => switch (this) {
    Role.student => 'Student',
    Role.teacher => 'Teacher',
    Role.admin => 'Admin',
  };
}

const localeLabels = {'ar': 'Arabic', 'de': 'German', 'en': 'English'};
