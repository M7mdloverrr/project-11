import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Root-screen Back handling: [onBack] may consume Back (e.g. switch to the
/// first tab); otherwise the first press shows a hint and a second press
/// within [window] closes the app.
class DLExitGuard extends StatefulWidget {
  const DLExitGuard({super.key, required this.child, this.onBack, this.window = const Duration(seconds: 2)});

  final Widget child;
  final bool Function()? onBack;
  final Duration window;

  @override
  State<DLExitGuard> createState() => _DLExitGuardState();
}

class _DLExitGuardState extends State<DLExitGuard> {
  DateTime? _lastBack;

  void _handle() {
    if (widget.onBack?.call() ?? false) return;
    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) <= widget.window) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('exit-hint'),
          duration: widget.window,
          content: const Text('اضغط رجوع مرة أخرى للخروج • Press Back again to exit'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _handle();
    },
    child: widget.child,
  );
}
